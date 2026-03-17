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
import 'admin_signing_key.dart' as _i2;
import 'analytics_event.dart' as _i3;
import 'batch_submission_result.dart' as _i4;
import 'cloud_llm_call_type.dart' as _i5;
import 'cloud_llm_structured_request.dart' as _i6;
import 'cloud_llm_structured_response.dart' as _i7;
import 'consumption_schedule_data.dart' as _i8;
import 'error_report.dart' as _i9;
import 'feedback_report.dart' as _i10;
import 'feedback_type.dart' as _i11;
import 'notification.dart' as _i12;
import 'notification_receipt.dart' as _i13;
import 'notification_type.dart' as _i14;
import 'platform_catalog_response.dart' as _i15;
import 'platform_rail_entry.dart' as _i16;
import 'platform_rail_list.dart' as _i17;
import 'rail_catalog_entry.dart' as _i18;
import 'rail_status.dart' as _i19;
import 'server_error_code.dart' as _i20;
import 'server_exception.dart' as _i21;
import 'package:serverpod_auth_idp_client/serverpod_auth_idp_client.dart'
    as _i22;
import 'package:serverpod_auth_core_client/serverpod_auth_core_client.dart'
    as _i23;
import 'package:quanitya_client/quanitya_client.dart' as _i24;
import 'package:anonaccount_client/anonaccount_client.dart' as _i25;
import 'package:anonaccred_client/anonaccred_client.dart' as _i26;
export 'admin_signing_key.dart';
export 'analytics_event.dart';
export 'batch_submission_result.dart';
export 'cloud_llm_call_type.dart';
export 'cloud_llm_structured_request.dart';
export 'cloud_llm_structured_response.dart';
export 'consumption_schedule_data.dart';
export 'error_report.dart';
export 'feedback_report.dart';
export 'feedback_type.dart';
export 'notification.dart';
export 'notification_receipt.dart';
export 'notification_type.dart';
export 'platform_catalog_response.dart';
export 'platform_rail_entry.dart';
export 'platform_rail_list.dart';
export 'rail_catalog_entry.dart';
export 'rail_status.dart';
export 'server_error_code.dart';
export 'server_exception.dart';
export 'client.dart';

class Protocol extends _i1.SerializationManager {
  Protocol._();

  factory Protocol() => _instance;

  static final Protocol _instance = Protocol._();

  static String? getClassNameFromObjectJson(dynamic data) {
    if (data is! Map) return null;
    final className = data['__className__'] as String?;
    return className;
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

    if (t == _i2.AdminSigningKey) {
      return _i2.AdminSigningKey.fromJson(data) as T;
    }
    if (t == _i3.AnalyticsEvent) {
      return _i3.AnalyticsEvent.fromJson(data) as T;
    }
    if (t == _i4.BatchSubmissionResult) {
      return _i4.BatchSubmissionResult.fromJson(data) as T;
    }
    if (t == _i5.CloudLlmCallType) {
      return _i5.CloudLlmCallType.fromJson(data) as T;
    }
    if (t == _i6.CloudLlmStructuredRequest) {
      return _i6.CloudLlmStructuredRequest.fromJson(data) as T;
    }
    if (t == _i7.CloudLlmStructuredResponse) {
      return _i7.CloudLlmStructuredResponse.fromJson(data) as T;
    }
    if (t == _i8.ConsumptionScheduleData) {
      return _i8.ConsumptionScheduleData.fromJson(data) as T;
    }
    if (t == _i9.ErrorReport) {
      return _i9.ErrorReport.fromJson(data) as T;
    }
    if (t == _i10.FeedbackReport) {
      return _i10.FeedbackReport.fromJson(data) as T;
    }
    if (t == _i11.FeedbackType) {
      return _i11.FeedbackType.fromJson(data) as T;
    }
    if (t == _i12.Notification) {
      return _i12.Notification.fromJson(data) as T;
    }
    if (t == _i13.NotificationReceipt) {
      return _i13.NotificationReceipt.fromJson(data) as T;
    }
    if (t == _i14.NotificationType) {
      return _i14.NotificationType.fromJson(data) as T;
    }
    if (t == _i15.PlatformCatalogResponse) {
      return _i15.PlatformCatalogResponse.fromJson(data) as T;
    }
    if (t == _i16.PlatformRailEntry) {
      return _i16.PlatformRailEntry.fromJson(data) as T;
    }
    if (t == _i17.PlatformRailList) {
      return _i17.PlatformRailList.fromJson(data) as T;
    }
    if (t == _i18.RailCatalogEntry) {
      return _i18.RailCatalogEntry.fromJson(data) as T;
    }
    if (t == _i19.RailStatus) {
      return _i19.RailStatus.fromJson(data) as T;
    }
    if (t == _i20.ServerErrorCode) {
      return _i20.ServerErrorCode.fromJson(data) as T;
    }
    if (t == _i21.ServerException) {
      return _i21.ServerException.fromJson(data) as T;
    }
    if (t == _i1.getType<_i2.AdminSigningKey?>()) {
      return (data != null ? _i2.AdminSigningKey.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i3.AnalyticsEvent?>()) {
      return (data != null ? _i3.AnalyticsEvent.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i4.BatchSubmissionResult?>()) {
      return (data != null ? _i4.BatchSubmissionResult.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i5.CloudLlmCallType?>()) {
      return (data != null ? _i5.CloudLlmCallType.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i6.CloudLlmStructuredRequest?>()) {
      return (data != null
              ? _i6.CloudLlmStructuredRequest.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i7.CloudLlmStructuredResponse?>()) {
      return (data != null
              ? _i7.CloudLlmStructuredResponse.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i8.ConsumptionScheduleData?>()) {
      return (data != null ? _i8.ConsumptionScheduleData.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i9.ErrorReport?>()) {
      return (data != null ? _i9.ErrorReport.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i10.FeedbackReport?>()) {
      return (data != null ? _i10.FeedbackReport.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i11.FeedbackType?>()) {
      return (data != null ? _i11.FeedbackType.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i12.Notification?>()) {
      return (data != null ? _i12.Notification.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i13.NotificationReceipt?>()) {
      return (data != null ? _i13.NotificationReceipt.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i14.NotificationType?>()) {
      return (data != null ? _i14.NotificationType.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i15.PlatformCatalogResponse?>()) {
      return (data != null ? _i15.PlatformCatalogResponse.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i16.PlatformRailEntry?>()) {
      return (data != null ? _i16.PlatformRailEntry.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i17.PlatformRailList?>()) {
      return (data != null ? _i17.PlatformRailList.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i18.RailCatalogEntry?>()) {
      return (data != null ? _i18.RailCatalogEntry.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i19.RailStatus?>()) {
      return (data != null ? _i19.RailStatus.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i20.ServerErrorCode?>()) {
      return (data != null ? _i20.ServerErrorCode.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i21.ServerException?>()) {
      return (data != null ? _i21.ServerException.fromJson(data) : null) as T;
    }
    if (t == List<_i18.RailCatalogEntry>) {
      return (data as List)
              .map((e) => deserialize<_i18.RailCatalogEntry>(e))
              .toList()
          as T;
    }
    if (t == List<_i16.PlatformRailEntry>) {
      return (data as List)
              .map((e) => deserialize<_i16.PlatformRailEntry>(e))
              .toList()
          as T;
    }
    if (t == List<String>) {
      return (data as List).map((e) => deserialize<String>(e)).toList() as T;
    }
    try {
      return _i22.Protocol().deserialize<T>(data, t);
    } on _i1.DeserializationTypeNotFoundException catch (_) {}
    try {
      return _i23.Protocol().deserialize<T>(data, t);
    } on _i1.DeserializationTypeNotFoundException catch (_) {}
    try {
      return _i24.Protocol().deserialize<T>(data, t);
    } on _i1.DeserializationTypeNotFoundException catch (_) {}
    try {
      return _i25.Protocol().deserialize<T>(data, t);
    } on _i1.DeserializationTypeNotFoundException catch (_) {}
    try {
      return _i26.Protocol().deserialize<T>(data, t);
    } on _i1.DeserializationTypeNotFoundException catch (_) {}
    return super.deserialize<T>(data, t);
  }

  static String? getClassNameForType(Type type) {
    return switch (type) {
      _i2.AdminSigningKey => 'AdminSigningKey',
      _i3.AnalyticsEvent => 'AnalyticsEvent',
      _i4.BatchSubmissionResult => 'BatchSubmissionResult',
      _i5.CloudLlmCallType => 'CloudLlmCallType',
      _i6.CloudLlmStructuredRequest => 'CloudLlmStructuredRequest',
      _i7.CloudLlmStructuredResponse => 'CloudLlmStructuredResponse',
      _i8.ConsumptionScheduleData => 'ConsumptionScheduleData',
      _i9.ErrorReport => 'ErrorReport',
      _i10.FeedbackReport => 'FeedbackReport',
      _i11.FeedbackType => 'FeedbackType',
      _i12.Notification => 'Notification',
      _i13.NotificationReceipt => 'NotificationReceipt',
      _i14.NotificationType => 'NotificationType',
      _i15.PlatformCatalogResponse => 'PlatformCatalogResponse',
      _i16.PlatformRailEntry => 'PlatformRailEntry',
      _i17.PlatformRailList => 'PlatformRailList',
      _i18.RailCatalogEntry => 'RailCatalogEntry',
      _i19.RailStatus => 'RailStatus',
      _i20.ServerErrorCode => 'ServerErrorCode',
      _i21.ServerException => 'ServerException',
      _ => null,
    };
  }

  @override
  String? getClassNameForObject(Object? data) {
    String? className = super.getClassNameForObject(data);
    if (className != null) return className;

    if (data is Map<String, dynamic> && data['__className__'] is String) {
      return (data['__className__'] as String).replaceFirst(
        'quanitya_cloud.',
        '',
      );
    }

    switch (data) {
      case _i2.AdminSigningKey():
        return 'AdminSigningKey';
      case _i3.AnalyticsEvent():
        return 'AnalyticsEvent';
      case _i4.BatchSubmissionResult():
        return 'BatchSubmissionResult';
      case _i5.CloudLlmCallType():
        return 'CloudLlmCallType';
      case _i6.CloudLlmStructuredRequest():
        return 'CloudLlmStructuredRequest';
      case _i7.CloudLlmStructuredResponse():
        return 'CloudLlmStructuredResponse';
      case _i8.ConsumptionScheduleData():
        return 'ConsumptionScheduleData';
      case _i9.ErrorReport():
        return 'ErrorReport';
      case _i10.FeedbackReport():
        return 'FeedbackReport';
      case _i11.FeedbackType():
        return 'FeedbackType';
      case _i12.Notification():
        return 'Notification';
      case _i13.NotificationReceipt():
        return 'NotificationReceipt';
      case _i14.NotificationType():
        return 'NotificationType';
      case _i15.PlatformCatalogResponse():
        return 'PlatformCatalogResponse';
      case _i16.PlatformRailEntry():
        return 'PlatformRailEntry';
      case _i17.PlatformRailList():
        return 'PlatformRailList';
      case _i18.RailCatalogEntry():
        return 'RailCatalogEntry';
      case _i19.RailStatus():
        return 'RailStatus';
      case _i20.ServerErrorCode():
        return 'ServerErrorCode';
      case _i21.ServerException():
        return 'ServerException';
    }
    className = _i22.Protocol().getClassNameForObject(data);
    if (className != null) {
      return 'serverpod_auth_idp.$className';
    }
    className = _i23.Protocol().getClassNameForObject(data);
    if (className != null) {
      return 'serverpod_auth_core.$className';
    }
    className = _i24.Protocol().getClassNameForObject(data);
    if (className != null) {
      return 'quanitya.$className';
    }
    className = _i25.Protocol().getClassNameForObject(data);
    if (className != null) {
      return 'anonaccount.$className';
    }
    className = _i26.Protocol().getClassNameForObject(data);
    if (className != null) {
      return 'anonaccred.$className';
    }
    return null;
  }

  @override
  dynamic deserializeByClassName(Map<String, dynamic> data) {
    var dataClassName = data['className'];
    if (dataClassName is! String) {
      return super.deserializeByClassName(data);
    }
    if (dataClassName == 'AdminSigningKey') {
      return deserialize<_i2.AdminSigningKey>(data['data']);
    }
    if (dataClassName == 'AnalyticsEvent') {
      return deserialize<_i3.AnalyticsEvent>(data['data']);
    }
    if (dataClassName == 'BatchSubmissionResult') {
      return deserialize<_i4.BatchSubmissionResult>(data['data']);
    }
    if (dataClassName == 'CloudLlmCallType') {
      return deserialize<_i5.CloudLlmCallType>(data['data']);
    }
    if (dataClassName == 'CloudLlmStructuredRequest') {
      return deserialize<_i6.CloudLlmStructuredRequest>(data['data']);
    }
    if (dataClassName == 'CloudLlmStructuredResponse') {
      return deserialize<_i7.CloudLlmStructuredResponse>(data['data']);
    }
    if (dataClassName == 'ConsumptionScheduleData') {
      return deserialize<_i8.ConsumptionScheduleData>(data['data']);
    }
    if (dataClassName == 'ErrorReport') {
      return deserialize<_i9.ErrorReport>(data['data']);
    }
    if (dataClassName == 'FeedbackReport') {
      return deserialize<_i10.FeedbackReport>(data['data']);
    }
    if (dataClassName == 'FeedbackType') {
      return deserialize<_i11.FeedbackType>(data['data']);
    }
    if (dataClassName == 'Notification') {
      return deserialize<_i12.Notification>(data['data']);
    }
    if (dataClassName == 'NotificationReceipt') {
      return deserialize<_i13.NotificationReceipt>(data['data']);
    }
    if (dataClassName == 'NotificationType') {
      return deserialize<_i14.NotificationType>(data['data']);
    }
    if (dataClassName == 'PlatformCatalogResponse') {
      return deserialize<_i15.PlatformCatalogResponse>(data['data']);
    }
    if (dataClassName == 'PlatformRailEntry') {
      return deserialize<_i16.PlatformRailEntry>(data['data']);
    }
    if (dataClassName == 'PlatformRailList') {
      return deserialize<_i17.PlatformRailList>(data['data']);
    }
    if (dataClassName == 'RailCatalogEntry') {
      return deserialize<_i18.RailCatalogEntry>(data['data']);
    }
    if (dataClassName == 'RailStatus') {
      return deserialize<_i19.RailStatus>(data['data']);
    }
    if (dataClassName == 'ServerErrorCode') {
      return deserialize<_i20.ServerErrorCode>(data['data']);
    }
    if (dataClassName == 'ServerException') {
      return deserialize<_i21.ServerException>(data['data']);
    }
    if (dataClassName.startsWith('serverpod_auth_idp.')) {
      data['className'] = dataClassName.substring(19);
      return _i22.Protocol().deserializeByClassName(data);
    }
    if (dataClassName.startsWith('serverpod_auth_core.')) {
      data['className'] = dataClassName.substring(20);
      return _i23.Protocol().deserializeByClassName(data);
    }
    if (dataClassName.startsWith('quanitya.')) {
      data['className'] = dataClassName.substring(9);
      return _i24.Protocol().deserializeByClassName(data);
    }
    if (dataClassName.startsWith('anonaccount.')) {
      data['className'] = dataClassName.substring(12);
      return _i25.Protocol().deserializeByClassName(data);
    }
    if (dataClassName.startsWith('anonaccred.')) {
      data['className'] = dataClassName.substring(11);
      return _i26.Protocol().deserializeByClassName(data);
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
      return _i22.Protocol().mapRecordToJson(record);
    } catch (_) {}
    try {
      return _i23.Protocol().mapRecordToJson(record);
    } catch (_) {}
    try {
      return _i24.Protocol().mapRecordToJson(record);
    } catch (_) {}
    try {
      return _i25.Protocol().mapRecordToJson(record);
    } catch (_) {}
    try {
      return _i26.Protocol().mapRecordToJson(record);
    } catch (_) {}
    throw Exception('Unsupported record type ${record.runtimeType}');
  }
}
