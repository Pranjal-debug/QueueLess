import 'dart:async';

import 'package:flutter/material.dart';
import 'package:queueless_client/queueless_client.dart';

import '../client.dart';
import '../design_system/app_components.dart';
import '../design_system/app_theme.dart';

class CustomerScreen extends StatefulWidget {
  final Future<List<QueueRoom>> Function()? roomsLoader;
  final Stream<QueueEvent> Function()? roomsStream;
  final Uri? initialUri;

  const CustomerScreen({
    super.key,
    this.roomsLoader,
    this.roomsStream,
    this.initialUri,
  });

  @override
  State<CustomerScreen> createState() => _CustomerScreenState();
}

class _CustomerScreenState extends State<CustomerScreen>
    with WidgetsBindingObserver {
  final _nameController = TextEditingController();

  final List<_TrackedTicket> _trackedTickets = [];
  List<QueueRoom> _rooms = [];
  int? _selectedRoomId;

  bool _isJoining = false;
  bool _isLoadingRooms = true;
  bool _loadRoomsInFlight = false;
  bool _reloadRoomsQueued = false;
  String? _errorMessage;
  String? _roomLinkError;

  StreamSubscription<QueueEvent>? _roomsSubscription;
  Timer? _roomsReconnectTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadRooms();
    _subscribeToRooms();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Re-synchronize rooms list when the browser tab or app becomes active again.
      _loadRooms();
      if (_roomsSubscription == null) {
        _subscribeToRooms();
      }
    }
  }

  void _subscribeToRooms() {
    if (!mounted) return;
    _roomsReconnectTimer?.cancel();
    _roomsSubscription?.cancel();

    try {
      final stream = widget.roomsStream != null
          ? widget.roomsStream!()
          : client.queue.subscribeToRooms();

      _roomsSubscription = stream.listen(
        (event) {
          if (!mounted) return;
          // Refresh room list whenever a room is created or deleted
          _loadRooms();
        },
        onError: (_, _) {
          if (!mounted) return;
          _loadRooms();
          _scheduleRoomsReconnect();
        },
        onDone: () {
          if (!mounted) return;
          _scheduleRoomsReconnect();
        },
        cancelOnError: false,
      );
    } catch (_) {
      _scheduleRoomsReconnect();
    }
  }

  void _scheduleRoomsReconnect() {
    _roomsSubscription = null;
    _roomsReconnectTimer?.cancel();
    _roomsReconnectTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        _subscribeToRooms();
        _loadRooms();
      }
    });
  }

  Future<void> _loadRooms() async {
    if (_loadRoomsInFlight) {
      _reloadRoomsQueued = true;
      return;
    }

    _loadRoomsInFlight = true;
    if (_rooms.isEmpty && mounted) {
      setState(() {
        _isLoadingRooms = true;
        _errorMessage = null;
      });
    }

    try {
      final loader = widget.roomsLoader ?? client.queue.listRooms;
      final rooms = await loader();
      if (!mounted) return;

      final uri = widget.initialUri ?? Uri.base;
      String? roomIdParameter = uri.queryParameters['roomId'];
      if (roomIdParameter == null && uri.hasFragment) {
        final fragmentUri = Uri.tryParse(uri.fragment);
        roomIdParameter = fragmentUri?.queryParameters['roomId'];
      }

      int? selectedRoomId = _selectedRoomId;
      String? roomLinkError = _roomLinkError;

      if (_selectedRoomId != null) {
        // Customer has already selected a room in the UI: keep it if still active
        final stillExists = rooms.any((r) => r.id == _selectedRoomId);
        if (!stillExists) {
          selectedRoomId = null;
          roomLinkError =
              'The selected room is no longer available. Please choose an active room.';
        }
      } else if (roomIdParameter == null || roomIdParameter.trim().isEmpty) {
        // No roomId provided in URL -> No error! Customer chooses from the room-selection screen.
        roomLinkError = null;
        selectedRoomId = null;
      } else {
        final parsedRoomId = int.tryParse(roomIdParameter.trim());
        if (parsedRoomId == null || parsedRoomId <= 0) {
          roomLinkError =
              'This room link is invalid. Please select an active room from the list.';
          selectedRoomId = null;
        } else {
          final matchingRoom =
              rooms.where((room) => room.id == parsedRoomId).firstOrNull;
          if (matchingRoom == null) {
            roomLinkError =
                'This room is unavailable or does not exist. Please select an active room from the list.';
            selectedRoomId = null;
          } else {
            selectedRoomId = matchingRoom.id;
            roomLinkError = null;
          }
        }
      }

      setState(() {
        _rooms = rooms;
        _selectedRoomId = selectedRoomId;
        _roomLinkError = roomLinkError;
        _isLoadingRooms = false;
        if (rooms.isEmpty && roomLinkError == null) {
          _errorMessage = 'No queue rooms are available right now.';
        } else if (rooms.isNotEmpty && _errorMessage == 'No queue rooms are available right now.') {
          _errorMessage = null;
        }
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          if (_rooms.isEmpty) {
            _errorMessage = 'Could not load available rooms.';
          }
          _isLoadingRooms = false;
        });
      }
    } finally {
      _loadRoomsInFlight = false;
      if (_reloadRoomsQueued) {
        _reloadRoomsQueued = false;
        unawaited(_loadRooms());
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _roomsReconnectTimer?.cancel();
    _roomsSubscription?.cancel();
    _nameController.dispose();
    for (final trackedTicket in _trackedTickets) {
      trackedTicket.dispose();
    }
    super.dispose();
  }

  QueueRoom? _selectedRoom() {
    final selectedRoomId = _selectedRoomId;
    if (selectedRoomId == null) return null;
    for (final room in _rooms) {
      if (room.id == selectedRoomId) return room;
    }
    return null;
  }

  Future<void> _joinQueue() async {
    if (_isJoining) return;

    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _errorMessage = 'Please enter your name to get started.');
      return;
    }
    if (_selectedRoomId == null) {
      setState(
        () => _roomLinkError ??=
            'Please select a room before joining the queue.',
      );
      return;
    }

    setState(() {
      _isJoining = true;
      _errorMessage = null;
    });

    try {
      final status = await client.queue.joinQueue(
        name,
        roomId: _selectedRoomId,
      );
      if (!mounted) return;
      final ticketId = status.ticket.id;
      if (ticketId == null) {
        setState(() => _errorMessage = 'The queue returned an invalid ticket.');
        return;
      }

      final trackedTicket = _TrackedTicket(status);
      setState(() {
        _trackedTickets.insert(0, trackedTicket);
        _nameController.clear();
      });
      _subscribeToUpdates(trackedTicket);
    } catch (_) {
      if (mounted) {
        setState(() {
          _errorMessage =
              'We couldn’t join the queue right now. Please try again.';
        });
      }
    } finally {
      if (mounted) setState(() => _isJoining = false);
    }
  }

  void _subscribeToUpdates(_TrackedTicket trackedTicket) {
    if (!mounted || !_trackedTickets.contains(trackedTicket)) return;
    final ticketStatus = trackedTicket.status.ticket.status;
    if (ticketStatus == 'completed' || ticketStatus == 'cancelled') return;

    trackedTicket.reconnectTimer?.cancel();
    trackedTicket.subscription?.cancel();
    final ticket = trackedTicket.status.ticket;
    final ticketId = ticket.id;
    if (ticketId == null) return;

    trackedTicket.subscription = client.queue
        .subscribeToRoomCustomer(ticketId, ticket.accessCode)
        .listen(
          (_) => _requestRefresh(trackedTicket),
          onError: (_, _) {
            if (!mounted) return;
            _requestRefresh(trackedTicket);
            _scheduleSubscriptionReconnect(trackedTicket);
          },
          onDone: () => _scheduleSubscriptionReconnect(trackedTicket),
          cancelOnError: false,
        );
  }

  void _scheduleSubscriptionReconnect(_TrackedTicket trackedTicket) {
    if (!mounted || !_trackedTickets.contains(trackedTicket)) return;
    final ticketStatus = trackedTicket.status.ticket.status;
    if (ticketStatus == 'completed' || ticketStatus == 'cancelled') return;

    trackedTicket.subscription = null;
    trackedTicket.reconnectTimer?.cancel();
    trackedTicket.reconnectTimer = Timer(const Duration(seconds: 2), () {
      if (mounted && _trackedTickets.contains(trackedTicket)) {
        _subscribeToUpdates(trackedTicket);
      }
    });
  }

  void _requestRefresh(_TrackedTicket trackedTicket) {
    if (!mounted || !_trackedTickets.contains(trackedTicket)) return;
    if (trackedTicket.refreshing) {
      trackedTicket.refreshQueued = true;
      return;
    }
    unawaited(_refreshStatus(trackedTicket));
  }

  Future<void> _refreshStatus(_TrackedTicket trackedTicket) async {
    if (!_trackedTickets.contains(trackedTicket)) return;
    if (trackedTicket.refreshing) {
      trackedTicket.refreshQueued = true;
      return;
    }

    trackedTicket.refreshing = true;
    if (mounted) setState(() {});

    try {
      final ticket = trackedTicket.status.ticket;
      final ticketId = ticket.id;
      if (ticketId == null) return;
      final status = await client.queue.getTicketStatus(
        ticketId,
        ticket.accessCode,
      );
      if (!mounted || !_trackedTickets.contains(trackedTicket)) return;

      if (status == null) {
        _removeTrackedTicket(trackedTicket);
      } else {
        setState(() => trackedTicket.status = status);
        if (status.ticket.status == 'completed' ||
            status.ticket.status == 'cancelled') {
          trackedTicket.reconnectTimer?.cancel();
          await trackedTicket.subscription?.cancel();
          trackedTicket.subscription = null;
        } else if (trackedTicket.subscription == null) {
          _subscribeToUpdates(trackedTicket);
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _errorMessage =
              'We couldn’t update your place in line. Check your connection and try again.';
        });
      }
    } finally {
      trackedTicket.refreshing = false;
      if (mounted) {
        setState(() {});
        if (trackedTicket.refreshQueued &&
            _trackedTickets.contains(trackedTicket)) {
          trackedTicket.refreshQueued = false;
          _requestRefresh(trackedTicket);
        }
      }
    }
  }

  void _removeTrackedTicket(_TrackedTicket trackedTicket) {
    trackedTicket.dispose();
    if (!mounted) return;
    setState(() => _trackedTickets.remove(trackedTicket));
  }

  Future<void> _stopTrackingTicket(_TrackedTicket trackedTicket) async {
    final ticket = trackedTicket.status.ticket;
    final ticketId = ticket.id;
    if (ticketId == null) {
      _removeTrackedTicket(trackedTicket);
      return;
    }

    // Immediately cancel local subscription and reconnect timers
    trackedTicket.reconnectTimer?.cancel();
    await trackedTicket.subscription?.cancel();
    trackedTicket.subscription = null;

    if (ticket.status == 'waiting') {
      try {
        final updatedStatus = await client.queue.cancelTicket(
          ticketId,
          ticket.accessCode,
        );
        if (!mounted) return;
        setState(() {
          trackedTicket.status = updatedStatus;
        });
      } catch (error) {
        if (!mounted) return;
        final errorMsg = error is QueueException
            ? error.message
            : 'Could not stop tracking. Check your connection and try again.';
        setState(() {
          _errorMessage = errorMsg;
        });
      }
    } else {
      _removeTrackedTicket(trackedTicket);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: AppColors.accentSoft,
                borderRadius: BorderRadius.circular(AppRadii.sm),
              ),
              child: const Icon(
                Icons.confirmation_number_outlined,
                size: 18,
                color: AppColors.accentDark,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            const Text('QueueLess'),
          ],
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final horizontalPadding = constraints.maxWidth >= 760
                ? AppSpacing.xxl
                : constraints.maxWidth < 360
                    ? AppSpacing.md
                    : AppSpacing.lg;
            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                AppSpacing.xl,
                horizontalPadding,
                AppSpacing.xxl,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 980),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildJoinContent(),
                      if (_trackedTickets.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.xxl),
                        _buildMyQueues(),
                      ],
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildJoinContent() {
    if (_selectedRoomId == null) {
      return _buildRoomSelectionView();
    }
    return _buildJoinView();
  }

  Widget _buildRoomSelectionView() {
    return Column(
      key: const ValueKey('room-selection'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppPageIntro(
          eyebrow: 'Customer view',
          title: _roomLinkError != null
              ? 'Room unavailable'
              : 'Select a room to join the queue',
          description: _roomLinkError != null
              ? 'The requested room could not be loaded. Please choose from the active rooms below.'
              : 'Choose an active room below to check in and receive your live place in line.',
          trailing: const AppStatusBadge(
            label: 'Live updates',
            icon: Icons.wifi_tethering,
            tone: AppStatusTone.positive,
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        if (_roomLinkError != null) ...[
          AppFeedbackBanner(
            message: _roomLinkError!,
            tone: AppStatusTone.danger,
            onDismiss: () => setState(() => _roomLinkError = null),
          ),
          const SizedBox(height: AppSpacing.md),
          AppSecondaryButton(
            label: 'Return to room selection',
            icon: Icons.arrow_back_rounded,
            onPressed: () => setState(() {
              _roomLinkError = null;
              _selectedRoomId = null;
            }),
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
        if (_errorMessage != null) ...[
          AppFeedbackBanner(
            message: _errorMessage!,
            onDismiss: () => setState(() => _errorMessage = null),
            onRetry: _loadRooms,
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
        if (_isLoadingRooms)
          const AppLoadingState(message: 'Loading available rooms…')
        else if (_rooms.isEmpty)
          const AppEmptyState(
            icon: Icons.meeting_room_outlined,
            title: 'No rooms available',
            message:
                'There are currently no active queues available to join. Please check back later or ask staff for assistance.',
          )
        else ...[
          AppSectionHeading(
            title: 'Available rooms',
            trailing: '${_rooms.length} available',
          ),
          const SizedBox(height: AppSpacing.md),
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 600;
              return Wrap(
                spacing: AppSpacing.md,
                runSpacing: AppSpacing.md,
                children: _rooms.map((room) {
                  return SizedBox(
                    width: isWide
                        ? (constraints.maxWidth - AppSpacing.md) / 2
                        : double.infinity,
                    child: AppSurface(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: AppColors.accentSoft,
                                  borderRadius:
                                      BorderRadius.circular(AppRadii.sm),
                                ),
                                child: const Icon(
                                  Icons.door_front_door_outlined,
                                  color: AppColors.accentDark,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      room.name,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w700,
                                          ),
                                    ),
                                    const SizedBox(height: 2),
                                    const Text(
                                      'Active queue',
                                      style: TextStyle(
                                        color: AppColors.positive,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          AppPrimaryButton(
                            label: 'Join this room',
                            icon: Icons.arrow_forward_rounded,
                            expand: true,
                            onPressed: () {
                              setState(() {
                                _selectedRoomId = room.id;
                                _roomLinkError = null;
                                _errorMessage = null;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ],
    );
  }

  Widget _buildJoinView() {
    final selectedRoomName = _selectedRoom()?.name ?? 'Room';
    return Column(
      key: const ValueKey('join-form'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppPageIntro(
          eyebrow: 'Customer view',
          title: 'Join the $selectedRoomName queue.',
          description:
              'Join a queue in a few seconds and keep every current ticket live in this session.',
          trailing: const AppStatusBadge(
            label: 'Live updates',
            icon: Icons.wifi_tethering,
            tone: AppStatusTone.positive,
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < 720) return _buildJoinCard();
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _buildJoinStory()),
                const SizedBox(width: AppSpacing.lg),
                Expanded(child: _buildJoinCard()),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildJoinStory() {
    return AppSurface(
      color: AppColors.ink,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.accent,
              borderRadius: BorderRadius.circular(AppRadii.md),
            ),
            child: const Icon(
              Icons.waves_outlined,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            'A calmer way to wait.',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.white,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Track multiple rooms in one session while each ticket keeps its own live position and ETA.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Colors.white.withValues(alpha: 0.72),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          const _JoinBenefit(
            icon: Icons.bolt_outlined,
            text: 'Quick name-based check-in',
          ),
          const SizedBox(height: AppSpacing.md),
          const _JoinBenefit(
            icon: Icons.sync_outlined,
            text: 'Live updates as each queue moves',
          ),
          const SizedBox(height: AppSpacing.md),
          const _JoinBenefit(
            icon: Icons.layers_outlined,
            text: 'Separate tickets for separate rooms',
          ),
        ],
      ),
    );
  }

  Widget _buildJoinCard() {
    final selectedRoomName = _selectedRoom()?.name ?? 'Room';
    return AppSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Get your ticket',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              TextButton.icon(
                icon: const Icon(Icons.arrow_back, size: 16),
                label: const Text('Change room'),
                onPressed: () => setState(() {
                  _selectedRoomId = null;
                  _errorMessage = null;
                }),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'You are joining $selectedRoomName. You can track another room after this ticket is created.',
          ),
          const SizedBox(height: AppSpacing.lg),
          TextField(
            controller: _nameController,
            enabled: !_isJoining,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _joinQueue(),
            autofillHints: const [AutofillHints.name],
            decoration: const InputDecoration(
              labelText: 'Your name',
              hintText: 'e.g. Alex Morgan',
              prefixIcon: Icon(Icons.person_outline),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          _buildRoomSelector(),
          if (_roomLinkError != null) ...[
            const SizedBox(height: AppSpacing.md),
            AppFeedbackBanner(
              message: _roomLinkError!,
              tone: AppStatusTone.danger,
              onDismiss: () => setState(() => _roomLinkError = null),
            ),
          ],
          if (_errorMessage != null) ...[
            const SizedBox(height: AppSpacing.md),
            AppFeedbackBanner(
              message: _errorMessage!,
              onDismiss: () => setState(() => _errorMessage = null),
              onRetry: _rooms.isEmpty ? _loadRooms : null,
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          AppPrimaryButton(
            label: 'Join the queue',
            icon: Icons.arrow_forward_rounded,
            onPressed: _isJoining ? null : _joinQueue,
            busy: _isJoining,
            expand: true,
          ),
        ],
      ),
    );
  }

  Widget _buildRoomSelector() {
    if (_isLoadingRooms) {
      return InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Selected room',
          prefixIcon: Icon(Icons.door_front_door_outlined),
        ),
        child: Row(
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: AppSpacing.md),
            Text(
              'Loading rooms…',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.inkMuted,
                  ),
            ),
          ],
        ),
      );
    }

    if (_rooms.isEmpty) {
      return InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Selected room',
          prefixIcon: Icon(Icons.door_front_door_outlined),
        ),
        child: Text(
          'No rooms available',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.inkMuted,
              ),
        ),
      );
    }

    final currentRoom = _selectedRoom();
    if (currentRoom != null) {
      return InputDecorator(
        decoration: InputDecoration(
          labelText: 'Selected room',
          prefixIcon: const Icon(Icons.door_front_door_outlined),
          suffixIcon: TextButton(
            onPressed: () => setState(() => _selectedRoomId = null),
            child: const Text('Change'),
          ),
        ),
        child: Text(
          currentRoom.name,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
      );
    }

    return DropdownButtonFormField<int>(
      initialValue: _selectedRoomId,
      decoration: const InputDecoration(
        labelText: 'Select room',
        prefixIcon: Icon(Icons.door_front_door_outlined),
      ),
      hint: const Text('Choose a room'),
      items: _rooms.map((room) {
        return DropdownMenuItem<int>(
          value: room.id,
          child: Text(room.name),
        );
      }).toList(),
      onChanged: (val) {
        setState(() {
          _selectedRoomId = val;
          _roomLinkError = null;
        });
      },
    );
  }

  Widget _buildMyQueues() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppSectionHeading(
          title: 'My queues',
          trailing: '${_trackedTickets.length} tracked',
        ),
        const SizedBox(height: AppSpacing.sm),
        ..._trackedTickets.map(
          (trackedTicket) => Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: _buildTrackedTicket(trackedTicket),
          ),
        ),
      ],
    );
  }

  Widget _buildTrackedTicket(_TrackedTicket trackedTicket) {
    final status = trackedTicket.status;
    final ticket = status.ticket;
    final presentation = _statusPresentation(ticket.status);
    final isWaiting = ticket.status == 'waiting';
    final isCompleted =
        ticket.status == 'completed' || ticket.status == 'cancelled';
    final roomName = _rooms
        .where((room) => room.id == ticket.roomId)
        .map((room) => room.name)
        .firstOrNull;

    return AppSurface(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            roomName ?? 'Queue room',
                            style: Theme.of(context).textTheme.labelLarge
                                ?.copyWith(
                                  color: AppColors.accent,
                                  letterSpacing: 1.2,
                                ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            '#${ticket.ticketNumber}',
                            style: Theme.of(context).textTheme.displaySmall
                                ?.copyWith(color: AppColors.accentDark),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            'Hi, ${ticket.customerName}',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ],
                      ),
                    ),
                    AppStatusBadge(
                      label: presentation.label,
                      icon: presentation.icon,
                      tone: presentation.tone,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: presentation.tone == AppStatusTone.warning
                        ? AppColors.warningSoft
                        : presentation.tone == AppStatusTone.positive
                        ? AppColors.positiveSoft
                        : AppColors.accentSoft,
                    borderRadius: BorderRadius.circular(AppRadii.md),
                  ),
                  child: Text(
                    presentation.description,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: presentation.color,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (isWaiting || ticket.status == 'serving') ...[
                  const SizedBox(height: AppSpacing.md),
                  AppQueueFlow(
                    waitingCount: status.totalWaiting,
                    servingCount: ticket.status == 'serving' ? 1 : 0,
                    customerPosition: isWaiting ? status.position : null,
                  ),
                ],
                if (isWaiting) ...[
                  const SizedBox(height: AppSpacing.md),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: [
                      AppQueueMetric(
                        label: 'Current position',
                        value: '#${status.position}',
                        icon: Icons.format_list_numbered,
                        tone: AppStatusTone.accent,
                      ),
                      AppQueueMetric(
                        label: 'Estimated wait',
                        value: _formatWait(status.estimatedWaitSeconds),
                        icon: Icons.schedule_outlined,
                        tone: AppStatusTone.warning,
                      ),
                      AppQueueMetric(
                        label: 'People waiting',
                        value: '${status.totalWaiting}',
                        icon: Icons.groups_outlined,
                        tone: AppStatusTone.neutral,
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Wrap(
              alignment: WrapAlignment.end,
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                if (!isCompleted)
                  AppSecondaryButton(
                    label: 'Refresh',
                    icon: Icons.refresh_rounded,
                    onPressed: () => _refreshStatus(trackedTicket),
                    busy: trackedTicket.refreshing,
                  ),
                AppSecondaryButton(
                  label: isCompleted ? 'Remove' : 'Stop tracking',
                  icon: isCompleted
                      ? Icons.delete_outline_rounded
                      : Icons.close_rounded,
                  onPressed: () => isCompleted
                      ? _removeTrackedTicket(trackedTicket)
                      : _stopTrackingTicket(trackedTicket),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatWait(int seconds) {
    if (seconds <= 0) return 'Updating';
    if (seconds < 60) return '< 1 min';
    final minutes = (seconds / 60).round();
    return '$minutes ${minutes == 1 ? 'min' : 'mins'}';
  }

  _StatusPresentation _statusPresentation(String value) {
    switch (value) {
      case 'serving':
        return const _StatusPresentation(
          label: 'It’s your turn',
          description:
              'Please head to the service desk — your ticket is being called now.',
          icon: Icons.notifications_active_outlined,
          tone: AppStatusTone.warning,
          color: AppColors.warning,
        );
      case 'completed':
        return const _StatusPresentation(
          label: 'Completed',
          description: 'Your visit is complete. Thanks for using QueueLess.',
          icon: Icons.check_circle_outline,
          tone: AppStatusTone.positive,
          color: AppColors.positive,
        );
      case 'cancelled':
        return const _StatusPresentation(
          label: 'Cancelled',
          description: 'You’ve left this queue. Tracking has stopped.',
          icon: Icons.cancel_outlined,
          tone: AppStatusTone.neutral,
          color: AppColors.inkMuted,
        );
      default:
        return const _StatusPresentation(
          label: 'Waiting',
          description:
              'You’re safely in line. We’ll update this view as the queue moves.',
          icon: Icons.schedule_outlined,
          tone: AppStatusTone.accent,
          color: AppColors.accentDark,
        );
    }
  }
}

class _TrackedTicket {
  QueueStatus status;
  StreamSubscription<QueueEvent>? subscription;
  Timer? reconnectTimer;
  bool refreshing = false;
  bool refreshQueued = false;

  _TrackedTicket(this.status);

  void dispose() {
    reconnectTimer?.cancel();
    subscription?.cancel();
    reconnectTimer = null;
    subscription = null;
  }
}

class _JoinBenefit extends StatelessWidget {
  final IconData icon;
  final String text;

  const _JoinBenefit({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.accentSoft),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.82),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _StatusPresentation {
  final String label;
  final String description;
  final IconData icon;
  final AppStatusTone tone;
  final Color color;

  const _StatusPresentation({
    required this.label,
    required this.description,
    required this.icon,
    required this.tone,
    required this.color,
  });
}
