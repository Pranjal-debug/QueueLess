import 'dart:async';
import 'dart:typed_data';

import 'package:test/test.dart';
import 'package:serverpod/serverpod.dart';
import 'package:serverpod_auth_idp_server/core.dart';
import 'package:queueless_server/src/generated/protocol.dart';
import 'test_tools/serverpod_test_tools.dart';

void main() {
  withServerpod('Given Queue endpoint', (sessionBuilder, endpoints) {
    late int defaultRoomId;
    late TestSessionBuilder staffSessionBuilder;

    setUp(() async {
      final session = sessionBuilder.build();
      try {
        await session.db.unsafeQuery(
          'ALTER SEQUENCE queue_room_id_seq RESTART WITH 1',
        );
      } catch (e) {
        /* ignore */
      }
      // Delete any leftover tickets first to prevent FK violation
      await QueueTicket.db.deleteWhere(session, where: (t) => t.id > 0);
      await QueueSession.db.deleteWhere(session, where: (s) => s.id > 0);
      await StaffRoomAccess.db.deleteWhere(session, where: (s) => s.id > 0);
      // Delete any leftover rooms to ensure test isolation
      await QueueRoom.db.deleteWhere(session, where: (r) => r.id > 0);

      final room = await QueueRoom.db.insertRow(
        session,
        QueueRoom(name: 'General', createdAt: DateTime.now()),
      );
      defaultRoomId = room.id!;

      staffSessionBuilder = sessionBuilder.copyWith(
        authentication: AuthenticationOverride.authenticationInfo(
          'staff-user-1',
          {Scope('staff')},
        ),
      );
      await StaffRoomAccess.db.insertRow(
        session,
        StaffRoomAccess(userId: 'staff-user-1', roomId: defaultRoomId),
      );
    });
    test('when a customer joins the queue, a ticket is created', () async {
      final status = await endpoints.queue.joinQueue(
        sessionBuilder,
        'Alice',
        roomId: defaultRoomId,
      );
      expect(status.ticket.customerName, 'Alice');
      expect(status.ticket.ticketNumber, 1);
      expect(status.ticket.status, 'waiting');
      expect(status.position, 1);
      expect(status.totalWaiting, 1);
    });

    test(
      'when multiple customers join, positions and ticket numbers increase',
      () async {
        await endpoints.queue.joinQueue(
          sessionBuilder,
          'Alice',
          roomId: defaultRoomId,
        );
        final status2 = await endpoints.queue.joinQueue(
          sessionBuilder,
          'Bob',
          roomId: defaultRoomId,
        );

        expect(status2.ticket.customerName, 'Bob');
        expect(status2.ticket.ticketNumber, 2);
        expect(status2.position, 2);
        expect(status2.totalWaiting, 2);
      },
    );

    test('when checking status of an existing ticket', () async {
      final status1 = await endpoints.queue.joinQueue(
        sessionBuilder,
        'Alice',
        roomId: defaultRoomId,
      );
      await endpoints.queue.joinQueue(
        sessionBuilder,
        'Bob',
        roomId: defaultRoomId,
      );

      final checkedStatus = await endpoints.queue.getTicketStatus(
        sessionBuilder,
        status1.ticket.id!,
        status1.ticket.accessCode,
      );
      expect(checkedStatus, isNotNull);
      expect(checkedStatus!.position, 1);
      expect(checkedStatus.totalWaiting, 2);
    });

    test(
      'getTicketStatus with invalid access token throws exception',
      () async {
        final status1 = await endpoints.queue.joinQueue(
          sessionBuilder,
          'Alice',
          roomId: defaultRoomId,
        );
        expect(
          endpoints.queue.getTicketStatus(
            sessionBuilder,
            status1.ticket.id!,
            'wrong_token',
          ),
          throwsException,
        );
      },
    );

    test('when calling the next customer, status updates to serving', () async {
      await endpoints.queue.joinQueue(
        sessionBuilder,
        'Alice',
        roomId: defaultRoomId,
      );
      await endpoints.queue.joinQueue(
        sessionBuilder,
        'Bob',
        roomId: defaultRoomId,
      );

      final ticket = await endpoints.queue.callNext(staffSessionBuilder);
      expect(ticket, isNotNull);
      expect(ticket!.customerName, 'Alice');
      expect(ticket.status, 'serving');

      final active = await endpoints.queue.getActiveQueue(staffSessionBuilder);
      expect(active.length, 2);
      expect(active[0].status, 'serving');
      expect(active[1].status, 'waiting');
    });

    test('unauthorized staff operations throw exceptions', () async {
      await endpoints.queue.joinQueue(
        sessionBuilder,
        'Alice',
        roomId: defaultRoomId,
      );

      expect(endpoints.queue.callNext(sessionBuilder), throwsException);
    });

    test('when completing a ticket', () async {
      await endpoints.queue.joinQueue(
        sessionBuilder,
        'Alice',
        roomId: defaultRoomId,
      );
      final ticket = await endpoints.queue.callNext(staffSessionBuilder);
      expect(ticket, isNotNull);

      final success = await endpoints.queue.completeTicket(
        staffSessionBuilder,
        ticket!.id!,
      );
      expect(success, isTrue);

      final active = await endpoints.queue.getActiveQueue(staffSessionBuilder);
      expect(active, isEmpty); // Alice is completed, so active queue is empty
    });

    test('calling next on empty queue is handled correctly', () async {
      final ticket = await endpoints.queue.callNext(staffSessionBuilder);
      expect(ticket, isNull);
    });

    test('joinQueue posts event to message bus', () async {
      final session = sessionBuilder.build();
      QueueEvent? receivedEvent;
      session.messages.addListener('queue_room_$defaultRoomId', (msg) {
        if (msg is QueueEvent) receivedEvent = msg;
      });

      await endpoints.queue.joinQueue(
        sessionBuilder,
        'Charlie',
        roomId: defaultRoomId,
      );
      // Yield to event loop to allow message to propagate
      await Future.delayed(Duration(milliseconds: 50));

      expect(receivedEvent, isNotNull);
      expect(receivedEvent!.roomId, defaultRoomId);
      expect(receivedEvent!.action, 'joined');
    });

    test('callNext and completeTicket post events to message bus', () async {
      final session = sessionBuilder.build();
      final events = <QueueEvent>[];
      session.messages.addListener('queue_room_$defaultRoomId', (msg) {
        if (msg is QueueEvent) events.add(msg);
      });

      await endpoints.queue.joinQueue(
        sessionBuilder,
        'Dave',
        roomId: defaultRoomId,
      );
      final ticket = await endpoints.queue.callNext(staffSessionBuilder);
      await endpoints.queue.completeTicket(staffSessionBuilder, ticket!.id!);

      await Future.delayed(Duration(milliseconds: 50));

      final actions = events.map((e) => e.action).toList();
      expect(actions, containsAll(['joined', 'called', 'completed']));
    });

    test(
      'customer subscription receives an event after its ticket is called',
      () async {
        final status = await endpoints.queue.joinQueue(
          sessionBuilder,
          'Alice',
          roomId: defaultRoomId,
        );
        final events = endpoints.queue.subscribeToRoomCustomer(
          sessionBuilder,
          status.ticket.id!,
          status.ticket.accessCode,
        );
        final eventFuture = events.first;

        await flushEventQueue();
        final calledTicket = await endpoints.queue.callNext(
          staffSessionBuilder,
        );
        final event = await eventFuture.timeout(const Duration(seconds: 2));

        expect(calledTicket?.id, status.ticket.id);
        expect(event.roomId, defaultRoomId);
        expect(event.action, 'called');
        final refreshed = await endpoints.queue.getTicketStatus(
          sessionBuilder,
          status.ticket.id!,
          status.ticket.accessCode,
        );
        expect(refreshed?.ticket.status, 'serving');
      },
    );

    test(
      'authorized staff subscription receives join, call, and completion events',
      () async {
        final mutationStaffSessionBuilder = sessionBuilder.copyWith(
          authentication: AuthenticationOverride.authenticationInfo(
            'staff-user-1',
            {Scope('staff')},
          ),
        );

        Future<StreamSubscription<QueueEvent>> listenForNext(
          Completer<QueueEvent> eventCompleter,
        ) async {
          final subscription = endpoints.queue
              .subscribeToRoomStaff(
                staffSessionBuilder,
                roomId: defaultRoomId,
              )
              .listen(
                eventCompleter.complete,
                onError: (Object error, StackTrace stackTrace) {
                  if (!eventCompleter.isCompleted) {
                    eventCompleter.completeError(error, stackTrace);
                  }
                },
              );
          await flushEventQueue();
          // The stream endpoint performs an async authorization query before
          // registering with the message bus.
          await Future<void>.delayed(const Duration(milliseconds: 50));
          return subscription;
        }

        final joinedCompleter = Completer<QueueEvent>();
        final joinedSubscription = await listenForNext(joinedCompleter);
        await endpoints.queue.joinQueue(
          sessionBuilder,
          'Alice',
          roomId: defaultRoomId,
        );
        final joined = await joinedCompleter.future.timeout(
          const Duration(seconds: 2),
        );
        await joinedSubscription.cancel();

        final calledCompleter = Completer<QueueEvent>();
        final calledSubscription = await listenForNext(calledCompleter);
        final ticket = await endpoints.queue.callNext(
          mutationStaffSessionBuilder,
        );
        final called = await calledCompleter.future.timeout(
          const Duration(seconds: 2),
        );
        await calledSubscription.cancel();

        final completedCompleter = Completer<QueueEvent>();
        final completedSubscription = await listenForNext(
          completedCompleter,
        );
        await endpoints.queue.completeTicket(
          mutationStaffSessionBuilder,
          ticket!.id!,
        );
        final completed = await completedCompleter.future.timeout(
          const Duration(seconds: 2),
        );
        await completedSubscription.cancel();

        final received = [joined, called, completed];
        expect(
          received.map((event) => event.roomId),
          everyElement(defaultRoomId),
        );
        expect(
          received.map((event) => event.action),
          ['joined', 'called', 'completed'],
        );
      },
    );

    test('Room A subscriptions do not receive Room B events', () async {
      final session = sessionBuilder.build();
      final roomB = await QueueRoom.db.insertRow(
        session,
        QueueRoom(name: 'Room B', createdAt: DateTime.now()),
      );
      final roomATicket = await endpoints.queue.joinQueue(
        sessionBuilder,
        'AliceA',
        roomId: defaultRoomId,
      );
      final roomAEvents = endpoints.queue.subscribeToRoomCustomer(
        sessionBuilder,
        roomATicket.ticket.id!,
        roomATicket.ticket.accessCode,
      );
      final receivedFuture = roomAEvents.first;

      await flushEventQueue();
      await endpoints.queue.joinQueue(
        sessionBuilder,
        'BobB',
        roomId: roomB.id!,
      );
      await endpoints.queue.joinQueue(
        sessionBuilder,
        'CharlieA',
        roomId: defaultRoomId,
      );

      final received = await receivedFuture.timeout(const Duration(seconds: 2));
      expect(received.roomId, defaultRoomId);
      expect(received.action, 'joined');
    });

    test(
      'cancelling and replacing a room subscription receives only the new room events',
      () async {
        final session = sessionBuilder.build();
        final roomB = await QueueRoom.db.insertRow(
          session,
          QueueRoom(name: 'Room B', createdAt: DateTime.now()),
        );
        await StaffRoomAccess.db.insertRow(
          session,
          StaffRoomAccess(userId: 'staff-user-1', roomId: roomB.id!),
        );
        expect(
          await endpoints.queue.getActiveQueue(
            staffSessionBuilder,
            roomId: roomB.id!,
          ),
          isEmpty,
        );

        final oldRoomEvents = <QueueEvent>[];
        final firstSubscription = endpoints.queue
            .subscribeToRoomStaff(staffSessionBuilder, roomId: defaultRoomId)
            .listen(oldRoomEvents.add);
        await flushEventQueue();
        await Future<void>.delayed(const Duration(milliseconds: 50));
        await firstSubscription.cancel();

        final receivedCompleter = Completer<QueueEvent>();
        final newRoomSubscription = endpoints.queue
            .subscribeToRoomStaff(
              staffSessionBuilder,
              roomId: roomB.id!,
            )
            .listen(
              receivedCompleter.complete,
              onError: (Object error, StackTrace stackTrace) {
                if (!receivedCompleter.isCompleted) {
                  receivedCompleter.completeError(error, stackTrace);
                }
              },
            );
        await flushEventQueue();
        await Future<void>.delayed(const Duration(milliseconds: 50));
        await endpoints.queue.joinQueue(
          sessionBuilder,
          'BobB',
          roomId: roomB.id!,
        );

        final received = await receivedCompleter.future.timeout(
          const Duration(seconds: 2),
        );
        await newRoomSubscription.cancel();
        expect(received.roomId, roomB.id);
        expect(received.action, 'joined');
        expect(oldRoomEvents, isEmpty);
      },
    );

    test('resubscribing after cancellation receives later events', () async {
      Future<StreamSubscription<QueueEvent>> listenForNext(
        Completer<QueueEvent> eventCompleter,
      ) async {
        final subscription = endpoints.queue
            .subscribeToRoomStaff(
              staffSessionBuilder,
              roomId: defaultRoomId,
            )
            .listen(
              eventCompleter.complete,
              onError: (Object error, StackTrace stackTrace) {
                if (!eventCompleter.isCompleted) {
                  eventCompleter.completeError(error, stackTrace);
                }
              },
            );
        await flushEventQueue();
        await Future<void>.delayed(const Duration(milliseconds: 50));
        return subscription;
      }

      final firstCompleter = Completer<QueueEvent>();
      final firstSubscription = await listenForNext(firstCompleter);
      await endpoints.queue.joinQueue(
        sessionBuilder,
        'First',
        roomId: defaultRoomId,
      );
      final first = await firstCompleter.future.timeout(
        const Duration(seconds: 2),
      );
      await firstSubscription.cancel();
      expect(first.action, 'joined');

      final secondCompleter = Completer<QueueEvent>();
      final secondSubscription = await listenForNext(secondCompleter);
      await endpoints.queue.joinQueue(
        sessionBuilder,
        'Second',
        roomId: defaultRoomId,
      );
      final received = await secondCompleter.future.timeout(
        const Duration(seconds: 2),
      );
      await secondSubscription.cancel();

      expect(received.roomId, defaultRoomId);
      expect(received.action, 'joined');
    });

    test('invalid roomId throws exception', () async {
      expect(
        endpoints.queue.joinQueue(sessionBuilder, 'Alice', roomId: 9999),
        throwsException,
      );
    });

    test('two rooms maintain independent ticket sequences', () async {
      final session = sessionBuilder.build();
      final room2 = await QueueRoom.db.insertRow(
        session,
        QueueRoom(name: 'Room 2', createdAt: DateTime.now()),
      );

      final status1 = await endpoints.queue.joinQueue(
        sessionBuilder,
        'Alice',
        roomId: defaultRoomId,
      ); // Room 1
      final status2 = await endpoints.queue.joinQueue(
        sessionBuilder,
        'Bob',
        roomId: room2.id!,
      );

      expect(status1.ticket.ticketNumber, 1);
      expect(status2.ticket.ticketNumber, 1);
    });

    test('cross-room ticket mutations are prevented', () async {
      final session = sessionBuilder.build();
      final room2 = await QueueRoom.db.insertRow(
        session,
        QueueRoom(name: 'Room 2', createdAt: DateTime.now()),
      );
      await StaffRoomAccess.db.insertRow(
        session,
        StaffRoomAccess(userId: 'staff-user-1', roomId: room2.id!),
      );

      await endpoints.queue.joinQueue(
        sessionBuilder,
        'Alice',
        roomId: defaultRoomId,
      ); // Room 1
      await endpoints.queue.joinQueue(
        sessionBuilder,
        'Bob',
        roomId: room2.id!,
      ); // Room 2

      // Call next in room 2 should return Bob, not Alice.
      final ticket2 = await endpoints.queue.callNext(
        staffSessionBuilder,
        roomId: room2.id!,
      );
      expect(ticket2?.customerName, 'Bob');

      // Active queue in room 1 should only contain Alice
      final active1 = await endpoints.queue.getActiveQueue(
        staffSessionBuilder,
        roomId: defaultRoomId,
      );
      expect(active1.length, 1);
      expect(active1.first.customerName, 'Alice');
    });

    test('listRooms returns all available rooms', () async {
      final session = sessionBuilder.build();
      await QueueRoom.db.insertRow(
        session,
        QueueRoom(name: 'Consultation', createdAt: DateTime.now()),
      );

      final rooms = await endpoints.queue.listRooms(sessionBuilder);
      expect(rooms.length, 2);
      expect(
        rooms.map((r) => r.name),
        containsAll(['General', 'Consultation']),
      );
    });

    test(
      'customer can list rooms safely without exposing private staff records or credentials',
      () async {
        final rooms = await endpoints.queue.listRooms(sessionBuilder);
        expect(rooms, isNotEmpty);
        for (final room in rooms) {
          expect(room.id, isNotNull);
          expect(room.name, isNotEmpty);
          expect(room.createdAt, isNotNull);
        }

        // Customer session cannot call staff-only room listing
        expect(
          endpoints.queue.listAuthorizedRooms(sessionBuilder),
          throwsA(isA<QueueException>()),
        );
      },
    );

    test(
      'listAuthorizedRooms enforces staff scope and filters authorized rooms',
      () async {
        final session = sessionBuilder.build();
        final room2 = await QueueRoom.db.insertRow(
          session,
          QueueRoom(name: 'VIP Room', createdAt: DateTime.now()),
        );

        // Unauthenticated / non-staff throws QueueException
        expect(
          endpoints.queue.listAuthorizedRooms(sessionBuilder),
          throwsA(isA<QueueException>()),
        );

        // Staff with access only to defaultRoomId sees only defaultRoomId
        final staffRoomsBefore = await endpoints.queue.listAuthorizedRooms(
          staffSessionBuilder,
        );
        expect(staffRoomsBefore.length, 1);
        expect(staffRoomsBefore.first.id, defaultRoomId);

        // Grant access to VIP Room
        await StaffRoomAccess.db.insertRow(
          session,
          StaffRoomAccess(userId: 'staff-user-1', roomId: room2.id!),
        );

        final staffRoomsAfter = await endpoints.queue.listAuthorizedRooms(
          staffSessionBuilder,
        );
        expect(staffRoomsAfter.length, 2);
        expect(
          staffRoomsAfter.map((r) => r.id),
          containsAll([defaultRoomId, room2.id!]),
        );
      },
    );

    test(
      'staff can create a room and receives access transactionally',
      () async {
        final created = await endpoints.queue.createRoom(
          staffSessionBuilder,
          'Exam Cell',
        );

        expect(created.id, isNotNull);
        expect(created.name, 'Exam Cell');
        final authorizedRooms = await endpoints.queue.listAuthorizedRooms(
          staffSessionBuilder,
        );
        expect(
          authorizedRooms.map((room) => room.id),
          contains(created.id),
        );

        final activeQueue = await endpoints.queue.getActiveQueue(
          staffSessionBuilder,
          roomId: created.id!,
        );
        expect(activeQueue, isEmpty);
      },
    );

    test('unauthenticated users cannot create rooms', () async {
      await expectLater(
        endpoints.queue.createRoom(sessionBuilder, 'Restricted'),
        throwsA(isA<QueueException>()),
      );
    });

    test(
      'customer joining Room A does not affect Room B queue position or ETA',
      () async {
        final session = sessionBuilder.build();
        final roomB = await QueueRoom.db.insertRow(
          session,
          QueueRoom(name: 'Room B', createdAt: DateTime.now()),
        );

        final statusA1 = await endpoints.queue.joinQueue(
          sessionBuilder,
          'AliceA',
          roomId: defaultRoomId,
        );
        final statusB1 = await endpoints.queue.joinQueue(
          sessionBuilder,
          'BobB',
          roomId: roomB.id!,
        );

        expect(statusA1.position, 1);
        expect(statusB1.position, 1);

        // Join second customer to Room A
        final statusA2 = await endpoints.queue.joinQueue(
          sessionBuilder,
          'CharlieA',
          roomId: defaultRoomId,
        );
        expect(statusA2.position, 2);

        // Verify Bob in Room B is still position 1 with 1 total waiting and 0 wait seconds
        final refreshedB = await endpoints.queue.getTicketStatus(
          sessionBuilder,
          statusB1.ticket.id!,
          statusB1.ticket.accessCode,
        );
        expect(refreshedB, isNotNull);
        expect(refreshedB!.position, 1);
        expect(refreshedB.totalWaiting, 1);
        expect(refreshedB.estimatedWaitSeconds, 0);
      },
    );

    test('each room keeps its own ETA history', () async {
      final session = sessionBuilder.build();
      final roomB = await QueueRoom.db.insertRow(
        session,
        QueueRoom(name: 'Room B', createdAt: DateTime.now()),
      );
      final now = DateTime.now();

      Future<void> addHistory({
        required int roomId,
        required int ticketNumber,
        required int durationSeconds,
      }) async {
        final calledAt = now.subtract(const Duration(minutes: 10));
        await QueueTicket.db.insertRow(
          session,
          QueueTicket(
            customerName: 'History $roomId $ticketNumber',
            roomId: roomId,
            accessCode: 'H$roomId$ticketNumber',
            ticketNumber: ticketNumber,
            status: 'completed',
            createdAt: calledAt,
            calledAt: calledAt,
            completedAt: calledAt.add(Duration(seconds: durationSeconds)),
          ),
        );
      }

      for (var i = 0; i < 3; i++) {
        await addHistory(
          roomId: defaultRoomId,
          ticketNumber: 100 + i,
          durationSeconds: 60,
        );
        await addHistory(
          roomId: roomB.id!,
          ticketNumber: 200 + i,
          durationSeconds: 120,
        );
      }

      await endpoints.queue.joinQueue(
        sessionBuilder,
        'AliceA',
        roomId: defaultRoomId,
      );
      final roomASecond = await endpoints.queue.joinQueue(
        sessionBuilder,
        'CharlieA',
        roomId: defaultRoomId,
      );
      await endpoints.queue.joinQueue(
        sessionBuilder,
        'BobB',
        roomId: roomB.id!,
      );
      final roomBSecond = await endpoints.queue.joinQueue(
        sessionBuilder,
        'DrewB',
        roomId: roomB.id!,
      );

      expect(roomASecond.estimatedWaitSeconds, 60);
      expect(roomBSecond.estimatedWaitSeconds, 120);
    });

    test(
      'staff can complete independent lifecycles in two authorized rooms',
      () async {
        final session = sessionBuilder.build();
        final roomB = await QueueRoom.db.insertRow(
          session,
          QueueRoom(name: 'Room B', createdAt: DateTime.now()),
        );
        await StaffRoomAccess.db.insertRow(
          session,
          StaffRoomAccess(userId: 'staff-user-1', roomId: roomB.id!),
        );

        final roomATicket = await endpoints.queue.joinQueue(
          sessionBuilder,
          'AliceA',
          roomId: defaultRoomId,
        );
        final roomBTicket = await endpoints.queue.joinQueue(
          sessionBuilder,
          'BobB',
          roomId: roomB.id!,
        );

        final servingA = await endpoints.queue.callNext(
          staffSessionBuilder,
          roomId: defaultRoomId,
        );
        final servingB = await endpoints.queue.callNext(
          staffSessionBuilder,
          roomId: roomB.id!,
        );

        expect(servingA?.id, roomATicket.ticket.id);
        expect(servingB?.id, roomBTicket.ticket.id);
        expect(servingA?.customerName, 'AliceA');
        expect(servingB?.customerName, 'BobB');

        expect(
          await endpoints.queue.completeTicket(
            staffSessionBuilder,
            servingA!.id!,
          ),
          isTrue,
        );
        expect(
          await endpoints.queue.completeTicket(
            staffSessionBuilder,
            servingB!.id!,
          ),
          isTrue,
        );
        expect(
          await endpoints.queue.getActiveQueue(
            staffSessionBuilder,
            roomId: defaultRoomId,
          ),
          isEmpty,
        );
        expect(
          await endpoints.queue.getActiveQueue(
            staffSessionBuilder,
            roomId: roomB.id!,
          ),
          isEmpty,
        );
      },
    );

    test('negative and nonexistent room IDs fail safely', () async {
      expect(
        endpoints.queue.joinQueue(sessionBuilder, 'Alice', roomId: -1),
        throwsException,
      );
      expect(
        endpoints.queue.joinQueue(sessionBuilder, 'Alice', roomId: 999999),
        throwsException,
      );
    });

    test(
      'staff user cannot read, call, complete, or subscribe to unauthorized room',
      () async {
        final session = sessionBuilder.build();
        final unauthorizedRoom = await QueueRoom.db.insertRow(
          session,
          QueueRoom(name: 'Restricted Room', createdAt: DateTime.now()),
        );

        // 1. Cannot get active queue
        await expectLater(
          endpoints.queue.getActiveQueue(
            staffSessionBuilder,
            roomId: unauthorizedRoom.id!,
          ),
          throwsA(isA<QueueException>()),
        );

        // 2. Cannot call next
        await expectLater(
          endpoints.queue.callNext(
            staffSessionBuilder,
            roomId: unauthorizedRoom.id!,
          ),
          throwsA(isA<QueueException>()),
        );

        // 3. Cannot complete ticket in unauthorized room
        await endpoints.queue.joinQueue(
          sessionBuilder,
          'SecretCustomer',
          roomId: unauthorizedRoom.id!,
        );

        // Insert another staff session that IS authorized for unauthorizedRoom to advance it to serving
        final otherStaffSessionBuilder = sessionBuilder.copyWith(
          authentication: AuthenticationOverride.authenticationInfo(
            'staff-user-2',
            {Scope('staff')},
          ),
        );
        await StaffRoomAccess.db.insertRow(
          session,
          StaffRoomAccess(userId: 'staff-user-2', roomId: unauthorizedRoom.id!),
        );
        final servingSecret = await endpoints.queue.callNext(
          otherStaffSessionBuilder,
          roomId: unauthorizedRoom.id!,
        );
        expect(servingSecret, isNotNull);

        // staff-user-1 tries to complete unauthorized room's ticket -> throws QueueException
        await expectLater(
          endpoints.queue.completeTicket(
            staffSessionBuilder,
            servingSecret!.id!,
          ),
          throwsA(isA<QueueException>()),
        );

        // 4. Cannot subscribe to unauthorized room
        await expectLater(
          endpoints.queue
              .subscribeToRoomStaff(
                staffSessionBuilder,
                roomId: unauthorizedRoom.id!,
              )
              .drain(),
          throwsA(isA<QueueException>()),
        );
      },
    );

    group('Room-level staff authorization and customer privilege isolation', () {
      late QueueRoom roomA;
      late QueueRoom roomB;
      late TestSessionBuilder staffASessionBuilder;
      late TestSessionBuilder staffBSessionBuilder;
      late TestSessionBuilder regularCustomerSessionBuilder;

      setUp(() async {
        final session = sessionBuilder.build();

        // Create isolated test fixtures for two distinct rooms
        roomA = await QueueRoom.db.insertRow(
          session,
          QueueRoom(name: 'Room A', createdAt: DateTime.now()),
        );
        roomB = await QueueRoom.db.insertRow(
          session,
          QueueRoom(name: 'Room B', createdAt: DateTime.now()),
        );

        // Create distinct staff identities
        staffASessionBuilder = sessionBuilder.copyWith(
          authentication: AuthenticationOverride.authenticationInfo(
            'staff-user-a',
            {Scope('staff')},
          ),
        );
        staffBSessionBuilder = sessionBuilder.copyWith(
          authentication: AuthenticationOverride.authenticationInfo(
            'staff-user-b',
            {Scope('staff')},
          ),
        );

        // Assign Staff A exclusively to Room A, and Staff B exclusively to Room B
        await StaffRoomAccess.db.insertRow(
          session,
          StaffRoomAccess(userId: 'staff-user-a', roomId: roomA.id!),
        );
        await StaffRoomAccess.db.insertRow(
          session,
          StaffRoomAccess(userId: 'staff-user-b', roomId: roomB.id!),
        );

        // Authenticated customer without staff scope
        regularCustomerSessionBuilder = sessionBuilder.copyWith(
          authentication: AuthenticationOverride.authenticationInfo(
            'regular-customer-1',
            <Scope>{},
          ),
        );
      });

      test('Staff A can read and operate Room A queue end-to-end', () async {
        // 1. Staff A can list authorized rooms and sees only Room A
        final authRooms = await endpoints.queue.listAuthorizedRooms(
          staffASessionBuilder,
        );
        expect(authRooms.map((r) => r.id), contains(roomA.id));
        expect(authRooms.map((r) => r.id), isNot(contains(roomB.id)));

        // 2. Staff A can get active queue for Room A
        final activeEmpty = await endpoints.queue.getActiveQueue(
          staffASessionBuilder,
          roomId: roomA.id!,
        );
        expect(activeEmpty, isEmpty);

        // Customer joins Room A
        final joinStatus = await endpoints.queue.joinQueue(
          sessionBuilder,
          'AliceInRoomA',
          roomId: roomA.id!,
        );
        expect(joinStatus.ticket.roomId, roomA.id);

        // 3. Staff A sees customer in active queue
        final activeWithCustomer = await endpoints.queue.getActiveQueue(
          staffASessionBuilder,
          roomId: roomA.id!,
        );
        expect(activeWithCustomer.length, 1);
        expect(activeWithCustomer.first.customerName, 'AliceInRoomA');

        // 4. Staff A can call next
        final calledTicket = await endpoints.queue.callNext(
          staffASessionBuilder,
          roomId: roomA.id!,
        );
        expect(calledTicket, isNotNull);
        expect(calledTicket!.id, joinStatus.ticket.id);
        expect(calledTicket.status, 'serving');

        // 5. Staff A can complete ticket
        final completed = await endpoints.queue.completeTicket(
          staffASessionBuilder,
          calledTicket.id!,
        );
        expect(completed, isTrue);

        final activeAfterComplete = await endpoints.queue.getActiveQueue(
          staffASessionBuilder,
          roomId: roomA.id!,
        );
        expect(activeAfterComplete, isEmpty);
      });

      test(
        'Staff A is denied access to Room B across all endpoints (getActiveQueue, callNext, completeTicket, subscribeToRoomStaff)',
        () async {
          // Join a customer to Room B
          final joinStatusB = await endpoints.queue.joinQueue(
            sessionBuilder,
            'BobInRoomB',
            roomId: roomB.id!,
          );

          // 1. Staff A cannot get active queue of Room B
          await expectLater(
            endpoints.queue.getActiveQueue(
              staffASessionBuilder,
              roomId: roomB.id!,
            ),
            throwsA(
              predicate<Object>(
                (e) =>
                    e is QueueException &&
                    e.message.contains(
                      'Unauthorized: You do not have permission to manage this room.',
                    ),
              ),
            ),
          );

          // 2. Staff A cannot call next in Room B
          await expectLater(
            endpoints.queue.callNext(
              staffASessionBuilder,
              roomId: roomB.id!,
            ),
            throwsA(
              predicate<Object>(
                (e) =>
                    e is QueueException &&
                    e.message.contains(
                      'Unauthorized: You do not have permission to manage this room.',
                    ),
              ),
            ),
          );

          // Staff B advances the ticket in Room B to serving
          final calledByB = await endpoints.queue.callNext(
            staffBSessionBuilder,
            roomId: roomB.id!,
          );
          expect(calledByB, isNotNull);
          expect(calledByB!.id, joinStatusB.ticket.id);

          // 3. Staff A cannot complete ticket belonging to Room B
          await expectLater(
            endpoints.queue.completeTicket(
              staffASessionBuilder,
              calledByB.id!,
            ),
            throwsA(
              predicate<Object>(
                (e) =>
                    e is QueueException &&
                    e.message.contains(
                      'Unauthorized: You do not have permission to manage this room.',
                    ),
              ),
            ),
          );

          // 4. Staff A cannot subscribe to Room B staff stream
          await expectLater(
            endpoints.queue
                .subscribeToRoomStaff(
                  staffASessionBuilder,
                  roomId: roomB.id!,
                )
                .drain(),
            throwsA(
              predicate<Object>(
                (e) =>
                    e is QueueException &&
                    e.message.contains(
                      'Unauthorized: You do not have permission to manage this room.',
                    ),
              ),
            ),
          );
        },
      );

      test(
        'Staff B has permissions exclusively for Room B and is denied Room A',
        () async {
          // 1. Staff B can list authorized rooms and sees only Room B
          final authRooms = await endpoints.queue.listAuthorizedRooms(
            staffBSessionBuilder,
          );
          expect(authRooms.map((r) => r.id), contains(roomB.id));
          expect(authRooms.map((r) => r.id), isNot(contains(roomA.id)));

          // Join customer to Room A
          final joinStatusA = await endpoints.queue.joinQueue(
            sessionBuilder,
            'CustomerInRoomA',
            roomId: roomA.id!,
          );

          // 2. Staff B cannot get active queue of Room A
          await expectLater(
            endpoints.queue.getActiveQueue(
              staffBSessionBuilder,
              roomId: roomA.id!,
            ),
            throwsA(
              predicate<Object>(
                (e) =>
                    e is QueueException &&
                    e.message.contains(
                      'Unauthorized: You do not have permission to manage this room.',
                    ),
              ),
            ),
          );

          // 3. Staff B cannot call next in Room A
          await expectLater(
            endpoints.queue.callNext(
              staffBSessionBuilder,
              roomId: roomA.id!,
            ),
            throwsA(
              predicate<Object>(
                (e) =>
                    e is QueueException &&
                    e.message.contains(
                      'Unauthorized: You do not have permission to manage this room.',
                    ),
              ),
            ),
          );

          // Staff A advances customer in Room A
          final calledByA = await endpoints.queue.callNext(
            staffASessionBuilder,
            roomId: roomA.id!,
          );
          expect(calledByA, isNotNull);
          expect(calledByA!.id, joinStatusA.ticket.id);

          // 4. Staff B cannot complete ticket in Room A
          await expectLater(
            endpoints.queue.completeTicket(
              staffBSessionBuilder,
              calledByA.id!,
            ),
            throwsA(
              predicate<Object>(
                (e) =>
                    e is QueueException &&
                    e.message.contains(
                      'Unauthorized: You do not have permission to manage this room.',
                    ),
              ),
            ),
          );

          // 5. Staff B cannot subscribe to Room A staff stream
          await expectLater(
            endpoints.queue
                .subscribeToRoomStaff(
                  staffBSessionBuilder,
                  roomId: roomA.id!,
                )
                .drain(),
            throwsA(
              predicate<Object>(
                (e) =>
                    e is QueueException &&
                    e.message.contains(
                      'Unauthorized: You do not have permission to manage this room.',
                    ),
              ),
            ),
          );

          // 6. Staff B CAN operate Room B
          final joinStatusB = await endpoints.queue.joinQueue(
            sessionBuilder,
            'CustomerInRoomB',
            roomId: roomB.id!,
          );
          final calledByB = await endpoints.queue.callNext(
            staffBSessionBuilder,
            roomId: roomB.id!,
          );
          expect(calledByB?.id, joinStatusB.ticket.id);
          final completeB = await endpoints.queue.completeTicket(
            staffBSessionBuilder,
            calledByB!.id!,
          );
          expect(completeB, isTrue);
        },
      );

      test(
        'Modifying requested roomId parameter cannot bypass server-side authorization',
        () async {
          // Even if Staff A provides roomB.id explicitly, backend rejects with QueueException
          await expectLater(
            endpoints.queue.getActiveQueue(
              staffASessionBuilder,
              roomId: roomB.id!,
            ),
            throwsA(isA<QueueException>()),
          );

          // Arbitrary non-existent room ID also fails authorization / access
          await expectLater(
            endpoints.queue.getActiveQueue(
              staffASessionBuilder,
              roomId: 88888,
            ),
            throwsA(isA<QueueException>()),
          );
          await expectLater(
            endpoints.queue.callNext(
              staffASessionBuilder,
              roomId: 88888,
            ),
            throwsA(isA<QueueException>()),
          );
          await expectLater(
            endpoints.queue
                .subscribeToRoomStaff(
                  staffASessionBuilder,
                  roomId: 88888,
                )
                .drain(),
            throwsA(isA<QueueException>()),
          );
        },
      );

      test(
        'Public customer operations remain available without granting staff privileges',
        () async {
          // 1. Unauthenticated customer can list available rooms
          final rooms = await endpoints.queue.listRooms(sessionBuilder);
          expect(rooms.map((r) => r.id), containsAll([roomA.id, roomB.id]));

          // 2. Unauthenticated customer can join any valid room
          final customerTicketA = await endpoints.queue.joinQueue(
            sessionBuilder,
            'WalkInCustomer',
            roomId: roomA.id!,
          );
          expect(customerTicketA.ticket.customerName, 'WalkInCustomer');
          expect(customerTicketA.position, 1);

          // 3. Unauthenticated customer can check status of their ticket with access code
          final status = await endpoints.queue.getTicketStatus(
            sessionBuilder,
            customerTicketA.ticket.id!,
            customerTicketA.ticket.accessCode,
          );
          expect(status, isNotNull);
          expect(status!.ticket.id, customerTicketA.ticket.id);

          // 4. Unauthenticated customer CANNOT call staff endpoints
          await expectLater(
            endpoints.queue.getActiveQueue(
              sessionBuilder,
              roomId: roomA.id!,
            ),
            throwsA(
              predicate<Object>(
                (e) =>
                    e is QueueException &&
                    e.message.contains('Unauthorized: Staff login required.'),
              ),
            ),
          );
          await expectLater(
            endpoints.queue.callNext(sessionBuilder, roomId: roomA.id!),
            throwsA(isA<QueueException>()),
          );
          await expectLater(
            endpoints.queue.completeTicket(
              sessionBuilder,
              customerTicketA.ticket.id!,
            ),
            throwsA(isA<QueueException>()),
          );
          await expectLater(
            endpoints.queue
                .subscribeToRoomStaff(sessionBuilder, roomId: roomA.id!)
                .drain(),
            throwsA(isA<QueueException>()),
          );
          await expectLater(
            endpoints.queue.createRoom(sessionBuilder, 'IllegalRoom'),
            throwsA(isA<QueueException>()),
          );
          await expectLater(
            endpoints.queue.listAuthorizedRooms(sessionBuilder),
            throwsA(isA<QueueException>()),
          );

          // 5. Authenticated non-staff user (logged-in customer without staff scope) CANNOT call staff endpoints
          await expectLater(
            endpoints.queue.getActiveQueue(
              regularCustomerSessionBuilder,
              roomId: roomA.id!,
            ),
            throwsA(
              predicate<Object>(
                (e) =>
                    e is QueueException &&
                    e.message.contains('Unauthorized: Staff login required.'),
              ),
            ),
          );
          await expectLater(
            endpoints.queue.callNext(
              regularCustomerSessionBuilder,
              roomId: roomA.id!,
            ),
            throwsA(isA<QueueException>()),
          );
          await expectLater(
            endpoints.queue.completeTicket(
              regularCustomerSessionBuilder,
              customerTicketA.ticket.id!,
            ),
            throwsA(isA<QueueException>()),
          );
          await expectLater(
            endpoints.queue
                .subscribeToRoomStaff(
                  regularCustomerSessionBuilder,
                  roomId: roomA.id!,
                )
                .drain(),
            throwsA(isA<QueueException>()),
          );
          await expectLater(
            endpoints.queue.createRoom(
              regularCustomerSessionBuilder,
              'IllegalRoom2',
            ),
            throwsA(isA<QueueException>()),
          );
          await expectLater(
            endpoints.queue.listAuthorizedRooms(regularCustomerSessionBuilder),
            throwsA(isA<QueueException>()),
          );
        },
      );
    });

    group('ETA Calculations', () {
      setUp(() async {
        final session = sessionBuilder.build();
        // Clear history for ETA tests
        await QueueTicket.db.deleteWhere(session, where: (t) => t.id > 0);
      });

      test(
        'fallback to default duration when history is insufficient',
        () async {
          final status = await endpoints.queue.joinQueue(
            sessionBuilder,
            'A',
            roomId: defaultRoomId,
          );
          expect(status.estimatedWaitSeconds, 0); // position 1 waits 0

          final status2 = await endpoints.queue.joinQueue(
            sessionBuilder,
            'B',
            roomId: defaultRoomId,
          );
          expect(status2.estimatedWaitSeconds, 300); // position 2 waits 1 * 300
        },
      );

      test('historical average calculation', () async {
        final session = sessionBuilder.build();
        // Insert 3 completed tickets taking exactly 60 seconds each
        final now = DateTime.now();
        for (int i = 0; i < 3; i++) {
          await QueueTicket.db.insertRow(
            session,
            QueueTicket(
              customerName: 'History$i',
              roomId: defaultRoomId,
              accessCode: 'ABCDEF',
              ticketNumber: 100 + i,
              status: 'completed',
              createdAt: now.subtract(const Duration(minutes: 10)),
              calledAt: now.subtract(Duration(minutes: 5 - i)),
              completedAt: now.subtract(
                Duration(minutes: 4 - i),
              ), // 1 min difference = 60s
            ),
          );
        }

        await endpoints.queue.joinQueue(
          sessionBuilder,
          'A',
          roomId: defaultRoomId,
        );
        final status2 = await endpoints.queue.joinQueue(
          sessionBuilder,
          'B',
          roomId: defaultRoomId,
        );
        // historical average is 60s. A is pos 1 (waits 0). B is pos 2 (waits 1 * 60 = 60s).
        expect(status2.estimatedWaitSeconds, 60);
      });

      test(
        'currently serving ticket reduces ETA based on elapsed time',
        () async {
          final session = sessionBuilder.build();
          // Create 3 historical tickets with 100s average duration
          final now = DateTime.now();
          for (int i = 0; i < 3; i++) {
            await QueueTicket.db.insertRow(
              session,
              QueueTicket(
                customerName: 'H$i',
                roomId: defaultRoomId,
                accessCode: 'ABCDEF',
                ticketNumber: 200 + i,
                status: 'completed',
                createdAt: now.subtract(const Duration(hours: 1)),
                calledAt: now.subtract(const Duration(minutes: 30)),
                completedAt: now
                    .subtract(const Duration(minutes: 30))
                    .add(const Duration(seconds: 100)),
              ),
            );
          }

          // Insert a currently serving ticket called 40s ago
          await QueueTicket.db.insertRow(
            session,
            QueueTicket(
              customerName: 'Serving',
              roomId: defaultRoomId,
              accessCode: 'XYZ',
              ticketNumber: 300,
              status: 'serving',
              createdAt: now.subtract(const Duration(minutes: 10)),
              calledAt: now.subtract(const Duration(seconds: 40)),
            ),
          );

          // Join new ticket. Should be position 1 in waiting line.
          // Wait time = servingRemaining + (pos - 1) * average
          // servingRemaining = 100s - 40s = 60s.
          final status = await endpoints.queue.joinQueue(
            sessionBuilder,
            'NewGuy',
            roomId: defaultRoomId,
          );
          expect(status.estimatedWaitSeconds, 60);
        },
      );

      test(
        'ignores invalid, negative, or zero duration historical tickets',
        () async {
          final session = sessionBuilder.build();
          final now = DateTime.now();
          // Insert 1 valid ticket (100s)
          await QueueTicket.db.insertRow(
            session,
            QueueTicket(
              customerName: 'Valid1',
              roomId: defaultRoomId,
              accessCode: 'A',
              ticketNumber: 400,
              status: 'completed',
              createdAt: now.subtract(const Duration(minutes: 10)),
              calledAt: now.subtract(const Duration(minutes: 5)),
              completedAt: now
                  .subtract(const Duration(minutes: 5))
                  .add(const Duration(seconds: 100)),
            ),
          );
          // Insert 1 negative duration ticket
          await QueueTicket.db.insertRow(
            session,
            QueueTicket(
              customerName: 'Neg',
              roomId: defaultRoomId,
              accessCode: 'B',
              ticketNumber: 401,
              status: 'completed',
              createdAt: now.subtract(const Duration(minutes: 10)),
              calledAt: now,
              completedAt: now.subtract(const Duration(minutes: 1)),
            ),
          );
          // Insert 1 zero duration ticket
          await QueueTicket.db.insertRow(
            session,
            QueueTicket(
              customerName: 'Zero',
              roomId: defaultRoomId,
              accessCode: 'C',
              ticketNumber: 402,
              status: 'completed',
              createdAt: now.subtract(const Duration(minutes: 10)),
              calledAt: now,
              completedAt: now,
            ),
          );
          // Insert 1 valid ticket (80s)
          await QueueTicket.db.insertRow(
            session,
            QueueTicket(
              customerName: 'Valid2',
              roomId: defaultRoomId,
              accessCode: 'D',
              ticketNumber: 403,
              status: 'completed',
              createdAt: now.subtract(const Duration(minutes: 10)),
              calledAt: now.subtract(const Duration(minutes: 4)),
              completedAt: now
                  .subtract(const Duration(minutes: 4))
                  .add(const Duration(seconds: 80)),
            ),
          );

          // We only have 2 valid tickets! Fallback should apply (300s)
          await endpoints.queue.joinQueue(
            sessionBuilder,
            'Pos1',
            roomId: defaultRoomId,
          );
          final status2 = await endpoints.queue.joinQueue(
            sessionBuilder,
            'Pos2',
            roomId: defaultRoomId,
          );
          expect(status2.estimatedWaitSeconds, 300); // 1 * 300

          // Insert one more valid ticket (120s)
          await QueueTicket.db.insertRow(
            session,
            QueueTicket(
              customerName: 'Valid3',
              roomId: defaultRoomId,
              accessCode: 'E',
              ticketNumber: 500,
              status: 'completed',
              createdAt: now.subtract(const Duration(minutes: 10)),
              calledAt: now.subtract(const Duration(minutes: 3)),
              completedAt: now
                  .subtract(const Duration(minutes: 3))
                  .add(const Duration(seconds: 120)),
            ),
          );

          // Now we have 3 valid tickets: 100s, 80s, 120s. Average = 100s.
          final status3 = await endpoints.queue.joinQueue(
            sessionBuilder,
            'Pos3',
            roomId: defaultRoomId,
          );
          expect(
            status3.estimatedWaitSeconds,
            200,
          ); // position 3 -> waits for pos 1 and 2 = 2 * 100s
        },
      );
    });

    test(
      'joinQueue without roomId throws QueueException and never falls back',
      () async {
        // Even when rooms exist in database
        expect(
          () => endpoints.queue.joinQueue(sessionBuilder, 'Alice'),
          throwsA(
            predicate<Object>(
              (e) =>
                  e is QueueException &&
                  e.message.contains(
                    'A valid room ID is required to join a queue.',
                  ),
            ),
          ),
        );
      },
    );

    test(
      'joinQueue with invalid or nonexistent roomId throws QueueException and never falls back',
      () async {
        expect(
          () => endpoints.queue.joinQueue(
            sessionBuilder,
            'Alice',
            roomId: -1,
          ),
          throwsA(
            predicate<Object>(
              (e) =>
                  e is QueueException &&
                  e.message.contains('Invalid room ID.'),
            ),
          ),
        );

        expect(
          () => endpoints.queue.joinQueue(
            sessionBuilder,
            'Alice',
            roomId: 999999,
          ),
          throwsA(
            predicate<Object>(
              (e) =>
                  e is QueueException &&
                  e.message.contains('Room not found.'),
            ),
          ),
        );
      },
    );

    test(
      'staff endpoint without roomId throws QueueException when staff has no authorized rooms',
      () async {
        final session = sessionBuilder.build();
        // Remove staff-user-1 room access
        await StaffRoomAccess.db.deleteWhere(
          session,
          where: (s) => s.userId.equals('staff-user-1'),
        );

        expect(
          () => endpoints.queue.getActiveQueue(staffSessionBuilder),
          throwsA(
            predicate<Object>(
              (e) =>
                  e is QueueException &&
                  e.message.contains(
                    'No authorized rooms found for staff user.',
                  ),
            ),
          ),
        );
      },
    );
  }, rollbackDatabase: RollbackDatabase.disabled);

  withServerpod('Given Queue endpoint concurrency', (
    sessionBuilder,
    endpoints,
  ) {
    late TestSessionBuilder staffSessionBuilder;
    late int defaultRoomId;

    setUp(() async {
      final session = sessionBuilder.build();
      try {
        await session.db.unsafeQuery(
          'ALTER SEQUENCE queue_room_id_seq RESTART WITH 1',
        );
      } catch (e) {
        /* ignore */
      }
      // Delete any leftover tickets first to prevent FK violation
      await QueueTicket.db.deleteWhere(session, where: (t) => t.id > 0);
      await QueueSession.db.deleteWhere(session, where: (s) => s.id > 0);
      await StaffRoomAccess.db.deleteWhere(session, where: (s) => s.id > 0);
      // Delete any leftover rooms to ensure test isolation
      await QueueRoom.db.deleteWhere(session, where: (r) => r.id > 0);

      final room = await QueueRoom.db.insertRow(
        session,
        QueueRoom(name: 'General', createdAt: DateTime.now()),
      );
      defaultRoomId = room.id!;

      staffSessionBuilder = sessionBuilder.copyWith(
        authentication: AuthenticationOverride.authenticationInfo(
          'staff-user-1',
          {
            Scope('staff'),
          },
        ),
      );
      await StaffRoomAccess.db.insertRow(
        session,
        StaffRoomAccess(userId: 'staff-user-1', roomId: room.id!),
      );
    });
    test('concurrent joins receive unique ticket numbers', () async {
      final futures = <Future<dynamic>>[];
      for (var i = 0; i < 10; i++) {
        futures.add(
          endpoints.queue.joinQueue(
            sessionBuilder,
            'User\$i',
            roomId: defaultRoomId,
          ),
        );
      }
      final statuses = await Future.wait(futures);
      final ticketNumbers = statuses.map((s) => s.ticket.ticketNumber).toSet();
      expect(ticketNumbers.length, 10);

      // Clean up for next test
      for (var i = 0; i < 10; i++) {
        var t = await endpoints.queue.callNext(staffSessionBuilder);
        await endpoints.queue.completeTicket(staffSessionBuilder, t!.id!);
      }
    });

    test(
      'concurrent joins publish one event each and persist the active queue',
      () async {
        final events = <QueueEvent>[];
        final eventsComplete = Completer<void>();
        final subscription = endpoints.queue
            .subscribeToRoomStaff(staffSessionBuilder)
            .listen((event) {
              events.add(event);
              if (events.length == 10 && !eventsComplete.isCompleted) {
                eventsComplete.complete();
              }
            });
        await Future.delayed(const Duration(milliseconds: 100));

        await Future.wait([
          for (var i = 0; i < 10; i++)
            endpoints.queue.joinQueue(
              sessionBuilder,
              'Concurrent $i',
              roomId: defaultRoomId,
            ),
        ]);
        await eventsComplete.future.timeout(const Duration(seconds: 5));
        await subscription.cancel();

        final active = await endpoints.queue.getActiveQueue(
          staffSessionBuilder,
        );
        expect(active, hasLength(10));
        expect(events, hasLength(10));
        expect(
          events,
          everyElement(
            predicate<QueueEvent>(
              (event) =>
                  event.roomId == defaultRoomId && event.action == 'joined',
            ),
          ),
        );
        await subscription.cancel();
      },
    );

    test(
      'concurrent callNext requests do not assign same ticket twice',
      () async {
        await endpoints.queue.joinQueue(
          sessionBuilder,
          'Alice',
          roomId: defaultRoomId,
        );
        await endpoints.queue.joinQueue(
          sessionBuilder,
          'Bob',
          roomId: defaultRoomId,
        );

        final futures = <Future<dynamic>>[];
        for (var i = 0; i < 5; i++) {
          futures.add(endpoints.queue.callNext(staffSessionBuilder));
        }
        final results = await Future.wait(futures);
        final claimedTickets = results.where((t) => t != null).toList();

        expect(claimedTickets.length, 2);
        final claimedNames = claimedTickets.map((t) => t.customerName).toSet();
        expect(claimedNames, containsAll(['Alice', 'Bob']));

        // Clean up
        for (var t in claimedTickets) {
          await endpoints.queue.completeTicket(staffSessionBuilder, t.id!);
        }
      },
    );

    test(
      'concurrent completeTicket requests safely complete only once',
      () async {
        await endpoints.queue.joinQueue(
          sessionBuilder,
          'Charlie',
          roomId: defaultRoomId,
        );
        final ticket = await endpoints.queue.callNext(staffSessionBuilder);

        final futures = <Future<dynamic>>[];
        for (var i = 0; i < 5; i++) {
          // Run completely concurrent
          futures.add(
            endpoints.queue
                .completeTicket(staffSessionBuilder, ticket!.id!)
                .catchError((_) => false),
          );
        }
        final results = await Future.wait(futures);
        final successfulCompletions = results.where((r) => r == true).toList();

        // Exactly one completion should succeed, the rest should fail/return false
        expect(successfulCompletions.length, 1);
      },
    );
  }, rollbackDatabase: RollbackDatabase.disabled);

  withServerpod(
    'Given Automatic Staff Authorization and Room Isolation',
    (sessionBuilder, endpoints) {
      setUp(() async {
        final session = sessionBuilder.build();
        await QueueTicket.db.deleteWhere(session, where: (t) => t.id > 0);
        await QueueSession.db.deleteWhere(session, where: (s) => s.id > 0);
        await StaffRoomAccess.db.deleteWhere(session, where: (s) => s.id > 0);
        await QueueRoom.db.deleteWhere(session, where: (r) => r.id > 0);
        await QueueRoom.db.insertRow(
          session,
          QueueRoom(name: 'General', createdAt: DateTime.now()),
        );
      });

      test('new user registration lifecycle callback grants staff scope', () async {
        final session = sessionBuilder.build();
        final authUsers = AuthUsers(
          config: AuthUsersConfig(
            onBeforeAuthUserCreated:
                (session, scopes, blocked, {required transaction}) async {
              return (
                scopes: {...scopes, Scope('staff')},
                blocked: blocked,
              );
            },
          ),
        );

        final userModel = await authUsers.create(session);
        final createdAuthUser = await AuthUser.db.findById(session, userModel.id);
        expect(createdAuthUser, isNotNull);
        expect(createdAuthUser!.scopeNames, contains('staff'));
      });

      test('legacy user without staff scope is granted staff scope via bootstrap', () async {
        final session = sessionBuilder.build();
        final user = await AuthUser.db.insertRow(
          session,
          AuthUser(scopeNames: <String>{}),
        );
        final userUuid = user.id!;

        final rt = await RefreshToken.db.insertRow(
          session,
          RefreshToken(
            authUserId: userUuid,
            scopeNames: <String>{},
            method: 'email',
            fixedSecret: Uint8List(32).buffer.asByteData(),
            rotatingSecretHash: 'dummy_hash',
            createdAt: DateTime.now(),
            lastUpdatedAt: DateTime.now(),
          ),
        );

        final legacySessionBuilder = sessionBuilder.copyWith(
          authentication: AuthenticationOverride.authenticationInfo(
            userUuid.toString(),
            {},
            authId: rt.id.toString(),
          ),
        );

        final result = await endpoints.queue.bootstrapStaffRole(legacySessionBuilder);
        expect(result, isTrue);

        final updatedUser = await AuthUser.db.findById(session, userUuid);
        expect(updatedUser!.scopeNames, contains('staff'));

        final updatedRt = await RefreshToken.db.findById(session, rt.id!);
        expect(updatedRt!.scopeNames, contains('staff'));
      });

      test('repeated bootstrapStaffRole calls are idempotent and succeed', () async {
        final session = sessionBuilder.build();
        final user = await AuthUser.db.insertRow(
          session,
          AuthUser(scopeNames: <String>{}),
        );
        final userUuid = user.id!;

        final legacySessionBuilder = sessionBuilder.copyWith(
          authentication: AuthenticationOverride.authenticationInfo(
            userUuid.toString(),
            {},
          ),
        );

        final first = await endpoints.queue.bootstrapStaffRole(legacySessionBuilder);
        final second = await endpoints.queue.bootstrapStaffRole(legacySessionBuilder);
        final third = await endpoints.queue.bootstrapStaffRole(legacySessionBuilder);

        expect(first, isTrue);
        expect(second, isTrue);
        expect(third, isTrue);

        final updatedUser = await AuthUser.db.findById(session, userUuid);
        expect(updatedUser!.scopeNames, contains('staff'));
      });

      test('simultaneous bootstrapStaffRole calls serialize safely under concurrency', () async {
        final session = sessionBuilder.build();
        final user = await AuthUser.db.insertRow(
          session,
          AuthUser(scopeNames: <String>{}),
        );
        final userUuid = user.id!;

        final legacySessionBuilder = sessionBuilder.copyWith(
          authentication: AuthenticationOverride.authenticationInfo(
            userUuid.toString(),
            {},
          ),
        );

        final futures = <Future<bool>>[];
        for (var i = 0; i < 5; i++) {
          futures.add(endpoints.queue.bootstrapStaffRole(legacySessionBuilder));
        }

        final results = await Future.wait(futures);
        expect(results, everyElement(isTrue));

        final updatedUser = await AuthUser.db.findById(session, userUuid);
        expect(updatedUser!.scopeNames, contains('staff'));
      });

      test('anonymous requests are rejected across all staff endpoints', () async {
        final anonymous = sessionBuilder;

        expect(
          endpoints.queue.bootstrapStaffRole(anonymous),
          throwsA(isA<QueueException>()),
        );
        expect(
          endpoints.queue.listAuthorizedRooms(anonymous),
          throwsA(isA<QueueException>()),
        );
        expect(
          endpoints.queue.createRoom(anonymous, 'Test Room'),
          throwsA(isA<QueueException>()),
        );
        expect(
          endpoints.queue.getActiveQueue(anonymous),
          throwsA(isA<QueueException>()),
        );
        expect(
          endpoints.queue.callNext(anonymous),
          throwsA(isA<QueueException>()),
        );
        expect(
          endpoints.queue.completeTicket(anonymous, 1),
          throwsA(isA<QueueException>()),
        );
        expect(
          endpoints.queue.subscribeToRoomStaff(anonymous),
          emitsError(isA<QueueException>()),
        );
      });

      test('createRoom atomically creates the room and grants creator access', () async {
        final session = sessionBuilder.build();
        final staffSession = sessionBuilder.copyWith(
          authentication: AuthenticationOverride.authenticationInfo(
            'staff-creator-1',
            {Scope('staff')},
          ),
        );

        final room = await endpoints.queue.createRoom(staffSession, 'Alpha Room');
        expect(room.name, 'Alpha Room');
        expect(room.id, isNotNull);

        final persistedRoom = await QueueRoom.db.findById(session, room.id!);
        expect(persistedRoom, isNotNull);

        final accesses = await StaffRoomAccess.db.find(
          session,
          where: (s) => s.userId.equals('staff-creator-1'),
        );
        expect(accesses, hasLength(1));
        expect(accesses.first.roomId, room.id);

        final authorizedRooms = await endpoints.queue.listAuthorizedRooms(staffSession);
        expect(authorizedRooms.map((r) => r.id), contains(room.id));
      });

      test('cross-user room isolation prevents listing and managing other users rooms', () async {
        final staffSessionA = sessionBuilder.copyWith(
          authentication: AuthenticationOverride.authenticationInfo(
            'staff-user-a',
            {Scope('staff')},
          ),
        );
        final staffSessionB = sessionBuilder.copyWith(
          authentication: AuthenticationOverride.authenticationInfo(
            'staff-user-b',
            {Scope('staff')},
          ),
        );

        final roomA = await endpoints.queue.createRoom(staffSessionA, 'Room A');
        final roomB = await endpoints.queue.createRoom(staffSessionB, 'Room B');

        // Verify listAuthorizedRooms isolation
        final roomsForA = await endpoints.queue.listAuthorizedRooms(staffSessionA);
        final roomsForB = await endpoints.queue.listAuthorizedRooms(staffSessionB);

        expect(roomsForA.map((r) => r.id), contains(roomA.id));
        expect(roomsForA.map((r) => r.id), isNot(contains(roomB.id)));

        expect(roomsForB.map((r) => r.id), contains(roomB.id));
        expect(roomsForB.map((r) => r.id), isNot(contains(roomA.id)));

        // Staff A cannot get queue or call next in Room B
        expect(
          endpoints.queue.getActiveQueue(staffSessionA, roomId: roomB.id),
          throwsA(isA<QueueException>()),
        );
        expect(
          endpoints.queue.callNext(staffSessionA, roomId: roomB.id),
          throwsA(isA<QueueException>()),
        );

        // Staff B cannot get queue or call next in Room A
        expect(
          endpoints.queue.getActiveQueue(staffSessionB, roomId: roomA.id),
          throwsA(isA<QueueException>()),
        );
        expect(
          endpoints.queue.callNext(staffSessionB, roomId: roomA.id),
          throwsA(isA<QueueException>()),
        );
      });

      test('completeTicket enforces authorization against the room on the persisted ticket', () async {
        final staffSessionA = sessionBuilder.copyWith(
          authentication: AuthenticationOverride.authenticationInfo(
            'staff-user-a',
            {Scope('staff')},
          ),
        );
        final staffSessionB = sessionBuilder.copyWith(
          authentication: AuthenticationOverride.authenticationInfo(
            'staff-user-b',
            {Scope('staff')},
          ),
        );

        await endpoints.queue.createRoom(staffSessionA, 'Room A');
        final roomB = await endpoints.queue.createRoom(staffSessionB, 'Room B');

        // Customer joins Room B and Staff B calls next
        final statusB = await endpoints.queue.joinQueue(
          sessionBuilder,
          'Customer in B',
          roomId: roomB.id,
        );
        final calledTicketB = await endpoints.queue.callNext(
          staffSessionB,
          roomId: roomB.id,
        );
        expect(calledTicketB, isNotNull);
        expect(calledTicketB!.id, statusB.ticket.id);

        // Staff A attempts to complete Ticket B using Ticket B's id -> must be denied!
        expect(
          endpoints.queue.completeTicket(staffSessionA, calledTicketB.id!),
          throwsA(isA<QueueException>()),
        );

        // Ticket remains serving in Room B
        final session = sessionBuilder.build();
        final persistedTicket = await QueueTicket.db.findById(session, calledTicketB.id!);
        expect(persistedTicket!.status, 'serving');

        // Staff B can complete Ticket B
        final completed = await endpoints.queue.completeTicket(staffSessionB, calledTicketB.id!);
        expect(completed, isTrue);

        final completedTicket = await QueueTicket.db.findById(session, calledTicketB.id!);
        expect(completedTicket!.status, 'completed');
      });

      test('stream isolation ensures unauthorized access is rejected and events do not leak', () async {
        final staffSessionA = sessionBuilder.copyWith(
          authentication: AuthenticationOverride.authenticationInfo(
            'staff-user-a',
            {Scope('staff')},
          ),
        );
        final staffSessionB = sessionBuilder.copyWith(
          authentication: AuthenticationOverride.authenticationInfo(
            'staff-user-b',
            {Scope('staff')},
          ),
        );

        final roomA = await endpoints.queue.createRoom(staffSessionA, 'Room A');
        final roomB = await endpoints.queue.createRoom(staffSessionB, 'Room B');

        // Staff A cannot subscribe to Room B staff stream
        expect(
          endpoints.queue.subscribeToRoomStaff(staffSessionA, roomId: roomB.id),
          emitsError(isA<QueueException>()),
        );

        // Listen to Room A and Room B streams
        final eventsA = <QueueEvent>[];
        final eventsB = <QueueEvent>[];

        final subA = endpoints.queue
            .subscribeToRoomStaff(staffSessionA, roomId: roomA.id)
            .listen(eventsA.add);
        final subB = endpoints.queue
            .subscribeToRoomStaff(staffSessionB, roomId: roomB.id)
            .listen(eventsB.add);

        await flushEventQueue();

        // Customer joins Room A
        await endpoints.queue.joinQueue(
          sessionBuilder,
          'Customer in Room A',
          roomId: roomA.id,
        );

        // Allow messages to dispatch
        await Future.delayed(const Duration(milliseconds: 200));

        expect(eventsA, hasLength(1));
        expect(eventsA.first.roomId, roomA.id);
        expect(eventsA.first.action, 'joined');

        // Room B must receive zero events from Room A
        expect(eventsB, isEmpty);

        await subA.cancel();
        await subB.cancel();
      });

      test(
        'expired or missing authentication is rejected across all staff endpoints with QueueException',
        () async {
          final unauthenticated = sessionBuilder;

          // None of the staff endpoints allow unauthenticated access
          expect(
            endpoints.queue.getActiveQueue(unauthenticated),
            throwsA(isA<QueueException>()),
          );
          expect(
            endpoints.queue.callNext(unauthenticated),
            throwsA(isA<QueueException>()),
          );
          expect(
            endpoints.queue.completeTicket(unauthenticated, 1),
            throwsA(isA<QueueException>()),
          );
          expect(
            endpoints.queue.createRoom(unauthenticated, 'Forbidden Room'),
            throwsA(isA<QueueException>()),
          );
          expect(
            endpoints.queue.listAuthorizedRooms(unauthenticated),
            throwsA(isA<QueueException>()),
          );
          expect(
            endpoints.queue.subscribeToRoomStaff(unauthenticated),
            emitsError(isA<QueueException>()),
          );
        },
      );

      test(
        'token refresh recovery allows staff user to re-establish authorized room operations',
        () async {
          final staffSessionA = sessionBuilder.copyWith(
            authentication: AuthenticationOverride.authenticationInfo(
              'staff-user-recovery-a',
              {Scope('staff')},
            ),
          );
          final staffSessionB = sessionBuilder.copyWith(
            authentication: AuthenticationOverride.authenticationInfo(
              'staff-user-recovery-b',
              {Scope('staff')},
            ),
          );

          // Staff A creates Room Alpha
          final roomAlpha =
              await endpoints.queue.createRoom(staffSessionA, 'Room Alpha');

          // Simulate an expired/unauthenticated attempt by using sessionBuilder without auth
          final expiredSession = sessionBuilder;
          expect(
            endpoints.queue.getActiveQueue(expiredSession, roomId: roomAlpha.id),
            throwsA(isA<QueueException>()),
          );

          // Simulated token refresh gives Staff A a refreshed valid staff session
          final refreshedStaffSessionA = sessionBuilder.copyWith(
            authentication: AuthenticationOverride.authenticationInfo(
              'staff-user-recovery-a',
              {Scope('staff')},
            ),
          );

          // With refreshed credentials, Staff A can immediately access Room Alpha
          final queue = await endpoints.queue
              .getActiveQueue(refreshedStaffSessionA, roomId: roomAlpha.id);
          expect(queue, isA<List<QueueTicket>>());

          // Even with valid refreshed credentials, Staff B cannot access Room Alpha
          expect(
            endpoints.queue
                .getActiveQueue(staffSessionB, roomId: roomAlpha.id),
            throwsA(isA<QueueException>()),
          );
        },
      );

      test(
        'customer queue join triggers real-time events while preserving mid-stream staff access isolation',
        () async {
          final staffSessionA = sessionBuilder.copyWith(
            authentication: AuthenticationOverride.authenticationInfo(
              'staff-event-a',
              {Scope('staff')},
            ),
          );
          final staffSessionB = sessionBuilder.copyWith(
            authentication: AuthenticationOverride.authenticationInfo(
              'staff-event-b',
              {Scope('staff')},
            ),
          );

          final roomA =
              await endpoints.queue.createRoom(staffSessionA, 'Stream Room A');
          final roomB =
              await endpoints.queue.createRoom(staffSessionB, 'Stream Room B');

          final eventsA = <QueueEvent>[];
          final subA = endpoints.queue
              .subscribeToRoomStaff(staffSessionA, roomId: roomA.id)
              .listen(eventsA.add);

          await flushEventQueue();

          // Concurrent customer joins in Room A and Room B
          await Future.wait([
            endpoints.queue.joinQueue(sessionBuilder, 'Customer 1', roomId: roomA.id),
            endpoints.queue.joinQueue(sessionBuilder, 'Customer 2', roomId: roomB.id),
          ]);

          await Future.delayed(const Duration(milliseconds: 200));

          // Staff A's stream receives joined event for Room A only
          expect(eventsA, hasLength(1));
          expect(eventsA.first.roomId, roomA.id);
          expect(eventsA.first.action, 'joined');

          // Now Staff A calls next customer in Room A
          final calledTicket =
              await endpoints.queue.callNext(staffSessionA, roomId: roomA.id);
          expect(calledTicket, isNotNull);
          expect(calledTicket!.customerName, 'Customer 1');

          // Staff B cannot call next in Room A
          expect(
            endpoints.queue.callNext(staffSessionB, roomId: roomA.id),
            throwsA(isA<QueueException>()),
          );

          await subA.cancel();
        },
      );

      group('cancelTicket', () {
        late int roomId;
        late TestSessionBuilder staffSession;

        setUp(() async {
          staffSession = sessionBuilder.copyWith(
            authentication: AuthenticationOverride.authenticationInfo(
              'staff-cancel-user',
              {Scope('staff')},
            ),
          );
          final room = await endpoints.queue.createRoom(
            staffSession,
            'Cancel Room',
          );
          roomId = room.id!;
        });

        test(
          'when customer cancels waiting ticket, position recalculates for remaining customers',
          () async {
            final alice = await endpoints.queue.joinQueue(
              sessionBuilder,
              'Alice',
              roomId: roomId,
            );
            final bob = await endpoints.queue.joinQueue(
              sessionBuilder,
              'Bob',
              roomId: roomId,
            );

            expect(alice.position, 1);
            expect(bob.position, 2);

            final cancelledAlice = await endpoints.queue.cancelTicket(
              sessionBuilder,
              alice.ticket.id!,
              alice.ticket.accessCode,
            );

            expect(cancelledAlice.ticket.status, 'cancelled');
            expect(cancelledAlice.position, 0);

            final bobStatus = await endpoints.queue.getTicketStatus(
              sessionBuilder,
              bob.ticket.id!,
              bob.ticket.accessCode,
            );
            expect(bobStatus, isNotNull);
            expect(bobStatus!.ticket.status, 'waiting');
            expect(bobStatus.position, 1);
            expect(bobStatus.totalWaiting, 1);
          },
        );

        test(
          'cancelled ticket is immediately excluded from getActiveQueue',
          () async {
            final alice = await endpoints.queue.joinQueue(
              sessionBuilder,
              'Alice',
              roomId: roomId,
            );
            final bob = await endpoints.queue.joinQueue(
              sessionBuilder,
              'Bob',
              roomId: roomId,
            );

            await endpoints.queue.cancelTicket(
              sessionBuilder,
              alice.ticket.id!,
              alice.ticket.accessCode,
            );

            final active = await endpoints.queue.getActiveQueue(
              staffSession,
              roomId: roomId,
            );

            expect(active.length, 1);
            expect(active.first.id, bob.ticket.id);
            expect(active.first.customerName, 'Bob');
          },
        );

        test('cancelTicket with invalid access code throws QueueException', () async {
          final alice = await endpoints.queue.joinQueue(
            sessionBuilder,
            'Alice',
            roomId: roomId,
          );

          await expectLater(
            endpoints.queue.cancelTicket(
              sessionBuilder,
              alice.ticket.id!,
              'invalid-code',
            ),
            throwsA(isA<QueueException>()),
          );
        });

        test('repeated cancelTicket call is idempotent', () async {
          final alice = await endpoints.queue.joinQueue(
            sessionBuilder,
            'Alice',
            roomId: roomId,
          );

          final firstCancel = await endpoints.queue.cancelTicket(
            sessionBuilder,
            alice.ticket.id!,
            alice.ticket.accessCode,
          );
          expect(firstCancel.ticket.status, 'cancelled');

          final secondCancel = await endpoints.queue.cancelTicket(
            sessionBuilder,
            alice.ticket.id!,
            alice.ticket.accessCode,
          );
          expect(secondCancel.ticket.status, 'cancelled');
          expect(secondCancel.position, 0);
        });

        test(
          'cannot cancel ticket that is already serving or completed',
          () async {
            final alice = await endpoints.queue.joinQueue(
              sessionBuilder,
              'Alice',
              roomId: roomId,
            );
            final calledTicket = await endpoints.queue.callNext(
              staffSession,
              roomId: roomId,
            );
            expect(calledTicket?.id, alice.ticket.id);

            // Attempting to cancel while serving throws QueueException
            await expectLater(
              endpoints.queue.cancelTicket(
                sessionBuilder,
                alice.ticket.id!,
                alice.ticket.accessCode,
              ),
              throwsA(isA<QueueException>()),
            );

            // Complete the ticket
            await endpoints.queue.completeTicket(
              staffSession,
              alice.ticket.id!,
            );

            // Attempting to cancel while completed throws QueueException
            await expectLater(
              endpoints.queue.cancelTicket(
                sessionBuilder,
                alice.ticket.id!,
                alice.ticket.accessCode,
              ),
              throwsA(isA<QueueException>()),
            );
          },
        );

        test(
          'cancelling ticket broadcasts cancelled QueueEvent to room stream',
          () async {
            final events = <QueueEvent>[];
            final sub = endpoints.queue
                .subscribeToRoomStaff(
                  staffSession,
                  roomId: roomId,
                )
                .listen(events.add);

            await flushEventQueue();
            await Future<void>.delayed(const Duration(milliseconds: 50));

            final alice = await endpoints.queue.joinQueue(
              sessionBuilder,
              'Alice',
              roomId: roomId,
            );

            await endpoints.queue.cancelTicket(
              sessionBuilder,
              alice.ticket.id!,
              alice.ticket.accessCode,
            );

            await Future<void>.delayed(const Duration(milliseconds: 100));
            await sub.cancel();

            final actions = events.map((e) => e.action).toList();
            expect(actions, containsAll(['joined', 'cancelled']));
            final cancelEvent = events.firstWhere((e) => e.action == 'cancelled');
            expect(cancelEvent.roomId, roomId);
          },
        );

        group('Staff default room resolution and room isolation regressions', () {
          late int roomAId;
          late int roomBId;
          late TestSessionBuilder staffASession;
          late TestSessionBuilder staffBSession;

          setUp(() async {
            final session = sessionBuilder.build();
            final roomA = await QueueRoom.db.insertRow(
              session,
              QueueRoom(name: 'Room A Isolated', createdAt: DateTime.now()),
            );
            roomAId = roomA.id!;

            final roomB = await QueueRoom.db.insertRow(
              session,
              QueueRoom(name: 'Room B Isolated', createdAt: DateTime.now()),
            );
            roomBId = roomB.id!;

            staffASession = sessionBuilder.copyWith(
              authentication: AuthenticationOverride.authenticationInfo(
                'staff-user-a',
                {Scope('staff')},
              ),
            );
            staffBSession = sessionBuilder.copyWith(
              authentication: AuthenticationOverride.authenticationInfo(
                'staff-user-b',
                {Scope('staff')},
              ),
            );

            await StaffRoomAccess.db.insertRow(
              session,
              StaffRoomAccess(userId: 'staff-user-a', roomId: roomAId),
            );
            await StaffRoomAccess.db.insertRow(
              session,
              StaffRoomAccess(userId: 'staff-user-b', roomId: roomBId),
            );
          });

          test(
            'staff user without General access resolves to their own authorized room when roomId is omitted',
            () async {
              await endpoints.queue.joinQueue(
                sessionBuilder,
                'Customer A',
                roomId: roomAId,
              );

              final queue = await endpoints.queue.getActiveQueue(
                staffASession,
                roomId: null,
              );

              expect(queue, hasLength(1));
              expect(queue.first.customerName, 'Customer A');
              expect(queue.first.roomId, roomAId);
            },
          );

          test(
            'staff user is strictly rejected when attempting to access another staff user room',
            () async {
              expect(
                () => endpoints.queue.getActiveQueue(
                  staffASession,
                  roomId: roomBId,
                ),
                throwsA(
                  isA<QueueException>().having(
                    (e) => e.message,
                    'message',
                    contains('You do not have permission to manage this room.'),
                  ),
                ),
              );
            },
          );

          test(
            'callNext with omitted roomId operates on staff user own authorized room',
            () async {
              await endpoints.queue.joinQueue(
                sessionBuilder,
                'Customer B',
                roomId: roomBId,
              );

              final ticket = await endpoints.queue.callNext(
                staffBSession,
                roomId: null,
              );

              expect(ticket, isNotNull);
              expect(ticket!.customerName, 'Customer B');
              expect(ticket.roomId, roomBId);
              expect(ticket.status, 'serving');
            },
          );

          test(
            'createRoom and deleteRoom broadcast realtime events to subscribeToRooms',
            () async {
              final roomEvents = endpoints.queue.subscribeToRooms(sessionBuilder);
              final eventsIterator = StreamIterator(roomEvents);

              // 1. Staff creates a room
              final createdRoom = await endpoints.queue.createRoom(
                staffASession,
                'Realtime Room Test',
              );
              expect(createdRoom.id, isNotNull);

              expect(await eventsIterator.moveNext(), isTrue);
              expect(eventsIterator.current.roomId, createdRoom.id);
              expect(eventsIterator.current.action, 'created');

              // 2. Staff deletes the room
              await endpoints.queue.deleteRoom(
                staffASession,
                createdRoom.id!,
              );

              expect(await eventsIterator.moveNext(), isTrue);
              expect(eventsIterator.current.roomId, createdRoom.id);
              expect(eventsIterator.current.action, 'deleted');

              await eventsIterator.cancel();
            },
          );
        });
      });
    },
    rollbackDatabase: RollbackDatabase.disabled,
  );
}
