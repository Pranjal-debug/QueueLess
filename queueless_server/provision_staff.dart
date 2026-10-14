import 'dart:io';
import 'package:queueless_server/src/generated/serverpod.dart';
import 'package:queueless_server/src/business/staff_provisioning.dart';

void main(List<String> args) async {
  if (args.length != 2) {
    print('Usage: dart run provision_staff.dart <email> <roomId>');
    exit(1);
  }

  final email = args[0].trim();
  final roomIdStr = args[1].trim();
  final roomId = int.tryParse(roomIdStr);
  
  if (roomId == null) {
    print('Error: Room ID must be an integer.');
    exit(1);
  }

  final pod = Serverpod(['--mode', 'development']);
  
  // 1. Harden environment checks
  if (pod.runMode != 'development') {
    print('Error: Provisioning script must run in development mode.');
    exit(1);
  }
  
  final dbHost = pod.config.database?.host;
  final dbPort = pod.config.database?.port;
  final dbName = pod.config.database?.name;
  
  if (dbHost != 'localhost' && dbHost != '127.0.0.1') {
    print('Error: Host must be localhost for local provisioning (found \$dbHost).');
    exit(1);
  }
  if (dbPort != 8090) {
    print('Error: Expected local database port 8090 (found \$dbPort).');
    exit(1);
  }
  if (dbName != 'queueless') {
    print('Error: Expected local database name queueless (found \$dbName).');
    exit(1);
  }

  print('Creating session...');
  final session = await pod.createSession(enableLogging: false);
  print('Session created.');

  try {
    print('Starting StaffProvisioning.provision...');
    await StaffProvisioning.provision(session, email, roomId);
    print('Provisioning complete.');

    print('Successfully provisioned $email for Room $roomId.');
    print('NOTE: The user MUST sign out and sign back in to receive a new authentication token with the updated scopes.');
  } on ArgumentError catch (e) {
    print('Provisioning Error: ${e.message}');
    exit(1);
  } on StateError catch (e) {
    print('Provisioning Error: ${e.message}');
    exit(1);
  } catch (e) {
    print('Provisioning failed: $e');
    exit(1);
  } finally {
    print('Closing session...');
    await session.close();
    print('Session closed.');
  }

  exit(0);
}
