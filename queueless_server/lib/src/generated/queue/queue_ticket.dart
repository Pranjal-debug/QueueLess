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

abstract class QueueTicket
    implements _is.TableRow<int?>, _is.ProtocolSerialization {
  QueueTicket._({
    this.id,
    required this.customerName,
    required this.roomId,
    this.sessionId,
    required this.accessCode,
    required this.ticketNumber,
    required this.status,
    required this.createdAt,
    this.calledAt,
    this.completedAt,
  });

  factory QueueTicket({
    int? id,
    required String customerName,
    required int roomId,
    int? sessionId,
    required String accessCode,
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
      roomId: jsonSerialization['roomId'] as int,
      sessionId: jsonSerialization['sessionId'] as int?,
      accessCode: jsonSerialization['accessCode'] as String,
      ticketNumber: jsonSerialization['ticketNumber'] as int,
      status: jsonSerialization['status'] as String,
      createdAt: _is.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
      calledAt: jsonSerialization['calledAt'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(jsonSerialization['calledAt']),
      completedAt: jsonSerialization['completedAt'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(
              jsonSerialization['completedAt'],
            ),
    );
  }

  static final t = QueueTicketTable();

  static const db = QueueTicketRepository._();

  @override
  int? id;

  String customerName;

  int roomId;

  int? sessionId;

  String accessCode;

  int ticketNumber;

  String status;

  DateTime createdAt;

  DateTime? calledAt;

  DateTime? completedAt;

  @override
  _is.Table<int?> get table => t;

  /// Returns a shallow copy of this [QueueTicket]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  QueueTicket copyWith({
    int? id,
    String? customerName,
    int? roomId,
    int? sessionId,
    String? accessCode,
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
      'roomId': roomId,
      if (sessionId != null) 'sessionId': sessionId,
      'accessCode': accessCode,
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
      'roomId': roomId,
      if (sessionId != null) 'sessionId': sessionId,
      'accessCode': accessCode,
      'ticketNumber': ticketNumber,
      'status': status,
      'createdAt': createdAt.toJson(),
      if (calledAt != null) 'calledAt': calledAt?.toJson(),
      if (completedAt != null) 'completedAt': completedAt?.toJson(),
    };
  }

  static QueueTicketInclude include() {
    return QueueTicketInclude._();
  }

  static QueueTicketIncludeList includeList({
    _is.WhereExpressionBuilder<QueueTicketTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<QueueTicketTable>? orderBy,
    _is.OrderByListBuilder<QueueTicketTable>? orderByList,
    QueueTicketInclude? include,
  }) {
    return QueueTicketIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(QueueTicket.t),
      orderByList: orderByList?.call(QueueTicket.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _QueueTicketImpl extends QueueTicket {
  _QueueTicketImpl({
    int? id,
    required String customerName,
    required int roomId,
    int? sessionId,
    required String accessCode,
    required int ticketNumber,
    required String status,
    required DateTime createdAt,
    DateTime? calledAt,
    DateTime? completedAt,
  }) : super._(
         id: id,
         customerName: customerName,
         roomId: roomId,
         sessionId: sessionId,
         accessCode: accessCode,
         ticketNumber: ticketNumber,
         status: status,
         createdAt: createdAt,
         calledAt: calledAt,
         completedAt: completedAt,
       );

  /// Returns a shallow copy of this [QueueTicket]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  QueueTicket copyWith({
    Object? id = _Undefined,
    String? customerName,
    int? roomId,
    Object? sessionId = _Undefined,
    String? accessCode,
    int? ticketNumber,
    String? status,
    DateTime? createdAt,
    Object? calledAt = _Undefined,
    Object? completedAt = _Undefined,
  }) {
    return QueueTicket(
      id: id is int? ? id : this.id,
      customerName: customerName ?? this.customerName,
      roomId: roomId ?? this.roomId,
      sessionId: sessionId is int? ? sessionId : this.sessionId,
      accessCode: accessCode ?? this.accessCode,
      ticketNumber: ticketNumber ?? this.ticketNumber,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      calledAt: calledAt is DateTime? ? calledAt : this.calledAt,
      completedAt: completedAt is DateTime? ? completedAt : this.completedAt,
    );
  }
}

class QueueTicketUpdateTable extends _is.UpdateTable<QueueTicketTable> {
  QueueTicketUpdateTable(super.table);

  _is.ColumnValue<String, String> customerName(String value) => _is.ColumnValue(
    table.customerName,
    value,
  );

  _is.ColumnValue<int, int> roomId(int value) => _is.ColumnValue(
    table.roomId,
    value,
  );

  _is.ColumnValue<int, int> sessionId(int? value) => _is.ColumnValue(
    table.sessionId,
    value,
  );

  _is.ColumnValue<String, String> accessCode(String value) => _is.ColumnValue(
    table.accessCode,
    value,
  );

  _is.ColumnValue<int, int> ticketNumber(int value) => _is.ColumnValue(
    table.ticketNumber,
    value,
  );

  _is.ColumnValue<String, String> status(String value) => _is.ColumnValue(
    table.status,
    value,
  );

  _is.ColumnValue<DateTime, DateTime> createdAt(DateTime value) =>
      _is.ColumnValue(
        table.createdAt,
        value,
      );

  _is.ColumnValue<DateTime, DateTime> calledAt(DateTime? value) =>
      _is.ColumnValue(
        table.calledAt,
        value,
      );

  _is.ColumnValue<DateTime, DateTime> completedAt(DateTime? value) =>
      _is.ColumnValue(
        table.completedAt,
        value,
      );
}

class QueueTicketTable extends _is.Table<int?> {
  QueueTicketTable({super.tableRelation}) : super(tableName: 'queue_ticket') {
    updateTable = QueueTicketUpdateTable(this);
    customerName = _is.ColumnString(
      'customerName',
      this,
    );
    roomId = _is.ColumnInt(
      'roomId',
      this,
    );
    sessionId = _is.ColumnInt(
      'sessionId',
      this,
    );
    accessCode = _is.ColumnString(
      'accessCode',
      this,
    );
    ticketNumber = _is.ColumnInt(
      'ticketNumber',
      this,
    );
    status = _is.ColumnString(
      'status',
      this,
    );
    createdAt = _is.ColumnDateTime(
      'createdAt',
      this,
    );
    calledAt = _is.ColumnDateTime(
      'calledAt',
      this,
    );
    completedAt = _is.ColumnDateTime(
      'completedAt',
      this,
    );
  }

  late final QueueTicketUpdateTable updateTable;

  late final _is.ColumnString customerName;

  late final _is.ColumnInt roomId;

  late final _is.ColumnInt sessionId;

  late final _is.ColumnString accessCode;

  late final _is.ColumnInt ticketNumber;

  late final _is.ColumnString status;

  late final _is.ColumnDateTime createdAt;

  late final _is.ColumnDateTime calledAt;

  late final _is.ColumnDateTime completedAt;

  @override
  List<_is.Column> get columns => [
    id,
    customerName,
    roomId,
    sessionId,
    accessCode,
    ticketNumber,
    status,
    createdAt,
    calledAt,
    completedAt,
  ];
}

class QueueTicketInclude extends _is.IncludeObject {
  QueueTicketInclude._();

  @override
  Map<String, _is.Include?> get includes => {};

  @override
  _is.Table<int?> get table => QueueTicket.t;
}

class QueueTicketIncludeList extends _is.IncludeList {
  QueueTicketIncludeList._({
    _is.WhereExpressionBuilder<QueueTicketTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(QueueTicket.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<int?> get table => QueueTicket.t;
}

class QueueTicketRepository {
  const QueueTicketRepository._();

  /// Returns a list of [QueueTicket]s matching the given query parameters.
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
  Future<List<QueueTicket>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<QueueTicketTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<QueueTicketTable>? orderBy,
    _is.OrderByListBuilder<QueueTicketTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<QueueTicket>(
      where: where?.call(QueueTicket.t),
      orderBy: orderBy?.call(QueueTicket.t),
      orderByList: orderByList?.call(QueueTicket.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [QueueTicket] matching the given query parameters.
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
  Future<QueueTicket?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<QueueTicketTable>? where,
    int? offset,
    _is.OrderByBuilder<QueueTicketTable>? orderBy,
    _is.OrderByListBuilder<QueueTicketTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<QueueTicket>(
      where: where?.call(QueueTicket.t),
      orderBy: orderBy?.call(QueueTicket.t),
      orderByList: orderByList?.call(QueueTicket.t),
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [QueueTicket] by its [id] or null if no such row exists.
  Future<QueueTicket?> findById(
    _is.DatabaseSession session,
    int id, {
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<QueueTicket>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [QueueTicket]s in the list and returns the inserted rows.
  ///
  /// The returned [QueueTicket]s will have their `id` fields set.
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
  Future<List<QueueTicket>> insert(
    _is.DatabaseSession session,
    List<QueueTicket> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<QueueTicket>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [QueueTicket] and returns the inserted row.
  ///
  /// The returned [QueueTicket] will have its `id` field set.
  Future<QueueTicket> insertRow(
    _is.DatabaseSession session,
    QueueTicket row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<QueueTicket>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [QueueTicket]s in the list and returns the resulting rows.
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
  /// The returned [QueueTicket]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<QueueTicket>> upsert(
    _is.DatabaseSession session,
    List<QueueTicket> rows, {
    required _is.ColumnSelections<QueueTicketTable> conflictColumns,
    _is.ColumnSelections<QueueTicketTable>? updateColumns,
    _is.WhereExpressionBuilder<QueueTicketTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<QueueTicket>(
      rows,
      conflictColumns: conflictColumns(QueueTicket.t),
      updateColumns: updateColumns?.call(QueueTicket.t),
      updateWhere: updateWhere?.call(QueueTicket.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [QueueTicket] and returns the resulting row.
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
  /// The returned [QueueTicket] will have its `id` field set.
  Future<QueueTicket?> upsertRow(
    _is.DatabaseSession session,
    QueueTicket row, {
    required _is.ColumnSelections<QueueTicketTable> conflictColumns,
    _is.ColumnSelections<QueueTicketTable>? updateColumns,
    _is.WhereExpressionBuilder<QueueTicketTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<QueueTicket>(
      row,
      conflictColumns: conflictColumns(QueueTicket.t),
      updateColumns: updateColumns?.call(QueueTicket.t),
      updateWhere: updateWhere?.call(QueueTicket.t),
      transaction: transaction,
    );
  }

  /// Updates all [QueueTicket]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<QueueTicket>> update(
    _is.DatabaseSession session,
    List<QueueTicket> rows, {
    _is.ColumnSelections<QueueTicketTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<QueueTicket>(
      rows,
      columns: columns?.call(QueueTicket.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [QueueTicket]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<QueueTicket> updateRow(
    _is.DatabaseSession session,
    QueueTicket row, {
    _is.ColumnSelections<QueueTicketTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<QueueTicket>(
      row,
      columns: columns?.call(QueueTicket.t),
      transaction: transaction,
    );
  }

  /// Updates a single [QueueTicket] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<QueueTicket?> updateById(
    _is.DatabaseSession session,
    int id, {
    required _is.ColumnValueListBuilder<QueueTicketUpdateTable> columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<QueueTicket>(
      id,
      columnValues: columnValues(QueueTicket.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [QueueTicket]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<QueueTicket>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<QueueTicketUpdateTable> columnValues,
    required _is.WhereExpressionBuilder<QueueTicketTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<QueueTicketTable>? orderBy,
    _is.OrderByListBuilder<QueueTicketTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<QueueTicket>(
      columnValues: columnValues(QueueTicket.t.updateTable),
      where: where(QueueTicket.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(QueueTicket.t),
      orderByList: orderByList?.call(QueueTicket.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [QueueTicket]s in the list and returns the deleted rows.
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
  Future<List<QueueTicket>> delete(
    _is.DatabaseSession session,
    List<QueueTicket> rows, {
    _is.OrderByBuilder<QueueTicketTable>? orderBy,
    _is.OrderByListBuilder<QueueTicketTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<QueueTicket>(
      rows,
      orderBy: orderBy?.call(QueueTicket.t),
      orderByList: orderByList?.call(QueueTicket.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [QueueTicket].
  Future<QueueTicket> deleteRow(
    _is.DatabaseSession session,
    QueueTicket row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<QueueTicket>(
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
  Future<List<QueueTicket>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<QueueTicketTable> where,
    _is.OrderByBuilder<QueueTicketTable>? orderBy,
    _is.OrderByListBuilder<QueueTicketTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<QueueTicket>(
      where: where(QueueTicket.t),
      orderBy: orderBy?.call(QueueTicket.t),
      orderByList: orderByList?.call(QueueTicket.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<QueueTicketTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<QueueTicket>(
      where: where?.call(QueueTicket.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [QueueTicket] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<QueueTicketTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<QueueTicket>(
      where: where(QueueTicket.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
