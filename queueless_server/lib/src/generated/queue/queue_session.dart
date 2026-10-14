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

abstract class QueueSession
    implements _is.TableRow<int?>, _is.ProtocolSerialization {
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
      startedAt: _is.DateTimeJsonExtension.fromJson(
        jsonSerialization['startedAt'],
      ),
      closedAt: jsonSerialization['closedAt'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(jsonSerialization['closedAt']),
    );
  }

  static final t = QueueSessionTable();

  static const db = QueueSessionRepository._();

  @override
  int? id;

  int roomId;

  String businessDate;

  int sessionNumber;

  String status;

  DateTime startedAt;

  DateTime? closedAt;

  @override
  _is.Table<int?> get table => t;

  /// Returns a shallow copy of this [QueueSession]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
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

  static QueueSessionInclude include() {
    return QueueSessionInclude._();
  }

  static QueueSessionIncludeList includeList({
    _is.WhereExpressionBuilder<QueueSessionTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<QueueSessionTable>? orderBy,
    _is.OrderByListBuilder<QueueSessionTable>? orderByList,
    QueueSessionInclude? include,
  }) {
    return QueueSessionIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(QueueSession.t),
      orderByList: orderByList?.call(QueueSession.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
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
  @_is.useResult
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

class QueueSessionUpdateTable extends _is.UpdateTable<QueueSessionTable> {
  QueueSessionUpdateTable(super.table);

  _is.ColumnValue<int, int> roomId(int value) => _is.ColumnValue(
    table.roomId,
    value,
  );

  _is.ColumnValue<String, String> businessDate(String value) => _is.ColumnValue(
    table.businessDate,
    value,
  );

  _is.ColumnValue<int, int> sessionNumber(int value) => _is.ColumnValue(
    table.sessionNumber,
    value,
  );

  _is.ColumnValue<String, String> status(String value) => _is.ColumnValue(
    table.status,
    value,
  );

  _is.ColumnValue<DateTime, DateTime> startedAt(DateTime value) =>
      _is.ColumnValue(
        table.startedAt,
        value,
      );

  _is.ColumnValue<DateTime, DateTime> closedAt(DateTime? value) =>
      _is.ColumnValue(
        table.closedAt,
        value,
      );
}

class QueueSessionTable extends _is.Table<int?> {
  QueueSessionTable({super.tableRelation}) : super(tableName: 'queue_session') {
    updateTable = QueueSessionUpdateTable(this);
    roomId = _is.ColumnInt(
      'roomId',
      this,
    );
    businessDate = _is.ColumnString(
      'businessDate',
      this,
    );
    sessionNumber = _is.ColumnInt(
      'sessionNumber',
      this,
    );
    status = _is.ColumnString(
      'status',
      this,
    );
    startedAt = _is.ColumnDateTime(
      'startedAt',
      this,
    );
    closedAt = _is.ColumnDateTime(
      'closedAt',
      this,
    );
  }

  late final QueueSessionUpdateTable updateTable;

  late final _is.ColumnInt roomId;

  late final _is.ColumnString businessDate;

  late final _is.ColumnInt sessionNumber;

  late final _is.ColumnString status;

  late final _is.ColumnDateTime startedAt;

  late final _is.ColumnDateTime closedAt;

  @override
  List<_is.Column> get columns => [
    id,
    roomId,
    businessDate,
    sessionNumber,
    status,
    startedAt,
    closedAt,
  ];
}

class QueueSessionInclude extends _is.IncludeObject {
  QueueSessionInclude._();

  @override
  Map<String, _is.Include?> get includes => {};

  @override
  _is.Table<int?> get table => QueueSession.t;
}

class QueueSessionIncludeList extends _is.IncludeList {
  QueueSessionIncludeList._({
    _is.WhereExpressionBuilder<QueueSessionTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(QueueSession.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<int?> get table => QueueSession.t;
}

class QueueSessionRepository {
  const QueueSessionRepository._();

  /// Returns a list of [QueueSession]s matching the given query parameters.
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
  Future<List<QueueSession>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<QueueSessionTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<QueueSessionTable>? orderBy,
    _is.OrderByListBuilder<QueueSessionTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<QueueSession>(
      where: where?.call(QueueSession.t),
      orderBy: orderBy?.call(QueueSession.t),
      orderByList: orderByList?.call(QueueSession.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [QueueSession] matching the given query parameters.
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
  Future<QueueSession?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<QueueSessionTable>? where,
    int? offset,
    _is.OrderByBuilder<QueueSessionTable>? orderBy,
    _is.OrderByListBuilder<QueueSessionTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<QueueSession>(
      where: where?.call(QueueSession.t),
      orderBy: orderBy?.call(QueueSession.t),
      orderByList: orderByList?.call(QueueSession.t),
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [QueueSession] by its [id] or null if no such row exists.
  Future<QueueSession?> findById(
    _is.DatabaseSession session,
    int id, {
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<QueueSession>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [QueueSession]s in the list and returns the inserted rows.
  ///
  /// The returned [QueueSession]s will have their `id` fields set.
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
  Future<List<QueueSession>> insert(
    _is.DatabaseSession session,
    List<QueueSession> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<QueueSession>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [QueueSession] and returns the inserted row.
  ///
  /// The returned [QueueSession] will have its `id` field set.
  Future<QueueSession> insertRow(
    _is.DatabaseSession session,
    QueueSession row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<QueueSession>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [QueueSession]s in the list and returns the resulting rows.
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
  /// The returned [QueueSession]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<QueueSession>> upsert(
    _is.DatabaseSession session,
    List<QueueSession> rows, {
    required _is.ColumnSelections<QueueSessionTable> conflictColumns,
    _is.ColumnSelections<QueueSessionTable>? updateColumns,
    _is.WhereExpressionBuilder<QueueSessionTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<QueueSession>(
      rows,
      conflictColumns: conflictColumns(QueueSession.t),
      updateColumns: updateColumns?.call(QueueSession.t),
      updateWhere: updateWhere?.call(QueueSession.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [QueueSession] and returns the resulting row.
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
  /// The returned [QueueSession] will have its `id` field set.
  Future<QueueSession?> upsertRow(
    _is.DatabaseSession session,
    QueueSession row, {
    required _is.ColumnSelections<QueueSessionTable> conflictColumns,
    _is.ColumnSelections<QueueSessionTable>? updateColumns,
    _is.WhereExpressionBuilder<QueueSessionTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<QueueSession>(
      row,
      conflictColumns: conflictColumns(QueueSession.t),
      updateColumns: updateColumns?.call(QueueSession.t),
      updateWhere: updateWhere?.call(QueueSession.t),
      transaction: transaction,
    );
  }

  /// Updates all [QueueSession]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<QueueSession>> update(
    _is.DatabaseSession session,
    List<QueueSession> rows, {
    _is.ColumnSelections<QueueSessionTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<QueueSession>(
      rows,
      columns: columns?.call(QueueSession.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [QueueSession]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<QueueSession> updateRow(
    _is.DatabaseSession session,
    QueueSession row, {
    _is.ColumnSelections<QueueSessionTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<QueueSession>(
      row,
      columns: columns?.call(QueueSession.t),
      transaction: transaction,
    );
  }

  /// Updates a single [QueueSession] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<QueueSession?> updateById(
    _is.DatabaseSession session,
    int id, {
    required _is.ColumnValueListBuilder<QueueSessionUpdateTable> columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<QueueSession>(
      id,
      columnValues: columnValues(QueueSession.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [QueueSession]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<QueueSession>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<QueueSessionUpdateTable> columnValues,
    required _is.WhereExpressionBuilder<QueueSessionTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<QueueSessionTable>? orderBy,
    _is.OrderByListBuilder<QueueSessionTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<QueueSession>(
      columnValues: columnValues(QueueSession.t.updateTable),
      where: where(QueueSession.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(QueueSession.t),
      orderByList: orderByList?.call(QueueSession.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [QueueSession]s in the list and returns the deleted rows.
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
  Future<List<QueueSession>> delete(
    _is.DatabaseSession session,
    List<QueueSession> rows, {
    _is.OrderByBuilder<QueueSessionTable>? orderBy,
    _is.OrderByListBuilder<QueueSessionTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<QueueSession>(
      rows,
      orderBy: orderBy?.call(QueueSession.t),
      orderByList: orderByList?.call(QueueSession.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [QueueSession].
  Future<QueueSession> deleteRow(
    _is.DatabaseSession session,
    QueueSession row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<QueueSession>(
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
  Future<List<QueueSession>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<QueueSessionTable> where,
    _is.OrderByBuilder<QueueSessionTable>? orderBy,
    _is.OrderByListBuilder<QueueSessionTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<QueueSession>(
      where: where(QueueSession.t),
      orderBy: orderBy?.call(QueueSession.t),
      orderByList: orderByList?.call(QueueSession.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<QueueSessionTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<QueueSession>(
      where: where?.call(QueueSession.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [QueueSession] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<QueueSessionTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<QueueSession>(
      where: where(QueueSession.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
