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
import 'api_response.dart' as _i4;
import 'cloud_llm_call_type.dart' as _i5;
import 'cloud_llm_structured_request.dart' as _i6;
import 'consumption_schedule_data.dart' as _i7;
import 'error_report.dart' as _i8;
import 'error_report_challenge.dart' as _i9;
import 'feature_access_response.dart' as _i10;
import 'feedback_report.dart' as _i11;
import 'notification.dart' as _i12;
import 'notification_receipt.dart' as _i13;
import 'public_challenge_response.dart' as _i14;
import 'rate_limit_counter.dart' as _i15;
import 'sync_access_status.dart' as _i16;
import 'sync_usage_stats.dart' as _i17;
import 'package:quanitya_cloud_client/src/protocol/admin_signing_key.dart'
    as _i18;
import 'package:serverpod_auth_idp_client/serverpod_auth_idp_client.dart'
    as _i19;
import 'package:serverpod_auth_core_client/serverpod_auth_core_client.dart'
    as _i20;
import 'package:quanitya_client/quanitya_client.dart' as _i21;
import 'package:anonaccount_client/anonaccount_client.dart' as _i22;
import 'package:anonaccred_client/anonaccred_client.dart' as _i23;
export 'admin_signing_key.dart';
export 'analytics_event.dart';
export 'api_response.dart';
export 'cloud_llm_call_type.dart';
export 'cloud_llm_structured_request.dart';
export 'consumption_schedule_data.dart';
export 'error_report.dart';
export 'error_report_challenge.dart';
export 'feature_access_response.dart';
export 'feedback_report.dart';
export 'notification.dart';
export 'notification_receipt.dart';
export 'public_challenge_response.dart';
export 'rate_limit_counter.dart';
export 'sync_access_status.dart';
export 'sync_usage_stats.dart';
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
    if (t == _i4.ApiResponse) {
      return _i4.ApiResponse.fromJson(data) as T;
    }
    if (t == _i5.CloudLlmCallType) {
      return _i5.CloudLlmCallType.fromJson(data) as T;
    }
    if (t == _i6.CloudLlmStructuredRequest) {
      return _i6.CloudLlmStructuredRequest.fromJson(data) as T;
    }
    if (t == _i7.ConsumptionScheduleData) {
      return _i7.ConsumptionScheduleData.fromJson(data) as T;
    }
    if (t == _i8.ErrorReport) {
      return _i8.ErrorReport.fromJson(data) as T;
    }
    if (t == _i9.ErrorReportChallenge) {
      return _i9.ErrorReportChallenge.fromJson(data) as T;
    }
    if (t == _i10.FeatureAccessResponse) {
      return _i10.FeatureAccessResponse.fromJson(data) as T;
    }
    if (t == _i11.FeedbackReport) {
      return _i11.FeedbackReport.fromJson(data) as T;
    }
    if (t == _i12.Notification) {
      return _i12.Notification.fromJson(data) as T;
    }
    if (t == _i13.NotificationReceipt) {
      return _i13.NotificationReceipt.fromJson(data) as T;
    }
    if (t == _i14.PublicChallengeResponse) {
      return _i14.PublicChallengeResponse.fromJson(data) as T;
    }
    if (t == _i15.RateLimitCounter) {
      return _i15.RateLimitCounter.fromJson(data) as T;
    }
    if (t == _i16.SyncAccessStatus) {
      return _i16.SyncAccessStatus.fromJson(data) as T;
    }
    if (t == _i17.SyncUsageStats) {
      return _i17.SyncUsageStats.fromJson(data) as T;
    }
    if (t == _i1.getType<_i2.AdminSigningKey?>()) {
      return (data != null ? _i2.AdminSigningKey.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i3.AnalyticsEvent?>()) {
      return (data != null ? _i3.AnalyticsEvent.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i4.ApiResponse?>()) {
      return (data != null ? _i4.ApiResponse.fromJson(data) : null) as T;
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
    if (t == _i1.getType<_i7.ConsumptionScheduleData?>()) {
      return (data != null ? _i7.ConsumptionScheduleData.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i8.ErrorReport?>()) {
      return (data != null ? _i8.ErrorReport.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i9.ErrorReportChallenge?>()) {
      return (data != null ? _i9.ErrorReportChallenge.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i10.FeatureAccessResponse?>()) {
      return (data != null ? _i10.FeatureAccessResponse.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i11.FeedbackReport?>()) {
      return (data != null ? _i11.FeedbackReport.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i12.Notification?>()) {
      return (data != null ? _i12.Notification.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i13.NotificationReceipt?>()) {
      return (data != null ? _i13.NotificationReceipt.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i14.PublicChallengeResponse?>()) {
      return (data != null ? _i14.PublicChallengeResponse.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i15.RateLimitCounter?>()) {
      return (data != null ? _i15.RateLimitCounter.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i16.SyncAccessStatus?>()) {
      return (data != null ? _i16.SyncAccessStatus.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i17.SyncUsageStats?>()) {
      return (data != null ? _i17.SyncUsageStats.fromJson(data) : null) as T;
    }
    if (t == List<_i18.AdminSigningKey>) {
      return (data as List)
              .map((e) => deserialize<_i18.AdminSigningKey>(e))
              .toList()
          as T;
    }
    if (t == Map<int, double>) {
      return Map.fromEntries(
            (data as List).map(
              (e) => MapEntry(
                deserialize<int>(e['k']),
                deserialize<double>(e['v']),
              ),
            ),
          )
          as T;
    }
    if (t == List<int>) {
      return (data as List).map((e) => deserialize<int>(e)).toList() as T;
    }
    if (t == _i1.getType<List<int>?>()) {
      return (data != null
              ? (data as List).map((e) => deserialize<int>(e)).toList()
              : null)
          as T;
    }
    if (t == List<String>) {
      return (data as List).map((e) => deserialize<String>(e)).toList() as T;
    }
    try {
      return _i19.Protocol().deserialize<T>(data, t);
    } on _i1.DeserializationTypeNotFoundException catch (_) {}
    try {
      return _i20.Protocol().deserialize<T>(data, t);
    } on _i1.DeserializationTypeNotFoundException catch (_) {}
    try {
      return _i21.Protocol().deserialize<T>(data, t);
    } on _i1.DeserializationTypeNotFoundException catch (_) {}
    try {
      return _i22.Protocol().deserialize<T>(data, t);
    } on _i1.DeserializationTypeNotFoundException catch (_) {}
    try {
      return _i23.Protocol().deserialize<T>(data, t);
    } on _i1.DeserializationTypeNotFoundException catch (_) {}
    return super.deserialize<T>(data, t);
  }

  static String? getClassNameForType(Type type) {
    return switch (type) {
      _i2.AdminSigningKey => 'AdminSigningKey',
      _i3.AnalyticsEvent => 'AnalyticsEvent',
      _i4.ApiResponse => 'ApiResponse',
      _i5.CloudLlmCallType => 'CloudLlmCallType',
      _i6.CloudLlmStructuredRequest => 'CloudLlmStructuredRequest',
      _i7.ConsumptionScheduleData => 'ConsumptionScheduleData',
      _i8.ErrorReport => 'ErrorReport',
      _i9.ErrorReportChallenge => 'ErrorReportChallenge',
      _i10.FeatureAccessResponse => 'FeatureAccessResponse',
      _i11.FeedbackReport => 'FeedbackReport',
      _i12.Notification => 'Notification',
      _i13.NotificationReceipt => 'NotificationReceipt',
      _i14.PublicChallengeResponse => 'PublicChallengeResponse',
      _i15.RateLimitCounter => 'RateLimitCounter',
      _i16.SyncAccessStatus => 'SyncAccessStatus',
      _i17.SyncUsageStats => 'SyncUsageStats',
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
      case _i4.ApiResponse():
        return 'ApiResponse';
      case _i5.CloudLlmCallType():
        return 'CloudLlmCallType';
      case _i6.CloudLlmStructuredRequest():
        return 'CloudLlmStructuredRequest';
      case _i7.ConsumptionScheduleData():
        return 'ConsumptionScheduleData';
      case _i8.ErrorReport():
        return 'ErrorReport';
      case _i9.ErrorReportChallenge():
        return 'ErrorReportChallenge';
      case _i10.FeatureAccessResponse():
        return 'FeatureAccessResponse';
      case _i11.FeedbackReport():
        return 'FeedbackReport';
      case _i12.Notification():
        return 'Notification';
      case _i13.NotificationReceipt():
        return 'NotificationReceipt';
      case _i14.PublicChallengeResponse():
        return 'PublicChallengeResponse';
      case _i15.RateLimitCounter():
        return 'RateLimitCounter';
      case _i16.SyncAccessStatus():
        return 'SyncAccessStatus';
      case _i17.SyncUsageStats():
        return 'SyncUsageStats';
    }
    className = _i19.Protocol().getClassNameForObject(data);
    if (className != null) {
      return 'serverpod_auth_idp.$className';
    }
    className = _i20.Protocol().getClassNameForObject(data);
    if (className != null) {
      return 'serverpod_auth_core.$className';
    }
    className = _i21.Protocol().getClassNameForObject(data);
    if (className != null) {
      return 'quanitya.$className';
    }
    className = _i22.Protocol().getClassNameForObject(data);
    if (className != null) {
      return 'anonaccount.$className';
    }
    className = _i23.Protocol().getClassNameForObject(data);
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
    if (dataClassName == 'ApiResponse') {
      return deserialize<_i4.ApiResponse>(data['data']);
    }
    if (dataClassName == 'CloudLlmCallType') {
      return deserialize<_i5.CloudLlmCallType>(data['data']);
    }
    if (dataClassName == 'CloudLlmStructuredRequest') {
      return deserialize<_i6.CloudLlmStructuredRequest>(data['data']);
    }
    if (dataClassName == 'ConsumptionScheduleData') {
      return deserialize<_i7.ConsumptionScheduleData>(data['data']);
    }
    if (dataClassName == 'ErrorReport') {
      return deserialize<_i8.ErrorReport>(data['data']);
    }
    if (dataClassName == 'ErrorReportChallenge') {
      return deserialize<_i9.ErrorReportChallenge>(data['data']);
    }
    if (dataClassName == 'FeatureAccessResponse') {
      return deserialize<_i10.FeatureAccessResponse>(data['data']);
    }
    if (dataClassName == 'FeedbackReport') {
      return deserialize<_i11.FeedbackReport>(data['data']);
    }
    if (dataClassName == 'Notification') {
      return deserialize<_i12.Notification>(data['data']);
    }
    if (dataClassName == 'NotificationReceipt') {
      return deserialize<_i13.NotificationReceipt>(data['data']);
    }
    if (dataClassName == 'PublicChallengeResponse') {
      return deserialize<_i14.PublicChallengeResponse>(data['data']);
    }
    if (dataClassName == 'RateLimitCounter') {
      return deserialize<_i15.RateLimitCounter>(data['data']);
    }
    if (dataClassName == 'SyncAccessStatus') {
      return deserialize<_i16.SyncAccessStatus>(data['data']);
    }
    if (dataClassName == 'SyncUsageStats') {
      return deserialize<_i17.SyncUsageStats>(data['data']);
    }
    if (dataClassName.startsWith('serverpod_auth_idp.')) {
      data['className'] = dataClassName.substring(19);
      return _i19.Protocol().deserializeByClassName(data);
    }
    if (dataClassName.startsWith('serverpod_auth_core.')) {
      data['className'] = dataClassName.substring(20);
      return _i20.Protocol().deserializeByClassName(data);
    }
    if (dataClassName.startsWith('quanitya.')) {
      data['className'] = dataClassName.substring(9);
      return _i21.Protocol().deserializeByClassName(data);
    }
    if (dataClassName.startsWith('anonaccount.')) {
      data['className'] = dataClassName.substring(12);
      return _i22.Protocol().deserializeByClassName(data);
    }
    if (dataClassName.startsWith('anonaccred.')) {
      data['className'] = dataClassName.substring(11);
      return _i23.Protocol().deserializeByClassName(data);
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
      return _i19.Protocol().mapRecordToJson(record);
    } catch (_) {}
    try {
      return _i20.Protocol().mapRecordToJson(record);
    } catch (_) {}
    try {
      return _i21.Protocol().mapRecordToJson(record);
    } catch (_) {}
    try {
      return _i22.Protocol().mapRecordToJson(record);
    } catch (_) {}
    try {
      return _i23.Protocol().mapRecordToJson(record);
    } catch (_) {}
    throw Exception('Unsupported record type ${record.runtimeType}');
  }

  /// Maps container types (like [List], [Map], [Set]) containing
  /// [Record]s or non-String-keyed [Map]s to their JSON representation.
  ///
  /// It should not be called for [SerializableModel] types. These
  /// handle the "[Record] in container" mapping internally already.
  ///
  /// It is only supposed to be called from generated protocol code.
  ///
  /// Returns either a `List<dynamic>` (for List, Sets, and Maps with
  /// non-String keys) or a `Map<String, dynamic>` in case the input was
  /// a `Map<String, …>`.
  Object? mapContainerToJson(Object obj) {
    if (obj is! Iterable && obj is! Map) {
      throw ArgumentError.value(
        obj,
        'obj',
        'The object to serialize should be of type List, Map, or Set',
      );
    }

    dynamic mapIfNeeded(Object? obj) {
      return switch (obj) {
        Record record => mapRecordToJson(record),
        Iterable iterable => mapContainerToJson(iterable),
        Map map => mapContainerToJson(map),
        Object? value => value,
      };
    }

    switch (obj) {
      case Map<String, dynamic>():
        return {
          for (var entry in obj.entries) entry.key: mapIfNeeded(entry.value),
        };
      case Map():
        return [
          for (var entry in obj.entries)
            {
              'k': mapIfNeeded(entry.key),
              'v': mapIfNeeded(entry.value),
            },
        ];

      case Iterable():
        return [
          for (var e in obj) mapIfNeeded(e),
        ];
    }

    return obj;
  }
}
