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

abstract class EncryptedEntry
    implements _i1.TableRow<_i1.UuidValue>, _i1.ProtocolSerialization {
  EncryptedEntry._({
    _i1.UuidValue? id,
    required this.accountId,
    required this.encryptedData,
    DateTime? updatedAt,
  }) : id = id ?? _i1.Uuid().v4obj(),
       updatedAt = updatedAt ?? DateTime.now();

  factory EncryptedEntry({
    _i1.UuidValue? id,
    required int accountId,
    required String encryptedData,
    DateTime? updatedAt,
  }) = _EncryptedEntryImpl;

  factory EncryptedEntry.fromJson(Map<String, dynamic> jsonSerialization) {
    return EncryptedEntry(
      id: _i1.UuidValueJsonExtension.fromJson(jsonSerialization['id']),
      accountId: jsonSerialization['accountId'] as int,
      encryptedData: jsonSerialization['encryptedData'] as String,
      updatedAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['updatedAt'],
      ),
    );
  }

  static final t = EncryptedEntryTable();

  static const db = EncryptedEntryRepository._();

  @override
  _i1.UuidValue id;

  int accountId;

  String encryptedData;

  DateTime updatedAt;

  @override
  _i1.Table<_i1.UuidValue> get table => t;

  /// Returns a shallow copy of this [EncryptedEntry]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  EncryptedEntry copyWith({
    _i1.UuidValue? id,
    int? accountId,
    String? encryptedData,
    DateTime? updatedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'quanitya.EncryptedEntry',
      'id': id.toJson(),
      'accountId': accountId,
      'encryptedData': encryptedData,
      'updatedAt': updatedAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'quanitya.EncryptedEntry',
      'id': id.toJson(),
      'accountId': accountId,
      'encryptedData': encryptedData,
      'updatedAt': updatedAt.toJson(),
    };
  }

  static EncryptedEntryInclude include() {
    return EncryptedEntryInclude._();
  }

  static EncryptedEntryIncludeList includeList({
    _i1.WhereExpressionBuilder<EncryptedEntryTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<EncryptedEntryTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<EncryptedEntryTable>? orderByList,
    EncryptedEntryInclude? include,
  }) {
    return EncryptedEntryIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(EncryptedEntry.t),
      orderDescending: orderDescending,
      orderByList: orderByList?.call(EncryptedEntry.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _EncryptedEntryImpl extends EncryptedEntry {
  _EncryptedEntryImpl({
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

  /// Returns a shallow copy of this [EncryptedEntry]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  EncryptedEntry copyWith({
    _i1.UuidValue? id,
    int? accountId,
    String? encryptedData,
    DateTime? updatedAt,
  }) {
    return EncryptedEntry(
      id: id ?? this.id,
      accountId: accountId ?? this.accountId,
      encryptedData: encryptedData ?? this.encryptedData,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class EncryptedEntryUpdateTable extends _i1.UpdateTable<EncryptedEntryTable> {
  EncryptedEntryUpdateTable(super.table);

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

class EncryptedEntryTable extends _i1.Table<_i1.UuidValue> {
  EncryptedEntryTable({super.tableRelation})
    : super(tableName: 'encrypted_entries') {
    updateTable = EncryptedEntryUpdateTable(this);
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

  late final EncryptedEntryUpdateTable updateTable;

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

class EncryptedEntryInclude extends _i1.IncludeObject {
  EncryptedEntryInclude._();

  @override
  Map<String, _i1.Include?> get includes => {};

  @override
  _i1.Table<_i1.UuidValue> get table => EncryptedEntry.t;
}

class EncryptedEntryIncludeList extends _i1.IncludeList {
  EncryptedEntryIncludeList._({
    _i1.WhereExpressionBuilder<EncryptedEntryTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderDescending,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(EncryptedEntry.t);
  }

  @override
  Map<String, _i1.Include?> get includes => include?.includes ?? {};

  @override
  _i1.Table<_i1.UuidValue> get table => EncryptedEntry.t;
}

class EncryptedEntryRepository {
  const EncryptedEntryRepository._();

  /// Returns a list of [EncryptedEntry]s matching the given query parameters.
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
  Future<List<EncryptedEntry>> find(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<EncryptedEntryTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<EncryptedEntryTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<EncryptedEntryTable>? orderByList,
    _i1.Transaction? transaction,
  }) async {
    return session.db.find<EncryptedEntry>(
      where: where?.call(EncryptedEntry.t),
      orderBy: orderBy?.call(EncryptedEntry.t),
      orderByList: orderByList?.call(EncryptedEntry.t),
      orderDescending: orderDescending,
      limit: limit,
      offset: offset,
      transaction: transaction,
    );
  }

  /// Returns the first matching [EncryptedEntry] matching the given query parameters.
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
  Future<EncryptedEntry?> findFirstRow(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<EncryptedEntryTable>? where,
    int? offset,
    _i1.OrderByBuilder<EncryptedEntryTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<EncryptedEntryTable>? orderByList,
    _i1.Transaction? transaction,
  }) async {
    return session.db.findFirstRow<EncryptedEntry>(
      where: where?.call(EncryptedEntry.t),
      orderBy: orderBy?.call(EncryptedEntry.t),
      orderByList: orderByList?.call(EncryptedEntry.t),
      orderDescending: orderDescending,
      offset: offset,
      transaction: transaction,
    );
  }

  /// Finds a single [EncryptedEntry] by its [id] or null if no such row exists.
  Future<EncryptedEntry?> findById(
    _i1.Session session,
    _i1.UuidValue id, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.findById<EncryptedEntry>(
      id,
      transaction: transaction,
    );
  }

  /// Inserts all [EncryptedEntry]s in the list and returns the inserted rows.
  ///
  /// The returned [EncryptedEntry]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// insert, none of the rows will be inserted.
  Future<List<EncryptedEntry>> insert(
    _i1.Session session,
    List<EncryptedEntry> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insert<EncryptedEntry>(
      rows,
      transaction: transaction,
    );
  }

  /// Inserts a single [EncryptedEntry] and returns the inserted row.
  ///
  /// The returned [EncryptedEntry] will have its `id` field set.
  Future<EncryptedEntry> insertRow(
    _i1.Session session,
    EncryptedEntry row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insertRow<EncryptedEntry>(
      row,
      transaction: transaction,
    );
  }

  /// Updates all [EncryptedEntry]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  Future<List<EncryptedEntry>> update(
    _i1.Session session,
    List<EncryptedEntry> rows, {
    _i1.ColumnSelections<EncryptedEntryTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.update<EncryptedEntry>(
      rows,
      columns: columns?.call(EncryptedEntry.t),
      transaction: transaction,
    );
  }

  /// Updates a single [EncryptedEntry]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<EncryptedEntry> updateRow(
    _i1.Session session,
    EncryptedEntry row, {
    _i1.ColumnSelections<EncryptedEntryTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateRow<EncryptedEntry>(
      row,
      columns: columns?.call(EncryptedEntry.t),
      transaction: transaction,
    );
  }

  /// Updates a single [EncryptedEntry] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<EncryptedEntry?> updateById(
    _i1.Session session,
    _i1.UuidValue id, {
    required _i1.ColumnValueListBuilder<EncryptedEntryUpdateTable> columnValues,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateById<EncryptedEntry>(
      id,
      columnValues: columnValues(EncryptedEntry.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [EncryptedEntry]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  Future<List<EncryptedEntry>> updateWhere(
    _i1.Session session, {
    required _i1.ColumnValueListBuilder<EncryptedEntryUpdateTable> columnValues,
    required _i1.WhereExpressionBuilder<EncryptedEntryTable> where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<EncryptedEntryTable>? orderBy,
    _i1.OrderByListBuilder<EncryptedEntryTable>? orderByList,
    bool orderDescending = false,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateWhere<EncryptedEntry>(
      columnValues: columnValues(EncryptedEntry.t.updateTable),
      where: where(EncryptedEntry.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(EncryptedEntry.t),
      orderByList: orderByList?.call(EncryptedEntry.t),
      orderDescending: orderDescending,
      transaction: transaction,
    );
  }

  /// Deletes all [EncryptedEntry]s in the list and returns the deleted rows.
  /// This is an atomic operation, meaning that if one of the rows fail to
  /// be deleted, none of the rows will be deleted.
  Future<List<EncryptedEntry>> delete(
    _i1.Session session,
    List<EncryptedEntry> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.delete<EncryptedEntry>(
      rows,
      transaction: transaction,
    );
  }

  /// Deletes a single [EncryptedEntry].
  Future<EncryptedEntry> deleteRow(
    _i1.Session session,
    EncryptedEntry row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteRow<EncryptedEntry>(
      row,
      transaction: transaction,
    );
  }

  /// Deletes all rows matching the [where] expression.
  Future<List<EncryptedEntry>> deleteWhere(
    _i1.Session session, {
    required _i1.WhereExpressionBuilder<EncryptedEntryTable> where,
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteWhere<EncryptedEntry>(
      where: where(EncryptedEntry.t),
      transaction: transaction,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<EncryptedEntryTable>? where,
    int? limit,
    _i1.Transaction? transaction,
  }) async {
    return session.db.count<EncryptedEntry>(
      where: where?.call(EncryptedEntry.t),
      limit: limit,
      transaction: transaction,
    );
  }
}
