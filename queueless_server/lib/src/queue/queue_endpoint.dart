import 'package:serverpod/serverpod.dart';
import '../generated/protocol.dart';

class QueueEndpoint extends Endpoint {
  /// Join the queue. Returns the created ticket and its position.
  Future<QueueStatus> joinQueue(Session session, String customerName) async {
    final trimmedName = customerName.trim();
    if (trimmedName.isEmpty) {
      throw Exception('Customer name cannot be empty.');
    }

    // Use a transaction to ensure no duplicate ticket numbers if called concurrently.
    return session.db.transaction((transaction) async {
      await session.db.unsafeQuery('LOCK TABLE queue_ticket IN EXCLUSIVE MODE;', transaction: transaction);

      // Find the current max ticket number
      final latestTicket = await QueueTicket.db.findFirstRow(
        session,
        orderByList: (t) => [t.ticketNumber.desc()],
        transaction: transaction,
      );

      final nextTicketNumber = (latestTicket?.ticketNumber ?? 0) + 1;

      var ticket = QueueTicket(
        customerName: trimmedName,
        ticketNumber: nextTicketNumber,
        status: 'waiting',
        createdAt: DateTime.now(),
      );

      ticket = await QueueTicket.db.insertRow(session, ticket, transaction: transaction);

      final totalWaiting = await QueueTicket.db.count(
        session,
        where: (t) => t.status.equals('waiting'),
        transaction: transaction,
      );

      // The new ticket is at the end, so its position is totalWaiting.
      return QueueStatus(
        ticket: ticket,
        position: totalWaiting,
        totalWaiting: totalWaiting,
      );
    });
  }

  /// Get the status of a specific ticket.
  Future<QueueStatus?> getTicketStatus(Session session, int ticketId) async {
    final ticket = await QueueTicket.db.findById(session, ticketId);
    if (ticket == null) {
      return null;
    }

    if (ticket.status != 'waiting') {
      return QueueStatus(
        ticket: ticket,
        position: 0,
        totalWaiting: await _getTotalWaiting(session),
      );
    }

    final position = await QueueTicket.db.count(
      session,
      where: (t) => t.status.equals('waiting') & (t.ticketNumber <= ticket.ticketNumber),
    );

    return QueueStatus(
      ticket: ticket,
      position: position,
      totalWaiting: await _getTotalWaiting(session),
    );
  }

  /// Returns currently waiting and serving tickets ordered by ticket number.
  Future<List<QueueTicket>> getActiveQueue(Session session) async {
    return QueueTicket.db.find(
      session,
      where: (t) => t.status.equals('waiting') | t.status.equals('serving'),
      orderBy: (t) => t.ticketNumber,
    );
  }

  /// Call the next waiting customer.
  Future<QueueTicket?> callNext(Session session) async {
    return session.db.transaction((transaction) async {
      // Find the earliest waiting ticket.
      var ticket = await QueueTicket.db.findFirstRow(
        session,
        where: (t) => t.status.equals('waiting'),
        orderBy: (t) => t.ticketNumber,
        transaction: transaction,
        lockMode: LockMode.forUpdate,
        lockBehavior: LockBehavior.skipLocked,
      );

      if (ticket == null) {
        return null;
      }

      ticket = ticket.copyWith(
        status: 'serving',
        calledAt: DateTime.now(),
      );

      return QueueTicket.db.updateRow(session, ticket, transaction: transaction);
    });
  }

  /// Complete a ticket that is currently being served.
  Future<bool> completeTicket(Session session, int ticketId) async {
    return session.db.transaction((transaction) async {
      var ticket = await QueueTicket.db.findById(session, ticketId, transaction: transaction);
      if (ticket == null) {
        throw Exception('Ticket not found.');
      }
      if (ticket.status != 'serving') {
        throw Exception('Can only complete tickets that are currently serving.');
      }

      ticket = ticket.copyWith(
        status: 'completed',
        completedAt: DateTime.now(),
      );

      await QueueTicket.db.updateRow(session, ticket, transaction: transaction);
      return true;
    });
  }

  Future<int> _getTotalWaiting(Session session) async {
    return QueueTicket.db.count(
      session,
      where: (t) => t.status.equals('waiting'),
    );
  }
}
