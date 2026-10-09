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

abstract class QueueTicket
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  QueueTicket._({
    this.id,
    required this.customerName,
    required this.ticketNumber,
    required this.status,
    required this.createdAt,
    this.calledAt,
    this.completedAt,
  });

  factory QueueTicket({
    int? id,
    required String customerName,
    required int ticketNumber,
    required String status,
    required DateTime createdAt,
    DateTime? calledAt,
    DateTime? completedAt,
  }) = _QueueTicketImpl;

  factory QueueTicket.fromJson(Map<String, dynamic> jsonSerialization) {
    return QueueTicket(
      id: jsonSerialization['id'] as int?,
      customerName: jsonSerialization['customerName'] as String,
      ticketNumber: jsonSerialization['ticketNumber'] as int,
      status: jsonSerialization['status'] as String,
      createdAt: _isc.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
      calledAt: jsonSerialization['calledAt'] == null
          ? null
          : _isc.DateTimeJsonExtension.fromJson(jsonSerialization['calledAt']),
      completedAt: jsonSerialization['completedAt'] == null
          ? null
          : _isc.DateTimeJsonExtension.fromJson(
              jsonSerialization['completedAt'],
            ),
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  String customerName;

  int ticketNumber;

  String status;

  DateTime createdAt;

  DateTime? calledAt;

  DateTime? completedAt;

  /// Returns a shallow copy of this [QueueTicket]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  QueueTicket copyWith({
    int? id,
    String? customerName,
    int? ticketNumber,
    String? status,
    DateTime? createdAt,
    DateTime? calledAt,
    DateTime? completedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'QueueTicket',
      if (id != null) 'id': id,
      'customerName': customerName,
      'ticketNumber': ticketNumber,
      'status': status,
      'createdAt': createdAt.toJson(),
      if (calledAt != null) 'calledAt': calledAt?.toJson(),
      if (completedAt != null) 'completedAt': completedAt?.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'QueueTicket',
      if (id != null) 'id': id,
      'customerName': customerName,
      'ticketNumber': ticketNumber,
      'status': status,
      'createdAt': createdAt.toJson(),
      if (calledAt != null) 'calledAt': calledAt?.toJson(),
      if (completedAt != null) 'completedAt': completedAt?.toJson(),
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _QueueTicketImpl extends QueueTicket {
  _QueueTicketImpl({
    int? id,
    required String customerName,
    required int ticketNumber,
    required String status,
    required DateTime createdAt,
    DateTime? calledAt,
    DateTime? completedAt,
  }) : super._(
         id: id,
         customerName: customerName,
         ticketNumber: ticketNumber,
         status: status,
         createdAt: createdAt,
         calledAt: calledAt,
         completedAt: completedAt,
       );

  /// Returns a shallow copy of this [QueueTicket]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  QueueTicket copyWith({
    Object? id = _Undefined,
    String? customerName,
    int? ticketNumber,
    String? status,
    DateTime? createdAt,
    Object? calledAt = _Undefined,
    Object? completedAt = _Undefined,
  }) {
    return QueueTicket(
      id: id is int? ? id : this.id,
      customerName: customerName ?? this.customerName,
      ticketNumber: ticketNumber ?? this.ticketNumber,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      calledAt: calledAt is DateTime? ? calledAt : this.calledAt,
      completedAt: completedAt is DateTime? ? completedAt : this.completedAt,
    );
  }
}
