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

abstract class StaffRoomAccess
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  StaffRoomAccess._({
    this.id,
    required this.userId,
    required this.roomId,
  });

  factory StaffRoomAccess({
    int? id,
    required String userId,
    required int roomId,
  }) = _StaffRoomAccessImpl;

  factory StaffRoomAccess.fromJson(Map<String, dynamic> jsonSerialization) {
    return StaffRoomAccess(
      id: jsonSerialization['id'] as int?,
      userId: jsonSerialization['userId'] as String,
      roomId: jsonSerialization['roomId'] as int,
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  String userId;

  int roomId;

  /// Returns a shallow copy of this [StaffRoomAccess]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  StaffRoomAccess copyWith({
    int? id,
    String? userId,
    int? roomId,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'StaffRoomAccess',
      if (id != null) 'id': id,
      'userId': userId,
      'roomId': roomId,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'StaffRoomAccess',
      if (id != null) 'id': id,
      'userId': userId,
      'roomId': roomId,
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _StaffRoomAccessImpl extends StaffRoomAccess {
  _StaffRoomAccessImpl({
    int? id,
    required String userId,
    required int roomId,
  }) : super._(
         id: id,
         userId: userId,
         roomId: roomId,
       );

  /// Returns a shallow copy of this [StaffRoomAccess]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  StaffRoomAccess copyWith({
    Object? id = _Undefined,
    String? userId,
    int? roomId,
  }) {
    return StaffRoomAccess(
      id: id is int? ? id : this.id,
      userId: userId ?? this.userId,
      roomId: roomId ?? this.roomId,
    );
  }
}
