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
import 'package:queueless_client/src/protocol/protocol.dart' as _ilk7xq1b;
import 'package:serverpod_client/serverpod_client.dart' as _isc;
import '../queue/queue_ticket.dart' as _i8nm8tqe;

abstract class QueueStatus
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  QueueStatus._({
    required this.ticket,
    required this.position,
    required this.totalWaiting,
    required this.estimatedWaitSeconds,
  });

  factory QueueStatus({
    required _i8nm8tqe.QueueTicket ticket,
    required int position,
    required int totalWaiting,
    required int estimatedWaitSeconds,
  }) = _QueueStatusImpl;

  factory QueueStatus.fromJson(Map<String, dynamic> jsonSerialization) {
    return QueueStatus(
      ticket: _ilk7xq1b.Protocol().deserialize<_i8nm8tqe.QueueTicket>(
        jsonSerialization['ticket'],
      ),
      position: jsonSerialization['position'] as int,
      totalWaiting: jsonSerialization['totalWaiting'] as int,
      estimatedWaitSeconds: jsonSerialization['estimatedWaitSeconds'] as int,
    );
  }

  _i8nm8tqe.QueueTicket ticket;

  int position;

  int totalWaiting;

  int estimatedWaitSeconds;

  /// Returns a shallow copy of this [QueueStatus]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  QueueStatus copyWith({
    _i8nm8tqe.QueueTicket? ticket,
    int? position,
    int? totalWaiting,
    int? estimatedWaitSeconds,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'QueueStatus',
      'ticket': ticket.toJson(),
      'position': position,
      'totalWaiting': totalWaiting,
      'estimatedWaitSeconds': estimatedWaitSeconds,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'QueueStatus',
      'ticket': ticket.toJsonForProtocol(),
      'position': position,
      'totalWaiting': totalWaiting,
      'estimatedWaitSeconds': estimatedWaitSeconds,
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _QueueStatusImpl extends QueueStatus {
  _QueueStatusImpl({
    required _i8nm8tqe.QueueTicket ticket,
    required int position,
    required int totalWaiting,
    required int estimatedWaitSeconds,
  }) : super._(
         ticket: ticket,
         position: position,
         totalWaiting: totalWaiting,
         estimatedWaitSeconds: estimatedWaitSeconds,
       );

  /// Returns a shallow copy of this [QueueStatus]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  QueueStatus copyWith({
    _i8nm8tqe.QueueTicket? ticket,
    int? position,
    int? totalWaiting,
    int? estimatedWaitSeconds,
  }) {
    return QueueStatus(
      ticket: ticket ?? this.ticket.copyWith(),
      position: position ?? this.position,
      totalWaiting: totalWaiting ?? this.totalWaiting,
      estimatedWaitSeconds: estimatedWaitSeconds ?? this.estimatedWaitSeconds,
    );
  }
}
