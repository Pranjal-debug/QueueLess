/* AUTOMATICALLY GENERATED CODE DO NOT MODIFY */
/*   To generate run: "serverpod generate"    */

// ignore_for_file: implementation_imports
// ignore_for_file: library_private_types_in_public_api
// ignore_for_file: non_constant_identifier_names
// ignore_for_file: public_member_api_docs
// ignore_for_file: type_literal_in_constant_pattern
// ignore_for_file: use_super_parameters
// ignore_for_file: invalid_use_of_internal_member

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'dart:async' as _ida;
import 'package:http/http.dart' as _i85jenna;
import 'package:queueless_client/src/protocol/greetings/greeting.dart'
    as _i9nnokya;
import 'package:queueless_client/src/protocol/queue/queue_event.dart'
    as _i900e7tr;
import 'package:queueless_client/src/protocol/queue/queue_room.dart'
    as _ircwtnoc;
import 'package:queueless_client/src/protocol/queue/queue_session.dart'
    as _im9s5reg;
import 'package:queueless_client/src/protocol/queue/queue_status.dart'
    as _i3ewmjui;
import 'package:queueless_client/src/protocol/queue/queue_ticket.dart'
    as _i3l0aei0;
import 'package:serverpod_auth_core_client/serverpod_auth_core_client.dart'
    as _iacc;
import 'package:serverpod_auth_idp_client/serverpod_auth_idp_client.dart'
    as _iaic;
import 'package:serverpod_client/serverpod_client.dart' as _isc;
import 'protocol.dart' as _il2as5qe;

/// By extending [EmailIdpBaseEndpoint], the email identity provider endpoints
/// are made available on the server and enable the corresponding sign-in widget
/// on the client.
/// {@category Endpoint}
class EndpointEmailIdp extends _iaic.EndpointEmailIdpBase {
  EndpointEmailIdp(_isc.EndpointCaller caller) : super(caller);

  @override
  String get name => 'emailIdp';

  /// Logs in the user and returns a new session.
  ///
  /// Throws an [EmailAccountLoginException] in case of errors, with reason:
  /// - [EmailAccountLoginExceptionReason.invalidCredentials] if the email or
  ///   password is incorrect.
  /// - [EmailAccountLoginExceptionReason.tooManyAttempts] if there have been
  ///   too many failed login attempts.
  ///
  /// Throws an [AuthUserBlockedException] if the auth user is blocked.
  @override
  _ida.Future<_iacc.AuthSuccess> login({
    required String email,
    required String password,
  }) => caller.callServerEndpoint<_iacc.AuthSuccess>(
    'emailIdp',
    'login',
    {
      'email': email,
      'password': password,
    },
  );

  /// Starts the registration for a new user account with an email-based login
  /// associated to it.
  ///
  /// Upon successful completion of this method, an email will have been
  /// sent to [email] with a verification link, which the user must open to
  /// complete the registration.
  ///
  /// Always returns a account request ID, which can be used to complete the
  /// registration. If the email is already registered, the returned ID will not
  /// be valid.
  @override
  _ida.Future<_isc.UuidValue> startRegistration({required String email}) =>
      caller.callServerEndpoint<_isc.UuidValue>(
        'emailIdp',
        'startRegistration',
        {'email': email},
      );

  /// Verifies an account request code and returns a token
  /// that can be used to complete the account creation.
  ///
  /// Throws an [EmailAccountRequestException] in case of errors, with reason:
  /// - [EmailAccountRequestExceptionReason.expired] if the account request has
  ///   already expired.
  /// - [EmailAccountRequestExceptionReason.policyViolation] if the password
  ///   does not comply with the password policy.
  /// - [EmailAccountRequestExceptionReason.invalid] if no request exists
  ///   for the given [accountRequestId] or [verificationCode] is invalid.
  @override
  _ida.Future<String> verifyRegistrationCode({
    required _isc.UuidValue accountRequestId,
    required String verificationCode,
  }) => caller.callServerEndpoint<String>(
    'emailIdp',
    'verifyRegistrationCode',
    {
      'accountRequestId': accountRequestId,
      'verificationCode': verificationCode,
    },
  );

  /// Completes a new account registration, creating a new auth user with a
  /// profile and attaching the given email account to it.
  ///
  /// Throws an [EmailAccountRequestException] in case of errors, with reason:
  /// - [EmailAccountRequestExceptionReason.expired] if the account request has
  ///   already expired.
  /// - [EmailAccountRequestExceptionReason.policyViolation] if the password
  ///   does not comply with the password policy.
  /// - [EmailAccountRequestExceptionReason.invalid] if the [registrationToken]
  ///   is invalid.
  ///
  /// Throws an [AuthUserBlockedException] if the auth user is blocked.
  ///
  /// Returns a session for the newly created user.
  @override
  _ida.Future<_iacc.AuthSuccess> finishRegistration({
    required String registrationToken,
    required String password,
  }) => caller.callServerEndpoint<_iacc.AuthSuccess>(
    'emailIdp',
    'finishRegistration',
    {
      'registrationToken': registrationToken,
      'password': password,
    },
  );

  /// Requests a password reset for [email].
  ///
  /// If the email address is registered, an email with reset instructions will
  /// be send out. If the email is unknown, this method will have no effect.
  ///
  /// Always returns a password reset request ID, which can be used to complete
  /// the reset. If the email is not registered, the returned ID will not be
  /// valid.
  ///
  /// Throws an [EmailAccountPasswordResetException] in case of errors, with reason:
  /// - [EmailAccountPasswordResetExceptionReason.tooManyAttempts] if the user has
  ///   made too many attempts trying to request a password reset.
  ///
  @override
  _ida.Future<_isc.UuidValue> startPasswordReset({required String email}) =>
      caller.callServerEndpoint<_isc.UuidValue>(
        'emailIdp',
        'startPasswordReset',
        {'email': email},
      );

  /// Verifies a password reset code and returns a finishPasswordResetToken
  /// that can be used to finish the password reset.
  ///
  /// Throws an [EmailAccountPasswordResetException] in case of errors, with reason:
  /// - [EmailAccountPasswordResetExceptionReason.expired] if the password reset
  ///   request has already expired.
  /// - [EmailAccountPasswordResetExceptionReason.tooManyAttempts] if the user has
  ///   made too many attempts trying to verify the password reset.
  /// - [EmailAccountPasswordResetExceptionReason.invalid] if no request exists
  ///   for the given [passwordResetRequestId] or [verificationCode] is invalid.
  ///
  /// If multiple steps are required to complete the password reset, this endpoint
  /// should be overridden to return credentials for the next step instead
  /// of the credentials for setting the password.
  @override
  _ida.Future<String> verifyPasswordResetCode({
    required _isc.UuidValue passwordResetRequestId,
    required String verificationCode,
  }) => caller.callServerEndpoint<String>(
    'emailIdp',
    'verifyPasswordResetCode',
    {
      'passwordResetRequestId': passwordResetRequestId,
      'verificationCode': verificationCode,
    },
  );

  /// Completes a password reset request by setting a new password.
  ///
  /// The [verificationCode] returned from [verifyPasswordResetCode] is used to
  /// validate the password reset request.
  ///
  /// Throws an [EmailAccountPasswordResetException] in case of errors, with reason:
  /// - [EmailAccountPasswordResetExceptionReason.expired] if the password reset
  ///   request has already expired.
  /// - [EmailAccountPasswordResetExceptionReason.policyViolation] if the new
  ///   password does not comply with the password policy.
  /// - [EmailAccountPasswordResetExceptionReason.invalid] if no request exists
  ///   for the given [passwordResetRequestId] or [verificationCode] is invalid.
  ///
  /// Throws an [AuthUserBlockedException] if the auth user is blocked.
  @override
  _ida.Future<void> finishPasswordReset({
    required String finishPasswordResetToken,
    required String newPassword,
  }) => caller.callServerEndpoint<void>(
    'emailIdp',
    'finishPasswordReset',
    {
      'finishPasswordResetToken': finishPasswordResetToken,
      'newPassword': newPassword,
    },
  );

  @override
  _ida.Future<bool> hasAccount() => caller.callServerEndpoint<bool>(
    'emailIdp',
    'hasAccount',
    {},
  );
}

/// By extending [RefreshJwtTokensEndpoint], the JWT token refresh endpoint
/// is made available on the server and enables automatic token refresh on the client.
/// {@category Endpoint}
class EndpointJwtRefresh extends _iacc.EndpointRefreshJwtTokens {
  EndpointJwtRefresh(_isc.EndpointCaller caller) : super(caller);

  @override
  String get name => 'jwtRefresh';

  /// Creates a new token pair for the given [refreshToken].
  ///
  /// If [refreshToken] is omitted, cookie-mode web clients fall back to the
  /// configured HttpOnly refresh cookie. When neither source is present this
  /// throws [RefreshTokenNotFoundException], the same public "no usable refresh
  /// credential" exception used for unknown refresh tokens.
  ///
  /// Can throw the following exceptions:
  /// -[RefreshTokenMalformedException]: refresh token is malformed and could
  ///   not be parsed. Not expected to happen for tokens issued by the server.
  /// -[RefreshTokenNotFoundException]: refresh token is unknown to the server.
  ///   Either the token was deleted or generated by a different server.
  /// -[RefreshTokenExpiredException]: refresh token has expired. Will happen
  ///   only if it has not been used within configured `refreshTokenLifetime`.
  /// -[RefreshTokenInvalidSecretException]: refresh token is incorrect, meaning
  ///   it does not refer to the current secret refresh token. This indicates
  ///   either a malfunctioning client or a malicious attempt by someone who has
  ///   obtained the refresh token. In this case the underlying refresh token
  ///   will be deleted, and access to it will expire fully when the last access
  ///   token is elapsed.
  ///
  /// This endpoint is unauthenticated, meaning the client won't include any
  /// authentication information with the call.
  @override
  _ida.Future<_iacc.AuthSuccess> refreshAccessToken({String? refreshToken}) =>
      caller.callServerEndpoint<_iacc.AuthSuccess>(
        'jwtRefresh',
        'refreshAccessToken',
        {'refreshToken': refreshToken},
        authenticated: false,
      );
}

/// This is an example endpoint that returns a greeting message through
/// its [hello] method.
/// {@category Endpoint}
class EndpointGreeting extends _isc.EndpointRef {
  EndpointGreeting(_isc.EndpointCaller caller) : super(caller);

  @override
  String get name => 'greeting';

  /// Returns a personalized greeting message: "Hello {name}".
  _ida.Future<_i9nnokya.Greeting> hello(String name) =>
      caller.callServerEndpoint<_i9nnokya.Greeting>(
        'greeting',
        'hello',
        {'name': name},
      );
}

/// {@category Endpoint}
class EndpointQueue extends _isc.EndpointRef {
  EndpointQueue(_isc.EndpointCaller caller) : super(caller);

  @override
  String get name => 'queue';

  /// Separate, idempotent, concurrency-safe role bootstrap for authenticated accounts
  /// that are missing the staff scope.
  _ida.Future<bool> bootstrapStaffRole() => caller.callServerEndpoint<bool>(
    'queue',
    'bootstrapStaffRole',
    {},
  );

  /// List all active, non-deleted queue rooms.
  _ida.Future<List<_ircwtnoc.QueueRoom>> listRooms() =>
      caller.callServerEndpoint<List<_ircwtnoc.QueueRoom>>(
        'queue',
        'listRooms',
        {},
      );

  /// Create a room for an authenticated staff member and grant that member
  /// access in the same transaction as the room insert.
  _ida.Future<_ircwtnoc.QueueRoom> createRoom(String roomName) =>
      caller.callServerEndpoint<_ircwtnoc.QueueRoom>(
        'queue',
        'createRoom',
        {'roomName': roomName},
      );

  /// List active rooms the signed-in staff is authorized to access.
  _ida.Future<List<_ircwtnoc.QueueRoom>> listAuthorizedRooms() =>
      caller.callServerEndpoint<List<_ircwtnoc.QueueRoom>>(
        'queue',
        'listAuthorizedRooms',
        {},
      );

  /// Get the current active session for [roomId], triggering rollover if date changed.
  _ida.Future<_im9s5reg.QueueSession> getActiveSession(
    int roomId, {
    DateTime? referenceTime,
  }) => caller.callServerEndpoint<_im9s5reg.QueueSession>(
    'queue',
    'getActiveSession',
    {
      'roomId': roomId,
      'referenceTime': referenceTime,
    },
  );

  /// Restart the queue session for the specified room.
  /// Closes the existing active session and its waiting/serving tickets (cancelled),
  /// and atomically creates a new active session with ticket numbering starting at #1.
  _ida.Future<_im9s5reg.QueueSession> restartQueue(int roomId) =>
      caller.callServerEndpoint<_im9s5reg.QueueSession>(
        'queue',
        'restartQueue',
        {'roomId': roomId},
      );

  /// Safely soft-deletes a room.
  /// Requires staff authorization. Closes the active session, cancels any active tickets,
  /// and sets deletedAt timestamp. Historical tickets and room data are preserved.
  _ida.Future<bool> deleteRoom(int roomId) => caller.callServerEndpoint<bool>(
    'queue',
    'deleteRoom',
    {'roomId': roomId},
  );

  /// Join the queue. Returns the created ticket and its position.
  _ida.Future<_i3ewmjui.QueueStatus> joinQueue(
    String customerName, {
    int? roomId,
  }) => caller.callServerEndpoint<_i3ewmjui.QueueStatus>(
    'queue',
    'joinQueue',
    {
      'customerName': customerName,
      'roomId': roomId,
    },
  );

  /// Get the status of a specific ticket.
  _ida.Future<_i3ewmjui.QueueStatus?> getTicketStatus(
    int ticketId,
    String accessCode,
  ) => caller.callServerEndpoint<_i3ewmjui.QueueStatus?>(
    'queue',
    'getTicketStatus',
    {
      'ticketId': ticketId,
      'accessCode': accessCode,
    },
  );

  /// Cancel a customer's waiting ticket.
  _ida.Future<_i3ewmjui.QueueStatus> cancelTicket(
    int ticketId,
    String accessCode,
  ) => caller.callServerEndpoint<_i3ewmjui.QueueStatus>(
    'queue',
    'cancelTicket',
    {
      'ticketId': ticketId,
      'accessCode': accessCode,
    },
  );

  /// Returns currently waiting and serving tickets for the current session ordered by ticket number.
  _ida.Future<List<_i3l0aei0.QueueTicket>> getActiveQueue({int? roomId}) =>
      caller.callServerEndpoint<List<_i3l0aei0.QueueTicket>>(
        'queue',
        'getActiveQueue',
        {'roomId': roomId},
      );

  /// Call the next waiting customer in the active session.
  _ida.Future<_i3l0aei0.QueueTicket?> callNext({int? roomId}) =>
      caller.callServerEndpoint<_i3l0aei0.QueueTicket?>(
        'queue',
        'callNext',
        {'roomId': roomId},
      );

  /// Complete a ticket that is currently being served.
  _ida.Future<bool> completeTicket(int ticketId) =>
      caller.callServerEndpoint<bool>(
        'queue',
        'completeTicket',
        {'ticketId': ticketId},
      );

  /// Subscribe to real-time events for a specific room as a customer.
  _ida.Stream<_i900e7tr.QueueEvent> subscribeToRoomCustomer(
    int ticketId,
    String accessCode,
  ) =>
      caller.callStreamingServerEndpoint<
        _ida.Stream<_i900e7tr.QueueEvent>,
        _i900e7tr.QueueEvent
      >(
        'queue',
        'subscribeToRoomCustomer',
        {
          'ticketId': ticketId,
          'accessCode': accessCode,
        },
        {},
      );

  /// Subscribe to real-time events for a specific room as staff.
  _ida.Stream<_i900e7tr.QueueEvent> subscribeToRoomStaff({int? roomId}) =>
      caller.callStreamingServerEndpoint<
        _ida.Stream<_i900e7tr.QueueEvent>,
        _i900e7tr.QueueEvent
      >(
        'queue',
        'subscribeToRoomStaff',
        {'roomId': roomId},
        {},
      );

  /// Subscribe to public room list changes (e.g., room created or deleted).
  _ida.Stream<_i900e7tr.QueueEvent> subscribeToRooms() =>
      caller.callStreamingServerEndpoint<
        _ida.Stream<_i900e7tr.QueueEvent>,
        _i900e7tr.QueueEvent
      >(
        'queue',
        'subscribeToRooms',
        {},
        {},
      );
}

class Modules {
  Modules(Client client) {
    serverpod_auth_idp = _iaic.Caller(client);
    serverpod_auth_core = _iacc.Caller(client);
  }

  late final _iaic.Caller serverpod_auth_idp;

  late final _iacc.Caller serverpod_auth_core;
}

class Client extends _isc.ServerpodClientShared {
  Client(
    String host, {
    dynamic securityContext,
    Duration? streamingConnectionTimeout,
    Duration? connectionTimeout,
    Function(
      _isc.MethodCallContext,
      Object,
      StackTrace,
    )?
    onFailedCall,
    Function(_isc.MethodCallContext)? onSucceededCall,
    bool? disconnectStreamsOnLostInternetConnection,
    _i85jenna.Client? httpClientOverride,
  }) : super(
         host,
         _il2as5qe.Protocol(),
         securityContext: securityContext,
         streamingConnectionTimeout: streamingConnectionTimeout,
         connectionTimeout: connectionTimeout,
         onFailedCall: onFailedCall,
         onSucceededCall: onSucceededCall,
         disconnectStreamsOnLostInternetConnection:
             disconnectStreamsOnLostInternetConnection,
         httpClientOverride: httpClientOverride,
       ) {
    emailIdp = EndpointEmailIdp(this);
    jwtRefresh = EndpointJwtRefresh(this);
    greeting = EndpointGreeting(this);
    queue = EndpointQueue(this);
    modules = Modules(this);
  }

  late final EndpointEmailIdp emailIdp;

  late final EndpointJwtRefresh jwtRefresh;

  late final EndpointGreeting greeting;

  late final EndpointQueue queue;

  late final Modules modules;

  @override
  Map<String, _isc.EndpointRef> get endpointRefLookup => {
    'emailIdp': emailIdp,
    'jwtRefresh': jwtRefresh,
    'greeting': greeting,
    'queue': queue,
  };

  @override
  Map<String, _isc.ModuleEndpointCaller> get moduleLookup => {
    'serverpod_auth_idp': modules.serverpod_auth_idp,
    'serverpod_auth_core': modules.serverpod_auth_core,
  };
}
