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
import 'package:serverpod_client/serverpod_client.dart' as _isc;

abstract class QueueSession
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  QueueSession._({
    this.id,
    required this.roomId,
    required this.businessDate,
    required this.sessionNumber,
    required this.status,
    required this.startedAt,
    this.closedAt,
  });

  factory QueueSession({
    int? id,
    required int roomId,
    required String businessDate,
    required int sessionNumber,
    required String status,
    required DateTime startedAt,
    DateTime? closedAt,
  }) = _QueueSessionImpl;

  factory QueueSession.fromJson(Map<String, dynamic> jsonSerialization) {
    return QueueSession(
      id: jsonSerialization['id'] as int?,
      roomId: jsonSerialization['roomId'] as int,
      businessDate: jsonSerialization['businessDate'] as String,
      sessionNumber: jsonSerialization['sessionNumber'] as int,
      status: jsonSerialization['status'] as String,
      startedAt: _isc.DateTimeJsonExtension.fromJson(
        jsonSerialization['startedAt'],
      ),
      closedAt: jsonSerialization['closedAt'] == null
          ? null
          : _isc.DateTimeJsonExtension.fromJson(jsonSerialization['closedAt']),
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  int roomId;

  String businessDate;

  int sessionNumber;

  String status;

  DateTime startedAt;

  DateTime? closedAt;

  /// Returns a shallow copy of this [QueueSession]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  QueueSession copyWith({
    int? id,
    int? roomId,
    String? businessDate,
    int? sessionNumber,
    String? status,
    DateTime? startedAt,
    DateTime? closedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'QueueSession',
      if (id != null) 'id': id,
      'roomId': roomId,
      'businessDate': businessDate,
      'sessionNumber': sessionNumber,
      'status': status,
      'startedAt': startedAt.toJson(),
      if (closedAt != null) 'closedAt': closedAt?.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'QueueSession',
      if (id != null) 'id': id,
      'roomId': roomId,
      'businessDate': businessDate,
      'sessionNumber': sessionNumber,
      'status': status,
      'startedAt': startedAt.toJson(),
      if (closedAt != null) 'closedAt': closedAt?.toJson(),
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _QueueSessionImpl extends QueueSession {
  _QueueSessionImpl({
    int? id,
    required int roomId,
    required String businessDate,
    required int sessionNumber,
    required String status,
    required DateTime startedAt,
    DateTime? closedAt,
  }) : super._(
         id: id,
         roomId: roomId,
         businessDate: businessDate,
         sessionNumber: sessionNumber,
         status: status,
         startedAt: startedAt,
         closedAt: closedAt,
       );

  /// Returns a shallow copy of this [QueueSession]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  QueueSession copyWith({
    Object? id = _Undefined,
    int? roomId,
    String? businessDate,
    int? sessionNumber,
    String? status,
    DateTime? startedAt,
    Object? closedAt = _Undefined,
  }) {
    return QueueSession(
      id: id is int? ? id : this.id,
      roomId: roomId ?? this.roomId,
      businessDate: businessDate ?? this.businessDate,
      sessionNumber: sessionNumber ?? this.sessionNumber,
      status: status ?? this.status,
      startedAt: startedAt ?? this.startedAt,
      closedAt: closedAt is DateTime? ? closedAt : this.closedAt,
    );
  }
}
