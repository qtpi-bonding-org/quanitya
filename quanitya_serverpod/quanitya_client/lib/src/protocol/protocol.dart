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
import 'package:serverpod_client/serverpod_client.dart' as _i1;
import 'account_storage_usage.dart' as _i2;
import 'archival_schedule_data.dart' as _i3;
import 'archive_metadata.dart' as _i4;
import 'archive_month_info.dart' as _i5;
import 'archive_search_result.dart' as _i6;
import 'archived_month.dart' as _i7;
import 'encrypted_analysis_script.dart' as _i8;
import 'encrypted_entry.dart' as _i9;
import 'encrypted_schedule.dart' as _i10;
import 'encrypted_template.dart' as _i11;
import 'encrypted_template_aesthetics.dart' as _i12;
import 'greeting.dart' as _i13;
import 'notification_inbox.dart' as _i14;
import 'powersync_token.dart' as _i15;
import 'storage_usage_response.dart' as _i16;
import 'template_aesthetics.dart' as _i17;
import 'package:quanitya_client/src/protocol/archived_month.dart' as _i18;
import 'package:quanitya_client/src/protocol/archive_search_result.dart'
    as _i19;
import 'package:serverpod_auth_idp_client/serverpod_auth_idp_client.dart'
    as _i20;
import 'package:serverpod_auth_core_client/serverpod_auth_core_client.dart'
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
export 'template_aesthetics.dart';
export 'client.dart';

class Protocol extends _i1.SerializationManager {
  Protocol._();

  factory Protocol() => _instance;

  static final Protocol _instance = Protocol._();

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

    if (t == _i2.AccountStorageUsage) {
      return _i2.AccountStorageUsage.fromJson(data) as T;
    }
    if (t == _i3.ArchivalScheduleData) {
      return _i3.ArchivalScheduleData.fromJson(data) as T;
    }
    if (t == _i4.ArchiveMetadata) {
      return _i4.ArchiveMetadata.fromJson(data) as T;
    }
    if (t == _i5.ArchiveMonthInfo) {
      return _i5.ArchiveMonthInfo.fromJson(data) as T;
    }
    if (t == _i6.ArchiveSearchResult) {
      return _i6.ArchiveSearchResult.fromJson(data) as T;
    }
    if (t == _i7.ArchivedMonth) {
      return _i7.ArchivedMonth.fromJson(data) as T;
    }
    if (t == _i8.EncryptedAnalysisScript) {
      return _i8.EncryptedAnalysisScript.fromJson(data) as T;
    }
    if (t == _i9.EncryptedEntry) {
      return _i9.EncryptedEntry.fromJson(data) as T;
    }
    if (t == _i10.EncryptedSchedule) {
      return _i10.EncryptedSchedule.fromJson(data) as T;
    }
    if (t == _i11.EncryptedTemplate) {
      return _i11.EncryptedTemplate.fromJson(data) as T;
    }
    if (t == _i12.EncryptedTemplateAesthetics) {
      return _i12.EncryptedTemplateAesthetics.fromJson(data) as T;
    }
    if (t == _i13.Greeting) {
      return _i13.Greeting.fromJson(data) as T;
    }
    if (t == _i14.NotificationInbox) {
      return _i14.NotificationInbox.fromJson(data) as T;
    }
    if (t == _i15.PowerSyncToken) {
      return _i15.PowerSyncToken.fromJson(data) as T;
    }
    if (t == _i16.StorageUsageResponse) {
      return _i16.StorageUsageResponse.fromJson(data) as T;
    }
    if (t == _i17.TemplateAesthetics) {
      return _i17.TemplateAesthetics.fromJson(data) as T;
    }
    if (t == _i1.getType<_i2.AccountStorageUsage?>()) {
      return (data != null ? _i2.AccountStorageUsage.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i3.ArchivalScheduleData?>()) {
      return (data != null ? _i3.ArchivalScheduleData.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i4.ArchiveMetadata?>()) {
      return (data != null ? _i4.ArchiveMetadata.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i5.ArchiveMonthInfo?>()) {
      return (data != null ? _i5.ArchiveMonthInfo.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i6.ArchiveSearchResult?>()) {
      return (data != null ? _i6.ArchiveSearchResult.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i7.ArchivedMonth?>()) {
      return (data != null ? _i7.ArchivedMonth.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i8.EncryptedAnalysisScript?>()) {
      return (data != null ? _i8.EncryptedAnalysisScript.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i9.EncryptedEntry?>()) {
      return (data != null ? _i9.EncryptedEntry.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i10.EncryptedSchedule?>()) {
      return (data != null ? _i10.EncryptedSchedule.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i11.EncryptedTemplate?>()) {
      return (data != null ? _i11.EncryptedTemplate.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i12.EncryptedTemplateAesthetics?>()) {
      return (data != null
              ? _i12.EncryptedTemplateAesthetics.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i13.Greeting?>()) {
      return (data != null ? _i13.Greeting.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i14.NotificationInbox?>()) {
      return (data != null ? _i14.NotificationInbox.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i15.PowerSyncToken?>()) {
      return (data != null ? _i15.PowerSyncToken.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i16.StorageUsageResponse?>()) {
      return (data != null ? _i16.StorageUsageResponse.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i17.TemplateAesthetics?>()) {
      return (data != null ? _i17.TemplateAesthetics.fromJson(data) : null)
          as T;
    }
    if (t == List<_i5.ArchiveMonthInfo>) {
      return (data as List)
              .map((e) => deserialize<_i5.ArchiveMonthInfo>(e))
              .toList()
          as T;
    }
    if (t == List<_i9.EncryptedEntry>) {
      return (data as List)
              .map((e) => deserialize<_i9.EncryptedEntry>(e))
              .toList()
          as T;
    }
    if (t == List<_i11.EncryptedTemplate>) {
      return (data as List)
              .map((e) => deserialize<_i11.EncryptedTemplate>(e))
              .toList()
          as T;
    }
    if (t == List<_i10.EncryptedSchedule>) {
      return (data as List)
              .map((e) => deserialize<_i10.EncryptedSchedule>(e))
              .toList()
          as T;
    }
    if (t == List<_i8.EncryptedAnalysisScript>) {
      return (data as List)
              .map((e) => deserialize<_i8.EncryptedAnalysisScript>(e))
              .toList()
          as T;
    }
    if (t == List<_i18.ArchivedMonth>) {
      return (data as List)
              .map((e) => deserialize<_i18.ArchivedMonth>(e))
              .toList()
          as T;
    }
    if (t == List<_i19.ArchiveSearchResult>) {
      return (data as List)
              .map((e) => deserialize<_i19.ArchiveSearchResult>(e))
              .toList()
          as T;
    }
    try {
      return _i20.Protocol().deserialize<T>(data, t);
    } on _i1.DeserializationTypeNotFoundException catch (_) {}
    try {
      return _i21.Protocol().deserialize<T>(data, t);
    } on _i1.DeserializationTypeNotFoundException catch (_) {}
    return super.deserialize<T>(data, t);
  }

  static String? getClassNameForType(Type type) {
    return switch (type) {
      _i2.AccountStorageUsage => 'AccountStorageUsage',
      _i3.ArchivalScheduleData => 'ArchivalScheduleData',
      _i4.ArchiveMetadata => 'ArchiveMetadata',
      _i5.ArchiveMonthInfo => 'ArchiveMonthInfo',
      _i6.ArchiveSearchResult => 'ArchiveSearchResult',
      _i7.ArchivedMonth => 'ArchivedMonth',
      _i8.EncryptedAnalysisScript => 'EncryptedAnalysisScript',
      _i9.EncryptedEntry => 'EncryptedEntry',
      _i10.EncryptedSchedule => 'EncryptedSchedule',
      _i11.EncryptedTemplate => 'EncryptedTemplate',
      _i12.EncryptedTemplateAesthetics => 'EncryptedTemplateAesthetics',
      _i13.Greeting => 'Greeting',
      _i14.NotificationInbox => 'NotificationInbox',
      _i15.PowerSyncToken => 'PowerSyncToken',
      _i16.StorageUsageResponse => 'StorageUsageResponse',
      _i17.TemplateAesthetics => 'TemplateAesthetics',
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
      case _i2.AccountStorageUsage():
        return 'AccountStorageUsage';
      case _i3.ArchivalScheduleData():
        return 'ArchivalScheduleData';
      case _i4.ArchiveMetadata():
        return 'ArchiveMetadata';
      case _i5.ArchiveMonthInfo():
        return 'ArchiveMonthInfo';
      case _i6.ArchiveSearchResult():
        return 'ArchiveSearchResult';
      case _i7.ArchivedMonth():
        return 'ArchivedMonth';
      case _i8.EncryptedAnalysisScript():
        return 'EncryptedAnalysisScript';
      case _i9.EncryptedEntry():
        return 'EncryptedEntry';
      case _i10.EncryptedSchedule():
        return 'EncryptedSchedule';
      case _i11.EncryptedTemplate():
        return 'EncryptedTemplate';
      case _i12.EncryptedTemplateAesthetics():
        return 'EncryptedTemplateAesthetics';
      case _i13.Greeting():
        return 'Greeting';
      case _i14.NotificationInbox():
        return 'NotificationInbox';
      case _i15.PowerSyncToken():
        return 'PowerSyncToken';
      case _i16.StorageUsageResponse():
        return 'StorageUsageResponse';
      case _i17.TemplateAesthetics():
        return 'TemplateAesthetics';
    }
    className = _i20.Protocol().getClassNameForObject(data);
    if (className != null) {
      return 'serverpod_auth_idp.$className';
    }
    className = _i21.Protocol().getClassNameForObject(data);
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
      return deserialize<_i2.AccountStorageUsage>(data['data']);
    }
    if (dataClassName == 'ArchivalScheduleData') {
      return deserialize<_i3.ArchivalScheduleData>(data['data']);
    }
    if (dataClassName == 'ArchiveMetadata') {
      return deserialize<_i4.ArchiveMetadata>(data['data']);
    }
    if (dataClassName == 'ArchiveMonthInfo') {
      return deserialize<_i5.ArchiveMonthInfo>(data['data']);
    }
    if (dataClassName == 'ArchiveSearchResult') {
      return deserialize<_i6.ArchiveSearchResult>(data['data']);
    }
    if (dataClassName == 'ArchivedMonth') {
      return deserialize<_i7.ArchivedMonth>(data['data']);
    }
    if (dataClassName == 'EncryptedAnalysisScript') {
      return deserialize<_i8.EncryptedAnalysisScript>(data['data']);
    }
    if (dataClassName == 'EncryptedEntry') {
      return deserialize<_i9.EncryptedEntry>(data['data']);
    }
    if (dataClassName == 'EncryptedSchedule') {
      return deserialize<_i10.EncryptedSchedule>(data['data']);
    }
    if (dataClassName == 'EncryptedTemplate') {
      return deserialize<_i11.EncryptedTemplate>(data['data']);
    }
    if (dataClassName == 'EncryptedTemplateAesthetics') {
      return deserialize<_i12.EncryptedTemplateAesthetics>(data['data']);
    }
    if (dataClassName == 'Greeting') {
      return deserialize<_i13.Greeting>(data['data']);
    }
    if (dataClassName == 'NotificationInbox') {
      return deserialize<_i14.NotificationInbox>(data['data']);
    }
    if (dataClassName == 'PowerSyncToken') {
      return deserialize<_i15.PowerSyncToken>(data['data']);
    }
    if (dataClassName == 'StorageUsageResponse') {
      return deserialize<_i16.StorageUsageResponse>(data['data']);
    }
    if (dataClassName == 'TemplateAesthetics') {
      return deserialize<_i17.TemplateAesthetics>(data['data']);
    }
    if (dataClassName.startsWith('serverpod_auth_idp.')) {
      data['className'] = dataClassName.substring(19);
      return _i20.Protocol().deserializeByClassName(data);
    }
    if (dataClassName.startsWith('serverpod_auth_core.')) {
      data['className'] = dataClassName.substring(20);
      return _i21.Protocol().deserializeByClassName(data);
    }
    return super.deserializeByClassName(data);
  }

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
      return _i20.Protocol().mapRecordToJson(record);
    } catch (_) {}
    try {
      return _i21.Protocol().mapRecordToJson(record);
    } catch (_) {}
    throw Exception('Unsupported record type ${record.runtimeType}');
  }
}
