import 'dart:convert';
import 'package:serverpod/serverpod.dart';
import 'package:serverpod_auth_idp_server/core.dart';
import '../generated/protocol.dart';
import 'dart:math';

/// Calculates current business date in Asia/Kolkata timezone (UTC+05:30).
String getKolkataBusinessDate([DateTime? referenceTime]) {
  final utc = (referenceTime ?? DateTime.now()).toUtc();
  final kolkata = utc.add(const Duration(hours: 5, minutes: 30));
  final y = kolkata.year.toString().padLeft(4, '0');
  final m = kolkata.month.toString().padLeft(2, '0');
  final d = kolkata.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}

void _logAuthFailure(
  Session session, {
  required String category,
  required String endpoint,
  String? userId,
  int? roomId,
  String? reason,
}) {
  String tokenExpiryMeta = 'none';
  try {
    final dynamic dynSession = session;
    final dynamic httpRequest = dynSession.httpRequest;
    if (httpRequest != null) {
      final dynamic headers = httpRequest.headers;
      final authHeader = headers['authorization'];
      if (authHeader != null) {
        final String headerVal =
            (authHeader is List ? authHeader.first : authHeader).toString();
        if (headerVal.startsWith('Bearer ')) {
          final token = headerVal.substring(7);
          final parts = token.split('.');
          if (parts.length >= 2) {
            final payloadNormalized = base64Url.normalize(parts[1]);
            final payloadJson = utf8.decode(base64Url.decode(payloadNormalized));
            final payload = jsonDecode(payloadJson);
            if (payload is Map && payload.containsKey('exp')) {
              final exp = payload['exp'];
              if (exp is int) {
                final expDate =
                    DateTime.fromMillisecondsSinceEpoch(exp * 1000, isUtc: true);
                final isExpired = DateTime.now().toUtc().isAfter(expDate);
                tokenExpiryMeta =
                    'exp=${expDate.toIso8601String()}, isExpired=$isExpired';
              }
            }
          }
        }
      }
    }
  } catch (_) {
    tokenExpiryMeta = 'unparsed';
  }

  // ignore: avoid_print
  print(
    '[AUTH_DIAGNOSTIC] category=$category, endpoint=$endpoint, user=${userId ?? "anonymous"}, roomId=${roomId ?? "none"}, tokenMeta=($tokenExpiryMeta), reason=${reason ?? ""}',
  );
}

String _generateAccessCode() {
  const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
  final rnd = Random.secure();
  return String.fromCharCodes(
    Iterable.generate(6, (_) => chars.codeUnitAt(rnd.nextInt(chars.length))),
  );
}

class QueueEndpoint extends Endpoint {
  /// Separate, idempotent, concurrency-safe role bootstrap for authenticated accounts
  /// that are missing the staff scope.
  Future<bool> bootstrapStaffRole(Session session) async {
    final auth = session.authenticated;
    if (auth == null) {
      _logAuthFailure(
        session,
        category: 'NO_AUTH',
        endpoint: 'bootstrapStaffRole',
        reason: 'Login required to bootstrap staff role.',
      );
      throw QueueException(message: 'Unauthorized: Login required.');
    }

    final UuidValue userUuid;
    try {
      userUuid = UuidValue.fromString(auth.userIdentifier);
    } catch (_) {
      throw QueueException(message: 'Invalid user identifier.');
    }

    return await session.db.transaction((transaction) async {
      final authUser = await AuthUser.db.findById(
        session,
        userUuid,
        transaction: transaction,
        lockMode: LockMode.forUpdate,
      );
      if (authUser == null) {
        throw QueueException(message: 'User not found.');
      }
      if (authUser.blocked) {
        throw QueueException(message: 'User is blocked.');
      }

      if (!authUser.scopeNames.contains('staff')) {
        final updatedScopes = {...authUser.scopeNames, 'staff'};
        await AuthUser.db.updateRow(
          session,
          authUser.copyWith(scopeNames: updatedScopes),
          transaction: transaction,
        );
      }

      try {
        final rtId = UuidValue.fromString(auth.authId);
        final refreshToken = await RefreshToken.db.findById(
          session,
          rtId,
          transaction: transaction,
          lockMode: LockMode.forUpdate,
        );
        if (refreshToken != null &&
            !refreshToken.scopeNames.contains('staff')) {
          final updatedRtScopes = {...refreshToken.scopeNames, 'staff'};
          await RefreshToken.db.updateRow(
            session,
            refreshToken.copyWith(
              scopeNames: updatedRtScopes,
              lastUpdatedAt: DateTime.now(),
            ),
            transaction: transaction,
          );
        }
      } catch (_) {
        // Ignore invalid UUID authId in test environments
      }

      return true;
    });
  }

  Future<int> _getDefaultRoomIdForStaff(
    Session session,
    String staffUserId,
  ) async {
    final accesses = await StaffRoomAccess.db.find(
      session,
      where: (s) => s.userId.equals(staffUserId),
      orderBy: (s) => s.roomId,
    );
    for (final access in accesses) {
      final room = await QueueRoom.db.findById(session, access.roomId);
      if (room != null && room.deletedAt == null) {
        return room.id!;
      }
    }
    throw QueueException(message: 'No authorized rooms found for staff user.');
  }

  /// List all active, non-deleted queue rooms.
  Future<List<QueueRoom>> listRooms(Session session) async {
    return await QueueRoom.db.find(
      session,
      where: (r) => r.deletedAt.equals(null),
      orderBy: (r) => r.id,
    );
  }

  /// Create a room for an authenticated staff member and grant that member
  /// access in the same transaction as the room insert.
  Future<QueueRoom> createRoom(Session session, String roomName) async {
    final staffUserId = _requireStaffIdentity(session, 'createRoom');
    final name = roomName.trim();
    if (name.length < 2 || name.length > 80) {
      throw QueueException(
        message: 'Room name must be between 2 and 80 characters.',
      );
    }

    final room = await session.db.transaction((transaction) async {
      final existingRoom = await QueueRoom.db.findFirstRow(
        session,
        where: (r) => r.name.equals(name),
        transaction: transaction,
      );
      if (existingRoom != null) {
        if (existingRoom.deletedAt == null) {
          throw QueueException(message: 'A room with this name already exists.');
        }
      }

      final room = await QueueRoom.db.insertRow(
        session,
        QueueRoom(name: name, createdAt: DateTime.now()),
        transaction: transaction,
      );
      await StaffRoomAccess.db.insertRow(
        session,
        StaffRoomAccess(userId: staffUserId, roomId: room.id!),
        transaction: transaction,
      );
      return room;
    });

    // Notify customer room-selection screens and staff room discovery that room list has changed.
    await session.messages.postMessage(
      'customer_rooms',
      QueueEvent(roomId: room.id!, action: 'created'),
    );

    return room;
  }

  /// List active rooms the signed-in staff is authorized to access.
  Future<List<QueueRoom>> listAuthorizedRooms(Session session) async {
    final staffUserId = _requireStaffIdentity(session, 'listAuthorizedRooms');

    final accesses = await StaffRoomAccess.db.find(
      session,
      where: (s) => s.userId.equals(staffUserId),
    );

    if (accesses.isEmpty) return [];

    final roomIds = accesses.map((a) => a.roomId).toSet();

    final allActiveRooms = await QueueRoom.db.find(
      session,
      where: (r) => r.deletedAt.equals(null),
      orderBy: (r) => r.id,
    );
    return allActiveRooms.where((r) => roomIds.contains(r.id)).toList();
  }

  /// Retrieves the active QueueSession for [roomId], or creates a new one.
  /// If the current session's business date is earlier than today's Kolkata date,
  /// automatic rollover occurs: the previous session and its waiting/serving tickets
  /// are closed (cancelled), and a new session starting at ticket #1 is created.
  ///
  /// Concurrency safety: Requires a row-level lock on QueueRoom via LockMode.forUpdate.
  ///
  /// Note on scheduling: Rollover occurs on the first interaction after the business date changes
  /// rather than exactly at midnight, ensuring zero idle overhead and concurrency safety.
  Future<QueueSession> _getOrCreateActiveSession(
    Session session,
    int roomId, {
    Transaction? transaction,
    DateTime? referenceTime,
  }) async {
    final todayDate = getKolkataBusinessDate(referenceTime);

    Future<QueueSession> execute(Transaction tx) async {
      final room = await QueueRoom.db.findById(
        session,
        roomId,
        transaction: tx,
        lockMode: LockMode.forUpdate,
      );
      if (room == null) {
        throw QueueException(message: 'Room not found.');
      }
      if (room.deletedAt != null) {
        throw QueueException(
          message:
              'This room has been deleted and is no longer accepting queue entries.',
        );
      }

      final activeSession = await QueueSession.db.findFirstRow(
        session,
        where: (s) => s.roomId.equals(roomId) & s.status.equals('active'),
        orderByList: (s) => [s.id.desc()],
        transaction: tx,
        lockMode: LockMode.forUpdate,
      );

      if (activeSession != null) {
        if (activeSession.businessDate == todayDate) {
          return activeSession;
        }

        // Business date has rolled over: close old session and its active tickets
        await QueueSession.db.updateRow(
          session,
          activeSession.copyWith(
            status: 'closed',
            closedAt: DateTime.now(),
          ),
          transaction: tx,
        );

        final staleTickets = await QueueTicket.db.find(
          session,
          where: (t) =>
              t.sessionId.equals(activeSession.id!) &
              (t.status.equals('waiting') | t.status.equals('serving')),
          transaction: tx,
        );
        final now = DateTime.now();
        for (final t in staleTickets) {
          await QueueTicket.db.updateRow(
            session,
            t.copyWith(
              status: 'cancelled',
              completedAt: now,
            ),
            transaction: tx,
          );
        }
      }

      // Create new active session for today's date
      final latestSession = await QueueSession.db.findFirstRow(
        session,
        where: (s) => s.roomId.equals(roomId),
        orderByList: (s) => [s.sessionNumber.desc()],
        transaction: tx,
      );
      final nextSessionNumber = (latestSession?.sessionNumber ?? 0) + 1;

      return await QueueSession.db.insertRow(
        session,
        QueueSession(
          roomId: roomId,
          businessDate: todayDate,
          sessionNumber: nextSessionNumber,
          status: 'active',
          startedAt: DateTime.now(),
        ),
        transaction: tx,
      );
    }

    if (transaction != null) {
      return execute(transaction);
    } else {
      return session.db.transaction((tx) async => execute(tx));
    }
  }

  /// Get the current active session for [roomId], triggering rollover if date changed.
  Future<QueueSession> getActiveSession(
    Session session,
    int roomId, {
    DateTime? referenceTime,
  }) async {
    return _getOrCreateActiveSession(
      session,
      roomId,
      referenceTime: referenceTime,
    );
  }

  /// Restart the queue session for the specified room.
  /// Closes the existing active session and its waiting/serving tickets (cancelled),
  /// and atomically creates a new active session with ticket numbering starting at #1.
  Future<QueueSession> restartQueue(Session session, int roomId) async {
    _requireStaffIdentity(session, 'restartQueue');
    await _requireStaffRoomAccess(session, roomId, 'restartQueue');

    final newSession = await session.db.transaction((transaction) async {
      final room = await QueueRoom.db.findById(
        session,
        roomId,
        transaction: transaction,
        lockMode: LockMode.forUpdate,
      );
      if (room == null) {
        throw QueueException(message: 'Room not found.');
      }
      if (room.deletedAt != null) {
        throw QueueException(
          message: 'Cannot restart queue for a deleted room.',
        );
      }

      final activeSession = await QueueSession.db.findFirstRow(
        session,
        where: (s) => s.roomId.equals(roomId) & s.status.equals('active'),
        orderByList: (s) => [s.id.desc()],
        transaction: transaction,
        lockMode: LockMode.forUpdate,
      );

      if (activeSession != null) {
        await QueueSession.db.updateRow(
          session,
          activeSession.copyWith(
            status: 'closed',
            closedAt: DateTime.now(),
          ),
          transaction: transaction,
        );

        final activeTickets = await QueueTicket.db.find(
          session,
          where: (t) =>
              t.sessionId.equals(activeSession.id!) &
              (t.status.equals('waiting') | t.status.equals('serving')),
          transaction: transaction,
        );
        final now = DateTime.now();
        for (final t in activeTickets) {
          await QueueTicket.db.updateRow(
            session,
            t.copyWith(
              status: 'cancelled',
              completedAt: now,
            ),
            transaction: transaction,
          );
        }
      }

      final todayDate = getKolkataBusinessDate();
      final latestSession = await QueueSession.db.findFirstRow(
        session,
        where: (s) => s.roomId.equals(roomId),
        orderByList: (s) => [s.sessionNumber.desc()],
        transaction: transaction,
      );
      final nextSessionNumber = (latestSession?.sessionNumber ?? 0) + 1;

      return await QueueSession.db.insertRow(
        session,
        QueueSession(
          roomId: roomId,
          businessDate: todayDate,
          sessionNumber: nextSessionNumber,
          status: 'active',
          startedAt: DateTime.now(),
        ),
        transaction: transaction,
      );
    });

    await session.messages.postMessage(
      'queue_room_$roomId',
      QueueEvent(roomId: roomId, action: 'restarted'),
    );

    return newSession;
  }

  /// Safely soft-deletes a room.
  /// Requires staff authorization. Closes the active session, cancels any active tickets,
  /// and sets deletedAt timestamp. Historical tickets and room data are preserved.
  Future<bool> deleteRoom(Session session, int roomId) async {
    _requireStaffIdentity(session, 'deleteRoom');
    await _requireStaffRoomAccess(session, roomId, 'deleteRoom');

    await session.db.transaction((transaction) async {
      final room = await QueueRoom.db.findById(
        session,
        roomId,
        transaction: transaction,
        lockMode: LockMode.forUpdate,
      );
      if (room == null) {
        throw QueueException(message: 'Room not found.');
      }
      if (room.deletedAt != null) {
        return; // Idempotent
      }

      final activeSession = await QueueSession.db.findFirstRow(
        session,
        where: (s) => s.roomId.equals(roomId) & s.status.equals('active'),
        orderByList: (s) => [s.id.desc()],
        transaction: transaction,
        lockMode: LockMode.forUpdate,
      );

      if (activeSession != null) {
        await QueueSession.db.updateRow(
          session,
          activeSession.copyWith(
            status: 'closed',
            closedAt: DateTime.now(),
          ),
          transaction: transaction,
        );

        final activeTickets = await QueueTicket.db.find(
          session,
          where: (t) =>
              t.sessionId.equals(activeSession.id!) &
              (t.status.equals('waiting') | t.status.equals('serving')),
          transaction: transaction,
        );
        final now = DateTime.now();
        for (final t in activeTickets) {
          await QueueTicket.db.updateRow(
            session,
            t.copyWith(
              status: 'cancelled',
              completedAt: now,
            ),
            transaction: transaction,
          );
        }
      }

      await QueueRoom.db.updateRow(
        session,
        room.copyWith(deletedAt: DateTime.now()),
        transaction: transaction,
      );
    });

    await session.messages.postMessage(
      'queue_room_$roomId',
      QueueEvent(roomId: roomId, action: 'deleted'),
    );
    await session.messages.postMessage(
      'customer_rooms',
      QueueEvent(roomId: roomId, action: 'deleted'),
    );

    return true;
  }

  /// Join the queue. Returns the created ticket and its position.
  Future<QueueStatus> joinQueue(
    Session session,
    String customerName, {
    int? roomId,
  }) async {
    final trimmedName = customerName.trim();
    if (trimmedName.isEmpty) {
      throw Exception('Customer name cannot be empty.');
    }

    if (roomId == null) {
      throw QueueException(
        message: 'A valid room ID is required to join a queue.',
      );
    }
    if (roomId <= 0) {
      throw QueueException(message: 'Invalid room ID.');
    }

    final targetRoomId = roomId;

    final status = await session.db.transaction((transaction) async {
      // 1. Concurrency-safe retrieval / rollover of active session
      final currentSession = await _getOrCreateActiveSession(
        session,
        targetRoomId,
        transaction: transaction,
      );

      // 2. Find the current max ticket number for this session
      final latestTicket = await QueueTicket.db.findFirstRow(
        session,
        where: (t) => t.sessionId.equals(currentSession.id!),
        orderByList: (t) => [t.ticketNumber.desc()],
        transaction: transaction,
      );

      final nextTicketNumber = (latestTicket?.ticketNumber ?? 0) + 1;

      var ticket = QueueTicket(
        customerName: trimmedName,
        roomId: targetRoomId,
        sessionId: currentSession.id!,
        accessCode: _generateAccessCode(),
        ticketNumber: nextTicketNumber,
        status: 'waiting',
        createdAt: DateTime.now(),
      );

      ticket = await QueueTicket.db.insertRow(
        session,
        ticket,
        transaction: transaction,
      );

      final totalWaiting = await QueueTicket.db.count(
        session,
        where: (t) =>
            t.sessionId.equals(currentSession.id!) &
            t.status.equals('waiting'),
        transaction: transaction,
      );

      final position = totalWaiting;

      return QueueStatus(
        ticket: ticket,
        position: position,
        totalWaiting: totalWaiting,
        estimatedWaitSeconds: 0, // updated below
      );
    });

    final eta = await _calculateETA(session, targetRoomId, status.position);
    final finalStatus = status.copyWith(estimatedWaitSeconds: eta);

    await session.messages.postMessage(
      'queue_room_$targetRoomId',
      QueueEvent(roomId: targetRoomId, action: 'joined'),
    );
    return finalStatus;
  }

  /// Get the status of a specific ticket.
  Future<QueueStatus?> getTicketStatus(
    Session session,
    int ticketId,
    String accessCode,
  ) async {
    final ticket = await QueueTicket.db.findById(session, ticketId);
    if (ticket == null || ticket.accessCode != accessCode) {
      throw Exception('Unauthorized or not found.');
    }

    final activeSession = await QueueSession.db.findFirstRow(
      session,
      where: (s) => s.roomId.equals(ticket.roomId) & s.status.equals('active'),
      orderByList: (s) => [s.id.desc()],
    );

    final isTicketInActiveSession =
        activeSession != null && ticket.sessionId == activeSession.id;

    if (ticket.status != 'waiting' || !isTicketInActiveSession) {
      final totalWaiting = isTicketInActiveSession
          ? await _getTotalWaitingInSession(session, activeSession.id!)
          : 0;
      return QueueStatus(
        ticket: ticket,
        position: 0,
        totalWaiting: totalWaiting,
        estimatedWaitSeconds: 0,
      );
    }

    final position = await QueueTicket.db.count(
      session,
      where: (t) =>
          t.sessionId.equals(activeSession.id!) &
          t.status.equals('waiting') &
          (t.ticketNumber <= ticket.ticketNumber),
    );

    final totalWaiting =
        await _getTotalWaitingInSession(session, activeSession.id!);
    final eta = await _calculateETA(session, ticket.roomId, position);

    return QueueStatus(
      ticket: ticket,
      position: position,
      totalWaiting: totalWaiting,
      estimatedWaitSeconds: eta,
    );
  }

  /// Cancel a customer's waiting ticket.
  Future<QueueStatus> cancelTicket(
    Session session,
    int ticketId,
    String accessCode,
  ) async {
    final ticket = await QueueTicket.db.findById(session, ticketId);
    if (ticket == null || ticket.accessCode != accessCode) {
      throw QueueException(message: 'Unauthorized: Invalid ticket credentials.');
    }

    if (ticket.status == 'cancelled') {
      final activeSession = await QueueSession.db.findFirstRow(
        session,
        where: (s) => s.roomId.equals(ticket.roomId) & s.status.equals('active'),
        orderByList: (s) => [s.id.desc()],
      );
      final totalWaiting = (activeSession != null && ticket.sessionId == activeSession.id)
          ? await _getTotalWaitingInSession(session, activeSession.id!)
          : 0;
      return QueueStatus(
        ticket: ticket,
        position: 0,
        totalWaiting: totalWaiting,
        estimatedWaitSeconds: 0,
      );
    }

    if (ticket.status == 'serving') {
      throw QueueException(
        message: 'Cannot cancel a ticket that is currently being served.',
      );
    }

    if (ticket.status == 'completed') {
      throw QueueException(
        message: 'Cannot cancel a ticket that has already been completed.',
      );
    }

    final updatedTicket = await session.db.transaction((transaction) async {
      final lockedTicket = await QueueTicket.db.findById(
        session,
        ticketId,
        transaction: transaction,
        lockMode: LockMode.forUpdate,
      );
      if (lockedTicket == null || lockedTicket.accessCode != accessCode) {
        throw QueueException(
          message: 'Unauthorized: Invalid ticket credentials.',
        );
      }

      if (lockedTicket.status == 'cancelled') {
        return lockedTicket;
      }
      if (lockedTicket.status == 'serving') {
        throw QueueException(
          message: 'Cannot cancel a ticket that is currently being served.',
        );
      }
      if (lockedTicket.status == 'completed') {
        throw QueueException(
          message: 'Cannot cancel a ticket that has already been completed.',
        );
      }

      final toUpdate = lockedTicket.copyWith(
        status: 'cancelled',
        completedAt: DateTime.now(),
      );
      return await QueueTicket.db.updateRow(
        session,
        toUpdate,
        transaction: transaction,
      );
    });

    final activeSession = await QueueSession.db.findFirstRow(
      session,
      where: (s) =>
          s.roomId.equals(updatedTicket.roomId) & s.status.equals('active'),
      orderByList: (s) => [s.id.desc()],
    );

    final isTicketInActiveSession =
        activeSession != null && updatedTicket.sessionId == activeSession.id;

    if (isTicketInActiveSession) {
      await session.messages.postMessage(
        'queue_room_${updatedTicket.roomId}',
        QueueEvent(roomId: updatedTicket.roomId, action: 'cancelled'),
      );
    }

    final totalWaiting = isTicketInActiveSession
        ? await _getTotalWaitingInSession(session, activeSession.id!)
        : 0;

    return QueueStatus(
      ticket: updatedTicket,
      position: 0,
      totalWaiting: totalWaiting,
      estimatedWaitSeconds: 0,
    );
  }

  /// Returns currently waiting and serving tickets for the current session ordered by ticket number.
  Future<List<QueueTicket>> getActiveQueue(
    Session session, {
    int? roomId,
  }) async {
    final staffUserId = _requireStaffIdentity(session, 'getActiveQueue');
    final targetRoomId =
        roomId ?? await _getDefaultRoomIdForStaff(session, staffUserId);
    await _requireStaffRoomAccess(session, targetRoomId, 'getActiveQueue');

    final activeSession = await _getOrCreateActiveSession(
      session,
      targetRoomId,
    );

    final tickets = await QueueTicket.db.find(
      session,
      where: (t) =>
          t.sessionId.equals(activeSession.id!) &
          (t.status.equals('waiting') | t.status.equals('serving')),
      orderBy: (t) => t.ticketNumber,
    );
    // Sanitize access codes to avoid leaking them in public endpoints
    return tickets.map((t) => t.copyWith(accessCode: '')).toList();
  }

  /// Call the next waiting customer in the active session.
  Future<QueueTicket?> callNext(Session session, {int? roomId}) async {
    final staffUserId = _requireStaffIdentity(session, 'callNext');
    final targetRoomId =
        roomId ?? await _getDefaultRoomIdForStaff(session, staffUserId);
    await _requireStaffRoomAccess(session, targetRoomId, 'callNext');

    final ticket = await session.db.transaction((transaction) async {
      final activeSession = await _getOrCreateActiveSession(
        session,
        targetRoomId,
        transaction: transaction,
      );

      // Find the earliest waiting ticket in active session.
      var t = await QueueTicket.db.findFirstRow(
        session,
        where: (t) =>
            t.sessionId.equals(activeSession.id!) &
            t.status.equals('waiting'),
        orderBy: (t) => t.ticketNumber,
        transaction: transaction,
        lockMode: LockMode.forUpdate,
        lockBehavior: LockBehavior.skipLocked,
      );

      if (t == null) {
        return null;
      }

      t = t.copyWith(
        status: 'serving',
        calledAt: DateTime.now(),
      );

      return QueueTicket.db.updateRow(session, t, transaction: transaction);
    });

    if (ticket != null) {
      await session.messages.postMessage(
        'queue_room_$targetRoomId',
        QueueEvent(roomId: targetRoomId, action: 'called'),
      );
    }
    return ticket;
  }

  /// Complete a ticket that is currently being served.
  Future<bool> completeTicket(Session session, int ticketId) async {
    _requireStaffIdentity(session, 'completeTicket');
    final ticket = await QueueTicket.db.findById(session, ticketId);
    if (ticket == null) {
      throw Exception('Ticket not found.');
    }

    await _requireStaffRoomAccess(session, ticket.roomId, 'completeTicket');

    final successRoomId = await session.db.transaction((transaction) async {
      var t = await QueueTicket.db.findFirstRow(
        session,
        where: (t) => t.id.equals(ticketId) & t.status.equals('serving'),
        transaction: transaction,
        lockMode: LockMode.forUpdate,
        lockBehavior: LockBehavior.skipLocked,
      );
      if (t == null) {
        throw Exception('Ticket not found or already completed.');
      }

      t = t.copyWith(
        status: 'completed',
        completedAt: DateTime.now(),
      );

      await QueueTicket.db.updateRow(session, t, transaction: transaction);
      return t.roomId;
    });

    await session.messages.postMessage(
      'queue_room_$successRoomId',
      QueueEvent(roomId: successRoomId, action: 'completed'),
    );
    return true;
  }

  Future<int> _getTotalWaitingInSession(Session session, int sessionId) async {
    return QueueTicket.db.count(
      session,
      where: (t) => t.sessionId.equals(sessionId) & t.status.equals('waiting'),
    );
  }

  Future<int> _calculateETA(Session session, int roomId, int position) async {
    if (position <= 0) return 0;

    // 1. Calculate historical average service duration (in seconds)
    final completedTickets = await QueueTicket.db.find(
      session,
      where: (t) =>
          t.roomId.equals(roomId) &
          t.status.equals('completed') &
          t.calledAt.notEquals(null) &
          t.completedAt.notEquals(null),
      orderByList: (t) => [t.completedAt.desc()],
      limit: 50,
    );

    int averageDurationSeconds = 300; // Default 5 minutes approximation

    int validCount = 0;
    int totalSeconds = 0;
    for (final t in completedTickets) {
      if (t.completedAt != null && t.calledAt != null) {
        final duration = t.completedAt!.difference(t.calledAt!).inSeconds;
        if (duration > 0) {
          totalSeconds += duration;
          validCount++;
        }
      }
    }
    if (validCount >= 3) {
      averageDurationSeconds = totalSeconds ~/ validCount;
    }

    // 2. Adjust for currently serving ticket
    int servingRemaining = 0;
    final servingTicket = await QueueTicket.db.findFirstRow(
      session,
      where: (t) => t.roomId.equals(roomId) & t.status.equals('serving'),
      orderBy: (t) => t.calledAt,
    );

    if (servingTicket != null && servingTicket.calledAt != null) {
      final elapsed = DateTime.now()
          .difference(servingTicket.calledAt!)
          .inSeconds;
      servingRemaining = max(0, averageDurationSeconds - elapsed);
    }

    return servingRemaining + ((position - 1) * averageDurationSeconds);
  }

  String _requireStaffIdentity(Session session, [String endpoint = 'unknown']) {
    final auth = session.authenticated;
    if (auth == null) {
      _logAuthFailure(
        session,
        category: 'NO_AUTH',
        endpoint: endpoint,
        reason:
            'Session has no authenticated user (missing or expired access token).',
      );
      throw QueueException(message: 'Unauthorized: Staff login required.');
    }
    if (!auth.scopes.contains(Scope('staff'))) {
      _logAuthFailure(
        session,
        category: 'MISSING_STAFF_SCOPE',
        endpoint: endpoint,
        userId: auth.userIdentifier,
        reason:
            'User scopes [${auth.scopes.map((s) => s.name).join(", ")}] lack staff scope.',
      );
      throw QueueException(message: 'Unauthorized: Staff login required.');
    }
    return auth.userIdentifier;
  }

  Future<void> _requireStaffRoomAccess(
    Session session,
    int roomId, [
    String endpoint = 'unknown',
  ]) async {
    final staffUserId = _requireStaffIdentity(session, endpoint);
    final hasAccess = await StaffRoomAccess.db.findFirstRow(
      session,
      where: (s) => s.userId.equals(staffUserId) & s.roomId.equals(roomId),
    );

    if (hasAccess == null) {
      final staffScopeCheckSucceeded =
          session.authenticated?.scopes.contains(Scope('staff')) ?? false;

      final accessRecordsForRoom = await StaffRoomAccess.db.find(
        session,
        where: (s) => s.roomId.equals(roomId),
      );

      final accessRecordsForUser = await StaffRoomAccess.db.find(
        session,
        where: (s) => s.userId.equals(staffUserId),
      );

      // ignore: avoid_print
      print(
        '[ROOM_ACCESS_DENIAL_DIAGNOSTIC] '
        'endpoint=$endpoint, '
        'authenticatedUserIdentifier=$staffUserId, '
        'requestedRoomId=$roomId, '
        'exactStaffRoomAccessExists=false, '
        'staffScopeCheckSucceeded=$staffScopeCheckSucceeded, '
        'roomAccessRecordsForRoom=[${accessRecordsForRoom.map((a) => "StaffRoomAccess(id:${a.id}, userId:${a.userId}, roomId:${a.roomId})").join(", ")}], '
        'userAuthorizedRooms=[${accessRecordsForUser.map((a) => "StaffRoomAccess(id:${a.id}, userId:${a.userId}, roomId:${a.roomId})").join(", ")}]',
      );

      _logAuthFailure(
        session,
        category: 'ROOM_ACCESS_DENIED',
        endpoint: endpoint,
        userId: staffUserId,
        roomId: roomId,
        reason: 'No StaffRoomAccess record for user in room $roomId.',
      );
      throw QueueException(
        message:
            'Unauthorized: You do not have permission to manage this room.',
      );
    }
  }

  /// Subscribe to real-time events for a specific room as a customer.
  Stream<QueueEvent> subscribeToRoomCustomer(
    Session session,
    int ticketId,
    String accessCode,
  ) async* {
    final ticket = await QueueTicket.db.findById(session, ticketId);
    if (ticket == null || ticket.accessCode != accessCode) {
      throw Exception('Unauthorized.');
    }
    final room = await QueueRoom.db.findById(session, ticket.roomId);
    if (room == null || room.deletedAt != null) {
      throw Exception('Room not found or deleted.');
    }

    yield* session.messages.createStream<QueueEvent>(
      'queue_room_${ticket.roomId}',
    );
  }

  /// Subscribe to real-time events for a specific room as staff.
  Stream<QueueEvent> subscribeToRoomStaff(
    Session session, {
    int? roomId,
  }) async* {
    final staffUserId = _requireStaffIdentity(session, 'subscribeToRoomStaff');
    final targetRoomId =
        roomId ?? await _getDefaultRoomIdForStaff(session, staffUserId);
    await _requireStaffRoomAccess(
      session,
      targetRoomId,
      'subscribeToRoomStaff',
    );
    final room = await QueueRoom.db.findById(session, targetRoomId);
    if (room == null || room.deletedAt != null) {
      throw QueueException(message: 'Room not found or deleted.');
    }

    yield* session.messages.createStream<QueueEvent>(
      'queue_room_$targetRoomId',
    );
  }

  /// Subscribe to public room list changes (e.g., room created or deleted).
  Stream<QueueEvent> subscribeToRooms(Session session) async* {
    yield* session.messages.createStream<QueueEvent>('customer_rooms');
  }
}
