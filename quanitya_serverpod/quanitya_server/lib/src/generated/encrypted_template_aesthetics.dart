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

abstract class EncryptedTemplateAesthetics
    implements _i1.TableRow<_i1.UuidValue>, _i1.ProtocolSerialization {
  EncryptedTemplateAesthetics._({
    _i1.UuidValue? id,
    required this.accountId,
    required this.encryptedData,
    DateTime? updatedAt,
  }) : id = id ?? const _i1.Uuid().v4obj(),
       updatedAt = updatedAt ?? DateTime.now();

  factory EncryptedTemplateAesthetics({
    _i1.UuidValue? id,
    required int accountId,
    required String encryptedData,
    DateTime? updatedAt,
  }) = _EncryptedTemplateAestheticsImpl;

  factory EncryptedTemplateAesthetics.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return EncryptedTemplateAesthetics(
      id: jsonSerialization['id'] == null
          ? null
          : _i1.UuidValueJsonExtension.fromJson(jsonSerialization['id']),
      accountId: jsonSerialization['accountId'] as int,
      encryptedData: jsonSerialization['encryptedData'] as String,
      updatedAt: jsonSerialization['updatedAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(jsonSerialization['updatedAt']),
    );
  }

  static final t = EncryptedTemplateAestheticsTable();

  static const db = EncryptedTemplateAestheticsRepository._();

  @override
  _i1.UuidValue id;

  int accountId;

  String encryptedData;

  DateTime updatedAt;

  @override
  _i1.Table<_i1.UuidValue> get table => t;

  /// Returns a shallow copy of this [EncryptedTemplateAesthetics]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  EncryptedTemplateAesthetics copyWith({
    _i1.UuidValue? id,
    int? accountId,
    String? encryptedData,
    DateTime? updatedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'quanitya.EncryptedTemplateAesthetics',
      'id': id.toJson(),
      'accountId': accountId,
      'encryptedData': encryptedData,
      'updatedAt': updatedAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'quanitya.EncryptedTemplateAesthetics',
      'id': id.toJson(),
      'accountId': accountId,
      'encryptedData': encryptedData,
      'updatedAt': updatedAt.toJson(),
    };
  }

  static EncryptedTemplateAestheticsInclude include() {
    return EncryptedTemplateAestheticsInclude._();
  }

  static EncryptedTemplateAestheticsIncludeList includeList({
    _i1.WhereExpressionBuilder<EncryptedTemplateAestheticsTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<EncryptedTemplateAestheticsTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<EncryptedTemplateAestheticsTable>? orderByList,
    EncryptedTemplateAestheticsInclude? include,
  }) {
    return EncryptedTemplateAestheticsIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(EncryptedTemplateAesthetics.t),
      orderDescending: orderDescending,
      orderByList: orderByList?.call(EncryptedTemplateAesthetics.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _EncryptedTemplateAestheticsImpl extends EncryptedTemplateAesthetics {
  _EncryptedTemplateAestheticsImpl({
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

  /// Returns a shallow copy of this [EncryptedTemplateAesthetics]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  EncryptedTemplateAesthetics copyWith({
    _i1.UuidValue? id,
    int? accountId,
    String? encryptedData,
    DateTime? updatedAt,
  }) {
    return EncryptedTemplateAesthetics(
      id: id ?? this.id,
      accountId: accountId ?? this.accountId,
      encryptedData: encryptedData ?? this.encryptedData,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class EncryptedTemplateAestheticsUpdateTable
    extends _i1.UpdateTable<EncryptedTemplateAestheticsTable> {
  EncryptedTemplateAestheticsUpdateTable(super.table);

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

class EncryptedTemplateAestheticsTable extends _i1.Table<_i1.UuidValue> {
  EncryptedTemplateAestheticsTable({super.tableRelation})
    : super(tableName: 'encrypted_template_aesthetics') {
    updateTable = EncryptedTemplateAestheticsUpdateTable(this);
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

  late final EncryptedTemplateAestheticsUpdateTable updateTable;

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

class EncryptedTemplateAestheticsInclude extends _i1.IncludeObject {
  EncryptedTemplateAestheticsInclude._();

  @override
  Map<String, _i1.Include?> get includes => {};

  @override
  _i1.Table<_i1.UuidValue> get table => EncryptedTemplateAesthetics.t;
}

class EncryptedTemplateAestheticsIncludeList extends _i1.IncludeList {
  EncryptedTemplateAestheticsIncludeList._({
    _i1.WhereExpressionBuilder<EncryptedTemplateAestheticsTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderDescending,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(EncryptedTemplateAesthetics.t);
  }

  @override
  Map<String, _i1.Include?> get includes => include?.includes ?? {};

  @override
  _i1.Table<_i1.UuidValue> get table => EncryptedTemplateAesthetics.t;
}

class EncryptedTemplateAestheticsRepository {
  const EncryptedTemplateAestheticsRepository._();

  /// Returns a list of [EncryptedTemplateAesthetics]s matching the given query parameters.
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
  Future<List<EncryptedTemplateAesthetics>> find(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<EncryptedTemplateAestheticsTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<EncryptedTemplateAestheticsTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<EncryptedTemplateAestheticsTable>? orderByList,
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<EncryptedTemplateAesthetics>(
      where: where?.call(EncryptedTemplateAesthetics.t),
      orderBy: orderBy?.call(EncryptedTemplateAesthetics.t),
      orderByList: orderByList?.call(EncryptedTemplateAesthetics.t),
      orderDescending: orderDescending,
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [EncryptedTemplateAesthetics] matching the given query parameters.
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
  Future<EncryptedTemplateAesthetics?> findFirstRow(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<EncryptedTemplateAestheticsTable>? where,
    int? offset,
    _i1.OrderByBuilder<EncryptedTemplateAestheticsTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<EncryptedTemplateAestheticsTable>? orderByList,
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<EncryptedTemplateAesthetics>(
      where: where?.call(EncryptedTemplateAesthetics.t),
      orderBy: orderBy?.call(EncryptedTemplateAesthetics.t),
      orderByList: orderByList?.call(EncryptedTemplateAesthetics.t),
      orderDescending: orderDescending,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [EncryptedTemplateAesthetics] by its [id] or null if no such row exists.
  Future<EncryptedTemplateAesthetics?> findById(
    _i1.Session session,
    _i1.UuidValue id, {
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<EncryptedTemplateAesthetics>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [EncryptedTemplateAesthetics]s in the list and returns the inserted rows.
  ///
  /// The returned [EncryptedTemplateAesthetics]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// insert, none of the rows will be inserted.
  ///
  /// If [ignoreConflicts] is set to `true`, rows that conflict with existing
  /// rows are silently skipped, and only the successfully inserted rows are
  /// returned.
  Future<List<EncryptedTemplateAesthetics>> insert(
    _i1.Session session,
    List<EncryptedTemplateAesthetics> rows, {
    _i1.Transaction? transaction,
    bool ignoreConflicts = false,
  }) async {
    return session.db.insert<EncryptedTemplateAesthetics>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
    );
  }

  /// Inserts a single [EncryptedTemplateAesthetics] and returns the inserted row.
  ///
  /// The returned [EncryptedTemplateAesthetics] will have its `id` field set.
  Future<EncryptedTemplateAesthetics> insertRow(
    _i1.Session session,
    EncryptedTemplateAesthetics row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insertRow<EncryptedTemplateAesthetics>(
      row,
      transaction: transaction,
    );
  }

  /// Updates all [EncryptedTemplateAesthetics]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  Future<List<EncryptedTemplateAesthetics>> update(
    _i1.Session session,
    List<EncryptedTemplateAesthetics> rows, {
    _i1.ColumnSelections<EncryptedTemplateAestheticsTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.update<EncryptedTemplateAesthetics>(
      rows,
      columns: columns?.call(EncryptedTemplateAesthetics.t),
      transaction: transaction,
    );
  }

  /// Updates a single [EncryptedTemplateAesthetics]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<EncryptedTemplateAesthetics> updateRow(
    _i1.Session session,
    EncryptedTemplateAesthetics row, {
    _i1.ColumnSelections<EncryptedTemplateAestheticsTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateRow<EncryptedTemplateAesthetics>(
      row,
      columns: columns?.call(EncryptedTemplateAesthetics.t),
      transaction: transaction,
    );
  }

  /// Updates a single [EncryptedTemplateAesthetics] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<EncryptedTemplateAesthetics?> updateById(
    _i1.Session session,
    _i1.UuidValue id, {
    required _i1.ColumnValueListBuilder<EncryptedTemplateAestheticsUpdateTable>
    columnValues,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateById<EncryptedTemplateAesthetics>(
      id,
      columnValues: columnValues(EncryptedTemplateAesthetics.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [EncryptedTemplateAesthetics]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  Future<List<EncryptedTemplateAesthetics>> updateWhere(
    _i1.Session session, {
    required _i1.ColumnValueListBuilder<EncryptedTemplateAestheticsUpdateTable>
    columnValues,
    required _i1.WhereExpressionBuilder<EncryptedTemplateAestheticsTable> where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<EncryptedTemplateAestheticsTable>? orderBy,
    _i1.OrderByListBuilder<EncryptedTemplateAestheticsTable>? orderByList,
    bool orderDescending = false,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateWhere<EncryptedTemplateAesthetics>(
      columnValues: columnValues(EncryptedTemplateAesthetics.t.updateTable),
      where: where(EncryptedTemplateAesthetics.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(EncryptedTemplateAesthetics.t),
      orderByList: orderByList?.call(EncryptedTemplateAesthetics.t),
      orderDescending: orderDescending,
      transaction: transaction,
    );
  }

  /// Deletes all [EncryptedTemplateAesthetics]s in the list and returns the deleted rows.
  /// This is an atomic operation, meaning that if one of the rows fail to
  /// be deleted, none of the rows will be deleted.
  Future<List<EncryptedTemplateAesthetics>> delete(
    _i1.Session session,
    List<EncryptedTemplateAesthetics> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.delete<EncryptedTemplateAesthetics>(
      rows,
      transaction: transaction,
    );
  }

  /// Deletes a single [EncryptedTemplateAesthetics].
  Future<EncryptedTemplateAesthetics> deleteRow(
    _i1.Session session,
    EncryptedTemplateAesthetics row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteRow<EncryptedTemplateAesthetics>(
      row,
      transaction: transaction,
    );
  }

  /// Deletes all rows matching the [where] expression.
  Future<List<EncryptedTemplateAesthetics>> deleteWhere(
    _i1.Session session, {
    required _i1.WhereExpressionBuilder<EncryptedTemplateAestheticsTable> where,
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteWhere<EncryptedTemplateAesthetics>(
      where: where(EncryptedTemplateAesthetics.t),
      transaction: transaction,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<EncryptedTemplateAestheticsTable>? where,
    int? limit,
    _i1.Transaction? transaction,
  }) async {
    return session.db.count<EncryptedTemplateAesthetics>(
      where: where?.call(EncryptedTemplateAesthetics.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [EncryptedTemplateAesthetics] rows matching the [where] expression.
  Future<void> lockRows(
    _i1.Session session, {
    required _i1.WhereExpressionBuilder<EncryptedTemplateAestheticsTable> where,
    required _i1.LockMode lockMode,
    required _i1.Transaction transaction,
    _i1.LockBehavior lockBehavior = _i1.LockBehavior.wait,
  }) async {
    return session.db.lockRows<EncryptedTemplateAesthetics>(
      where: where(EncryptedTemplateAesthetics.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
