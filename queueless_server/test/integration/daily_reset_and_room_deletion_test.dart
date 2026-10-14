import 'dart:async';
import 'package:test/test.dart';
import 'package:serverpod/serverpod.dart';
import 'package:queueless_server/src/generated/protocol.dart';
import 'package:queueless_server/src/queue/queue_endpoint.dart';
import 'test_tools/serverpod_test_tools.dart';

void main() {
  withServerpod('Feature 1, 2, 3: Daily Reset, Restart Queue & Room Deletion',
      (sessionBuilder, endpoints) {
    late int roomAId;
    late int roomBId;
    late TestSessionBuilder staffASession;
    late TestSessionBuilder staffBSession;

    setUp(() async {
      final session = sessionBuilder.build();
      await QueueTicket.db.deleteWhere(session, where: (t) => t.id > 0);
      await QueueSession.db.deleteWhere(session, where: (s) => s.id > 0);
      await StaffRoomAccess.db.deleteWhere(session, where: (s) => s.id > 0);
      await QueueRoom.db.deleteWhere(session, where: (r) => r.id > 0);

      // Create two rooms for two different staff members
      final roomA = await QueueRoom.db.insertRow(
        session,
        QueueRoom(name: 'Room Alpha', createdAt: DateTime.now()),
      );
      roomAId = roomA.id!;

      final roomB = await QueueRoom.db.insertRow(
        session,
        QueueRoom(name: 'Room Beta', createdAt: DateTime.now()),
      );
      roomBId = roomB.id!;

      staffASession = sessionBuilder.copyWith(
        authentication: AuthenticationOverride.authenticationInfo(
          'staff-user-A',
          {Scope('staff')},
        ),
      );
      await StaffRoomAccess.db.insertRow(
        session,
        StaffRoomAccess(userId: 'staff-user-A', roomId: roomAId),
      );

      staffBSession = sessionBuilder.copyWith(
        authentication: AuthenticationOverride.authenticationInfo(
          'staff-user-B',
          {Scope('staff')},
        ),
      );
      await StaffRoomAccess.db.insertRow(
        session,
        StaffRoomAccess(userId: 'staff-user-B', roomId: roomBId),
      );
    });

    group('Feature 1: Daily Ticket Numbering Reset & Sessions', () {
      test('first ticket in a new session is #1 and sequential joins increment numbers', () async {
        final t1 = await endpoints.queue.joinQueue(
          sessionBuilder,
          'Customer 1',
          roomId: roomAId,
        );
        expect(t1.ticket.ticketNumber, 1);
        expect(t1.position, 1);
        expect(t1.totalWaiting, 1);

        final t2 = await endpoints.queue.joinQueue(
          sessionBuilder,
          'Customer 2',
          roomId: roomAId,
        );
        expect(t2.ticket.ticketNumber, 2);
        expect(t2.position, 2);
        expect(t2.totalWaiting, 2);

        final t3 = await endpoints.queue.joinQueue(
          sessionBuilder,
          'Customer 3',
          roomId: roomAId,
        );
        expect(t3.ticket.ticketNumber, 3);
        expect(t3.position, 3);
        expect(t3.totalWaiting, 3);
      });

      test('two rooms have completely independent counters', () async {
        final tA1 = await endpoints.queue.joinQueue(
          sessionBuilder,
          'Alice',
          roomId: roomAId,
        );
        final tA2 = await endpoints.queue.joinQueue(
          sessionBuilder,
          'Adam',
          roomId: roomAId,
        );

        final tB1 = await endpoints.queue.joinQueue(
          sessionBuilder,
          'Bob',
          roomId: roomBId,
        );

        expect(tA1.ticket.ticketNumber, 1);
        expect(tA2.ticket.ticketNumber, 2);
        // Room B starts at #1 independently
        expect(tB1.ticket.ticketNumber, 1);
      });

      test('Asia/Kolkata date calculation correctly accounts for UTC+5:30 offset', () {
        // 2026-10-13 18:29:00 UTC -> 23:59:00 IST (same day: 2026-10-13)
        final beforeMidnightUtc = DateTime.utc(2026, 10, 13, 18, 29, 0);
        expect(getKolkataBusinessDate(beforeMidnightUtc), '2026-10-13');

        // 2026-10-13 18:31:00 UTC -> 00:01:00 IST next day (2026-10-14)
        final afterMidnightUtc = DateTime.utc(2026, 10, 13, 18, 31, 0);
        expect(getKolkataBusinessDate(afterMidnightUtc), '2026-10-14');
      });

      test('daily rollover resets ticket numbers to #1, closes old tickets, and preserves history', () async {
        final sessionDb = sessionBuilder.build();
        final day1Time = DateTime.now().toUtc().subtract(const Duration(days: 1));
        final day1Date = getKolkataBusinessDate(day1Time);
        final s1 = await endpoints.queue.getActiveSession(
          sessionBuilder,
          roomAId,
          referenceTime: day1Time,
        );
        expect(s1.businessDate, day1Date);
        expect(s1.sessionNumber, 1);

        // Seed customer on Day 1 session
        final day1Cust1 = await QueueTicket.db.insertRow(
          sessionDb,
          QueueTicket(
            customerName: 'Day 1 Cust 1',
            roomId: roomAId,
            sessionId: s1.id!,
            accessCode: '123456',
            ticketNumber: 1,
            status: 'waiting',
            createdAt: day1Time,
          ),
        );
        expect(day1Cust1.ticketNumber, 1);

        // Day 2 arrives (current business date in Kolkata)
        final todayDate = getKolkataBusinessDate();
        final s2 = await endpoints.queue.getActiveSession(
          sessionBuilder,
          roomAId,
        );
        expect(s2.businessDate, todayDate);
        expect(s2.sessionNumber, 2);
        expect(s2.id, isNot(equals(s1.id)));

        // Verify old session s1 was closed
        final s1Reloaded = await QueueSession.db.findById(sessionDb, s1.id!);
        expect(s1Reloaded!.status, 'closed');
        expect(s1Reloaded.closedAt, isNotNull);

        // Verify day 1 ticket was cancelled
        final day1TicketReloaded =
            await QueueTicket.db.findById(sessionDb, day1Cust1.id!);
        expect(day1TicketReloaded!.status, 'cancelled');
        expect(day1TicketReloaded.completedAt, isNotNull);

        // Active queue for staff in new session is now empty
        final activeQueue = await endpoints.queue.getActiveQueue(
          staffASession,
          roomId: roomAId,
        );
        expect(activeQueue, isEmpty);

        // First customer in day 2 session receives ticket #1
        final day2Cust1 = await endpoints.queue.joinQueue(
          sessionBuilder,
          'Day 2 Cust 1',
          roomId: roomAId,
        );
        expect(day2Cust1.ticket.ticketNumber, 1);
        expect(day2Cust1.position, 1);
        expect(day2Cust1.totalWaiting, 1);

        // Historical tickets remain intact in the database
        final allRoomTickets = await QueueTicket.db.find(
          sessionDb,
          where: (t) => t.roomId.equals(roomAId),
        );
        expect(allRoomTickets.length, 2);
      });

      test('concurrent joins do not produce duplicate numbers', () async {
        final futures = List.generate(
          10,
          (i) => endpoints.queue.joinQueue(
            sessionBuilder,
            'Concurrent Cust $i',
            roomId: roomAId,
          ),
        );

        final results = await Future.wait(futures);
        final ticketNumbers = results.map((r) => r.ticket.ticketNumber).toList();
        expect(ticketNumbers.toSet().length, 10);
        expect(ticketNumbers..sort(), [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]);
      });

      test('old ticket from a closed session cannot modify the new session', () async {
        final cust = await endpoints.queue.joinQueue(
          sessionBuilder,
          'Old Cust',
          roomId: roomAId,
        );

        // Staff restarts queue, closing the session
        await endpoints.queue.restartQueue(staffASession, roomAId);

        // New customer joins in new session
        final newCust = await endpoints.queue.joinQueue(
          sessionBuilder,
          'New Cust',
          roomId: roomAId,
        );
        expect(newCust.ticket.ticketNumber, 1);

        // Old customer checks status
        final oldStatus = await endpoints.queue.getTicketStatus(
          sessionBuilder,
          cust.ticket.id!,
          cust.ticket.accessCode,
        );
        expect(oldStatus!.ticket.status, 'cancelled');
        expect(oldStatus.position, 0);

        // Old customer attempts to cancel their ticket -> returns position 0, does not alter active queue
        final cancelResult = await endpoints.queue.cancelTicket(
          sessionBuilder,
          cust.ticket.id!,
          cust.ticket.accessCode,
        );
        expect(cancelResult.position, 0);

        // Active queue still has newCust waiting
        final activeQueue = await endpoints.queue.getActiveQueue(
          staffASession,
          roomId: roomAId,
        );
        expect(activeQueue.length, 1);
        expect(activeQueue.first.ticketNumber, 1);
      });
    });

    group('Feature 2: Manual Queue Restart', () {
      test('authorized staff can restart queue, resetting counter to #1 and cancelling active tickets', () async {
        await endpoints.queue.joinQueue(
          sessionBuilder,
          'Cust 1',
          roomId: roomAId,
        );
        await endpoints.queue.joinQueue(
          sessionBuilder,
          'Cust 2',
          roomId: roomAId,
        );

        // Call Cust 1 to make it 'serving'
        await endpoints.queue.callNext(staffASession, roomId: roomAId);

        // Queue has 1 serving and 1 waiting
        final preRestartQueue = await endpoints.queue.getActiveQueue(
          staffASession,
          roomId: roomAId,
        );
        expect(preRestartQueue.length, 2);

        // Staff restarts queue
        final newSession = await endpoints.queue.restartQueue(
          staffASession,
          roomAId,
        );
        expect(newSession.sessionNumber, 2);
        expect(newSession.status, 'active');

        // Active queue is now empty
        final postRestartQueue = await endpoints.queue.getActiveQueue(
          staffASession,
          roomId: roomAId,
        );
        expect(postRestartQueue, isEmpty);

        // Next join starts at ticket #1
        final nextCust = await endpoints.queue.joinQueue(
          sessionBuilder,
          'Fresh Cust',
          roomId: roomAId,
        );
        expect(nextCust.ticket.ticketNumber, 1);

        // History preserved: old tickets are still in database
        final sessionDb = sessionBuilder.build();
        final allTickets = await QueueTicket.db.find(
          sessionDb,
          where: (t) => t.roomId.equals(roomAId),
        );
        expect(allTickets.length, 3);
      });

      test('unauthorized staff cannot restart another staff member queue', () async {
        expect(
          () => endpoints.queue.restartQueue(staffBSession, roomAId),
          throwsA(
            isA<QueueException>().having(
              (e) => e.message,
              'message',
              contains('You do not have permission to manage this room.'),
            ),
          ),
        );
      });

      test('unauthenticated caller cannot restart queue', () async {
        expect(
          () => endpoints.queue.restartQueue(sessionBuilder, roomAId),
          throwsA(isA<QueueException>()),
        );
      });

      test('concurrent restart requests do not create multiple active sessions', () async {
        final futures = List.generate(
          5,
          (_) => endpoints.queue.restartQueue(staffASession, roomAId),
        );

        await Future.wait(futures);

        final sessionDb = sessionBuilder.build();
        final activeSessions = await QueueSession.db.find(
          sessionDb,
          where: (s) => s.roomId.equals(roomAId) & s.status.equals('active'),
        );
        expect(activeSessions.length, 1);
      });
    });

    group('Feature 3: Safe Room Deletion', () {
      test('authorized staff can delete their room safely without deleting historical data', () async {
        await endpoints.queue.joinQueue(
          sessionBuilder,
          'Active Cust',
          roomId: roomAId,
        );

        final deleteSuccess = await endpoints.queue.deleteRoom(
          staffASession,
          roomAId,
        );
        expect(deleteSuccess, isTrue);

        final sessionDb = sessionBuilder.build();
        final room = await QueueRoom.db.findById(sessionDb, roomAId);
        expect(room, isNotNull);
        expect(room!.deletedAt, isNotNull);

        // Historical tickets preserved
        final tickets = await QueueTicket.db.find(
          sessionDb,
          where: (t) => t.roomId.equals(roomAId),
        );
        expect(tickets.length, 1);
        expect(tickets.first.status, 'cancelled');
      });

      test('deleted room is excluded from listRooms and listAuthorizedRooms', () async {
        final initialPublicRooms =
            await endpoints.queue.listRooms(sessionBuilder);
        expect(initialPublicRooms.any((r) => r.id == roomAId), isTrue);

        await endpoints.queue.deleteRoom(staffASession, roomAId);

        final publicRooms = await endpoints.queue.listRooms(sessionBuilder);
        expect(publicRooms.any((r) => r.id == roomAId), isFalse);

        final staffRooms =
            await endpoints.queue.listAuthorizedRooms(staffASession);
        expect(staffRooms.any((r) => r.id == roomAId), isFalse);
      });

      test('joining a deleted room is rejected with a clear error', () async {
        await endpoints.queue.deleteRoom(staffASession, roomAId);

        expect(
          () => endpoints.queue.joinQueue(
            sessionBuilder,
            'Late Customer',
            roomId: roomAId,
          ),
          throwsA(
            isA<QueueException>().having(
              (e) => e.message,
              'message',
              contains('This room has been deleted'),
            ),
          ),
        );
      });

      test('unauthorized staff cannot delete another account room', () async {
        expect(
          () => endpoints.queue.deleteRoom(staffBSession, roomAId),
          throwsA(
            isA<QueueException>().having(
              (e) => e.message,
              'message',
              contains('You do not have permission to manage this room.'),
            ),
          ),
        );
      });

      test('unauthenticated request to delete room is rejected', () async {
        expect(
          () => endpoints.queue.deleteRoom(sessionBuilder, roomAId),
          throwsA(isA<QueueException>()),
        );
      });
    });
  }, rollbackDatabase: RollbackDatabase.disabled);
}
