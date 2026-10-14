# QueueLess — Safe Staff Provisioning Guide

This guide explains how to provision a registered customer account as a staff member with access to a specific queue room.

## Prerequisites
- The target user MUST have already registered an account using the Flutter app.
- The queue room MUST already exist in the database.
- You must run this command in the `queueless_server` directory.

## Provisioning Script
A local provisioning script `provision_staff.dart` has been created. It performs the following actions:
1. Validates the existence of the `QueueRoom`.
2. Locates the `AuthUser` associated with the registered email.
3. Adds the `staff` scope to the user's `scopeNames`.
4. Creates a `StaffRoomAccess` record linking the user's ID to the specified room.
5. Executes the update in a transaction to ensure data integrity.

## Usage
Run the script using the Dart CLI:

```bash
dart run provision_staff.dart <user_email> <room_id>
```

**Example:**
```bash
dart run provision_staff.dart pranjal@example.com 1
```

## Security Considerations
- **Local Execution Only:** This script enforces execution in the development mode (`--mode development`) and performs strict validation on the local config (`host: localhost`, `port: 8090`, `name: queueless`) before running.
- **Identity Trust:** The user identity is resolved natively using Serverpod's `EmailAccount` database table. It does not trust any client-provided user IDs.
- **Role Isolation:** Staff access is bound strictly to the `QueueRoom` ID provided.
- **Idempotency & Scope Preservation:** Running the tool multiple times will not duplicate staff scopes, and existing unrelated scopes are safely preserved.

## Session Updates
NOTE: Serverpod authentication sessions cache their scope information. After provisioning, the user **MUST** sign out of the Flutter client and sign back in to receive a new JSON Web Token (JWT) bearing the updated `staff` scope.
