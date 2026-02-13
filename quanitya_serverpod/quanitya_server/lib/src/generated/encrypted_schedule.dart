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

abstract class EncryptedSchedule
    implements _i1.TableRow<_i1.UuidValue>, _i1.ProtocolSerialization {
  EncryptedSchedule._({
    _i1.UuidValue? id,
    required this.accountId,
    required this.encryptedData,
    DateTime? updatedAt,
  }) : id = id ?? const _i1.Uuid().v4obj(),
       updatedAt = updatedAt ?? DateTime.now();

  factory EncryptedSchedule({
    _i1.UuidValue? id,
    required int accountId,
    required String encryptedData,
    DateTime? updatedAt,
  }) = _EncryptedScheduleImpl;

  factory EncryptedSchedule.fromJson(Map<String, dynamic> jsonSerialization) {
    return EncryptedSchedule(
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

  static final t = EncryptedScheduleTable();

  static const db = EncryptedScheduleRepository._();

  @override
  _i1.UuidValue id;

  int accountId;

  String encryptedData;

  DateTime updatedAt;

  @override
  _i1.Table<_i1.UuidValue> get table => t;

  /// Returns a shallow copy of this [EncryptedSchedule]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  EncryptedSchedule copyWith({
    _i1.UuidValue? id,
    int? accountId,
    String? encryptedData,
    DateTime? updatedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'quanitya.EncryptedSchedule',
      'id': id.toJson(),
      'accountId': accountId,
      'encryptedData': encryptedData,
      'updatedAt': updatedAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'quanitya.EncryptedSchedule',
      'id': id.toJson(),
      'accountId': accountId,
      'encryptedData': encryptedData,
      'updatedAt': updatedAt.toJson(),
    };
  }

  static EncryptedScheduleInclude include() {
    return EncryptedScheduleInclude._();
  }

  static EncryptedScheduleIncludeList includeList({
    _i1.WhereExpressionBuilder<EncryptedScheduleTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<EncryptedScheduleTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<EncryptedScheduleTable>? orderByList,
    EncryptedScheduleInclude? include,
  }) {
    return EncryptedScheduleIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(EncryptedSchedule.t),
      orderDescending: orderDescending,
      orderByList: orderByList?.call(EncryptedSchedule.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _EncryptedScheduleImpl extends EncryptedSchedule {
  _EncryptedScheduleImpl({
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

  /// Returns a shallow copy of this [EncryptedSchedule]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  EncryptedSchedule copyWith({
    _i1.UuidValue? id,
    int? accountId,
    String? encryptedData,
    DateTime? updatedAt,
  }) {
    return EncryptedSchedule(
      id: id ?? this.id,
      accountId: accountId ?? this.accountId,
      encryptedData: encryptedData ?? this.encryptedData,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class EncryptedScheduleUpdateTable
    extends _i1.UpdateTable<EncryptedScheduleTable> {
  EncryptedScheduleUpdateTable(super.table);

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

class EncryptedScheduleTable extends _i1.Table<_i1.UuidValue> {
  EncryptedScheduleTable({super.tableRelation})
    : super(tableName: 'encrypted_schedules') {
    updateTable = EncryptedScheduleUpdateTable(this);
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

  late final EncryptedScheduleUpdateTable updateTable;

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

class EncryptedScheduleInclude extends _i1.IncludeObject {
  EncryptedScheduleInclude._();

  @override
  Map<String, _i1.Include?> get includes => {};

  @override
  _i1.Table<_i1.UuidValue> get table => EncryptedSchedule.t;
}

class EncryptedScheduleIncludeList extends _i1.IncludeList {
  EncryptedScheduleIncludeList._({
    _i1.WhereExpressionBuilder<EncryptedScheduleTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderDescending,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(EncryptedSchedule.t);
  }

  @override
  Map<String, _i1.Include?> get includes => include?.includes ?? {};

  @override
  _i1.Table<_i1.UuidValue> get table => EncryptedSchedule.t;
}

class EncryptedScheduleRepository {
  const EncryptedScheduleRepository._();

  /// Returns a list of [EncryptedSchedule]s matching the given query parameters.
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
  Future<List<EncryptedSchedule>> find(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<EncryptedScheduleTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<EncryptedScheduleTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<EncryptedScheduleTable>? orderByList,
    _i1.Transaction? transaction,
  }) async {
    return session.db.find<EncryptedSchedule>(
      where: where?.call(EncryptedSchedule.t),
      orderBy: orderBy?.call(EncryptedSchedule.t),
      orderByList: orderByList?.call(EncryptedSchedule.t),
      orderDescending: orderDescending,
      limit: limit,
      offset: offset,
      transaction: transaction,
    );
  }

  /// Returns the first matching [EncryptedSchedule] matching the given query parameters.
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
  Future<EncryptedSchedule?> findFirstRow(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<EncryptedScheduleTable>? where,
    int? offset,
    _i1.OrderByBuilder<EncryptedScheduleTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<EncryptedScheduleTable>? orderByList,
    _i1.Transaction? transaction,
  }) async {
    return session.db.findFirstRow<EncryptedSchedule>(
      where: where?.call(EncryptedSchedule.t),
      orderBy: orderBy?.call(EncryptedSchedule.t),
      orderByList: orderByList?.call(EncryptedSchedule.t),
      orderDescending: orderDescending,
      offset: offset,
      transaction: transaction,
    );
  }

  /// Finds a single [EncryptedSchedule] by its [id] or null if no such row exists.
  Future<EncryptedSchedule?> findById(
    _i1.Session session,
    _i1.UuidValue id, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.findById<EncryptedSchedule>(
      id,
      transaction: transaction,
    );
  }

  /// Inserts all [EncryptedSchedule]s in the list and returns the inserted rows.
  ///
  /// The returned [EncryptedSchedule]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// insert, none of the rows will be inserted.
  Future<List<EncryptedSchedule>> insert(
    _i1.Session session,
    List<EncryptedSchedule> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insert<EncryptedSchedule>(
      rows,
      transaction: transaction,
    );
  }

  /// Inserts a single [EncryptedSchedule] and returns the inserted row.
  ///
  /// The returned [EncryptedSchedule] will have its `id` field set.
  Future<EncryptedSchedule> insertRow(
    _i1.Session session,
    EncryptedSchedule row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insertRow<EncryptedSchedule>(
      row,
      transaction: transaction,
    );
  }

  /// Updates all [EncryptedSchedule]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  Future<List<EncryptedSchedule>> update(
    _i1.Session session,
    List<EncryptedSchedule> rows, {
    _i1.ColumnSelections<EncryptedScheduleTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.update<EncryptedSchedule>(
      rows,
      columns: columns?.call(EncryptedSchedule.t),
      transaction: transaction,
    );
  }

  /// Updates a single [EncryptedSchedule]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<EncryptedSchedule> updateRow(
    _i1.Session session,
    EncryptedSchedule row, {
    _i1.ColumnSelections<EncryptedScheduleTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateRow<EncryptedSchedule>(
      row,
      columns: columns?.call(EncryptedSchedule.t),
      transaction: transaction,
    );
  }

  /// Updates a single [EncryptedSchedule] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<EncryptedSchedule?> updateById(
    _i1.Session session,
    _i1.UuidValue id, {
    required _i1.ColumnValueListBuilder<EncryptedScheduleUpdateTable>
    columnValues,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateById<EncryptedSchedule>(
      id,
      columnValues: columnValues(EncryptedSchedule.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [EncryptedSchedule]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  Future<List<EncryptedSchedule>> updateWhere(
    _i1.Session session, {
    required _i1.ColumnValueListBuilder<EncryptedScheduleUpdateTable>
    columnValues,
    required _i1.WhereExpressionBuilder<EncryptedScheduleTable> where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<EncryptedScheduleTable>? orderBy,
    _i1.OrderByListBuilder<EncryptedScheduleTable>? orderByList,
    bool orderDescending = false,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateWhere<EncryptedSchedule>(
      columnValues: columnValues(EncryptedSchedule.t.updateTable),
      where: where(EncryptedSchedule.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(EncryptedSchedule.t),
      orderByList: orderByList?.call(EncryptedSchedule.t),
      orderDescending: orderDescending,
      transaction: transaction,
    );
  }

  /// Deletes all [EncryptedSchedule]s in the list and returns the deleted rows.
  /// This is an atomic operation, meaning that if one of the rows fail to
  /// be deleted, none of the rows will be deleted.
  Future<List<EncryptedSchedule>> delete(
    _i1.Session session,
    List<EncryptedSchedule> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.delete<EncryptedSchedule>(
      rows,
      transaction: transaction,
    );
  }

  /// Deletes a single [EncryptedSchedule].
  Future<EncryptedSchedule> deleteRow(
    _i1.Session session,
    EncryptedSchedule row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteRow<EncryptedSchedule>(
      row,
      transaction: transaction,
    );
  }

  /// Deletes all rows matching the [where] expression.
  Future<List<EncryptedSchedule>> deleteWhere(
    _i1.Session session, {
    required _i1.WhereExpressionBuilder<EncryptedScheduleTable> where,
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteWhere<EncryptedSchedule>(
      where: where(EncryptedSchedule.t),
      transaction: transaction,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<EncryptedScheduleTable>? where,
    int? limit,
    _i1.Transaction? transaction,
  }) async {
    return session.db.count<EncryptedSchedule>(
      where: where?.call(EncryptedSchedule.t),
      limit: limit,
      transaction: transaction,
    );
  }
}
