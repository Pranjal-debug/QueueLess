import 'dart:async';

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:queueless_client/queueless_client.dart';
import 'package:serverpod_auth_idp_flutter/serverpod_auth_idp_flutter.dart';

import '../client.dart';
import '../room_join_link.dart';
import '../design_system/app_components.dart';
import '../design_system/app_theme.dart';

class StaffScreen extends StatefulWidget {
  const StaffScreen({super.key});

  @override
  State<StaffScreen> createState() => _StaffScreenState();
}

class _StaffScreenState extends State<StaffScreen> {
  List<QueueTicket> _activeQueue = [];
  StreamSubscription<QueueEvent>? _subscription;
  Timer? _subscriptionReconnectTimer;
  Timer? _proactiveTokenRefreshTimer;
  AuthSuccess? _currentAuthInfo;
  bool _hasFatalAuthError = false;

  bool _isBusy = false;
  bool _isRefreshing = false;
  bool _loadInFlight = false;
  bool _reloadQueued = false;
  String? _errorMessage;

  List<QueueRoom> _rooms = [];
  int? _selectedRoomId;
  bool _isLoadingRooms = true;

  @override
  void initState() {
    super.initState();
    _currentAuthInfo = client.auth.authInfo;
    client.auth.authInfoListenable.addListener(_onAuthChanged);
    _proactiveTokenRefreshTimer = Timer.periodic(
      const Duration(minutes: 5),
      (_) async {
        if (mounted && client.auth.isAuthenticated) {
          try {
            await client.auth.refreshAuthKey(force: true);
          } catch (_) {}
        }
      },
    );
    _loadRoomsAndQueue();
  }

  void _onAuthChanged() {
    if (!mounted) return;
    final newAuth = client.auth.authInfo;
    final oldAuth = _currentAuthInfo;
    if (newAuth != oldAuth) {
      _currentAuthInfo = newAuth;
      _subscriptionReconnectTimer?.cancel();
      _subscription?.cancel();
      _subscription = null;
      final userChanged = newAuth?.authUserId != oldAuth?.authUserId;
      if (userChanged) {
        _rooms = [];
        _selectedRoomId = null;
        _activeQueue = [];
      }
      _hasFatalAuthError = false;
      _loadRoomsAndQueue();
    }
  }

  Future<T> _executeWithAuthRetry<T>(Future<T> Function() action) async {
    try {
      return await action();
    } catch (error) {
      if (_isUnauthorized(error)) {
        try {
          await client.auth.refreshAuthKey(force: true);
          return await action();
        } catch (_) {}
      }
      rethrow;
    }
  }

  Future<void> _loadRoomsAndQueue() async {
    try {
      final scopes = client.auth.authInfo?.scopeNames ?? {};
      if (!scopes.contains('staff')) {
        await client.queue.bootstrapStaffRole();
        await client.auth.refreshAuthKey(force: true);
      }
      final rooms = await _executeWithAuthRetry(
        () => client.queue.listAuthorizedRooms(),
      );
      if (!mounted) return;
      setState(() {
        _rooms = rooms;
        if (rooms.isNotEmpty) {
          if (_selectedRoomId == null || !rooms.any((r) => r.id == _selectedRoomId)) {
            _selectedRoomId = rooms.first.id;
          }
        } else {
          _selectedRoomId = null;
          _activeQueue = [];
        }
        _isLoadingRooms = false;
        _errorMessage = null;
        _hasFatalAuthError = false;
      });
      if (rooms.isNotEmpty) {
        unawaited(_loadQueue());
        _subscribeToQueue();
      } else {
        _subscriptionReconnectTimer?.cancel();
        _subscription?.cancel();
        _subscription = null;
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Could not load authorized rooms.';
          _isLoadingRooms = false;
        });
      }
    }
  }

  @override
  void dispose() {
    client.auth.authInfoListenable.removeListener(_onAuthChanged);
    _proactiveTokenRefreshTimer?.cancel();
    _subscriptionReconnectTimer?.cancel();
    _subscription?.cancel();
    super.dispose();
  }

  void _subscribeToQueue() {
    if (!mounted || _selectedRoomId == null) return;

    _subscriptionReconnectTimer?.cancel();
    _subscription?.cancel();
    _hasFatalAuthError = false;

    _subscription = client.queue
        .subscribeToRoomStaff(roomId: _selectedRoomId)
        .listen(
          (event) {
            if (event.action == 'deleted') {
              unawaited(_loadRoomsAndQueue());
            } else {
              unawaited(_loadQueue());
            }
          },
          onError: (error, _) async {
            if (!mounted) return;
            debugPrint(
              '[STAFF_SCREEN_DIAGNOSTIC] subscribeToRoomStaff error for room=$_selectedRoomId: $error',
            );
            if (_isUnauthorized(error)) {
              try {
                await client.auth.refreshAuthKey(force: true);
                if (mounted) {
                  debugPrint(
                    '[STAFF_SCREEN_DIAGNOSTIC] Stream refreshed auth key successfully, reconnecting...',
                  );
                  _scheduleSubscriptionReconnect();
                  unawaited(_loadQueue());
                  return;
                }
              } catch (_) {}
              _hasFatalAuthError = true;
              unawaited(_loadQueue());
              return;
            }
            unawaited(_loadQueue());
            _scheduleSubscriptionReconnect();
          },
          onDone: () {
            if (!_hasFatalAuthError) {
              _scheduleSubscriptionReconnect();
            }
          },
          cancelOnError: false,
        );
  }

  void _scheduleSubscriptionReconnect() {
    _subscription = null;
    _subscriptionReconnectTimer?.cancel();
    _subscriptionReconnectTimer = Timer(const Duration(seconds: 2), () {
      if (mounted && !_hasFatalAuthError) _subscribeToQueue();
    });
  }

  Future<void> _loadQueue() async {
    if (_loadInFlight) {
      _reloadQueued = true;
      return;
    }

    _loadInFlight = true;
    if (mounted) setState(() => _isRefreshing = true);

    if (_selectedRoomId == null) {
      _loadInFlight = false;
      if (mounted) setState(() => _isRefreshing = false);
      return;
    }

    try {
      final queue = await _executeWithAuthRetry(
        () => client.queue.getActiveQueue(roomId: _selectedRoomId),
      );
      if (!mounted) return;
      setState(() {
        _activeQueue = queue;
        _errorMessage = null;
        _hasFatalAuthError = false;
      });
    } catch (error) {
      if (!mounted) return;
      final unauthorized = _isUnauthorized(error);
      debugPrint(
        '[STAFF_SCREEN_DIAGNOSTIC] _loadQueue failed for room=$_selectedRoomId, unauthorized=$unauthorized: $error',
      );
      if (unauthorized) {
        try {
          final refreshedRooms = await client.queue.listAuthorizedRooms();
          if (!mounted) return;
          if (refreshedRooms.isNotEmpty) {
            final currentRoomValid =
                refreshedRooms.any((r) => r.id == _selectedRoomId);
            if (!currentRoomValid) {
              setState(() {
                _rooms = refreshedRooms;
                _selectedRoomId = refreshedRooms.first.id;
                _activeQueue = [];
                _errorMessage = null;
                _hasFatalAuthError = false;
              });
              _subscribeToQueue();
              unawaited(_loadQueue());
              return;
            }
          } else {
            setState(() {
              _rooms = [];
              _selectedRoomId = null;
              _activeQueue = [];
              _errorMessage = null;
              _hasFatalAuthError = false;
            });
            return;
          }
        } catch (_) {}
      }
      setState(() {
        // Never leave previously fetched privileged data visible after an
        // authorization failure.
        if (unauthorized) {
          _activeQueue = [];
          _hasFatalAuthError = true;
        }
        _errorMessage = unauthorized
            ? 'You don’t have permission to manage this room. Sign in with an authorized staff account.'
            : 'We couldn’t load the queue. Check your connection and try again.';
      });
    } finally {
      _loadInFlight = false;
      if (mounted) {
        setState(() => _isRefreshing = false);
        if (_reloadQueued) {
          _reloadQueued = false;
          unawaited(_loadQueue());
        }
      }
    }
  }

  Future<void> _callNext() async {
    if (_isBusy || _isRefreshing) return;
    setState(() {
      _isBusy = true;
      _errorMessage = null;
    });

    try {
      final ticket = await _executeWithAuthRetry(
        () => client.queue.callNext(roomId: _selectedRoomId),
      );
      if (!mounted) return;
      if (ticket == null) {
        setState(
          () => _errorMessage = 'There are no waiting customers right now.',
        );
      } else {
        await _loadQueue();
      }
    } catch (error) {
      if (mounted) {
        setState(
          () => _errorMessage = _actionError(error, 'call next customer'),
        );
      }
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _signOut() async {
    try {
      await client.auth.signOutDevice();
    } catch (_) {
      if (mounted) {
        setState(
          () => _errorMessage = 'We couldn’t sign you out. Please try again.',
        );
      }
    }
  }

  Future<void> _completeTicket(int ticketId) async {
    if (_isBusy || _isRefreshing) return;
    setState(() {
      _isBusy = true;
      _errorMessage = null;
    });

    try {
      final success = await _executeWithAuthRetry(
        () => client.queue.completeTicket(ticketId),
      );
      if (!mounted) return;
      if (success) {
        await _loadQueue();
      } else {
        setState(() => _errorMessage = 'That ticket could not be completed.');
      }
    } catch (error) {
      if (mounted) {
        setState(
          () => _errorMessage = _actionError(error, 'complete that ticket'),
        );
      }
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  bool _isUnauthorized(Object error) {
    final message = error.toString().toLowerCase();
    return message.contains('unauthorized') ||
        message.contains('access denied');
  }

  String _actionError(Object error, String action) {
    if (_isUnauthorized(error)) {
      return 'You don’t have permission to $action in this room.';
    }
    return 'We couldn’t $action. Check your connection and try again.';
  }

  QueueRoom? _selectedRoom() {
    final selectedRoomId = _selectedRoomId;
    if (selectedRoomId == null) return null;
    for (final room in _rooms) {
      if (room.id == selectedRoomId) return room;
    }
    return null;
  }

  String? _selectedRoomJoinUrl() {
    final room = _selectedRoom();
    return buildRoomJoinUrl(roomId: room?.id);
  }

  Future<void> _showRoomQrCode() async {
    final room = _selectedRoom();
    final joinUrl = _selectedRoomJoinUrl();
    if (room == null || joinUrl == null) {
      if (mounted) {
        setState(
          () => _errorMessage =
              'This room does not have a valid customer joining link.',
        );
      }
      return;
    }

    final screenWidth = MediaQuery.sizeOf(context).width;
    final qrSize = (screenWidth * 0.55).clamp(160.0, 220.0);

    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Join ${room.name}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Semantics(
                label: 'QR code for ${room.name}',
                child: QrImageView(
                  data: joinUrl,
                  version: QrVersions.auto,
                  size: qrSize,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              const Text(
                'Customers can scan this code to open the selected room. The text link remains available as a fallback.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.md),
              SelectableText(joinUrl, textAlign: TextAlign.center),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _showCreateRoomDialog() async {
    final controller = TextEditingController();
    final roomName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create a room'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 80,
          textInputAction: TextInputAction.done,
          decoration: const InputDecoration(
            labelText: 'Room name',
            hintText: 'e.g. Exam Cell',
            prefixIcon: Icon(Icons.door_front_door_outlined),
          ),
          onSubmitted: (_) => Navigator.of(context).pop(controller.text),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: const Text('Create room'),
          ),
        ],
      ),
    );
    controller.dispose();

    final trimmedName = roomName?.trim();
    if (trimmedName == null || trimmedName.isEmpty) return;
    await _createRoom(trimmedName);
  }

  Future<void> _createRoom(String name) async {
    if (_isBusy || _isRefreshing) return;
    setState(() {
      _isBusy = true;
      _errorMessage = null;
    });

    try {
      final room = await _executeWithAuthRetry(
        () => client.queue.createRoom(name),
      );
      if (!mounted) return;
      final rooms = [..._rooms.where((item) => item.id != room.id), room]
        ..sort((a, b) => (a.id ?? 0).compareTo(b.id ?? 0));
      setState(() {
        _rooms = rooms;
        _selectedRoomId = room.id;
        _activeQueue = [];
      });
      _subscribeToQueue();
      await _loadQueue();
    } catch (error) {
      if (mounted) {
        setState(
          () => _errorMessage = _actionError(error, 'create that room'),
        );
      }
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _confirmAndRestartQueue() async {
    final room = _selectedRoom();
    if (room == null || _isBusy || _isRefreshing) return;

    final servingCount =
        _activeQueue.where((t) => t.status == 'serving').length;
    final waitingCount =
        _activeQueue.where((t) => t.status == 'waiting').length;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Restart queue for ${room.name}?'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Starting a new queue session will restart ticket numbering at #1 for ${room.name}.',
              ),
              const SizedBox(height: AppSpacing.sm),
              if (servingCount > 0 || waitingCount > 0)
                Text(
                  'Notice: There are currently $servingCount serving and $waitingCount waiting tickets. These active tickets will be closed and cancelled. Old ticket history is preserved and will not be deleted.',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.warning,
                  ),
                )
              else
                const Text(
                  'Existing ticket history is preserved. New customer joins will begin at ticket #1.',
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.warning,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Restart queue'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;
    await _restartQueue();
  }

  Future<void> _restartQueue() async {
    final roomId = _selectedRoomId;
    if (roomId == null || _isBusy || _isRefreshing) return;

    setState(() {
      _isBusy = true;
      _errorMessage = null;
    });

    try {
      await _executeWithAuthRetry(
        () => client.queue.restartQueue(roomId),
      );
      if (!mounted) return;
      await _loadQueue();
    } catch (error) {
      if (mounted) {
        setState(
          () => _errorMessage = _actionError(error, 'restart the queue'),
        );
      }
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _confirmAndDeleteRoom() async {
    final room = _selectedRoom();
    if (room == null || _isBusy || _isRefreshing) return;

    final servingCount =
        _activeQueue.where((t) => t.status == 'serving').length;
    final waitingCount =
        _activeQueue.where((t) => t.status == 'waiting').length;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete room "${room.name}"?'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Are you sure you want to delete "${room.name}"? This action cannot be undone.',
              ),
              const SizedBox(height: AppSpacing.sm),
              if (servingCount > 0 || waitingCount > 0)
                Text(
                  'Warning: This room currently has $servingCount serving and $waitingCount waiting tickets. All active tickets and the current queue session will be closed and cancelled. The room will be removed from customer and staff discovery.',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.danger,
                  ),
                )
              else
                const Text(
                  'The room will be removed from customer discovery and your staff workspace. Historical ticket records are safely preserved for audit.',
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.danger,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete room'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;
    await _deleteRoom(room.id!);
  }

  Future<void> _deleteRoom(int roomId) async {
    if (_isBusy || _isRefreshing) return;

    setState(() {
      _isBusy = true;
      _errorMessage = null;
    });

    try {
      await _executeWithAuthRetry(
        () => client.queue.deleteRoom(roomId),
      );
      if (!mounted) return;
      _subscriptionReconnectTimer?.cancel();
      _subscription?.cancel();
      _subscription = null;
      await _loadRoomsAndQueue();
    } catch (error) {
      if (mounted) {
        setState(
          () => _errorMessage = _actionError(error, 'delete this room'),
        );
      }
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final servingTickets = _activeQueue
        .where((t) => t.status == 'serving')
        .toList();
    final waitingTickets = _activeQueue
        .where((t) => t.status == 'waiting')
        .toList();

    final isCompactAppBar = MediaQuery.sizeOf(context).width < 600;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Staff workspace'),
        actions: [
          if (_rooms.isNotEmpty && !_isLoadingRooms)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.sm),
              child: SizedBox(
                width: isCompactAppBar ? 124 : 180,
                child: DropdownButton<int>(
                  value: _selectedRoomId,
                  isExpanded: true,
                  underline: const SizedBox(),
                  items: _rooms
                      .map(
                        (r) => DropdownMenuItem(
                          value: r.id,
                          child: Text(
                            r.name,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: _isBusy || _isRefreshing
                      ? null
                      : (val) {
                          setState(() {
                            _selectedRoomId = val;
                            _activeQueue = [];
                          });
                          _subscribeToQueue();
                          _loadQueue();
                        },
                ),
              ),
            ),
          IconButton(
            onPressed: _isBusy || _isRefreshing
                ? null
                : _showCreateRoomDialog,
            icon: const Icon(Icons.add_business_outlined),
            tooltip: 'Create room',
          ),
          IconButton(
            onPressed: _isBusy || _isRefreshing
                ? null
                : _loadRoomsAndQueue,
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh queue',
          ),
          IconButton(
            onPressed: _isBusy ? null : _signOut,
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Sign out',
          ),
          const SizedBox(width: AppSpacing.xs),
        ],
      ),
      body: SafeArea(
        child: _isRefreshing && _activeQueue.isEmpty
            ? const AppLoadingState(message: 'Loading the room queue…')
            : LayoutBuilder(
                builder: (context, constraints) {
                  final horizontalPadding = constraints.maxWidth < 360
                      ? AppSpacing.sm
                      : AppSpacing.lg;
                  return RefreshIndicator(
                    onRefresh: _loadRoomsAndQueue,
                    color: AppColors.accent,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: EdgeInsets.fromLTRB(
                        horizontalPadding,
                        AppSpacing.md,
                        horizontalPadding,
                        AppSpacing.xxl,
                      ),
                      children: [
                        Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 1120),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                            if (_rooms.isEmpty && !_isLoadingRooms) ...[
                              const AppPageIntro(
                                eyebrow: 'Staff workspace',
                                title: 'Rooms & Queues',
                                description:
                                    'Create your first room to start calling customers and managing queues.',
                              ),
                              if (_errorMessage != null) ...[
                                const SizedBox(height: AppSpacing.md),
                                AppFeedbackBanner(
                                  message: _errorMessage!,
                                  onDismiss: () =>
                                      setState(() => _errorMessage = null),
                                  onRetry: _loadRoomsAndQueue,
                                ),
                              ],
                              const SizedBox(height: AppSpacing.xl),
                              Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const AppEmptyState(
                                      icon: Icons.meeting_room_outlined,
                                      title: 'No rooms yet',
                                      message:
                                          'You do not have access to any rooms yet. Create a room to start serving customers.',
                                    ),
                                    const SizedBox(height: AppSpacing.sm),
                                    FilledButton.icon(
                                      onPressed: _isBusy || _isRefreshing
                                          ? null
                                          : _showCreateRoomDialog,
                                      icon: const Icon(Icons.add_business_outlined),
                                      label: const Text('Create a room'),
                                    ),
                                  ],
                                ),
                              ),
                            ] else ...[
                              AppPageIntro(
                                eyebrow: 'Staff workspace',
                                title:
                                    '${_selectedRoom()?.name ?? 'Selected'} room queue',
                                description:
                                    'A live view of the people waiting and the tickets currently being served.',
                              ),
                              const SizedBox(height: AppSpacing.xl),
                              _buildPrimaryAction(waitingTickets.length),
                              if (_errorMessage != null) ...[
                                const SizedBox(height: AppSpacing.md),
                                AppFeedbackBanner(
                                  message: _errorMessage!,
                                  onDismiss: () =>
                                      setState(() => _errorMessage = null),
                                  onRetry: _loadQueue,
                                ),
                              ],
                              const SizedBox(height: AppSpacing.xl),
                              if (servingTickets.isNotEmpty) ...[
                                AppSectionHeading(
                                  title: 'Currently serving',
                                  trailing: '${servingTickets.length} active',
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                ...servingTickets.map(
                                  (ticket) => Padding(
                                    padding: const EdgeInsets.only(
                                      bottom: AppSpacing.sm,
                                    ),
                                    child: _buildTicketCard(
                                      ticket,
                                      isServing: true,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.lg),
                              ],
                              AppSectionHeading(
                                title: 'Waiting in line',
                                trailing: '${waitingTickets.length} waiting',
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              if (waitingTickets.isEmpty)
                                const AppEmptyState(
                                  icon: Icons.inbox_outlined,
                                  title: 'The queue is clear',
                                  message:
                                      'New customers will appear here when they join.',
                                )
                              else
                                ...waitingTickets.map(
                                  (ticket) => Padding(
                                    padding: const EdgeInsets.only(
                                      bottom: AppSpacing.sm,
                                    ),
                                    child: _buildTicketCard(ticket),
                                  ),
                                ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
      ),
    );
  }

  Widget _buildPrimaryAction(int waitingCount) {
    return AppSurface(
      color: AppColors.accentSoft,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final joinUrl = _selectedRoomJoinUrl();
          final copy = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Move the line forward',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                waitingCount == 0
                    ? 'No one is waiting at the moment.'
                    : '$waitingCount ${waitingCount == 1 ? 'customer is' : 'customers are'} ready to be called.',
              ),
              if (joinUrl != null) ...[
                const SizedBox(height: AppSpacing.md),
                SelectableText(
                  'Join link: $joinUrl',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.inkMuted,
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.md),
              AppQueueFlow(
                waitingCount: waitingCount,
                servingCount: _activeQueue
                    .where((ticket) => ticket.status == 'serving')
                    .length,
              ),
            ],
          );

          final callNextButton = AppPrimaryButton(
            label: 'Call next customer',
            icon: Icons.campaign_outlined,
            onPressed: _callNext,
            busy: _isBusy,
          );
          final shareButton = AppSecondaryButton(
            label: 'Share room',
            icon: Icons.qr_code_2_rounded,
            onPressed: joinUrl == null ? null : _showRoomQrCode,
          );
          final createButton = AppSecondaryButton(
            label: 'Create room',
            icon: Icons.add_business_outlined,
            onPressed: _isBusy || _isRefreshing ? null : _showCreateRoomDialog,
          );
          final restartButton = AppSecondaryButton(
            label: 'Restart queue',
            icon: Icons.restart_alt_rounded,
            foregroundColor: AppColors.warning,
            borderColor: AppColors.warning.withValues(alpha: 0.5),
            onPressed:
                _isBusy || _isRefreshing ? null : _confirmAndRestartQueue,
          );
          final deleteButton = AppSecondaryButton(
            label: 'Delete room',
            icon: Icons.delete_outline_rounded,
            foregroundColor: AppColors.danger,
            borderColor: AppColors.danger.withValues(alpha: 0.5),
            onPressed:
                _isBusy || _isRefreshing ? null : _confirmAndDeleteRoom,
          );

          final actionsList = [
            createButton,
            shareButton,
            restartButton,
            deleteButton,
            callNextButton,
          ];

          if (constraints.maxWidth < 640) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                copy,
                const SizedBox(height: AppSpacing.lg),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: actionsList,
                ),
              ],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: copy),
              const SizedBox(width: AppSpacing.lg),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 380),
                child: Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  alignment: WrapAlignment.end,
                  children: actionsList,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTicketCard(QueueTicket ticket, {bool isServing = false}) {
    return AppSurface(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final ticketMarker = Container(
            width: 58,
            height: 58,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isServing ? AppColors.warningSoft : AppColors.surfaceMuted,
              borderRadius: BorderRadius.circular(AppRadii.md),
            ),
            child: Text(
              '#${ticket.ticketNumber}',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: isServing ? AppColors.warning : AppColors.ink,
                fontWeight: FontWeight.w800,
              ),
            ),
          );

          final details = Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ticket.customerName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Joined ${_formatTime(ticket.createdAt)}'
                    '${isServing && ticket.calledAt != null ? '  •  Called ${_formatTime(ticket.calledAt!)}' : ''}',
                  ),
                ],
              ),
            ),
          );

          final action = isServing
              ? AppPrimaryButton(
                  label: 'Complete',
                  icon: Icons.check_rounded,
                  onPressed: () => _completeTicket(ticket.id!),
                  busy: _isBusy,
                )
              : const AppStatusBadge(
                  label: 'Waiting',
                  icon: Icons.schedule_outlined,
                  tone: AppStatusTone.accent,
                );
          final mobileStatus = isServing
              ? const AppStatusBadge(
                  label: 'Serving',
                  icon: Icons.campaign_outlined,
                  tone: AppStatusTone.warning,
                )
              : action;

          if (constraints.maxWidth < 600) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(children: [ticketMarker, details, mobileStatus]),
                if (isServing) ...[
                  const SizedBox(height: AppSpacing.md),
                  AppPrimaryButton(
                    label: 'Complete ticket',
                    icon: Icons.check_rounded,
                    onPressed: () => _completeTicket(ticket.id!),
                    busy: _isBusy,
                    expand: true,
                  ),
                ],
              ],
            );
          }

          return Row(children: [ticketMarker, details, action]);
        },
      ),
    );
  }

  String _formatTime(DateTime time) {
    final local = time.toLocal();
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
