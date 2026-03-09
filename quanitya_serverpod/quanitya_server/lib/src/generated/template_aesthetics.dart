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

abstract class TemplateAesthetics
    implements _i1.TableRow<_i1.UuidValue>, _i1.ProtocolSerialization {
  TemplateAesthetics._({
    _i1.UuidValue? id,
    required this.accountId,
    required this.templateId,
    this.themeName,
    this.icon,
    this.emoji,
    this.paletteJson,
    this.fontConfigJson,
    this.colorMappingsJson,
    DateTime? updatedAt,
  }) : id = id ?? const _i1.Uuid().v4obj(),
       updatedAt = updatedAt ?? DateTime.now();

  factory TemplateAesthetics({
    _i1.UuidValue? id,
    required int accountId,
    required String templateId,
    String? themeName,
    String? icon,
    String? emoji,
    String? paletteJson,
    String? fontConfigJson,
    String? colorMappingsJson,
    DateTime? updatedAt,
  }) = _TemplateAestheticsImpl;

  factory TemplateAesthetics.fromJson(Map<String, dynamic> jsonSerialization) {
    return TemplateAesthetics(
      id: jsonSerialization['id'] == null
          ? null
          : _i1.UuidValueJsonExtension.fromJson(jsonSerialization['id']),
      accountId: jsonSerialization['accountId'] as int,
      templateId: jsonSerialization['templateId'] as String,
      themeName: jsonSerialization['themeName'] as String?,
      icon: jsonSerialization['icon'] as String?,
      emoji: jsonSerialization['emoji'] as String?,
      paletteJson: jsonSerialization['paletteJson'] as String?,
      fontConfigJson: jsonSerialization['fontConfigJson'] as String?,
      colorMappingsJson: jsonSerialization['colorMappingsJson'] as String?,
      updatedAt: jsonSerialization['updatedAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(jsonSerialization['updatedAt']),
    );
  }

  static final t = TemplateAestheticsTable();

  static const db = TemplateAestheticsRepository._();

  @override
  _i1.UuidValue id;

  int accountId;

  String templateId;

  String? themeName;

  String? icon;

  String? emoji;

  String? paletteJson;

  String? fontConfigJson;

  String? colorMappingsJson;

  DateTime updatedAt;

  @override
  _i1.Table<_i1.UuidValue> get table => t;

  /// Returns a shallow copy of this [TemplateAesthetics]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  TemplateAesthetics copyWith({
    _i1.UuidValue? id,
    int? accountId,
    String? templateId,
    String? themeName,
    String? icon,
    String? emoji,
    String? paletteJson,
    String? fontConfigJson,
    String? colorMappingsJson,
    DateTime? updatedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'quanitya.TemplateAesthetics',
      'id': id.toJson(),
      'accountId': accountId,
      'templateId': templateId,
      if (themeName != null) 'themeName': themeName,
      if (icon != null) 'icon': icon,
      if (emoji != null) 'emoji': emoji,
      if (paletteJson != null) 'paletteJson': paletteJson,
      if (fontConfigJson != null) 'fontConfigJson': fontConfigJson,
      if (colorMappingsJson != null) 'colorMappingsJson': colorMappingsJson,
      'updatedAt': updatedAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'quanitya.TemplateAesthetics',
      'id': id.toJson(),
      'accountId': accountId,
      'templateId': templateId,
      if (themeName != null) 'themeName': themeName,
      if (icon != null) 'icon': icon,
      if (emoji != null) 'emoji': emoji,
      if (paletteJson != null) 'paletteJson': paletteJson,
      if (fontConfigJson != null) 'fontConfigJson': fontConfigJson,
      if (colorMappingsJson != null) 'colorMappingsJson': colorMappingsJson,
      'updatedAt': updatedAt.toJson(),
    };
  }

  static TemplateAestheticsInclude include() {
    return TemplateAestheticsInclude._();
  }

  static TemplateAestheticsIncludeList includeList({
    _i1.WhereExpressionBuilder<TemplateAestheticsTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<TemplateAestheticsTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<TemplateAestheticsTable>? orderByList,
    TemplateAestheticsInclude? include,
  }) {
    return TemplateAestheticsIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(TemplateAesthetics.t),
      orderDescending: orderDescending,
      orderByList: orderByList?.call(TemplateAesthetics.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _TemplateAestheticsImpl extends TemplateAesthetics {
  _TemplateAestheticsImpl({
    _i1.UuidValue? id,
    required int accountId,
    required String templateId,
    String? themeName,
    String? icon,
    String? emoji,
    String? paletteJson,
    String? fontConfigJson,
    String? colorMappingsJson,
    DateTime? updatedAt,
  }) : super._(
         id: id,
         accountId: accountId,
         templateId: templateId,
         themeName: themeName,
         icon: icon,
         emoji: emoji,
         paletteJson: paletteJson,
         fontConfigJson: fontConfigJson,
         colorMappingsJson: colorMappingsJson,
         updatedAt: updatedAt,
       );

  /// Returns a shallow copy of this [TemplateAesthetics]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  TemplateAesthetics copyWith({
    _i1.UuidValue? id,
    int? accountId,
    String? templateId,
    Object? themeName = _Undefined,
    Object? icon = _Undefined,
    Object? emoji = _Undefined,
    Object? paletteJson = _Undefined,
    Object? fontConfigJson = _Undefined,
    Object? colorMappingsJson = _Undefined,
    DateTime? updatedAt,
  }) {
    return TemplateAesthetics(
      id: id ?? this.id,
      accountId: accountId ?? this.accountId,
      templateId: templateId ?? this.templateId,
      themeName: themeName is String? ? themeName : this.themeName,
      icon: icon is String? ? icon : this.icon,
      emoji: emoji is String? ? emoji : this.emoji,
      paletteJson: paletteJson is String? ? paletteJson : this.paletteJson,
      fontConfigJson: fontConfigJson is String?
          ? fontConfigJson
          : this.fontConfigJson,
      colorMappingsJson: colorMappingsJson is String?
          ? colorMappingsJson
          : this.colorMappingsJson,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class TemplateAestheticsUpdateTable
    extends _i1.UpdateTable<TemplateAestheticsTable> {
  TemplateAestheticsUpdateTable(super.table);

  _i1.ColumnValue<int, int> accountId(int value) => _i1.ColumnValue(
    table.accountId,
    value,
  );

  _i1.ColumnValue<String, String> templateId(String value) => _i1.ColumnValue(
    table.templateId,
    value,
  );

  _i1.ColumnValue<String, String> themeName(String? value) => _i1.ColumnValue(
    table.themeName,
    value,
  );

  _i1.ColumnValue<String, String> icon(String? value) => _i1.ColumnValue(
    table.icon,
    value,
  );

  _i1.ColumnValue<String, String> emoji(String? value) => _i1.ColumnValue(
    table.emoji,
    value,
  );

  _i1.ColumnValue<String, String> paletteJson(String? value) => _i1.ColumnValue(
    table.paletteJson,
    value,
  );

  _i1.ColumnValue<String, String> fontConfigJson(String? value) =>
      _i1.ColumnValue(
        table.fontConfigJson,
        value,
      );

  _i1.ColumnValue<String, String> colorMappingsJson(String? value) =>
      _i1.ColumnValue(
        table.colorMappingsJson,
        value,
      );

  _i1.ColumnValue<DateTime, DateTime> updatedAt(DateTime value) =>
      _i1.ColumnValue(
        table.updatedAt,
        value,
      );
}

class TemplateAestheticsTable extends _i1.Table<_i1.UuidValue> {
  TemplateAestheticsTable({super.tableRelation})
    : super(tableName: 'template_aesthetics') {
    updateTable = TemplateAestheticsUpdateTable(this);
    accountId = _i1.ColumnInt(
      'accountId',
      this,
    );
    templateId = _i1.ColumnString(
      'templateId',
      this,
    );
    themeName = _i1.ColumnString(
      'themeName',
      this,
    );
    icon = _i1.ColumnString(
      'icon',
      this,
    );
    emoji = _i1.ColumnString(
      'emoji',
      this,
    );
    paletteJson = _i1.ColumnString(
      'paletteJson',
      this,
    );
    fontConfigJson = _i1.ColumnString(
      'fontConfigJson',
      this,
    );
    colorMappingsJson = _i1.ColumnString(
      'colorMappingsJson',
      this,
    );
    updatedAt = _i1.ColumnDateTime(
      'updatedAt',
      this,
      hasDefault: true,
    );
  }

  late final TemplateAestheticsUpdateTable updateTable;

  late final _i1.ColumnInt accountId;

  late final _i1.ColumnString templateId;

  late final _i1.ColumnString themeName;

  late final _i1.ColumnString icon;

  late final _i1.ColumnString emoji;

  late final _i1.ColumnString paletteJson;

  late final _i1.ColumnString fontConfigJson;

  late final _i1.ColumnString colorMappingsJson;

  late final _i1.ColumnDateTime updatedAt;

  @override
  List<_i1.Column> get columns => [
    id,
    accountId,
    templateId,
    themeName,
    icon,
    emoji,
    paletteJson,
    fontConfigJson,
    colorMappingsJson,
    updatedAt,
  ];
}

class TemplateAestheticsInclude extends _i1.IncludeObject {
  TemplateAestheticsInclude._();

  @override
  Map<String, _i1.Include?> get includes => {};

  @override
  _i1.Table<_i1.UuidValue> get table => TemplateAesthetics.t;
}

class TemplateAestheticsIncludeList extends _i1.IncludeList {
  TemplateAestheticsIncludeList._({
    _i1.WhereExpressionBuilder<TemplateAestheticsTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderDescending,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(TemplateAesthetics.t);
  }

  @override
  Map<String, _i1.Include?> get includes => include?.includes ?? {};

  @override
  _i1.Table<_i1.UuidValue> get table => TemplateAesthetics.t;
}

class TemplateAestheticsRepository {
  const TemplateAestheticsRepository._();

  /// Returns a list of [TemplateAesthetics]s matching the given query parameters.
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
  Future<List<TemplateAesthetics>> find(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<TemplateAestheticsTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<TemplateAestheticsTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<TemplateAestheticsTable>? orderByList,
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<TemplateAesthetics>(
      where: where?.call(TemplateAesthetics.t),
      orderBy: orderBy?.call(TemplateAesthetics.t),
      orderByList: orderByList?.call(TemplateAesthetics.t),
      orderDescending: orderDescending,
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [TemplateAesthetics] matching the given query parameters.
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
  Future<TemplateAesthetics?> findFirstRow(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<TemplateAestheticsTable>? where,
    int? offset,
    _i1.OrderByBuilder<TemplateAestheticsTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<TemplateAestheticsTable>? orderByList,
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<TemplateAesthetics>(
      where: where?.call(TemplateAesthetics.t),
      orderBy: orderBy?.call(TemplateAesthetics.t),
      orderByList: orderByList?.call(TemplateAesthetics.t),
      orderDescending: orderDescending,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [TemplateAesthetics] by its [id] or null if no such row exists.
  Future<TemplateAesthetics?> findById(
    _i1.Session session,
    _i1.UuidValue id, {
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<TemplateAesthetics>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [TemplateAesthetics]s in the list and returns the inserted rows.
  ///
  /// The returned [TemplateAesthetics]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// insert, none of the rows will be inserted.
  ///
  /// If [ignoreConflicts] is set to `true`, rows that conflict with existing
  /// rows are silently skipped, and only the successfully inserted rows are
  /// returned.
  Future<List<TemplateAesthetics>> insert(
    _i1.Session session,
    List<TemplateAesthetics> rows, {
    _i1.Transaction? transaction,
    bool ignoreConflicts = false,
  }) async {
    return session.db.insert<TemplateAesthetics>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
    );
  }

  /// Inserts a single [TemplateAesthetics] and returns the inserted row.
  ///
  /// The returned [TemplateAesthetics] will have its `id` field set.
  Future<TemplateAesthetics> insertRow(
    _i1.Session session,
    TemplateAesthetics row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insertRow<TemplateAesthetics>(
      row,
      transaction: transaction,
    );
  }

  /// Updates all [TemplateAesthetics]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  Future<List<TemplateAesthetics>> update(
    _i1.Session session,
    List<TemplateAesthetics> rows, {
    _i1.ColumnSelections<TemplateAestheticsTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.update<TemplateAesthetics>(
      rows,
      columns: columns?.call(TemplateAesthetics.t),
      transaction: transaction,
    );
  }

  /// Updates a single [TemplateAesthetics]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<TemplateAesthetics> updateRow(
    _i1.Session session,
    TemplateAesthetics row, {
    _i1.ColumnSelections<TemplateAestheticsTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateRow<TemplateAesthetics>(
      row,
      columns: columns?.call(TemplateAesthetics.t),
      transaction: transaction,
    );
  }

  /// Updates a single [TemplateAesthetics] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<TemplateAesthetics?> updateById(
    _i1.Session session,
    _i1.UuidValue id, {
    required _i1.ColumnValueListBuilder<TemplateAestheticsUpdateTable>
    columnValues,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateById<TemplateAesthetics>(
      id,
      columnValues: columnValues(TemplateAesthetics.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [TemplateAesthetics]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  Future<List<TemplateAesthetics>> updateWhere(
    _i1.Session session, {
    required _i1.ColumnValueListBuilder<TemplateAestheticsUpdateTable>
    columnValues,
    required _i1.WhereExpressionBuilder<TemplateAestheticsTable> where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<TemplateAestheticsTable>? orderBy,
    _i1.OrderByListBuilder<TemplateAestheticsTable>? orderByList,
    bool orderDescending = false,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateWhere<TemplateAesthetics>(
      columnValues: columnValues(TemplateAesthetics.t.updateTable),
      where: where(TemplateAesthetics.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(TemplateAesthetics.t),
      orderByList: orderByList?.call(TemplateAesthetics.t),
      orderDescending: orderDescending,
      transaction: transaction,
    );
  }

  /// Deletes all [TemplateAesthetics]s in the list and returns the deleted rows.
  /// This is an atomic operation, meaning that if one of the rows fail to
  /// be deleted, none of the rows will be deleted.
  Future<List<TemplateAesthetics>> delete(
    _i1.Session session,
    List<TemplateAesthetics> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.delete<TemplateAesthetics>(
      rows,
      transaction: transaction,
    );
  }

  /// Deletes a single [TemplateAesthetics].
  Future<TemplateAesthetics> deleteRow(
    _i1.Session session,
    TemplateAesthetics row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteRow<TemplateAesthetics>(
      row,
      transaction: transaction,
    );
  }

  /// Deletes all rows matching the [where] expression.
  Future<List<TemplateAesthetics>> deleteWhere(
    _i1.Session session, {
    required _i1.WhereExpressionBuilder<TemplateAestheticsTable> where,
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteWhere<TemplateAesthetics>(
      where: where(TemplateAesthetics.t),
      transaction: transaction,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<TemplateAestheticsTable>? where,
    int? limit,
    _i1.Transaction? transaction,
  }) async {
    return session.db.count<TemplateAesthetics>(
      where: where?.call(TemplateAesthetics.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [TemplateAesthetics] rows matching the [where] expression.
  Future<void> lockRows(
    _i1.Session session, {
    required _i1.WhereExpressionBuilder<TemplateAestheticsTable> where,
    required _i1.LockMode lockMode,
    required _i1.Transaction transaction,
    _i1.LockBehavior lockBehavior = _i1.LockBehavior.wait,
  }) async {
    return session.db.lockRows<TemplateAesthetics>(
      where: where(TemplateAesthetics.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
