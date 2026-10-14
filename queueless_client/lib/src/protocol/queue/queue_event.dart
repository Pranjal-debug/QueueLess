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

abstract class QueueEvent
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  QueueEvent._({
    required this.roomId,
    required this.action,
  });

  factory QueueEvent({
    required int roomId,
    required String action,
  }) = _QueueEventImpl;

  factory QueueEvent.fromJson(Map<String, dynamic> jsonSerialization) {
    return QueueEvent(
      roomId: jsonSerialization['roomId'] as int,
      action: jsonSerialization['action'] as String,
    );
  }

  int roomId;

  String action;

  /// Returns a shallow copy of this [QueueEvent]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  QueueEvent copyWith({
    int? roomId,
    String? action,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'QueueEvent',
      'roomId': roomId,
      'action': action,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'QueueEvent',
      'roomId': roomId,
      'action': action,
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _QueueEventImpl extends QueueEvent {
  _QueueEventImpl({
    required int roomId,
    required String action,
  }) : super._(
         roomId: roomId,
         action: action,
       );

  /// Returns a shallow copy of this [QueueEvent]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  QueueEvent copyWith({
    int? roomId,
    String? action,
  }) {
    return QueueEvent(
      roomId: roomId ?? this.roomId,
      action: action ?? this.action,
    );
  }
}
