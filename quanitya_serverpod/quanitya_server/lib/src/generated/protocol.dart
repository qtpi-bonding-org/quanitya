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
import 'package:serverpod/protocol.dart' as _i2;
import 'package:serverpod_auth_idp_server/serverpod_auth_idp_server.dart'
    as _i3;
import 'package:serverpod_auth_core_server/serverpod_auth_core_server.dart'
    as _i4;
import 'account_storage_usage.dart' as _i5;
import 'archival_schedule_data.dart' as _i6;
import 'archive_metadata.dart' as _i7;
import 'archive_month_info.dart' as _i8;
import 'archive_search_result.dart' as _i9;
import 'archived_month.dart' as _i10;
import 'encrypted_analysis_script.dart' as _i11;
import 'encrypted_entry.dart' as _i12;
import 'encrypted_schedule.dart' as _i13;
import 'encrypted_template.dart' as _i14;
import 'encrypted_template_aesthetics.dart' as _i15;
import 'greeting.dart' as _i16;
import 'notification_inbox.dart' as _i17;
import 'powersync_token.dart' as _i18;
import 'storage_usage_response.dart' as _i19;
import 'package:quanitya_server/src/generated/archived_month.dart' as _i20;
import 'package:quanitya_server/src/generated/archive_search_result.dart'
    as _i21;
export 'account_storage_usage.dart';
export 'archival_schedule_data.dart';
export 'archive_metadata.dart';
export 'archive_month_info.dart';
export 'archive_search_result.dart';
export 'archived_month.dart';
export 'encrypted_analysis_script.dart';
export 'encrypted_entry.dart';
export 'encrypted_schedule.dart';
export 'encrypted_template.dart';
export 'encrypted_template_aesthetics.dart';
export 'greeting.dart';
export 'notification_inbox.dart';
export 'powersync_token.dart';
export 'storage_usage_response.dart';

class Protocol extends _i1.SerializationManagerServer {
  Protocol._();

  factory Protocol() => _instance;

  static final Protocol _instance = Protocol._();

  static final List<_i2.TableDefinition> targetTableDefinitions = [
    _i2.TableDefinition(
      name: 'account_storage_usage',
      dartName: 'AccountStorageUsage',
      schema: 'public',
      module: 'quanitya',
      columns: [
        _i2.ColumnDefinition(
          name: 'id',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'nextval(\'account_storage_usage_id_seq\'::regclass)',
        ),
        _i2.ColumnDefinition(
          name: 'accountUuid',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'bytesUsed',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _i2.ColumnDefinition(
          name: 'rowCount',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _i2.ColumnDefinition(
          name: 'updatedAt',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
          columnDefault: 'CURRENT_TIMESTAMP',
        ),
      ],
      foreignKeys: [],
      indexes: [
        _i2.IndexDefinition(
          indexName: 'account_storage_usage_pkey',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'id',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: true,
        ),
        _i2.IndexDefinition(
          indexName: 'account_storage_usage_account_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'accountUuid',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _i2.TableDefinition(
      name: 'archival_schedule_data',
      dartName: 'ArchivalScheduleData',
      schema: 'public',
      module: 'quanitya',
      columns: [
        _i2.ColumnDefinition(
          name: 'id',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'nextval(\'archival_schedule_data_id_seq\'::regclass)',
        ),
        _i2.ColumnDefinition(
          name: 'scheduledAt',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
        _i2.ColumnDefinition(
          name: 'lastRun',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: true,
          dartType: 'DateTime?',
        ),
      ],
      foreignKeys: [],
      indexes: [
        _i2.IndexDefinition(
          indexName: 'archival_schedule_data_pkey',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'id',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: true,
        ),
      ],
      managed: true,
    ),
    _i2.TableDefinition(
      name: 'encrypted_analysis_scripts',
      dartName: 'EncryptedAnalysisScript',
      schema: 'public',
      module: 'quanitya',
      columns: [
        _i2.ColumnDefinition(
          name: 'id',
          columnType: _i2.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
          columnDefault: 'gen_random_uuid()',
        ),
        _i2.ColumnDefinition(
          name: 'accountUuid',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'encryptedData',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'updatedAt',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
          columnDefault: 'CURRENT_TIMESTAMP',
        ),
      ],
      foreignKeys: [],
      indexes: [
        _i2.IndexDefinition(
          indexName: 'encrypted_analysis_scripts_pkey',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'id',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: true,
        ),
        _i2.IndexDefinition(
          indexName: 'encrypted_analysis_script_account_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'accountUuid',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _i2.TableDefinition(
      name: 'encrypted_entries',
      dartName: 'EncryptedEntry',
      schema: 'public',
      module: 'quanitya',
      columns: [
        _i2.ColumnDefinition(
          name: 'id',
          columnType: _i2.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
          columnDefault: 'gen_random_uuid()',
        ),
        _i2.ColumnDefinition(
          name: 'accountUuid',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'encryptedData',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'updatedAt',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
          columnDefault: 'CURRENT_TIMESTAMP',
        ),
      ],
      foreignKeys: [],
      indexes: [
        _i2.IndexDefinition(
          indexName: 'encrypted_entries_pkey',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'id',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: true,
        ),
        _i2.IndexDefinition(
          indexName: 'encrypted_entry_account_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'accountUuid',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _i2.TableDefinition(
      name: 'encrypted_schedules',
      dartName: 'EncryptedSchedule',
      schema: 'public',
      module: 'quanitya',
      columns: [
        _i2.ColumnDefinition(
          name: 'id',
          columnType: _i2.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
          columnDefault: 'gen_random_uuid()',
        ),
        _i2.ColumnDefinition(
          name: 'accountUuid',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'encryptedData',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'updatedAt',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
          columnDefault: 'CURRENT_TIMESTAMP',
        ),
      ],
      foreignKeys: [],
      indexes: [
        _i2.IndexDefinition(
          indexName: 'encrypted_schedules_pkey',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'id',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: true,
        ),
        _i2.IndexDefinition(
          indexName: 'encrypted_schedule_account_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'accountUuid',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _i2.TableDefinition(
      name: 'encrypted_template_aesthetics',
      dartName: 'EncryptedTemplateAesthetics',
      schema: 'public',
      module: 'quanitya',
      columns: [
        _i2.ColumnDefinition(
          name: 'id',
          columnType: _i2.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
          columnDefault: 'gen_random_uuid()',
        ),
        _i2.ColumnDefinition(
          name: 'accountUuid',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'encryptedData',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'updatedAt',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
          columnDefault: 'CURRENT_TIMESTAMP',
        ),
      ],
      foreignKeys: [],
      indexes: [
        _i2.IndexDefinition(
          indexName: 'encrypted_template_aesthetics_pkey',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'id',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: true,
        ),
        _i2.IndexDefinition(
          indexName: 'encrypted_template_aesthetics_account_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'accountUuid',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _i2.TableDefinition(
      name: 'encrypted_templates',
      dartName: 'EncryptedTemplate',
      schema: 'public',
      module: 'quanitya',
      columns: [
        _i2.ColumnDefinition(
          name: 'id',
          columnType: _i2.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
          columnDefault: 'gen_random_uuid()',
        ),
        _i2.ColumnDefinition(
          name: 'accountUuid',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'encryptedData',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'updatedAt',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
          columnDefault: 'CURRENT_TIMESTAMP',
        ),
      ],
      foreignKeys: [],
      indexes: [
        _i2.IndexDefinition(
          indexName: 'encrypted_templates_pkey',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'id',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: true,
        ),
        _i2.IndexDefinition(
          indexName: 'encrypted_template_account_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'accountUuid',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _i2.TableDefinition(
      name: 'notification_inbox',
      dartName: 'NotificationInbox',
      schema: 'public',
      module: 'quanitya',
      columns: [
        _i2.ColumnDefinition(
          name: 'id',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'nextval(\'notification_inbox_id_seq\'::regclass)',
        ),
        _i2.ColumnDefinition(
          name: 'userId',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _i2.ColumnDefinition(
          name: 'title',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'type',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'createdAt',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
        _i2.ColumnDefinition(
          name: 'actionPayload',
          columnType: _i2.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
      ],
      foreignKeys: [],
      indexes: [
        _i2.IndexDefinition(
          indexName: 'notification_inbox_pkey',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'id',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: true,
        ),
      ],
      managed: true,
    ),
    ..._i3.Protocol.targetTableDefinitions,
    ..._i4.Protocol.targetTableDefinitions,
  ];

  static String? getClassNameFromObjectJson(dynamic data) {
    if (data is! Map) return null;
    final className = data['__className__'] as String?;
    if (className == null) return null;
    if (!className.startsWith('quanitya.')) return className;
    return className.substring(9);
  }

  @override
  T deserialize<T>(
    dynamic data, [
    Type? t,
  ]) {
    t ??= T;

    final dataClassName = getClassNameFromObjectJson(data);
    if (dataClassName != null && dataClassName != getClassNameForType(t)) {
      try {
        return deserializeByClassName({
          'className': dataClassName,
          'data': data,
        });
      } on FormatException catch (_) {
        // If the className is not recognized (e.g., older client receiving
        // data with a new subtype), fall back to deserializing without the
        // className, using the expected type T.
      }
    }

    if (t == _i5.AccountStorageUsage) {
      return _i5.AccountStorageUsage.fromJson(data) as T;
    }
    if (t == _i6.ArchivalScheduleData) {
      return _i6.ArchivalScheduleData.fromJson(data) as T;
    }
    if (t == _i7.ArchiveMetadata) {
      return _i7.ArchiveMetadata.fromJson(data) as T;
    }
    if (t == _i8.ArchiveMonthInfo) {
      return _i8.ArchiveMonthInfo.fromJson(data) as T;
    }
    if (t == _i9.ArchiveSearchResult) {
      return _i9.ArchiveSearchResult.fromJson(data) as T;
    }
    if (t == _i10.ArchivedMonth) {
      return _i10.ArchivedMonth.fromJson(data) as T;
    }
    if (t == _i11.EncryptedAnalysisScript) {
      return _i11.EncryptedAnalysisScript.fromJson(data) as T;
    }
    if (t == _i12.EncryptedEntry) {
      return _i12.EncryptedEntry.fromJson(data) as T;
    }
    if (t == _i13.EncryptedSchedule) {
      return _i13.EncryptedSchedule.fromJson(data) as T;
    }
    if (t == _i14.EncryptedTemplate) {
      return _i14.EncryptedTemplate.fromJson(data) as T;
    }
    if (t == _i15.EncryptedTemplateAesthetics) {
      return _i15.EncryptedTemplateAesthetics.fromJson(data) as T;
    }
    if (t == _i16.Greeting) {
      return _i16.Greeting.fromJson(data) as T;
    }
    if (t == _i17.NotificationInbox) {
      return _i17.NotificationInbox.fromJson(data) as T;
    }
    if (t == _i18.PowerSyncToken) {
      return _i18.PowerSyncToken.fromJson(data) as T;
    }
    if (t == _i19.StorageUsageResponse) {
      return _i19.StorageUsageResponse.fromJson(data) as T;
    }
    if (t == _i1.getType<_i5.AccountStorageUsage?>()) {
      return (data != null ? _i5.AccountStorageUsage.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i6.ArchivalScheduleData?>()) {
      return (data != null ? _i6.ArchivalScheduleData.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i7.ArchiveMetadata?>()) {
      return (data != null ? _i7.ArchiveMetadata.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i8.ArchiveMonthInfo?>()) {
      return (data != null ? _i8.ArchiveMonthInfo.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i9.ArchiveSearchResult?>()) {
      return (data != null ? _i9.ArchiveSearchResult.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i10.ArchivedMonth?>()) {
      return (data != null ? _i10.ArchivedMonth.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i11.EncryptedAnalysisScript?>()) {
      return (data != null ? _i11.EncryptedAnalysisScript.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i12.EncryptedEntry?>()) {
      return (data != null ? _i12.EncryptedEntry.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i13.EncryptedSchedule?>()) {
      return (data != null ? _i13.EncryptedSchedule.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i14.EncryptedTemplate?>()) {
      return (data != null ? _i14.EncryptedTemplate.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i15.EncryptedTemplateAesthetics?>()) {
      return (data != null
              ? _i15.EncryptedTemplateAesthetics.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i16.Greeting?>()) {
      return (data != null ? _i16.Greeting.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i17.NotificationInbox?>()) {
      return (data != null ? _i17.NotificationInbox.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i18.PowerSyncToken?>()) {
      return (data != null ? _i18.PowerSyncToken.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i19.StorageUsageResponse?>()) {
      return (data != null ? _i19.StorageUsageResponse.fromJson(data) : null)
          as T;
    }
    if (t == List<_i8.ArchiveMonthInfo>) {
      return (data as List)
              .map((e) => deserialize<_i8.ArchiveMonthInfo>(e))
              .toList()
          as T;
    }
    if (t == List<_i12.EncryptedEntry>) {
      return (data as List)
              .map((e) => deserialize<_i12.EncryptedEntry>(e))
              .toList()
          as T;
    }
    if (t == List<_i14.EncryptedTemplate>) {
      return (data as List)
              .map((e) => deserialize<_i14.EncryptedTemplate>(e))
              .toList()
          as T;
    }
    if (t == List<_i13.EncryptedSchedule>) {
      return (data as List)
              .map((e) => deserialize<_i13.EncryptedSchedule>(e))
              .toList()
          as T;
    }
    if (t == List<_i11.EncryptedAnalysisScript>) {
      return (data as List)
              .map((e) => deserialize<_i11.EncryptedAnalysisScript>(e))
              .toList()
          as T;
    }
    if (t == List<_i20.ArchivedMonth>) {
      return (data as List)
              .map((e) => deserialize<_i20.ArchivedMonth>(e))
              .toList()
          as T;
    }
    if (t == List<_i21.ArchiveSearchResult>) {
      return (data as List)
              .map((e) => deserialize<_i21.ArchiveSearchResult>(e))
              .toList()
          as T;
    }
    try {
      return _i3.Protocol().deserialize<T>(data, t);
    } on _i1.DeserializationTypeNotFoundException catch (_) {}
    try {
      return _i4.Protocol().deserialize<T>(data, t);
    } on _i1.DeserializationTypeNotFoundException catch (_) {}
    try {
      return _i2.Protocol().deserialize<T>(data, t);
    } on _i1.DeserializationTypeNotFoundException catch (_) {}
    return super.deserialize<T>(data, t);
  }

  static String? getClassNameForType(Type type) {
    return switch (type) {
      _i5.AccountStorageUsage => 'AccountStorageUsage',
      _i6.ArchivalScheduleData => 'ArchivalScheduleData',
      _i7.ArchiveMetadata => 'ArchiveMetadata',
      _i8.ArchiveMonthInfo => 'ArchiveMonthInfo',
      _i9.ArchiveSearchResult => 'ArchiveSearchResult',
      _i10.ArchivedMonth => 'ArchivedMonth',
      _i11.EncryptedAnalysisScript => 'EncryptedAnalysisScript',
      _i12.EncryptedEntry => 'EncryptedEntry',
      _i13.EncryptedSchedule => 'EncryptedSchedule',
      _i14.EncryptedTemplate => 'EncryptedTemplate',
      _i15.EncryptedTemplateAesthetics => 'EncryptedTemplateAesthetics',
      _i16.Greeting => 'Greeting',
      _i17.NotificationInbox => 'NotificationInbox',
      _i18.PowerSyncToken => 'PowerSyncToken',
      _i19.StorageUsageResponse => 'StorageUsageResponse',
      _ => null,
    };
  }

  @override
  String? getClassNameForObject(Object? data) {
    String? className = super.getClassNameForObject(data);
    if (className != null) return className;

    if (data is Map<String, dynamic> && data['__className__'] is String) {
      return (data['__className__'] as String).replaceFirst('quanitya.', '');
    }

    switch (data) {
      case _i5.AccountStorageUsage():
        return 'AccountStorageUsage';
      case _i6.ArchivalScheduleData():
        return 'ArchivalScheduleData';
      case _i7.ArchiveMetadata():
        return 'ArchiveMetadata';
      case _i8.ArchiveMonthInfo():
        return 'ArchiveMonthInfo';
      case _i9.ArchiveSearchResult():
        return 'ArchiveSearchResult';
      case _i10.ArchivedMonth():
        return 'ArchivedMonth';
      case _i11.EncryptedAnalysisScript():
        return 'EncryptedAnalysisScript';
      case _i12.EncryptedEntry():
        return 'EncryptedEntry';
      case _i13.EncryptedSchedule():
        return 'EncryptedSchedule';
      case _i14.EncryptedTemplate():
        return 'EncryptedTemplate';
      case _i15.EncryptedTemplateAesthetics():
        return 'EncryptedTemplateAesthetics';
      case _i16.Greeting():
        return 'Greeting';
      case _i17.NotificationInbox():
        return 'NotificationInbox';
      case _i18.PowerSyncToken():
        return 'PowerSyncToken';
      case _i19.StorageUsageResponse():
        return 'StorageUsageResponse';
    }
    className = _i2.Protocol().getClassNameForObject(data);
    if (className != null) {
      return 'serverpod.$className';
    }
    className = _i3.Protocol().getClassNameForObject(data);
    if (className != null) {
      return 'serverpod_auth_idp.$className';
    }
    className = _i4.Protocol().getClassNameForObject(data);
    if (className != null) {
      return 'serverpod_auth_core.$className';
    }
    return null;
  }

  @override
  dynamic deserializeByClassName(Map<String, dynamic> data) {
    var dataClassName = data['className'];
    if (dataClassName is! String) {
      return super.deserializeByClassName(data);
    }
    if (dataClassName == 'AccountStorageUsage') {
      return deserialize<_i5.AccountStorageUsage>(data['data']);
    }
    if (dataClassName == 'ArchivalScheduleData') {
      return deserialize<_i6.ArchivalScheduleData>(data['data']);
    }
    if (dataClassName == 'ArchiveMetadata') {
      return deserialize<_i7.ArchiveMetadata>(data['data']);
    }
    if (dataClassName == 'ArchiveMonthInfo') {
      return deserialize<_i8.ArchiveMonthInfo>(data['data']);
    }
    if (dataClassName == 'ArchiveSearchResult') {
      return deserialize<_i9.ArchiveSearchResult>(data['data']);
    }
    if (dataClassName == 'ArchivedMonth') {
      return deserialize<_i10.ArchivedMonth>(data['data']);
    }
    if (dataClassName == 'EncryptedAnalysisScript') {
      return deserialize<_i11.EncryptedAnalysisScript>(data['data']);
    }
    if (dataClassName == 'EncryptedEntry') {
      return deserialize<_i12.EncryptedEntry>(data['data']);
    }
    if (dataClassName == 'EncryptedSchedule') {
      return deserialize<_i13.EncryptedSchedule>(data['data']);
    }
    if (dataClassName == 'EncryptedTemplate') {
      return deserialize<_i14.EncryptedTemplate>(data['data']);
    }
    if (dataClassName == 'EncryptedTemplateAesthetics') {
      return deserialize<_i15.EncryptedTemplateAesthetics>(data['data']);
    }
    if (dataClassName == 'Greeting') {
      return deserialize<_i16.Greeting>(data['data']);
    }
    if (dataClassName == 'NotificationInbox') {
      return deserialize<_i17.NotificationInbox>(data['data']);
    }
    if (dataClassName == 'PowerSyncToken') {
      return deserialize<_i18.PowerSyncToken>(data['data']);
    }
    if (dataClassName == 'StorageUsageResponse') {
      return deserialize<_i19.StorageUsageResponse>(data['data']);
    }
    if (dataClassName.startsWith('serverpod.')) {
      data['className'] = dataClassName.substring(10);
      return _i2.Protocol().deserializeByClassName(data);
    }
    if (dataClassName.startsWith('serverpod_auth_idp.')) {
      data['className'] = dataClassName.substring(19);
      return _i3.Protocol().deserializeByClassName(data);
    }
    if (dataClassName.startsWith('serverpod_auth_core.')) {
      data['className'] = dataClassName.substring(20);
      return _i4.Protocol().deserializeByClassName(data);
    }
    return super.deserializeByClassName(data);
  }

  @override
  _i1.Table? getTableForType(Type t) {
    {
      var table = _i3.Protocol().getTableForType(t);
      if (table != null) {
        return table;
      }
    }
    {
      var table = _i4.Protocol().getTableForType(t);
      if (table != null) {
        return table;
      }
    }
    {
      var table = _i2.Protocol().getTableForType(t);
      if (table != null) {
        return table;
      }
    }
    switch (t) {
      case _i5.AccountStorageUsage:
        return _i5.AccountStorageUsage.t;
      case _i6.ArchivalScheduleData:
        return _i6.ArchivalScheduleData.t;
      case _i11.EncryptedAnalysisScript:
        return _i11.EncryptedAnalysisScript.t;
      case _i12.EncryptedEntry:
        return _i12.EncryptedEntry.t;
      case _i13.EncryptedSchedule:
        return _i13.EncryptedSchedule.t;
      case _i14.EncryptedTemplate:
        return _i14.EncryptedTemplate.t;
      case _i15.EncryptedTemplateAesthetics:
        return _i15.EncryptedTemplateAesthetics.t;
      case _i17.NotificationInbox:
        return _i17.NotificationInbox.t;
    }
    return null;
  }

  @override
  List<_i2.TableDefinition> getTargetTableDefinitions() =>
      targetTableDefinitions;

  @override
  String getModuleName() => 'quanitya';

  /// Maps any `Record`s known to this [Protocol] to their JSON representation
  ///
  /// Throws in case the record type is not known.
  ///
  /// This method will return `null` (only) for `null` inputs.
  Map<String, dynamic>? mapRecordToJson(Record? record) {
    if (record == null) {
      return null;
    }
    try {
      return _i3.Protocol().mapRecordToJson(record);
    } catch (_) {}
    try {
      return _i4.Protocol().mapRecordToJson(record);
    } catch (_) {}
    throw Exception('Unsupported record type ${record.runtimeType}');
  }
}
