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

abstract class QueueRoom
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  QueueRoom._({
    this.id,
    required this.name,
    required this.createdAt,
    this.deletedAt,
  });

  factory QueueRoom({
    int? id,
    required String name,
    required DateTime createdAt,
    DateTime? deletedAt,
  }) = _QueueRoomImpl;

  factory QueueRoom.fromJson(Map<String, dynamic> jsonSerialization) {
    return QueueRoom(
      id: jsonSerialization['id'] as int?,
      name: jsonSerialization['name'] as String,
      createdAt: _isc.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
      deletedAt: jsonSerialization['deletedAt'] == null
          ? null
          : _isc.DateTimeJsonExtension.fromJson(jsonSerialization['deletedAt']),
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  String name;

  DateTime createdAt;

  DateTime? deletedAt;

  /// Returns a shallow copy of this [QueueRoom]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  QueueRoom copyWith({
    int? id,
    String? name,
    DateTime? createdAt,
    DateTime? deletedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'QueueRoom',
      if (id != null) 'id': id,
      'name': name,
      'createdAt': createdAt.toJson(),
      if (deletedAt != null) 'deletedAt': deletedAt?.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'QueueRoom',
      if (id != null) 'id': id,
      'name': name,
      'createdAt': createdAt.toJson(),
      if (deletedAt != null) 'deletedAt': deletedAt?.toJson(),
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _QueueRoomImpl extends QueueRoom {
  _QueueRoomImpl({
    int? id,
    required String name,
    required DateTime createdAt,
    DateTime? deletedAt,
  }) : super._(
         id: id,
         name: name,
         createdAt: createdAt,
         deletedAt: deletedAt,
       );

  /// Returns a shallow copy of this [QueueRoom]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  QueueRoom copyWith({
    Object? id = _Undefined,
    String? name,
    DateTime? createdAt,
    Object? deletedAt = _Undefined,
  }) {
    return QueueRoom(
      id: id is int? ? id : this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      deletedAt: deletedAt is DateTime? ? deletedAt : this.deletedAt,
    );
  }
}
