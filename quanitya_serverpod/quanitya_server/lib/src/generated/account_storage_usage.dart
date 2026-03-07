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

abstract class AccountStorageUsage
    implements _i1.TableRow<int?>, _i1.ProtocolSerialization {
  AccountStorageUsage._({
    this.id,
    required this.accountId,
    required this.bytesUsed,
    required this.rowCount,
    required this.bytesLimit,
    DateTime? updatedAt,
  }) : updatedAt = updatedAt ?? DateTime.now();

  factory AccountStorageUsage({
    int? id,
    required int accountId,
    required int bytesUsed,
    required int rowCount,
    required int bytesLimit,
    DateTime? updatedAt,
  }) = _AccountStorageUsageImpl;

  factory AccountStorageUsage.fromJson(Map<String, dynamic> jsonSerialization) {
    return AccountStorageUsage(
      id: jsonSerialization['id'] as int?,
      accountId: jsonSerialization['accountId'] as int,
      bytesUsed: jsonSerialization['bytesUsed'] as int,
      rowCount: jsonSerialization['rowCount'] as int,
      bytesLimit: jsonSerialization['bytesLimit'] as int,
      updatedAt: jsonSerialization['updatedAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(jsonSerialization['updatedAt']),
    );
  }

  static final t = AccountStorageUsageTable();

  static const db = AccountStorageUsageRepository._();

  @override
  int? id;

  int accountId;

  int bytesUsed;

  int rowCount;

  int bytesLimit;

  DateTime updatedAt;

  @override
  _i1.Table<int?> get table => t;

  /// Returns a shallow copy of this [AccountStorageUsage]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  AccountStorageUsage copyWith({
    int? id,
    int? accountId,
    int? bytesUsed,
    int? rowCount,
    int? bytesLimit,
    DateTime? updatedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'quanitya.AccountStorageUsage',
      if (id != null) 'id': id,
      'accountId': accountId,
      'bytesUsed': bytesUsed,
      'rowCount': rowCount,
      'bytesLimit': bytesLimit,
      'updatedAt': updatedAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'quanitya.AccountStorageUsage',
      if (id != null) 'id': id,
      'accountId': accountId,
      'bytesUsed': bytesUsed,
      'rowCount': rowCount,
      'bytesLimit': bytesLimit,
      'updatedAt': updatedAt.toJson(),
    };
  }

  static AccountStorageUsageInclude include() {
    return AccountStorageUsageInclude._();
  }

  static AccountStorageUsageIncludeList includeList({
    _i1.WhereExpressionBuilder<AccountStorageUsageTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<AccountStorageUsageTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<AccountStorageUsageTable>? orderByList,
    AccountStorageUsageInclude? include,
  }) {
    return AccountStorageUsageIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(AccountStorageUsage.t),
      orderDescending: orderDescending,
      orderByList: orderByList?.call(AccountStorageUsage.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _AccountStorageUsageImpl extends AccountStorageUsage {
  _AccountStorageUsageImpl({
    int? id,
    required int accountId,
    required int bytesUsed,
    required int rowCount,
    required int bytesLimit,
    DateTime? updatedAt,
  }) : super._(
         id: id,
         accountId: accountId,
         bytesUsed: bytesUsed,
         rowCount: rowCount,
         bytesLimit: bytesLimit,
         updatedAt: updatedAt,
       );

  /// Returns a shallow copy of this [AccountStorageUsage]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  AccountStorageUsage copyWith({
    Object? id = _Undefined,
    int? accountId,
    int? bytesUsed,
    int? rowCount,
    int? bytesLimit,
    DateTime? updatedAt,
  }) {
    return AccountStorageUsage(
      id: id is int? ? id : this.id,
      accountId: accountId ?? this.accountId,
      bytesUsed: bytesUsed ?? this.bytesUsed,
      rowCount: rowCount ?? this.rowCount,
      bytesLimit: bytesLimit ?? this.bytesLimit,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class AccountStorageUsageUpdateTable
    extends _i1.UpdateTable<AccountStorageUsageTable> {
  AccountStorageUsageUpdateTable(super.table);

  _i1.ColumnValue<int, int> accountId(int value) => _i1.ColumnValue(
    table.accountId,
    value,
  );

  _i1.ColumnValue<int, int> bytesUsed(int value) => _i1.ColumnValue(
    table.bytesUsed,
    value,
  );

  _i1.ColumnValue<int, int> rowCount(int value) => _i1.ColumnValue(
    table.rowCount,
    value,
  );

  _i1.ColumnValue<int, int> bytesLimit(int value) => _i1.ColumnValue(
    table.bytesLimit,
    value,
  );

  _i1.ColumnValue<DateTime, DateTime> updatedAt(DateTime value) =>
      _i1.ColumnValue(
        table.updatedAt,
        value,
      );
}

class AccountStorageUsageTable extends _i1.Table<int?> {
  AccountStorageUsageTable({super.tableRelation})
    : super(tableName: 'account_storage_usage') {
    updateTable = AccountStorageUsageUpdateTable(this);
    accountId = _i1.ColumnInt(
      'accountId',
      this,
    );
    bytesUsed = _i1.ColumnInt(
      'bytesUsed',
      this,
    );
    rowCount = _i1.ColumnInt(
      'rowCount',
      this,
    );
    bytesLimit = _i1.ColumnInt(
      'bytesLimit',
      this,
    );
    updatedAt = _i1.ColumnDateTime(
      'updatedAt',
      this,
      hasDefault: true,
    );
  }

  late final AccountStorageUsageUpdateTable updateTable;

  late final _i1.ColumnInt accountId;

  late final _i1.ColumnInt bytesUsed;

  late final _i1.ColumnInt rowCount;

  late final _i1.ColumnInt bytesLimit;

  late final _i1.ColumnDateTime updatedAt;

  @override
  List<_i1.Column> get columns => [
    id,
    accountId,
    bytesUsed,
    rowCount,
    bytesLimit,
    updatedAt,
  ];
}

class AccountStorageUsageInclude extends _i1.IncludeObject {
  AccountStorageUsageInclude._();

  @override
  Map<String, _i1.Include?> get includes => {};

  @override
  _i1.Table<int?> get table => AccountStorageUsage.t;
}

class AccountStorageUsageIncludeList extends _i1.IncludeList {
  AccountStorageUsageIncludeList._({
    _i1.WhereExpressionBuilder<AccountStorageUsageTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderDescending,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(AccountStorageUsage.t);
  }

  @override
  Map<String, _i1.Include?> get includes => include?.includes ?? {};

  @override
  _i1.Table<int?> get table => AccountStorageUsage.t;
}

class AccountStorageUsageRepository {
  const AccountStorageUsageRepository._();

  /// Returns a list of [AccountStorageUsage]s matching the given query parameters.
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
  Future<List<AccountStorageUsage>> find(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<AccountStorageUsageTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<AccountStorageUsageTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<AccountStorageUsageTable>? orderByList,
    _i1.Transaction? transaction,
  }) async {
    return session.db.find<AccountStorageUsage>(
      where: where?.call(AccountStorageUsage.t),
      orderBy: orderBy?.call(AccountStorageUsage.t),
      orderByList: orderByList?.call(AccountStorageUsage.t),
      orderDescending: orderDescending,
      limit: limit,
      offset: offset,
      transaction: transaction,
    );
  }

  /// Returns the first matching [AccountStorageUsage] matching the given query parameters.
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
  Future<AccountStorageUsage?> findFirstRow(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<AccountStorageUsageTable>? where,
    int? offset,
    _i1.OrderByBuilder<AccountStorageUsageTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<AccountStorageUsageTable>? orderByList,
    _i1.Transaction? transaction,
  }) async {
    return session.db.findFirstRow<AccountStorageUsage>(
      where: where?.call(AccountStorageUsage.t),
      orderBy: orderBy?.call(AccountStorageUsage.t),
      orderByList: orderByList?.call(AccountStorageUsage.t),
      orderDescending: orderDescending,
      offset: offset,
      transaction: transaction,
    );
  }

  /// Finds a single [AccountStorageUsage] by its [id] or null if no such row exists.
  Future<AccountStorageUsage?> findById(
    _i1.Session session,
    int id, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.findById<AccountStorageUsage>(
      id,
      transaction: transaction,
    );
  }

  /// Inserts all [AccountStorageUsage]s in the list and returns the inserted rows.
  ///
  /// The returned [AccountStorageUsage]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// insert, none of the rows will be inserted.
  Future<List<AccountStorageUsage>> insert(
    _i1.Session session,
    List<AccountStorageUsage> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insert<AccountStorageUsage>(
      rows,
      transaction: transaction,
    );
  }

  /// Inserts a single [AccountStorageUsage] and returns the inserted row.
  ///
  /// The returned [AccountStorageUsage] will have its `id` field set.
  Future<AccountStorageUsage> insertRow(
    _i1.Session session,
    AccountStorageUsage row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insertRow<AccountStorageUsage>(
      row,
      transaction: transaction,
    );
  }

  /// Updates all [AccountStorageUsage]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  Future<List<AccountStorageUsage>> update(
    _i1.Session session,
    List<AccountStorageUsage> rows, {
    _i1.ColumnSelections<AccountStorageUsageTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.update<AccountStorageUsage>(
      rows,
      columns: columns?.call(AccountStorageUsage.t),
      transaction: transaction,
    );
  }

  /// Updates a single [AccountStorageUsage]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<AccountStorageUsage> updateRow(
    _i1.Session session,
    AccountStorageUsage row, {
    _i1.ColumnSelections<AccountStorageUsageTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateRow<AccountStorageUsage>(
      row,
      columns: columns?.call(AccountStorageUsage.t),
      transaction: transaction,
    );
  }

  /// Updates a single [AccountStorageUsage] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<AccountStorageUsage?> updateById(
    _i1.Session session,
    int id, {
    required _i1.ColumnValueListBuilder<AccountStorageUsageUpdateTable>
    columnValues,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateById<AccountStorageUsage>(
      id,
      columnValues: columnValues(AccountStorageUsage.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [AccountStorageUsage]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  Future<List<AccountStorageUsage>> updateWhere(
    _i1.Session session, {
    required _i1.ColumnValueListBuilder<AccountStorageUsageUpdateTable>
    columnValues,
    required _i1.WhereExpressionBuilder<AccountStorageUsageTable> where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<AccountStorageUsageTable>? orderBy,
    _i1.OrderByListBuilder<AccountStorageUsageTable>? orderByList,
    bool orderDescending = false,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateWhere<AccountStorageUsage>(
      columnValues: columnValues(AccountStorageUsage.t.updateTable),
      where: where(AccountStorageUsage.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(AccountStorageUsage.t),
      orderByList: orderByList?.call(AccountStorageUsage.t),
      orderDescending: orderDescending,
      transaction: transaction,
    );
  }

  /// Deletes all [AccountStorageUsage]s in the list and returns the deleted rows.
  /// This is an atomic operation, meaning that if one of the rows fail to
  /// be deleted, none of the rows will be deleted.
  Future<List<AccountStorageUsage>> delete(
    _i1.Session session,
    List<AccountStorageUsage> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.delete<AccountStorageUsage>(
      rows,
      transaction: transaction,
    );
  }

  /// Deletes a single [AccountStorageUsage].
  Future<AccountStorageUsage> deleteRow(
    _i1.Session session,
    AccountStorageUsage row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteRow<AccountStorageUsage>(
      row,
      transaction: transaction,
    );
  }

  /// Deletes all rows matching the [where] expression.
  Future<List<AccountStorageUsage>> deleteWhere(
    _i1.Session session, {
    required _i1.WhereExpressionBuilder<AccountStorageUsageTable> where,
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteWhere<AccountStorageUsage>(
      where: where(AccountStorageUsage.t),
      transaction: transaction,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<AccountStorageUsageTable>? where,
    int? limit,
    _i1.Transaction? transaction,
  }) async {
    return session.db.count<AccountStorageUsage>(
      where: where?.call(AccountStorageUsage.t),
      limit: limit,
      transaction: transaction,
    );
  }
}
