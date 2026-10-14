import 'package:flutter_test/flutter_test.dart';
import 'package:queueless_client/queueless_client.dart';

void main() {
  test('E2E Endpoints', () async {
    final client = Client('http://localhost:8080/');

    // Test 1: Customer A joins
    final joinStatusA = await client.queue.joinQueue('Customer A', roomId: 1);
    final posA = joinStatusA.position;

    // Test 2: Customer B joins
    final joinStatusB = await client.queue.joinQueue('Customer B', roomId: 1);
    final posB = joinStatusB.position;

    // Check Customer A's status again and confirm Room 1 remains isolated.
    final statusA = await client.queue.getTicketStatus(
      joinStatusA.ticket.id!,
      joinStatusA.ticket.accessCode,
    );

    expect(posB, posA + 1);
    expect(statusA?.position, posA);
  });
}
