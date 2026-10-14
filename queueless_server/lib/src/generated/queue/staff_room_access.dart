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
import 'package:serverpod/serverpod.dart' as _is;

abstract class StaffRoomAccess
    implements _is.TableRow<int?>, _is.ProtocolSerialization {
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

  static final t = StaffRoomAccessTable();

  static const db = StaffRoomAccessRepository._();

  @override
  int? id;

  String userId;

  int roomId;

  @override
  _is.Table<int?> get table => t;

  /// Returns a shallow copy of this [StaffRoomAccess]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
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

  static StaffRoomAccessInclude include() {
    return StaffRoomAccessInclude._();
  }

  static StaffRoomAccessIncludeList includeList({
    _is.WhereExpressionBuilder<StaffRoomAccessTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<StaffRoomAccessTable>? orderBy,
    _is.OrderByListBuilder<StaffRoomAccessTable>? orderByList,
    StaffRoomAccessInclude? include,
  }) {
    return StaffRoomAccessIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(StaffRoomAccess.t),
      orderByList: orderByList?.call(StaffRoomAccess.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
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
  @_is.useResult
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

class StaffRoomAccessUpdateTable extends _is.UpdateTable<StaffRoomAccessTable> {
  StaffRoomAccessUpdateTable(super.table);

  _is.ColumnValue<String, String> userId(String value) => _is.ColumnValue(
    table.userId,
    value,
  );

  _is.ColumnValue<int, int> roomId(int value) => _is.ColumnValue(
    table.roomId,
    value,
  );
}

class StaffRoomAccessTable extends _is.Table<int?> {
  StaffRoomAccessTable({super.tableRelation})
    : super(tableName: 'staff_room_access') {
    updateTable = StaffRoomAccessUpdateTable(this);
    userId = _is.ColumnString(
      'userId',
      this,
    );
    roomId = _is.ColumnInt(
      'roomId',
      this,
    );
  }

  late final StaffRoomAccessUpdateTable updateTable;

  late final _is.ColumnString userId;

  late final _is.ColumnInt roomId;

  @override
  List<_is.Column> get columns => [
    id,
    userId,
    roomId,
  ];
}

class StaffRoomAccessInclude extends _is.IncludeObject {
  StaffRoomAccessInclude._();

  @override
  Map<String, _is.Include?> get includes => {};

  @override
  _is.Table<int?> get table => StaffRoomAccess.t;
}

class StaffRoomAccessIncludeList extends _is.IncludeList {
  StaffRoomAccessIncludeList._({
    _is.WhereExpressionBuilder<StaffRoomAccessTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(StaffRoomAccess.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<int?> get table => StaffRoomAccess.t;
}

class StaffRoomAccessRepository {
  const StaffRoomAccessRepository._();

  /// Returns a list of [StaffRoomAccess]s matching the given query parameters.
  ///
  /// Use [where] to specify which items to include in the return value.
  /// If none is specified, all items will be returned.
  ///
  /// To specify the order of the items use [orderBy] or [orderByList]
  /// when sorting by multiple columns.
  ///
  /// The maximum number of items can be set by [limit]. If no limit is set,
  /// all items matching the query will be returned.
  ///
  /// [offset] defines how many items to skip, after which [limit] (or all)
  /// items are read from the database.
  ///
  /// ```dart
  /// var persons = await Persons.db.find(
  ///   session,
  ///   where: (t) => t.lastName.equals('Jones'),
  ///   orderBy: (t) => t.firstName,
  ///   limit: 100,
  /// );
  /// ```
  Future<List<StaffRoomAccess>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<StaffRoomAccessTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<StaffRoomAccessTable>? orderBy,
    _is.OrderByListBuilder<StaffRoomAccessTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<StaffRoomAccess>(
      where: where?.call(StaffRoomAccess.t),
      orderBy: orderBy?.call(StaffRoomAccess.t),
      orderByList: orderByList?.call(StaffRoomAccess.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [StaffRoomAccess] matching the given query parameters.
  ///
  /// Use [where] to specify which items to include in the return value.
  /// If none is specified, all items will be returned.
  ///
  /// To specify the order use [orderBy] or [orderByList]
  /// when sorting by multiple columns.
  ///
  /// [offset] defines how many items to skip, after which the next one will be picked.
  ///
  /// ```dart
  /// var youngestPerson = await Persons.db.findFirstRow(
  ///   session,
  ///   where: (t) => t.lastName.equals('Jones'),
  ///   orderBy: (t) => t.age,
  /// );
  /// ```
  Future<StaffRoomAccess?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<StaffRoomAccessTable>? where,
    int? offset,
    _is.OrderByBuilder<StaffRoomAccessTable>? orderBy,
    _is.OrderByListBuilder<StaffRoomAccessTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<StaffRoomAccess>(
      where: where?.call(StaffRoomAccess.t),
      orderBy: orderBy?.call(StaffRoomAccess.t),
      orderByList: orderByList?.call(StaffRoomAccess.t),
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [StaffRoomAccess] by its [id] or null if no such row exists.
  Future<StaffRoomAccess?> findById(
    _is.DatabaseSession session,
    int id, {
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<StaffRoomAccess>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [StaffRoomAccess]s in the list and returns the inserted rows.
  ///
  /// The returned [StaffRoomAccess]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// insert, none of the rows will be inserted.
  ///
  /// If [ignoreConflicts] is set to `true`, rows that conflict with existing
  /// rows are silently skipped, and only the successfully inserted rows are
  /// returned.
  ///
  /// If [noReturn] is set to `true`, the inserted rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<StaffRoomAccess>> insert(
    _is.DatabaseSession session,
    List<StaffRoomAccess> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<StaffRoomAccess>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [StaffRoomAccess] and returns the inserted row.
  ///
  /// The returned [StaffRoomAccess] will have its `id` field set.
  Future<StaffRoomAccess> insertRow(
    _is.DatabaseSession session,
    StaffRoomAccess row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<StaffRoomAccess>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [StaffRoomAccess]s in the list and returns the resulting rows.
  ///
  /// If a row conflicts on the given [conflictColumns], the existing row is
  /// updated with the new values. Otherwise, a new row is inserted.
  ///
  /// If [updateColumns] is provided, only those columns will be updated on
  /// conflict. If null, all non-conflict, non-id columns are updated.
  ///
  /// If [updateWhere] is provided, the update only applies to rows matching the
  /// given expression. Conflicting rows that don't match are skipped and not
  /// returned, so the resulting list may be shorter than [rows].
  ///
  /// The returned [StaffRoomAccess]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<StaffRoomAccess>> upsert(
    _is.DatabaseSession session,
    List<StaffRoomAccess> rows, {
    required _is.ColumnSelections<StaffRoomAccessTable> conflictColumns,
    _is.ColumnSelections<StaffRoomAccessTable>? updateColumns,
    _is.WhereExpressionBuilder<StaffRoomAccessTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<StaffRoomAccess>(
      rows,
      conflictColumns: conflictColumns(StaffRoomAccess.t),
      updateColumns: updateColumns?.call(StaffRoomAccess.t),
      updateWhere: updateWhere?.call(StaffRoomAccess.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [StaffRoomAccess] and returns the resulting row.
  ///
  /// If the row conflicts on the given [conflictColumns], the existing row is
  /// updated. Otherwise, a new row is inserted.
  ///
  /// If [updateColumns] is provided, only those columns will be updated on
  /// conflict. If null, all non-conflict, non-id columns are updated.
  ///
  /// If [updateWhere] is provided, the update only applies when the existing
  /// row matches the expression. Returns `null` if no row was affected — for
  /// example when [updateWhere] does not match the conflicting row.
  ///
  /// The returned [StaffRoomAccess] will have its `id` field set.
  Future<StaffRoomAccess?> upsertRow(
    _is.DatabaseSession session,
    StaffRoomAccess row, {
    required _is.ColumnSelections<StaffRoomAccessTable> conflictColumns,
    _is.ColumnSelections<StaffRoomAccessTable>? updateColumns,
    _is.WhereExpressionBuilder<StaffRoomAccessTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<StaffRoomAccess>(
      row,
      conflictColumns: conflictColumns(StaffRoomAccess.t),
      updateColumns: updateColumns?.call(StaffRoomAccess.t),
      updateWhere: updateWhere?.call(StaffRoomAccess.t),
      transaction: transaction,
    );
  }

  /// Updates all [StaffRoomAccess]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<StaffRoomAccess>> update(
    _is.DatabaseSession session,
    List<StaffRoomAccess> rows, {
    _is.ColumnSelections<StaffRoomAccessTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<StaffRoomAccess>(
      rows,
      columns: columns?.call(StaffRoomAccess.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [StaffRoomAccess]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<StaffRoomAccess> updateRow(
    _is.DatabaseSession session,
    StaffRoomAccess row, {
    _is.ColumnSelections<StaffRoomAccessTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<StaffRoomAccess>(
      row,
      columns: columns?.call(StaffRoomAccess.t),
      transaction: transaction,
    );
  }

  /// Updates a single [StaffRoomAccess] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<StaffRoomAccess?> updateById(
    _is.DatabaseSession session,
    int id, {
    required _is.ColumnValueListBuilder<StaffRoomAccessUpdateTable>
    columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<StaffRoomAccess>(
      id,
      columnValues: columnValues(StaffRoomAccess.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [StaffRoomAccess]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<StaffRoomAccess>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<StaffRoomAccessUpdateTable>
    columnValues,
    required _is.WhereExpressionBuilder<StaffRoomAccessTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<StaffRoomAccessTable>? orderBy,
    _is.OrderByListBuilder<StaffRoomAccessTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<StaffRoomAccess>(
      columnValues: columnValues(StaffRoomAccess.t.updateTable),
      where: where(StaffRoomAccess.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(StaffRoomAccess.t),
      orderByList: orderByList?.call(StaffRoomAccess.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [StaffRoomAccess]s in the list and returns the deleted rows.
  ///
  /// To specify the order of the returned rows use [orderBy] or [orderByList]
  /// when sorting by multiple columns.
  ///
  /// This is an atomic operation, meaning that if one of the rows fail to
  /// be deleted, none of the rows will be deleted.
  ///
  /// If [noReturn] is set to `true`, the deleted rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<StaffRoomAccess>> delete(
    _is.DatabaseSession session,
    List<StaffRoomAccess> rows, {
    _is.OrderByBuilder<StaffRoomAccessTable>? orderBy,
    _is.OrderByListBuilder<StaffRoomAccessTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<StaffRoomAccess>(
      rows,
      orderBy: orderBy?.call(StaffRoomAccess.t),
      orderByList: orderByList?.call(StaffRoomAccess.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [StaffRoomAccess].
  Future<StaffRoomAccess> deleteRow(
    _is.DatabaseSession session,
    StaffRoomAccess row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<StaffRoomAccess>(
      row,
      transaction: transaction,
    );
  }

  /// Deletes all rows matching the [where] expression.
  ///
  /// To specify the order of the returned rows use [orderBy] or [orderByList]
  /// when sorting by multiple columns.
  ///
  /// If [noReturn] is set to `true`, the deleted rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<StaffRoomAccess>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<StaffRoomAccessTable> where,
    _is.OrderByBuilder<StaffRoomAccessTable>? orderBy,
    _is.OrderByListBuilder<StaffRoomAccessTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<StaffRoomAccess>(
      where: where(StaffRoomAccess.t),
      orderBy: orderBy?.call(StaffRoomAccess.t),
      orderByList: orderByList?.call(StaffRoomAccess.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<StaffRoomAccessTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<StaffRoomAccess>(
      where: where?.call(StaffRoomAccess.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [StaffRoomAccess] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<StaffRoomAccessTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<StaffRoomAccess>(
      where: where(StaffRoomAccess.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
