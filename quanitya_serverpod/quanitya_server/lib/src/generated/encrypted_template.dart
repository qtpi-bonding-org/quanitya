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

abstract class EncryptedTemplate
    implements _i1.TableRow<_i1.UuidValue>, _i1.ProtocolSerialization {
  EncryptedTemplate._({
    _i1.UuidValue? id,
    required this.accountUuid,
    required this.encryptedData,
    DateTime? updatedAt,
  }) : id = id ?? const _i1.Uuid().v4obj(),
       updatedAt = updatedAt ?? DateTime.now();

  factory EncryptedTemplate({
    _i1.UuidValue? id,
    required String accountUuid,
    required String encryptedData,
    DateTime? updatedAt,
  }) = _EncryptedTemplateImpl;

  factory EncryptedTemplate.fromJson(Map<String, dynamic> jsonSerialization) {
    return EncryptedTemplate(
      id: jsonSerialization['id'] == null
          ? null
          : _i1.UuidValueJsonExtension.fromJson(jsonSerialization['id']),
      accountUuid: jsonSerialization['accountUuid'] as String,
      encryptedData: jsonSerialization['encryptedData'] as String,
      updatedAt: jsonSerialization['updatedAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(jsonSerialization['updatedAt']),
    );
  }

  static final t = EncryptedTemplateTable();

  static const db = EncryptedTemplateRepository._();

  @override
  _i1.UuidValue id;

  String accountUuid;

  String encryptedData;

  DateTime updatedAt;

  @override
  _i1.Table<_i1.UuidValue> get table => t;

  /// Returns a shallow copy of this [EncryptedTemplate]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  EncryptedTemplate copyWith({
    _i1.UuidValue? id,
    String? accountUuid,
    String? encryptedData,
    DateTime? updatedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'quanitya.EncryptedTemplate',
      'id': id.toJson(),
      'accountUuid': accountUuid,
      'encryptedData': encryptedData,
      'updatedAt': updatedAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'quanitya.EncryptedTemplate',
      'id': id.toJson(),
      'accountUuid': accountUuid,
      'encryptedData': encryptedData,
      'updatedAt': updatedAt.toJson(),
    };
  }

  static EncryptedTemplateInclude include() {
    return EncryptedTemplateInclude._();
  }

  static EncryptedTemplateIncludeList includeList({
    _i1.WhereExpressionBuilder<EncryptedTemplateTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<EncryptedTemplateTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<EncryptedTemplateTable>? orderByList,
    EncryptedTemplateInclude? include,
  }) {
    return EncryptedTemplateIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(EncryptedTemplate.t),
      orderDescending: orderDescending,
      orderByList: orderByList?.call(EncryptedTemplate.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _EncryptedTemplateImpl extends EncryptedTemplate {
  _EncryptedTemplateImpl({
    _i1.UuidValue? id,
    required String accountUuid,
    required String encryptedData,
    DateTime? updatedAt,
  }) : super._(
         id: id,
         accountUuid: accountUuid,
         encryptedData: encryptedData,
         updatedAt: updatedAt,
       );

  /// Returns a shallow copy of this [EncryptedTemplate]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  EncryptedTemplate copyWith({
    _i1.UuidValue? id,
    String? accountUuid,
    String? encryptedData,
    DateTime? updatedAt,
  }) {
    return EncryptedTemplate(
      id: id ?? this.id,
      accountUuid: accountUuid ?? this.accountUuid,
      encryptedData: encryptedData ?? this.encryptedData,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class EncryptedTemplateUpdateTable
    extends _i1.UpdateTable<EncryptedTemplateTable> {
  EncryptedTemplateUpdateTable(super.table);

  _i1.ColumnValue<String, String> accountUuid(String value) => _i1.ColumnValue(
    table.accountUuid,
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

class EncryptedTemplateTable extends _i1.Table<_i1.UuidValue> {
  EncryptedTemplateTable({super.tableRelation})
    : super(tableName: 'encrypted_templates') {
    updateTable = EncryptedTemplateUpdateTable(this);
    accountUuid = _i1.ColumnString(
      'accountUuid',
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

  late final EncryptedTemplateUpdateTable updateTable;

  late final _i1.ColumnString accountUuid;

  late final _i1.ColumnString encryptedData;

  late final _i1.ColumnDateTime updatedAt;

  @override
  List<_i1.Column> get columns => [
    id,
    accountUuid,
    encryptedData,
    updatedAt,
  ];
}

class EncryptedTemplateInclude extends _i1.IncludeObject {
  EncryptedTemplateInclude._();

  @override
  Map<String, _i1.Include?> get includes => {};

  @override
  _i1.Table<_i1.UuidValue> get table => EncryptedTemplate.t;
}

class EncryptedTemplateIncludeList extends _i1.IncludeList {
  EncryptedTemplateIncludeList._({
    _i1.WhereExpressionBuilder<EncryptedTemplateTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderDescending,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(EncryptedTemplate.t);
  }

  @override
  Map<String, _i1.Include?> get includes => include?.includes ?? {};

  @override
  _i1.Table<_i1.UuidValue> get table => EncryptedTemplate.t;
}

class EncryptedTemplateRepository {
  const EncryptedTemplateRepository._();

  /// Returns a list of [EncryptedTemplate]s matching the given query parameters.
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
  Future<List<EncryptedTemplate>> find(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<EncryptedTemplateTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<EncryptedTemplateTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<EncryptedTemplateTable>? orderByList,
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<EncryptedTemplate>(
      where: where?.call(EncryptedTemplate.t),
      orderBy: orderBy?.call(EncryptedTemplate.t),
      orderByList: orderByList?.call(EncryptedTemplate.t),
      orderDescending: orderDescending,
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [EncryptedTemplate] matching the given query parameters.
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
  Future<EncryptedTemplate?> findFirstRow(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<EncryptedTemplateTable>? where,
    int? offset,
    _i1.OrderByBuilder<EncryptedTemplateTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<EncryptedTemplateTable>? orderByList,
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<EncryptedTemplate>(
      where: where?.call(EncryptedTemplate.t),
      orderBy: orderBy?.call(EncryptedTemplate.t),
      orderByList: orderByList?.call(EncryptedTemplate.t),
      orderDescending: orderDescending,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [EncryptedTemplate] by its [id] or null if no such row exists.
  Future<EncryptedTemplate?> findById(
    _i1.Session session,
    _i1.UuidValue id, {
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<EncryptedTemplate>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [EncryptedTemplate]s in the list and returns the inserted rows.
  ///
  /// The returned [EncryptedTemplate]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// insert, none of the rows will be inserted.
  ///
  /// If [ignoreConflicts] is set to `true`, rows that conflict with existing
  /// rows are silently skipped, and only the successfully inserted rows are
  /// returned.
  Future<List<EncryptedTemplate>> insert(
    _i1.Session session,
    List<EncryptedTemplate> rows, {
    _i1.Transaction? transaction,
    bool ignoreConflicts = false,
  }) async {
    return session.db.insert<EncryptedTemplate>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
    );
  }

  /// Inserts a single [EncryptedTemplate] and returns the inserted row.
  ///
  /// The returned [EncryptedTemplate] will have its `id` field set.
  Future<EncryptedTemplate> insertRow(
    _i1.Session session,
    EncryptedTemplate row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insertRow<EncryptedTemplate>(
      row,
      transaction: transaction,
    );
  }

  /// Updates all [EncryptedTemplate]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  Future<List<EncryptedTemplate>> update(
    _i1.Session session,
    List<EncryptedTemplate> rows, {
    _i1.ColumnSelections<EncryptedTemplateTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.update<EncryptedTemplate>(
      rows,
      columns: columns?.call(EncryptedTemplate.t),
      transaction: transaction,
    );
  }

  /// Updates a single [EncryptedTemplate]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<EncryptedTemplate> updateRow(
    _i1.Session session,
    EncryptedTemplate row, {
    _i1.ColumnSelections<EncryptedTemplateTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateRow<EncryptedTemplate>(
      row,
      columns: columns?.call(EncryptedTemplate.t),
      transaction: transaction,
    );
  }

  /// Updates a single [EncryptedTemplate] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<EncryptedTemplate?> updateById(
    _i1.Session session,
    _i1.UuidValue id, {
    required _i1.ColumnValueListBuilder<EncryptedTemplateUpdateTable>
    columnValues,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateById<EncryptedTemplate>(
      id,
      columnValues: columnValues(EncryptedTemplate.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [EncryptedTemplate]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  Future<List<EncryptedTemplate>> updateWhere(
    _i1.Session session, {
    required _i1.ColumnValueListBuilder<EncryptedTemplateUpdateTable>
    columnValues,
    required _i1.WhereExpressionBuilder<EncryptedTemplateTable> where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<EncryptedTemplateTable>? orderBy,
    _i1.OrderByListBuilder<EncryptedTemplateTable>? orderByList,
    bool orderDescending = false,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateWhere<EncryptedTemplate>(
      columnValues: columnValues(EncryptedTemplate.t.updateTable),
      where: where(EncryptedTemplate.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(EncryptedTemplate.t),
      orderByList: orderByList?.call(EncryptedTemplate.t),
      orderDescending: orderDescending,
      transaction: transaction,
    );
  }

  /// Deletes all [EncryptedTemplate]s in the list and returns the deleted rows.
  /// This is an atomic operation, meaning that if one of the rows fail to
  /// be deleted, none of the rows will be deleted.
  Future<List<EncryptedTemplate>> delete(
    _i1.Session session,
    List<EncryptedTemplate> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.delete<EncryptedTemplate>(
      rows,
      transaction: transaction,
    );
  }

  /// Deletes a single [EncryptedTemplate].
  Future<EncryptedTemplate> deleteRow(
    _i1.Session session,
    EncryptedTemplate row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteRow<EncryptedTemplate>(
      row,
      transaction: transaction,
    );
  }

  /// Deletes all rows matching the [where] expression.
  Future<List<EncryptedTemplate>> deleteWhere(
    _i1.Session session, {
    required _i1.WhereExpressionBuilder<EncryptedTemplateTable> where,
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteWhere<EncryptedTemplate>(
      where: where(EncryptedTemplate.t),
      transaction: transaction,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<EncryptedTemplateTable>? where,
    int? limit,
    _i1.Transaction? transaction,
  }) async {
    return session.db.count<EncryptedTemplate>(
      where: where?.call(EncryptedTemplate.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [EncryptedTemplate] rows matching the [where] expression.
  Future<void> lockRows(
    _i1.Session session, {
    required _i1.WhereExpressionBuilder<EncryptedTemplateTable> where,
    required _i1.LockMode lockMode,
    required _i1.Transaction transaction,
    _i1.LockBehavior lockBehavior = _i1.LockBehavior.wait,
  }) async {
    return session.db.lockRows<EncryptedTemplate>(
      where: where(EncryptedTemplate.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
