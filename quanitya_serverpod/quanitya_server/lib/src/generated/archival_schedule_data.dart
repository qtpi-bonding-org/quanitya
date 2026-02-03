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
import 'package:serverpod/serverpod.dart' as _i1;

abstract class ArchivalScheduleData
    implements _i1.TableRow<int?>, _i1.ProtocolSerialization {
  ArchivalScheduleData._({
    this.id,
    required this.scheduledAt,
    this.lastRun,
  });

  factory ArchivalScheduleData({
    int? id,
    required DateTime scheduledAt,
    DateTime? lastRun,
  }) = _ArchivalScheduleDataImpl;

  factory ArchivalScheduleData.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return ArchivalScheduleData(
      id: jsonSerialization['id'] as int?,
      scheduledAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['scheduledAt'],
      ),
      lastRun: jsonSerialization['lastRun'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(jsonSerialization['lastRun']),
    );
  }

  static final t = ArchivalScheduleDataTable();

  static const db = ArchivalScheduleDataRepository._();

  @override
  int? id;

  DateTime scheduledAt;

  DateTime? lastRun;

  @override
  _i1.Table<int?> get table => t;

  /// Returns a shallow copy of this [ArchivalScheduleData]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  ArchivalScheduleData copyWith({
    int? id,
    DateTime? scheduledAt,
    DateTime? lastRun,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'quanitya.ArchivalScheduleData',
      if (id != null) 'id': id,
      'scheduledAt': scheduledAt.toJson(),
      if (lastRun != null) 'lastRun': lastRun?.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'quanitya.ArchivalScheduleData',
      if (id != null) 'id': id,
      'scheduledAt': scheduledAt.toJson(),
      if (lastRun != null) 'lastRun': lastRun?.toJson(),
    };
  }

  static ArchivalScheduleDataInclude include() {
    return ArchivalScheduleDataInclude._();
  }

  static ArchivalScheduleDataIncludeList includeList({
    _i1.WhereExpressionBuilder<ArchivalScheduleDataTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<ArchivalScheduleDataTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<ArchivalScheduleDataTable>? orderByList,
    ArchivalScheduleDataInclude? include,
  }) {
    return ArchivalScheduleDataIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(ArchivalScheduleData.t),
      orderDescending: orderDescending,
      orderByList: orderByList?.call(ArchivalScheduleData.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _ArchivalScheduleDataImpl extends ArchivalScheduleData {
  _ArchivalScheduleDataImpl({
    int? id,
    required DateTime scheduledAt,
    DateTime? lastRun,
  }) : super._(
         id: id,
         scheduledAt: scheduledAt,
         lastRun: lastRun,
       );

  /// Returns a shallow copy of this [ArchivalScheduleData]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  ArchivalScheduleData copyWith({
    Object? id = _Undefined,
    DateTime? scheduledAt,
    Object? lastRun = _Undefined,
  }) {
    return ArchivalScheduleData(
      id: id is int? ? id : this.id,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      lastRun: lastRun is DateTime? ? lastRun : this.lastRun,
    );
  }
}

class ArchivalScheduleDataUpdateTable
    extends _i1.UpdateTable<ArchivalScheduleDataTable> {
  ArchivalScheduleDataUpdateTable(super.table);

  _i1.ColumnValue<DateTime, DateTime> scheduledAt(DateTime value) =>
      _i1.ColumnValue(
        table.scheduledAt,
        value,
      );

  _i1.ColumnValue<DateTime, DateTime> lastRun(DateTime? value) =>
      _i1.ColumnValue(
        table.lastRun,
        value,
      );
}

class ArchivalScheduleDataTable extends _i1.Table<int?> {
  ArchivalScheduleDataTable({super.tableRelation})
    : super(tableName: 'archival_schedule_data') {
    updateTable = ArchivalScheduleDataUpdateTable(this);
    scheduledAt = _i1.ColumnDateTime(
      'scheduledAt',
      this,
    );
    lastRun = _i1.ColumnDateTime(
      'lastRun',
      this,
    );
  }

  late final ArchivalScheduleDataUpdateTable updateTable;

  late final _i1.ColumnDateTime scheduledAt;

  late final _i1.ColumnDateTime lastRun;

  @override
  List<_i1.Column> get columns => [
    id,
    scheduledAt,
    lastRun,
  ];
}

class ArchivalScheduleDataInclude extends _i1.IncludeObject {
  ArchivalScheduleDataInclude._();

  @override
  Map<String, _i1.Include?> get includes => {};

  @override
  _i1.Table<int?> get table => ArchivalScheduleData.t;
}

class ArchivalScheduleDataIncludeList extends _i1.IncludeList {
  ArchivalScheduleDataIncludeList._({
    _i1.WhereExpressionBuilder<ArchivalScheduleDataTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderDescending,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(ArchivalScheduleData.t);
  }

  @override
  Map<String, _i1.Include?> get includes => include?.includes ?? {};

  @override
  _i1.Table<int?> get table => ArchivalScheduleData.t;
}

class ArchivalScheduleDataRepository {
  const ArchivalScheduleDataRepository._();

  /// Returns a list of [ArchivalScheduleData]s matching the given query parameters.
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
  Future<List<ArchivalScheduleData>> find(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<ArchivalScheduleDataTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<ArchivalScheduleDataTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<ArchivalScheduleDataTable>? orderByList,
    _i1.Transaction? transaction,
  }) async {
    return session.db.find<ArchivalScheduleData>(
      where: where?.call(ArchivalScheduleData.t),
      orderBy: orderBy?.call(ArchivalScheduleData.t),
      orderByList: orderByList?.call(ArchivalScheduleData.t),
      orderDescending: orderDescending,
      limit: limit,
      offset: offset,
      transaction: transaction,
    );
  }

  /// Returns the first matching [ArchivalScheduleData] matching the given query parameters.
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
  Future<ArchivalScheduleData?> findFirstRow(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<ArchivalScheduleDataTable>? where,
    int? offset,
    _i1.OrderByBuilder<ArchivalScheduleDataTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<ArchivalScheduleDataTable>? orderByList,
    _i1.Transaction? transaction,
  }) async {
    return session.db.findFirstRow<ArchivalScheduleData>(
      where: where?.call(ArchivalScheduleData.t),
      orderBy: orderBy?.call(ArchivalScheduleData.t),
      orderByList: orderByList?.call(ArchivalScheduleData.t),
      orderDescending: orderDescending,
      offset: offset,
      transaction: transaction,
    );
  }

  /// Finds a single [ArchivalScheduleData] by its [id] or null if no such row exists.
  Future<ArchivalScheduleData?> findById(
    _i1.Session session,
    int id, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.findById<ArchivalScheduleData>(
      id,
      transaction: transaction,
    );
  }

  /// Inserts all [ArchivalScheduleData]s in the list and returns the inserted rows.
  ///
  /// The returned [ArchivalScheduleData]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// insert, none of the rows will be inserted.
  Future<List<ArchivalScheduleData>> insert(
    _i1.Session session,
    List<ArchivalScheduleData> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insert<ArchivalScheduleData>(
      rows,
      transaction: transaction,
    );
  }

  /// Inserts a single [ArchivalScheduleData] and returns the inserted row.
  ///
  /// The returned [ArchivalScheduleData] will have its `id` field set.
  Future<ArchivalScheduleData> insertRow(
    _i1.Session session,
    ArchivalScheduleData row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insertRow<ArchivalScheduleData>(
      row,
      transaction: transaction,
    );
  }

  /// Updates all [ArchivalScheduleData]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  Future<List<ArchivalScheduleData>> update(
    _i1.Session session,
    List<ArchivalScheduleData> rows, {
    _i1.ColumnSelections<ArchivalScheduleDataTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.update<ArchivalScheduleData>(
      rows,
      columns: columns?.call(ArchivalScheduleData.t),
      transaction: transaction,
    );
  }

  /// Updates a single [ArchivalScheduleData]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<ArchivalScheduleData> updateRow(
    _i1.Session session,
    ArchivalScheduleData row, {
    _i1.ColumnSelections<ArchivalScheduleDataTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateRow<ArchivalScheduleData>(
      row,
      columns: columns?.call(ArchivalScheduleData.t),
      transaction: transaction,
    );
  }

  /// Updates a single [ArchivalScheduleData] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<ArchivalScheduleData?> updateById(
    _i1.Session session,
    int id, {
    required _i1.ColumnValueListBuilder<ArchivalScheduleDataUpdateTable>
    columnValues,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateById<ArchivalScheduleData>(
      id,
      columnValues: columnValues(ArchivalScheduleData.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [ArchivalScheduleData]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  Future<List<ArchivalScheduleData>> updateWhere(
    _i1.Session session, {
    required _i1.ColumnValueListBuilder<ArchivalScheduleDataUpdateTable>
    columnValues,
    required _i1.WhereExpressionBuilder<ArchivalScheduleDataTable> where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<ArchivalScheduleDataTable>? orderBy,
    _i1.OrderByListBuilder<ArchivalScheduleDataTable>? orderByList,
    bool orderDescending = false,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateWhere<ArchivalScheduleData>(
      columnValues: columnValues(ArchivalScheduleData.t.updateTable),
      where: where(ArchivalScheduleData.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(ArchivalScheduleData.t),
      orderByList: orderByList?.call(ArchivalScheduleData.t),
      orderDescending: orderDescending,
      transaction: transaction,
    );
  }

  /// Deletes all [ArchivalScheduleData]s in the list and returns the deleted rows.
  /// This is an atomic operation, meaning that if one of the rows fail to
  /// be deleted, none of the rows will be deleted.
  Future<List<ArchivalScheduleData>> delete(
    _i1.Session session,
    List<ArchivalScheduleData> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.delete<ArchivalScheduleData>(
      rows,
      transaction: transaction,
    );
  }

  /// Deletes a single [ArchivalScheduleData].
  Future<ArchivalScheduleData> deleteRow(
    _i1.Session session,
    ArchivalScheduleData row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteRow<ArchivalScheduleData>(
      row,
      transaction: transaction,
    );
  }

  /// Deletes all rows matching the [where] expression.
  Future<List<ArchivalScheduleData>> deleteWhere(
    _i1.Session session, {
    required _i1.WhereExpressionBuilder<ArchivalScheduleDataTable> where,
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteWhere<ArchivalScheduleData>(
      where: where(ArchivalScheduleData.t),
      transaction: transaction,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<ArchivalScheduleDataTable>? where,
    int? limit,
    _i1.Transaction? transaction,
  }) async {
    return session.db.count<ArchivalScheduleData>(
      where: where?.call(ArchivalScheduleData.t),
      limit: limit,
      transaction: transaction,
    );
  }
}
