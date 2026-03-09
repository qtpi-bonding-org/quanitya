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

/// A notification message for a specific user
abstract class NotificationInbox
    implements _i1.TableRow<int?>, _i1.ProtocolSerialization {
  NotificationInbox._({
    this.id,
    required this.userId,
    required this.title,
    required this.type,
    required this.createdAt,
    this.actionPayload,
  });

  factory NotificationInbox({
    int? id,
    required int userId,
    required String title,
    required String type,
    required DateTime createdAt,
    String? actionPayload,
  }) = _NotificationInboxImpl;

  factory NotificationInbox.fromJson(Map<String, dynamic> jsonSerialization) {
    return NotificationInbox(
      id: jsonSerialization['id'] as int?,
      userId: jsonSerialization['userId'] as int,
      title: jsonSerialization['title'] as String,
      type: jsonSerialization['type'] as String,
      createdAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
      actionPayload: jsonSerialization['actionPayload'] as String?,
    );
  }

  static final t = NotificationInboxTable();

  static const db = NotificationInboxRepository._();

  @override
  int? id;

  /// The ID of the user who should receive this notification
  int userId;

  /// The title/message content of the notification
  String title;

  /// The type of notification (system, report, alert)
  String type;

  /// When the notification was created
  DateTime createdAt;

  /// Optional JSON payload for navigation or actions
  String? actionPayload;

  @override
  _i1.Table<int?> get table => t;

  /// Returns a shallow copy of this [NotificationInbox]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  NotificationInbox copyWith({
    int? id,
    int? userId,
    String? title,
    String? type,
    DateTime? createdAt,
    String? actionPayload,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'quanitya.NotificationInbox',
      if (id != null) 'id': id,
      'userId': userId,
      'title': title,
      'type': type,
      'createdAt': createdAt.toJson(),
      if (actionPayload != null) 'actionPayload': actionPayload,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'quanitya.NotificationInbox',
      if (id != null) 'id': id,
      'userId': userId,
      'title': title,
      'type': type,
      'createdAt': createdAt.toJson(),
      if (actionPayload != null) 'actionPayload': actionPayload,
    };
  }

  static NotificationInboxInclude include() {
    return NotificationInboxInclude._();
  }

  static NotificationInboxIncludeList includeList({
    _i1.WhereExpressionBuilder<NotificationInboxTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<NotificationInboxTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<NotificationInboxTable>? orderByList,
    NotificationInboxInclude? include,
  }) {
    return NotificationInboxIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(NotificationInbox.t),
      orderDescending: orderDescending,
      orderByList: orderByList?.call(NotificationInbox.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _NotificationInboxImpl extends NotificationInbox {
  _NotificationInboxImpl({
    int? id,
    required int userId,
    required String title,
    required String type,
    required DateTime createdAt,
    String? actionPayload,
  }) : super._(
         id: id,
         userId: userId,
         title: title,
         type: type,
         createdAt: createdAt,
         actionPayload: actionPayload,
       );

  /// Returns a shallow copy of this [NotificationInbox]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  NotificationInbox copyWith({
    Object? id = _Undefined,
    int? userId,
    String? title,
    String? type,
    DateTime? createdAt,
    Object? actionPayload = _Undefined,
  }) {
    return NotificationInbox(
      id: id is int? ? id : this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      actionPayload: actionPayload is String?
          ? actionPayload
          : this.actionPayload,
    );
  }
}

class NotificationInboxUpdateTable
    extends _i1.UpdateTable<NotificationInboxTable> {
  NotificationInboxUpdateTable(super.table);

  _i1.ColumnValue<int, int> userId(int value) => _i1.ColumnValue(
    table.userId,
    value,
  );

  _i1.ColumnValue<String, String> title(String value) => _i1.ColumnValue(
    table.title,
    value,
  );

  _i1.ColumnValue<String, String> type(String value) => _i1.ColumnValue(
    table.type,
    value,
  );

  _i1.ColumnValue<DateTime, DateTime> createdAt(DateTime value) =>
      _i1.ColumnValue(
        table.createdAt,
        value,
      );

  _i1.ColumnValue<String, String> actionPayload(String? value) =>
      _i1.ColumnValue(
        table.actionPayload,
        value,
      );
}

class NotificationInboxTable extends _i1.Table<int?> {
  NotificationInboxTable({super.tableRelation})
    : super(tableName: 'notification_inbox') {
    updateTable = NotificationInboxUpdateTable(this);
    userId = _i1.ColumnInt(
      'userId',
      this,
    );
    title = _i1.ColumnString(
      'title',
      this,
    );
    type = _i1.ColumnString(
      'type',
      this,
    );
    createdAt = _i1.ColumnDateTime(
      'createdAt',
      this,
    );
    actionPayload = _i1.ColumnString(
      'actionPayload',
      this,
    );
  }

  late final NotificationInboxUpdateTable updateTable;

  /// The ID of the user who should receive this notification
  late final _i1.ColumnInt userId;

  /// The title/message content of the notification
  late final _i1.ColumnString title;

  /// The type of notification (system, report, alert)
  late final _i1.ColumnString type;

  /// When the notification was created
  late final _i1.ColumnDateTime createdAt;

  /// Optional JSON payload for navigation or actions
  late final _i1.ColumnString actionPayload;

  @override
  List<_i1.Column> get columns => [
    id,
    userId,
    title,
    type,
    createdAt,
    actionPayload,
  ];
}

class NotificationInboxInclude extends _i1.IncludeObject {
  NotificationInboxInclude._();

  @override
  Map<String, _i1.Include?> get includes => {};

  @override
  _i1.Table<int?> get table => NotificationInbox.t;
}

class NotificationInboxIncludeList extends _i1.IncludeList {
  NotificationInboxIncludeList._({
    _i1.WhereExpressionBuilder<NotificationInboxTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderDescending,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(NotificationInbox.t);
  }

  @override
  Map<String, _i1.Include?> get includes => include?.includes ?? {};

  @override
  _i1.Table<int?> get table => NotificationInbox.t;
}

class NotificationInboxRepository {
  const NotificationInboxRepository._();

  /// Returns a list of [NotificationInbox]s matching the given query parameters.
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
  Future<List<NotificationInbox>> find(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<NotificationInboxTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<NotificationInboxTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<NotificationInboxTable>? orderByList,
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<NotificationInbox>(
      where: where?.call(NotificationInbox.t),
      orderBy: orderBy?.call(NotificationInbox.t),
      orderByList: orderByList?.call(NotificationInbox.t),
      orderDescending: orderDescending,
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [NotificationInbox] matching the given query parameters.
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
  Future<NotificationInbox?> findFirstRow(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<NotificationInboxTable>? where,
    int? offset,
    _i1.OrderByBuilder<NotificationInboxTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<NotificationInboxTable>? orderByList,
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<NotificationInbox>(
      where: where?.call(NotificationInbox.t),
      orderBy: orderBy?.call(NotificationInbox.t),
      orderByList: orderByList?.call(NotificationInbox.t),
      orderDescending: orderDescending,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [NotificationInbox] by its [id] or null if no such row exists.
  Future<NotificationInbox?> findById(
    _i1.Session session,
    int id, {
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<NotificationInbox>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [NotificationInbox]s in the list and returns the inserted rows.
  ///
  /// The returned [NotificationInbox]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// insert, none of the rows will be inserted.
  ///
  /// If [ignoreConflicts] is set to `true`, rows that conflict with existing
  /// rows are silently skipped, and only the successfully inserted rows are
  /// returned.
  Future<List<NotificationInbox>> insert(
    _i1.Session session,
    List<NotificationInbox> rows, {
    _i1.Transaction? transaction,
    bool ignoreConflicts = false,
  }) async {
    return session.db.insert<NotificationInbox>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
    );
  }

  /// Inserts a single [NotificationInbox] and returns the inserted row.
  ///
  /// The returned [NotificationInbox] will have its `id` field set.
  Future<NotificationInbox> insertRow(
    _i1.Session session,
    NotificationInbox row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insertRow<NotificationInbox>(
      row,
      transaction: transaction,
    );
  }

  /// Updates all [NotificationInbox]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  Future<List<NotificationInbox>> update(
    _i1.Session session,
    List<NotificationInbox> rows, {
    _i1.ColumnSelections<NotificationInboxTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.update<NotificationInbox>(
      rows,
      columns: columns?.call(NotificationInbox.t),
      transaction: transaction,
    );
  }

  /// Updates a single [NotificationInbox]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<NotificationInbox> updateRow(
    _i1.Session session,
    NotificationInbox row, {
    _i1.ColumnSelections<NotificationInboxTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateRow<NotificationInbox>(
      row,
      columns: columns?.call(NotificationInbox.t),
      transaction: transaction,
    );
  }

  /// Updates a single [NotificationInbox] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<NotificationInbox?> updateById(
    _i1.Session session,
    int id, {
    required _i1.ColumnValueListBuilder<NotificationInboxUpdateTable>
    columnValues,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateById<NotificationInbox>(
      id,
      columnValues: columnValues(NotificationInbox.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [NotificationInbox]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  Future<List<NotificationInbox>> updateWhere(
    _i1.Session session, {
    required _i1.ColumnValueListBuilder<NotificationInboxUpdateTable>
    columnValues,
    required _i1.WhereExpressionBuilder<NotificationInboxTable> where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<NotificationInboxTable>? orderBy,
    _i1.OrderByListBuilder<NotificationInboxTable>? orderByList,
    bool orderDescending = false,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateWhere<NotificationInbox>(
      columnValues: columnValues(NotificationInbox.t.updateTable),
      where: where(NotificationInbox.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(NotificationInbox.t),
      orderByList: orderByList?.call(NotificationInbox.t),
      orderDescending: orderDescending,
      transaction: transaction,
    );
  }

  /// Deletes all [NotificationInbox]s in the list and returns the deleted rows.
  /// This is an atomic operation, meaning that if one of the rows fail to
  /// be deleted, none of the rows will be deleted.
  Future<List<NotificationInbox>> delete(
    _i1.Session session,
    List<NotificationInbox> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.delete<NotificationInbox>(
      rows,
      transaction: transaction,
    );
  }

  /// Deletes a single [NotificationInbox].
  Future<NotificationInbox> deleteRow(
    _i1.Session session,
    NotificationInbox row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteRow<NotificationInbox>(
      row,
      transaction: transaction,
    );
  }

  /// Deletes all rows matching the [where] expression.
  Future<List<NotificationInbox>> deleteWhere(
    _i1.Session session, {
    required _i1.WhereExpressionBuilder<NotificationInboxTable> where,
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteWhere<NotificationInbox>(
      where: where(NotificationInbox.t),
      transaction: transaction,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<NotificationInboxTable>? where,
    int? limit,
    _i1.Transaction? transaction,
  }) async {
    return session.db.count<NotificationInbox>(
      where: where?.call(NotificationInbox.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [NotificationInbox] rows matching the [where] expression.
  Future<void> lockRows(
    _i1.Session session, {
    required _i1.WhereExpressionBuilder<NotificationInboxTable> where,
    required _i1.LockMode lockMode,
    required _i1.Transaction transaction,
    _i1.LockBehavior lockBehavior = _i1.LockBehavior.wait,
  }) async {
    return session.db.lockRows<NotificationInbox>(
      where: where(NotificationInbox.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
