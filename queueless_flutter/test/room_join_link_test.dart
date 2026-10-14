import 'package:flutter_test/flutter_test.dart';
import 'package:queueless_flutter/room_join_link.dart';

void main() {
  test('builds a room-only customer URL from the configured base', () {
    final url = buildRoomJoinUrl(
      roomId: 7,
      baseUrl: 'https://queue.example/join?old=value',
    );

    expect(url, 'https://queue.example/join?roomId=7');
    expect(url, isNot(contains('token')));
    expect(url, isNot(contains('accessCode')));
  });

  test('drops unsafe URL components from the customer payload', () {
    final url = buildRoomJoinUrl(
      roomId: 7,
      baseUrl:
          'https://sentinel-user:sentinel-password@queue.example/'
          'staff/sentinel-dashboard?authToken=sentinel-auth-token&'
          'cookie=sentinel-cookie&accessCode=sentinel-access-code'
          '#sentinel-fragment',
    );

    expect(url, isNotNull);
    final parsed = Uri.parse(url!);
    expect(parsed.scheme, 'https');
    expect(parsed.host, 'queue.example');
    expect(parsed.userInfo, isEmpty);
    expect(parsed.path, isEmpty);
    expect(parsed.queryParameters, {'roomId': '7'});
    expect(parsed.fragment, isEmpty);
    expect(url, isNot(contains('sentinel-user')));
    expect(url, isNot(contains('sentinel-password')));
    expect(url, isNot(contains('sentinel-auth-token')));
    expect(url, isNot(contains('sentinel-cookie')));
    expect(url, isNot(contains('sentinel-access-code')));
    expect(url, isNot(contains('sentinel-dashboard')));
    expect(url, isNot(contains('sentinel-fragment')));
  });

  test('rejects invalid room IDs and unsupported bases safely', () {
    expect(
      buildRoomJoinUrl(roomId: null, baseUrl: 'https://queue.example'),
      isNull,
    );
    expect(
      buildRoomJoinUrl(roomId: 0, baseUrl: 'https://queue.example'),
      isNull,
    );
    expect(
      buildRoomJoinUrl(roomId: -1, baseUrl: 'https://queue.example'),
      isNull,
    );
    expect(buildRoomJoinUrl(roomId: 7, baseUrl: 'javascript:alert(1)'), isNull);
  });
}
