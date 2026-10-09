import 'package:test/test.dart';
import 'test_tools/serverpod_test_tools.dart';

void main() {
  withServerpod('Given Queue endpoint', (sessionBuilder, endpoints) {
    test('when a customer joins the queue, a ticket is created', () async {
      final status = await endpoints.queue.joinQueue(sessionBuilder, 'Alice');
      expect(status.ticket.customerName, 'Alice');
      expect(status.ticket.ticketNumber, 1);
      expect(status.ticket.status, 'waiting');
      expect(status.position, 1);
      expect(status.totalWaiting, 1);
    });

    test('when multiple customers join, positions and ticket numbers increase', () async {
      await endpoints.queue.joinQueue(sessionBuilder, 'Alice');
      final status2 = await endpoints.queue.joinQueue(sessionBuilder, 'Bob');
      
      expect(status2.ticket.customerName, 'Bob');
      expect(status2.ticket.ticketNumber, 2);
      expect(status2.position, 2);
      expect(status2.totalWaiting, 2);
    });

    test('when checking status of an existing ticket', () async {
      final status1 = await endpoints.queue.joinQueue(sessionBuilder, 'Alice');
      await endpoints.queue.joinQueue(sessionBuilder, 'Bob');

      final checkedStatus = await endpoints.queue.getTicketStatus(sessionBuilder, status1.ticket.id!);
      expect(checkedStatus, isNotNull);
      expect(checkedStatus!.position, 1);
      expect(checkedStatus.totalWaiting, 2);
    });

    test('when calling the next customer, status updates to serving', () async {
      await endpoints.queue.joinQueue(sessionBuilder, 'Alice');
      await endpoints.queue.joinQueue(sessionBuilder, 'Bob');

      final ticket = await endpoints.queue.callNext(sessionBuilder);
      expect(ticket, isNotNull);
      expect(ticket!.customerName, 'Alice');
      expect(ticket.status, 'serving');

      final active = await endpoints.queue.getActiveQueue(sessionBuilder);
      expect(active.length, 2);
      expect(active[0].status, 'serving');
      expect(active[1].status, 'waiting');
    });

    test('when completing a ticket', () async {
      await endpoints.queue.joinQueue(sessionBuilder, 'Alice');
      final ticket = await endpoints.queue.callNext(sessionBuilder);
      expect(ticket, isNotNull);

      final success = await endpoints.queue.completeTicket(sessionBuilder, ticket!.id!);
      expect(success, isTrue);

      final active = await endpoints.queue.getActiveQueue(sessionBuilder);
      expect(active, isEmpty); // Alice is completed, so active queue is empty
    });

    test('calling next on empty queue is handled correctly', () async {
      final ticket = await endpoints.queue.callNext(sessionBuilder);
      expect(ticket, isNull);
    });
  });

  withServerpod('Given Queue endpoint concurrency', (sessionBuilder, endpoints) {
    test('concurrent joins receive unique ticket numbers', () async {
      final futures = <Future<dynamic>>[];
      for (var i = 0; i < 10; i++) {
        futures.add(endpoints.queue.joinQueue(sessionBuilder, 'User\$i'));
      }
      final statuses = await Future.wait(futures);
      final ticketNumbers = statuses.map((s) => s.ticket.ticketNumber).toSet();
      expect(ticketNumbers.length, 10);
      
      // Clean up for next test
      for (var i = 0; i < 10; i++) {
        var t = await endpoints.queue.callNext(sessionBuilder);
        await endpoints.queue.completeTicket(sessionBuilder, t!.id!);
      }
    });

    test('concurrent callNext requests do not assign same ticket twice', () async {
      await endpoints.queue.joinQueue(sessionBuilder, 'Alice');
      await endpoints.queue.joinQueue(sessionBuilder, 'Bob');
      
      final futures = <Future<dynamic>>[];
      for (var i = 0; i < 5; i++) {
        futures.add(endpoints.queue.callNext(sessionBuilder));
      }
      final results = await Future.wait(futures);
      final claimedTickets = results.where((t) => t != null).toList();
      
      expect(claimedTickets.length, 2);
      final claimedNames = claimedTickets.map((t) => t.customerName).toSet();
      expect(claimedNames, containsAll(['Alice', 'Bob']));
      
      // Clean up
      for (var t in claimedTickets) {
        await endpoints.queue.completeTicket(sessionBuilder, t.id!);
      }
    });
  }, rollbackDatabase: RollbackDatabase.disabled);
}
