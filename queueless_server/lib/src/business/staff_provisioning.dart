import 'package:serverpod/serverpod.dart';
import 'package:serverpod_auth_idp_server/core.dart';
import 'package:queueless_server/src/generated/protocol.dart';

class StaffProvisioning {
  static Future<void> provision(Session session, String email, int roomId, {Future<void> Function()? testHook}) async {
    // 1. Validate room
    final room = await QueueRoom.db.findById(session, roomId);
    if (room == null) {
      throw ArgumentError('Room \$roomId does not exist.');
    }

    // 2. Precise account resolution
    final normalizedEmail = email.trim().toLowerCase();
    final escapedEmail = normalizedEmail.replaceAll('%', r'\%').replaceAll('_', r'\_');
    
    final emailAuths = await EmailAccount.db.find(
      session,
      where: (e) => e.email.ilike(escapedEmail),
    );

    if (emailAuths.isEmpty) {
      throw ArgumentError('No registered account found for email: $normalizedEmail');
    }
    if (emailAuths.length > 1) {
      throw StateError('Ambiguous match: Multiple accounts found for email: $normalizedEmail');
    }
    
    final emailAuth = emailAuths.first;

    final authUser = await AuthUser.db.findById(session, emailAuth.authUserId);
    if (authUser == null) {
      throw StateError('Internal inconsistency. AuthUser missing for EmailAccount.');
    }

    if (authUser.blocked) {
      throw ArgumentError('Account \$email is blocked.');
    }

    // 3. Preserve transaction safety
    final scopes = authUser.scopeNames;
    final needsScopeUpdate = !scopes.contains('staff');
    if (needsScopeUpdate) {
      scopes.add('staff');
    }

    final userIdStr = authUser.id.toString();

    await session.db.transaction((transaction) async {
      if (needsScopeUpdate) {
        authUser.scopeNames = scopes;
        await AuthUser.db.updateRow(session, authUser, transaction: transaction);
      }

      final existingAccess = await StaffRoomAccess.db.findFirstRow(
        session,
        where: (s) => s.userId.equals(userIdStr) & s.roomId.equals(roomId),
        transaction: transaction,
      );

      if (existingAccess == null) {
        await StaffRoomAccess.db.insertRow(
          session,
          StaffRoomAccess(
            userId: userIdStr,
            roomId: roomId,
          ),
          transaction: transaction,
        );
      }
      
      if (testHook != null) {
        await testHook();
      }
    });
  }
}
