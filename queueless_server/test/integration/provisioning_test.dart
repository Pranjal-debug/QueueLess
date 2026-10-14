import 'package:serverpod/serverpod.dart';
import 'package:test/test.dart';
import 'package:queueless_server/src/generated/protocol.dart';
import 'package:serverpod_auth_idp_server/core.dart';
import 'package:queueless_server/src/business/staff_provisioning.dart';

import 'test_tools/serverpod_test_tools.dart';

void main() {
  withServerpod('queueless', (sessionBuilder, endpoints) {
    var session = sessionBuilder.build();

    setUp(() async {
      // Create fresh session for setup
      session = sessionBuilder.build();

      // Clear tables
      await QueueTicket.db.deleteWhere(session, where: (_) => Constant.bool(true));
      await QueueSession.db.deleteWhere(session, where: (_) => Constant.bool(true));
      await StaffRoomAccess.db.deleteWhere(session, where: (_) => Constant.bool(true));
      await QueueRoom.db.deleteWhere(session, where: (_) => Constant.bool(true));
      await EmailAccount.db.deleteWhere(session, where: (_) => Constant.bool(true));
      await AuthUser.db.deleteWhere(session, where: (_) => Constant.bool(true));
    });

    Future<QueueRoom> createRoom(int roomId) async {
      final room = QueueRoom(
        id: roomId,
        name: 'Test Room \$roomId',
        createdAt: DateTime.now(),
      );
      return await QueueRoom.db.insertRow(session, room);
    }

    Future<void> createUser(String email, {bool blocked = false, List<String>? scopes}) async {
      final user = AuthUser(
        id: UuidValue.fromString(Uuid().v4()),
        scopeNames: (scopes ?? []).toSet(),
        blocked: blocked,
      );
      final insertedUser = await AuthUser.db.insertRow(session, user);

      final emailAccount = EmailAccount(
        authUserId: insertedUser.id!,
        email: email,
        passwordHash: 'mock_hash',
      );
      await EmailAccount.db.insertRow(session, emailAccount);
    }

    test('Existing user provisioned successfully with case insensitivity', () async {
      final room = await createRoom(10);
      await createUser('Test@Test.com'); // Inserted with uppercase

      // Provision with lowercase, should find it due to normalization
      await StaffProvisioning.provision(session, 'test@test.com', room.id!);

      final emailAuth = await EmailAccount.db.findFirstRow(session, where: (e) => e.email.equals('Test@Test.com'));
      final updatedUser = await AuthUser.db.findById(session, emailAuth!.authUserId);
      expect(updatedUser!.scopeNames, contains('staff'));

      final access = await StaffRoomAccess.db.findFirstRow(
        session,
        where: (s) => s.userId.equals(updatedUser.id.toString()) & s.roomId.equals(room.id!),
      );
      expect(access, isNotNull);
    });

    test('Missing email account', () async {
      final room = await createRoom(20);
      expect(
        StaffProvisioning.provision(session, 'nonexistent@test.com', room.id!),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('Blocked user', () async {
      final room = await createRoom(30);
      await createUser('blocked@test.com', blocked: true);
      expect(
        StaffProvisioning.provision(session, 'blocked@test.com', room.id!),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('Missing room', () async {
      await createUser('noroom@test.com');
      expect(
        StaffProvisioning.provision(session, 'noroom@test.com', 9999),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('Existing scopes preserved', () async {
      final room = await createRoom(40);
      await createUser('scopes@test.com', scopes: ['existing_scope']);

      await StaffProvisioning.provision(session, 'scopes@test.com', room.id!);

      final emailAuth = await EmailAccount.db.findFirstRow(session, where: (e) => e.email.equals('scopes@test.com'));
      final updatedUser = await AuthUser.db.findById(session, emailAuth!.authUserId);
      expect(updatedUser!.scopeNames, contains('staff'));
      expect(updatedUser.scopeNames, contains('existing_scope'));
    });

    test('Repeated provisioning does not duplicate access', () async {
      final room = await createRoom(50);
      await createUser('repeat@test.com');

      await StaffProvisioning.provision(session, 'repeat@test.com', room.id!);
      await StaffProvisioning.provision(session, 'repeat@test.com', room.id!);

      final emailAuth = await EmailAccount.db.findFirstRow(session, where: (e) => e.email.equals('repeat@test.com'));
      final updatedUser = await AuthUser.db.findById(session, emailAuth!.authUserId);
      expect(updatedUser!.scopeNames.where((s) => s == 'staff').length, equals(1));

      final accessList = await StaffRoomAccess.db.find(
        session,
        where: (s) => s.userId.equals(updatedUser.id.toString()) & s.roomId.equals(room.id!),
      );
      expect(accessList.length, equals(1));
    });

    test('Transaction failure leaves neither partial scope nor partial access', () async {
      final room = await createRoom(60);
      await createUser('rollback@test.com');
      
      final emailAuthBefore = await EmailAccount.db.findFirstRow(session, where: (e) => e.email.equals('rollback@test.com'));
      final authUserBefore = await AuthUser.db.findById(session, emailAuthBefore!.authUserId);
      expect(authUserBefore!.scopeNames, isNot(contains('staff')));

      // Attempt to provision, but use the hook to throw an exception inside the transaction
      // This guarantees the updateRow and insertRow run, but the transaction rolls back.
      bool threwException = false;
      try {
        await StaffProvisioning.provision(session, 'rollback@test.com', room.id!, testHook: () async {
          throw Exception('Simulated database failure');
        });
      } catch (e) {
        threwException = true;
      }
      expect(threwException, isTrue);

      // Verify AuthUser scope rolled back
      final authUserAfter = await AuthUser.db.findById(session, emailAuthBefore.authUserId);
      expect(authUserAfter!.scopeNames, isNot(contains('staff')));

      // Verify StaffRoomAccess rolled back
      final accessList = await StaffRoomAccess.db.find(
        session,
        where: (s) => s.userId.equals(authUserAfter.id.toString()) & s.roomId.equals(room.id!),
      );
      expect(accessList, isEmpty);
    });
  });
}
