import 'package:flutter_test/flutter_test.dart';
import 'package:queueless_client/queueless_client.dart';

void main() {
  test('E2E Endpoints exception', () async {
    final client = Client('http://localhost:8080/');

    expect(
      client.queue.getActiveQueue(roomId: 1),
      throwsA(
        predicate<Object>(
          (error) => error.toString().contains(
            'Unauthorized: Staff login required.',
          ),
        ),
      ),
    );
  });
}
