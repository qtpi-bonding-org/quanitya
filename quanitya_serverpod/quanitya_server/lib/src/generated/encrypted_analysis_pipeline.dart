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

abstract class EncryptedAnalysisPipeline
    implements _i1.TableRow<_i1.UuidValue>, _i1.ProtocolSerialization {
  EncryptedAnalysisPipeline._({
    _i1.UuidValue? id,
    required this.accountId,
    required this.encryptedData,
    DateTime? updatedAt,
  }) : id = id ?? _i1.Uuid().v4obj(),
       updatedAt = updatedAt ?? DateTime.now();

  factory EncryptedAnalysisPipeline({
    _i1.UuidValue? id,
    required int accountId,
    required String encryptedData,
    DateTime? updatedAt,
  }) = _EncryptedAnalysisPipelineImpl;

  factory EncryptedAnalysisPipeline.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return EncryptedAnalysisPipeline(
      id: _i1.UuidValueJsonExtension.fromJson(jsonSerialization['id']),
      accountId: jsonSerialization['accountId'] as int,
      encryptedData: jsonSerialization['encryptedData'] as String,
      updatedAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['updatedAt'],
      ),
    );
  }

  static final t = EncryptedAnalysisPipelineTable();

  static const db = EncryptedAnalysisPipelineRepository._();

  @override
  _i1.UuidValue id;

  int accountId;

  String encryptedData;

  DateTime updatedAt;

  @override
  _i1.Table<_i1.UuidValue> get table => t;

  /// Returns a shallow copy of this [EncryptedAnalysisPipeline]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  EncryptedAnalysisPipeline copyWith({
    _i1.UuidValue? id,
    int? accountId,
    String? encryptedData,
    DateTime? updatedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'quanitya.EncryptedAnalysisPipeline',
      'id': id.toJson(),
      'accountId': accountId,
      'encryptedData': encryptedData,
      'updatedAt': updatedAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'quanitya.EncryptedAnalysisPipeline',
      'id': id.toJson(),
      'accountId': accountId,
      'encryptedData': encryptedData,
      'updatedAt': updatedAt.toJson(),
    };
  }

  static EncryptedAnalysisPipelineInclude include() {
    return EncryptedAnalysisPipelineInclude._();
  }

  static EncryptedAnalysisPipelineIncludeList includeList({
    _i1.WhereExpressionBuilder<EncryptedAnalysisPipelineTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<EncryptedAnalysisPipelineTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<EncryptedAnalysisPipelineTable>? orderByList,
    EncryptedAnalysisPipelineInclude? include,
  }) {
    return EncryptedAnalysisPipelineIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(EncryptedAnalysisPipeline.t),
      orderDescending: orderDescending,
      orderByList: orderByList?.call(EncryptedAnalysisPipeline.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _EncryptedAnalysisPipelineImpl extends EncryptedAnalysisPipeline {
  _EncryptedAnalysisPipelineImpl({
    _i1.UuidValue? id,
    required int accountId,
    required String encryptedData,
    DateTime? updatedAt,
  }) : super._(
         id: id,
         accountId: accountId,
         encryptedData: encryptedData,
         updatedAt: updatedAt,
       );

  /// Returns a shallow copy of this [EncryptedAnalysisPipeline]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  EncryptedAnalysisPipeline copyWith({
    _i1.UuidValue? id,
    int? accountId,
    String? encryptedData,
    DateTime? updatedAt,
  }) {
    return EncryptedAnalysisPipeline(
      id: id ?? this.id,
      accountId: accountId ?? this.accountId,
      encryptedData: encryptedData ?? this.encryptedData,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class EncryptedAnalysisPipelineUpdateTable
    extends _i1.UpdateTable<EncryptedAnalysisPipelineTable> {
  EncryptedAnalysisPipelineUpdateTable(super.table);

  _i1.ColumnValue<int, int> accountId(int value) => _i1.ColumnValue(
    table.accountId,
    value,
  );

  _i1.ColumnValue<String, String> encryptedData(String value) =>
      _i1.ColumnValue(
        table.encryptedData,
        value,
      );

  _i1.ColumnValue<DateTime, DateTime> updatedAt(DateTime value) =>
      _i1.ColumnValue(
        table.updatedAt,
        value,
      );
}

class EncryptedAnalysisPipelineTable extends _i1.Table<_i1.UuidValue> {
  EncryptedAnalysisPipelineTable({super.tableRelation})
    : super(tableName: 'encrypted_analysis_pipelines') {
    updateTable = EncryptedAnalysisPipelineUpdateTable(this);
    accountId = _i1.ColumnInt(
      'accountId',
      this,
    );
    encryptedData = _i1.ColumnString(
      'encryptedData',
      this,
    );
    updatedAt = _i1.ColumnDateTime(
      'updatedAt',
      this,
      hasDefault: true,
    );
  }

  late final EncryptedAnalysisPipelineUpdateTable updateTable;

  late final _i1.ColumnInt accountId;

  late final _i1.ColumnString encryptedData;

  late final _i1.ColumnDateTime updatedAt;

  @override
  List<_i1.Column> get columns => [
    id,
    accountId,
    encryptedData,
    updatedAt,
  ];
}

class EncryptedAnalysisPipelineInclude extends _i1.IncludeObject {
  EncryptedAnalysisPipelineInclude._();

  @override
  Map<String, _i1.Include?> get includes => {};

  @override
  _i1.Table<_i1.UuidValue> get table => EncryptedAnalysisPipeline.t;
}

class EncryptedAnalysisPipelineIncludeList extends _i1.IncludeList {
  EncryptedAnalysisPipelineIncludeList._({
    _i1.WhereExpressionBuilder<EncryptedAnalysisPipelineTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderDescending,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(EncryptedAnalysisPipeline.t);
  }

  @override
  Map<String, _i1.Include?> get includes => include?.includes ?? {};

  @override
  _i1.Table<_i1.UuidValue> get table => EncryptedAnalysisPipeline.t;
}

class EncryptedAnalysisPipelineRepository {
  const EncryptedAnalysisPipelineRepository._();

  /// Returns a list of [EncryptedAnalysisPipeline]s matching the given query parameters.
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
  Future<List<EncryptedAnalysisPipeline>> find(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<EncryptedAnalysisPipelineTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<EncryptedAnalysisPipelineTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<EncryptedAnalysisPipelineTable>? orderByList,
    _i1.Transaction? transaction,
  }) async {
    return session.db.find<EncryptedAnalysisPipeline>(
      where: where?.call(EncryptedAnalysisPipeline.t),
      orderBy: orderBy?.call(EncryptedAnalysisPipeline.t),
      orderByList: orderByList?.call(EncryptedAnalysisPipeline.t),
      orderDescending: orderDescending,
      limit: limit,
      offset: offset,
      transaction: transaction,
    );
  }

  /// Returns the first matching [EncryptedAnalysisPipeline] matching the given query parameters.
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
  Future<EncryptedAnalysisPipeline?> findFirstRow(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<EncryptedAnalysisPipelineTable>? where,
    int? offset,
    _i1.OrderByBuilder<EncryptedAnalysisPipelineTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<EncryptedAnalysisPipelineTable>? orderByList,
    _i1.Transaction? transaction,
  }) async {
    return session.db.findFirstRow<EncryptedAnalysisPipeline>(
      where: where?.call(EncryptedAnalysisPipeline.t),
      orderBy: orderBy?.call(EncryptedAnalysisPipeline.t),
      orderByList: orderByList?.call(EncryptedAnalysisPipeline.t),
      orderDescending: orderDescending,
      offset: offset,
      transaction: transaction,
    );
  }

  /// Finds a single [EncryptedAnalysisPipeline] by its [id] or null if no such row exists.
  Future<EncryptedAnalysisPipeline?> findById(
    _i1.Session session,
    _i1.UuidValue id, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.findById<EncryptedAnalysisPipeline>(
      id,
      transaction: transaction,
    );
  }

  /// Inserts all [EncryptedAnalysisPipeline]s in the list and returns the inserted rows.
  ///
  /// The returned [EncryptedAnalysisPipeline]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// insert, none of the rows will be inserted.
  Future<List<EncryptedAnalysisPipeline>> insert(
    _i1.Session session,
    List<EncryptedAnalysisPipeline> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insert<EncryptedAnalysisPipeline>(
      rows,
      transaction: transaction,
    );
  }

  /// Inserts a single [EncryptedAnalysisPipeline] and returns the inserted row.
  ///
  /// The returned [EncryptedAnalysisPipeline] will have its `id` field set.
  Future<EncryptedAnalysisPipeline> insertRow(
    _i1.Session session,
    EncryptedAnalysisPipeline row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insertRow<EncryptedAnalysisPipeline>(
      row,
      transaction: transaction,
    );
  }

  /// Updates all [EncryptedAnalysisPipeline]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  Future<List<EncryptedAnalysisPipeline>> update(
    _i1.Session session,
    List<EncryptedAnalysisPipeline> rows, {
    _i1.ColumnSelections<EncryptedAnalysisPipelineTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.update<EncryptedAnalysisPipeline>(
      rows,
      columns: columns?.call(EncryptedAnalysisPipeline.t),
      transaction: transaction,
    );
  }

  /// Updates a single [EncryptedAnalysisPipeline]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<EncryptedAnalysisPipeline> updateRow(
    _i1.Session session,
    EncryptedAnalysisPipeline row, {
    _i1.ColumnSelections<EncryptedAnalysisPipelineTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateRow<EncryptedAnalysisPipeline>(
      row,
      columns: columns?.call(EncryptedAnalysisPipeline.t),
      transaction: transaction,
    );
  }

  /// Updates a single [EncryptedAnalysisPipeline] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<EncryptedAnalysisPipeline?> updateById(
    _i1.Session session,
    _i1.UuidValue id, {
    required _i1.ColumnValueListBuilder<EncryptedAnalysisPipelineUpdateTable>
    columnValues,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateById<EncryptedAnalysisPipeline>(
      id,
      columnValues: columnValues(EncryptedAnalysisPipeline.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [EncryptedAnalysisPipeline]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  Future<List<EncryptedAnalysisPipeline>> updateWhere(
    _i1.Session session, {
    required _i1.ColumnValueListBuilder<EncryptedAnalysisPipelineUpdateTable>
    columnValues,
    required _i1.WhereExpressionBuilder<EncryptedAnalysisPipelineTable> where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<EncryptedAnalysisPipelineTable>? orderBy,
    _i1.OrderByListBuilder<EncryptedAnalysisPipelineTable>? orderByList,
    bool orderDescending = false,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateWhere<EncryptedAnalysisPipeline>(
      columnValues: columnValues(EncryptedAnalysisPipeline.t.updateTable),
      where: where(EncryptedAnalysisPipeline.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(EncryptedAnalysisPipeline.t),
      orderByList: orderByList?.call(EncryptedAnalysisPipeline.t),
      orderDescending: orderDescending,
      transaction: transaction,
    );
  }

  /// Deletes all [EncryptedAnalysisPipeline]s in the list and returns the deleted rows.
  /// This is an atomic operation, meaning that if one of the rows fail to
  /// be deleted, none of the rows will be deleted.
  Future<List<EncryptedAnalysisPipeline>> delete(
    _i1.Session session,
    List<EncryptedAnalysisPipeline> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.delete<EncryptedAnalysisPipeline>(
      rows,
      transaction: transaction,
    );
  }

  /// Deletes a single [EncryptedAnalysisPipeline].
  Future<EncryptedAnalysisPipeline> deleteRow(
    _i1.Session session,
    EncryptedAnalysisPipeline row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteRow<EncryptedAnalysisPipeline>(
      row,
      transaction: transaction,
    );
  }

  /// Deletes all rows matching the [where] expression.
  Future<List<EncryptedAnalysisPipeline>> deleteWhere(
    _i1.Session session, {
    required _i1.WhereExpressionBuilder<EncryptedAnalysisPipelineTable> where,
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteWhere<EncryptedAnalysisPipeline>(
      where: where(EncryptedAnalysisPipeline.t),
      transaction: transaction,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<EncryptedAnalysisPipelineTable>? where,
    int? limit,
    _i1.Transaction? transaction,
  }) async {
    return session.db.count<EncryptedAnalysisPipeline>(
      where: where?.call(EncryptedAnalysisPipeline.t),
      limit: limit,
      transaction: transaction,
    );
  }
}
