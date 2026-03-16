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
import 'admin_action_result.dart' as _i2;
import 'admin_pagination_info.dart' as _i3;
import 'admin_role.dart' as _i4;
import 'admin_signing_key.dart' as _i5;
import 'analytics_event.dart' as _i6;
import 'analytics_statistics.dart' as _i7;
import 'batch_submission_result.dart' as _i8;
import 'cloud_llm_call_type.dart' as _i9;
import 'cloud_llm_structured_request.dart' as _i10;
import 'cloud_llm_structured_response.dart' as _i11;
import 'consumption_schedule_data.dart' as _i12;
import 'error_report.dart' as _i13;
import 'error_statistics.dart' as _i14;
import 'feedback_report.dart' as _i15;
import 'feedback_statistics.dart' as _i16;
import 'feedback_type.dart' as _i17;
import 'notification.dart' as _i18;
import 'notification_create_result.dart' as _i19;
import 'notification_details.dart' as _i20;
import 'notification_receipt.dart' as _i21;
import 'notification_statistics.dart' as _i22;
import 'notification_type.dart' as _i23;
import 'paginated_analytics_events.dart' as _i24;
import 'paginated_error_reports.dart' as _i25;
import 'paginated_feedback_reports.dart' as _i26;
import 'paginated_notifications.dart' as _i27;
import 'platform_catalog_response.dart' as _i28;
import 'platform_rail_entry.dart' as _i29;
import 'platform_rail_list.dart' as _i30;
import 'rail_catalog_entry.dart' as _i31;
import 'rail_status.dart' as _i32;
import 'server_error_code.dart' as _i33;
import 'server_exception.dart' as _i34;
import 'sync_access_info.dart' as _i35;
import 'sync_access_status.dart' as _i36;
import 'sync_tier_balance.dart' as _i37;
import 'sync_usage_stats.dart' as _i38;
import 'package:quanitya_cloud_client/src/protocol/admin_signing_key.dart'
    as _i39;
import 'package:serverpod_auth_idp_client/serverpod_auth_idp_client.dart'
    as _i40;
import 'package:serverpod_auth_core_client/serverpod_auth_core_client.dart'
    as _i41;
import 'package:quanitya_client/quanitya_client.dart' as _i42;
import 'package:anonaccount_client/anonaccount_client.dart' as _i43;
import 'package:anonaccred_client/anonaccred_client.dart' as _i44;
export 'admin_action_result.dart';
export 'admin_pagination_info.dart';
export 'admin_role.dart';
export 'admin_signing_key.dart';
export 'analytics_event.dart';
export 'analytics_statistics.dart';
export 'batch_submission_result.dart';
export 'cloud_llm_call_type.dart';
export 'cloud_llm_structured_request.dart';
export 'cloud_llm_structured_response.dart';
export 'consumption_schedule_data.dart';
export 'error_report.dart';
export 'error_statistics.dart';
export 'feedback_report.dart';
export 'feedback_statistics.dart';
export 'feedback_type.dart';
export 'notification.dart';
export 'notification_create_result.dart';
export 'notification_details.dart';
export 'notification_receipt.dart';
export 'notification_statistics.dart';
export 'notification_type.dart';
export 'paginated_analytics_events.dart';
export 'paginated_error_reports.dart';
export 'paginated_feedback_reports.dart';
export 'paginated_notifications.dart';
export 'platform_catalog_response.dart';
export 'platform_rail_entry.dart';
export 'platform_rail_list.dart';
export 'rail_catalog_entry.dart';
export 'rail_status.dart';
export 'server_error_code.dart';
export 'server_exception.dart';
export 'sync_access_info.dart';
export 'sync_access_status.dart';
export 'sync_tier_balance.dart';
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

    if (t == _i2.AdminActionResult) {
      return _i2.AdminActionResult.fromJson(data) as T;
    }
    if (t == _i3.AdminPaginationInfo) {
      return _i3.AdminPaginationInfo.fromJson(data) as T;
    }
    if (t == _i4.AdminRole) {
      return _i4.AdminRole.fromJson(data) as T;
    }
    if (t == _i5.AdminSigningKey) {
      return _i5.AdminSigningKey.fromJson(data) as T;
    }
    if (t == _i6.AnalyticsEvent) {
      return _i6.AnalyticsEvent.fromJson(data) as T;
    }
    if (t == _i7.AnalyticsStatistics) {
      return _i7.AnalyticsStatistics.fromJson(data) as T;
    }
    if (t == _i8.BatchSubmissionResult) {
      return _i8.BatchSubmissionResult.fromJson(data) as T;
    }
    if (t == _i9.CloudLlmCallType) {
      return _i9.CloudLlmCallType.fromJson(data) as T;
    }
    if (t == _i10.CloudLlmStructuredRequest) {
      return _i10.CloudLlmStructuredRequest.fromJson(data) as T;
    }
    if (t == _i11.CloudLlmStructuredResponse) {
      return _i11.CloudLlmStructuredResponse.fromJson(data) as T;
    }
    if (t == _i12.ConsumptionScheduleData) {
      return _i12.ConsumptionScheduleData.fromJson(data) as T;
    }
    if (t == _i13.ErrorReport) {
      return _i13.ErrorReport.fromJson(data) as T;
    }
    if (t == _i14.ErrorStatistics) {
      return _i14.ErrorStatistics.fromJson(data) as T;
    }
    if (t == _i15.FeedbackReport) {
      return _i15.FeedbackReport.fromJson(data) as T;
    }
    if (t == _i16.FeedbackStatistics) {
      return _i16.FeedbackStatistics.fromJson(data) as T;
    }
    if (t == _i17.FeedbackType) {
      return _i17.FeedbackType.fromJson(data) as T;
    }
    if (t == _i18.Notification) {
      return _i18.Notification.fromJson(data) as T;
    }
    if (t == _i19.NotificationCreateResult) {
      return _i19.NotificationCreateResult.fromJson(data) as T;
    }
    if (t == _i20.NotificationDetails) {
      return _i20.NotificationDetails.fromJson(data) as T;
    }
    if (t == _i21.NotificationReceipt) {
      return _i21.NotificationReceipt.fromJson(data) as T;
    }
    if (t == _i22.NotificationStatistics) {
      return _i22.NotificationStatistics.fromJson(data) as T;
    }
    if (t == _i23.NotificationType) {
      return _i23.NotificationType.fromJson(data) as T;
    }
    if (t == _i24.PaginatedAnalyticsEvents) {
      return _i24.PaginatedAnalyticsEvents.fromJson(data) as T;
    }
    if (t == _i25.PaginatedErrorReports) {
      return _i25.PaginatedErrorReports.fromJson(data) as T;
    }
    if (t == _i26.PaginatedFeedbackReports) {
      return _i26.PaginatedFeedbackReports.fromJson(data) as T;
    }
    if (t == _i27.PaginatedNotifications) {
      return _i27.PaginatedNotifications.fromJson(data) as T;
    }
    if (t == _i28.PlatformCatalogResponse) {
      return _i28.PlatformCatalogResponse.fromJson(data) as T;
    }
    if (t == _i29.PlatformRailEntry) {
      return _i29.PlatformRailEntry.fromJson(data) as T;
    }
    if (t == _i30.PlatformRailList) {
      return _i30.PlatformRailList.fromJson(data) as T;
    }
    if (t == _i31.RailCatalogEntry) {
      return _i31.RailCatalogEntry.fromJson(data) as T;
    }
    if (t == _i32.RailStatus) {
      return _i32.RailStatus.fromJson(data) as T;
    }
    if (t == _i33.ServerErrorCode) {
      return _i33.ServerErrorCode.fromJson(data) as T;
    }
    if (t == _i34.ServerException) {
      return _i34.ServerException.fromJson(data) as T;
    }
    if (t == _i35.SyncAccessInfo) {
      return _i35.SyncAccessInfo.fromJson(data) as T;
    }
    if (t == _i36.SyncAccessStatus) {
      return _i36.SyncAccessStatus.fromJson(data) as T;
    }
    if (t == _i37.SyncTierBalance) {
      return _i37.SyncTierBalance.fromJson(data) as T;
    }
    if (t == _i38.SyncUsageStats) {
      return _i38.SyncUsageStats.fromJson(data) as T;
    }
    if (t == _i1.getType<_i2.AdminActionResult?>()) {
      return (data != null ? _i2.AdminActionResult.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i3.AdminPaginationInfo?>()) {
      return (data != null ? _i3.AdminPaginationInfo.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i4.AdminRole?>()) {
      return (data != null ? _i4.AdminRole.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i5.AdminSigningKey?>()) {
      return (data != null ? _i5.AdminSigningKey.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i6.AnalyticsEvent?>()) {
      return (data != null ? _i6.AnalyticsEvent.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i7.AnalyticsStatistics?>()) {
      return (data != null ? _i7.AnalyticsStatistics.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i8.BatchSubmissionResult?>()) {
      return (data != null ? _i8.BatchSubmissionResult.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i9.CloudLlmCallType?>()) {
      return (data != null ? _i9.CloudLlmCallType.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i10.CloudLlmStructuredRequest?>()) {
      return (data != null
              ? _i10.CloudLlmStructuredRequest.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i11.CloudLlmStructuredResponse?>()) {
      return (data != null
              ? _i11.CloudLlmStructuredResponse.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i12.ConsumptionScheduleData?>()) {
      return (data != null ? _i12.ConsumptionScheduleData.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i13.ErrorReport?>()) {
      return (data != null ? _i13.ErrorReport.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i14.ErrorStatistics?>()) {
      return (data != null ? _i14.ErrorStatistics.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i15.FeedbackReport?>()) {
      return (data != null ? _i15.FeedbackReport.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i16.FeedbackStatistics?>()) {
      return (data != null ? _i16.FeedbackStatistics.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i17.FeedbackType?>()) {
      return (data != null ? _i17.FeedbackType.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i18.Notification?>()) {
      return (data != null ? _i18.Notification.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i19.NotificationCreateResult?>()) {
      return (data != null
              ? _i19.NotificationCreateResult.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i20.NotificationDetails?>()) {
      return (data != null ? _i20.NotificationDetails.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i21.NotificationReceipt?>()) {
      return (data != null ? _i21.NotificationReceipt.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i22.NotificationStatistics?>()) {
      return (data != null ? _i22.NotificationStatistics.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i23.NotificationType?>()) {
      return (data != null ? _i23.NotificationType.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i24.PaginatedAnalyticsEvents?>()) {
      return (data != null
              ? _i24.PaginatedAnalyticsEvents.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i25.PaginatedErrorReports?>()) {
      return (data != null ? _i25.PaginatedErrorReports.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i26.PaginatedFeedbackReports?>()) {
      return (data != null
              ? _i26.PaginatedFeedbackReports.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i27.PaginatedNotifications?>()) {
      return (data != null ? _i27.PaginatedNotifications.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i28.PlatformCatalogResponse?>()) {
      return (data != null ? _i28.PlatformCatalogResponse.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i29.PlatformRailEntry?>()) {
      return (data != null ? _i29.PlatformRailEntry.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i30.PlatformRailList?>()) {
      return (data != null ? _i30.PlatformRailList.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i31.RailCatalogEntry?>()) {
      return (data != null ? _i31.RailCatalogEntry.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i32.RailStatus?>()) {
      return (data != null ? _i32.RailStatus.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i33.ServerErrorCode?>()) {
      return (data != null ? _i33.ServerErrorCode.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i34.ServerException?>()) {
      return (data != null ? _i34.ServerException.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i35.SyncAccessInfo?>()) {
      return (data != null ? _i35.SyncAccessInfo.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i36.SyncAccessStatus?>()) {
      return (data != null ? _i36.SyncAccessStatus.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i37.SyncTierBalance?>()) {
      return (data != null ? _i37.SyncTierBalance.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i38.SyncUsageStats?>()) {
      return (data != null ? _i38.SyncUsageStats.fromJson(data) : null) as T;
    }
    if (t == Map<String, int>) {
      return (data as Map).map(
            (k, v) => MapEntry(deserialize<String>(k), deserialize<int>(v)),
          )
          as T;
    }
    if (t == List<_i6.AnalyticsEvent>) {
      return (data as List)
              .map((e) => deserialize<_i6.AnalyticsEvent>(e))
              .toList()
          as T;
    }
    if (t == List<_i13.ErrorReport>) {
      return (data as List)
              .map((e) => deserialize<_i13.ErrorReport>(e))
              .toList()
          as T;
    }
    if (t == List<_i15.FeedbackReport>) {
      return (data as List)
              .map((e) => deserialize<_i15.FeedbackReport>(e))
              .toList()
          as T;
    }
    if (t == List<String>) {
      return (data as List).map((e) => deserialize<String>(e)).toList() as T;
    }
    if (t == List<_i21.NotificationReceipt>) {
      return (data as List)
              .map((e) => deserialize<_i21.NotificationReceipt>(e))
              .toList()
          as T;
    }
    if (t == List<_i18.Notification>) {
      return (data as List)
              .map((e) => deserialize<_i18.Notification>(e))
              .toList()
          as T;
    }
    if (t == List<_i31.RailCatalogEntry>) {
      return (data as List)
              .map((e) => deserialize<_i31.RailCatalogEntry>(e))
              .toList()
          as T;
    }
    if (t == List<_i29.PlatformRailEntry>) {
      return (data as List)
              .map((e) => deserialize<_i29.PlatformRailEntry>(e))
              .toList()
          as T;
    }
    if (t == List<_i37.SyncTierBalance>) {
      return (data as List)
              .map((e) => deserialize<_i37.SyncTierBalance>(e))
              .toList()
          as T;
    }
    if (t == List<_i39.AdminSigningKey>) {
      return (data as List)
              .map((e) => deserialize<_i39.AdminSigningKey>(e))
              .toList()
          as T;
    }
    if (t == List<String>) {
      return (data as List).map((e) => deserialize<String>(e)).toList() as T;
    }
    if (t == _i1.getType<List<String>?>()) {
      return (data != null
              ? (data as List).map((e) => deserialize<String>(e)).toList()
              : null)
          as T;
    }
    try {
      return _i40.Protocol().deserialize<T>(data, t);
    } on _i1.DeserializationTypeNotFoundException catch (_) {}
    try {
      return _i41.Protocol().deserialize<T>(data, t);
    } on _i1.DeserializationTypeNotFoundException catch (_) {}
    try {
      return _i42.Protocol().deserialize<T>(data, t);
    } on _i1.DeserializationTypeNotFoundException catch (_) {}
    try {
      return _i43.Protocol().deserialize<T>(data, t);
    } on _i1.DeserializationTypeNotFoundException catch (_) {}
    try {
      return _i44.Protocol().deserialize<T>(data, t);
    } on _i1.DeserializationTypeNotFoundException catch (_) {}
    return super.deserialize<T>(data, t);
  }

  static String? getClassNameForType(Type type) {
    return switch (type) {
      _i2.AdminActionResult => 'AdminActionResult',
      _i3.AdminPaginationInfo => 'AdminPaginationInfo',
      _i4.AdminRole => 'AdminRole',
      _i5.AdminSigningKey => 'AdminSigningKey',
      _i6.AnalyticsEvent => 'AnalyticsEvent',
      _i7.AnalyticsStatistics => 'AnalyticsStatistics',
      _i8.BatchSubmissionResult => 'BatchSubmissionResult',
      _i9.CloudLlmCallType => 'CloudLlmCallType',
      _i10.CloudLlmStructuredRequest => 'CloudLlmStructuredRequest',
      _i11.CloudLlmStructuredResponse => 'CloudLlmStructuredResponse',
      _i12.ConsumptionScheduleData => 'ConsumptionScheduleData',
      _i13.ErrorReport => 'ErrorReport',
      _i14.ErrorStatistics => 'ErrorStatistics',
      _i15.FeedbackReport => 'FeedbackReport',
      _i16.FeedbackStatistics => 'FeedbackStatistics',
      _i17.FeedbackType => 'FeedbackType',
      _i18.Notification => 'Notification',
      _i19.NotificationCreateResult => 'NotificationCreateResult',
      _i20.NotificationDetails => 'NotificationDetails',
      _i21.NotificationReceipt => 'NotificationReceipt',
      _i22.NotificationStatistics => 'NotificationStatistics',
      _i23.NotificationType => 'NotificationType',
      _i24.PaginatedAnalyticsEvents => 'PaginatedAnalyticsEvents',
      _i25.PaginatedErrorReports => 'PaginatedErrorReports',
      _i26.PaginatedFeedbackReports => 'PaginatedFeedbackReports',
      _i27.PaginatedNotifications => 'PaginatedNotifications',
      _i28.PlatformCatalogResponse => 'PlatformCatalogResponse',
      _i29.PlatformRailEntry => 'PlatformRailEntry',
      _i30.PlatformRailList => 'PlatformRailList',
      _i31.RailCatalogEntry => 'RailCatalogEntry',
      _i32.RailStatus => 'RailStatus',
      _i33.ServerErrorCode => 'ServerErrorCode',
      _i34.ServerException => 'ServerException',
      _i35.SyncAccessInfo => 'SyncAccessInfo',
      _i36.SyncAccessStatus => 'SyncAccessStatus',
      _i37.SyncTierBalance => 'SyncTierBalance',
      _i38.SyncUsageStats => 'SyncUsageStats',
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
      case _i2.AdminActionResult():
        return 'AdminActionResult';
      case _i3.AdminPaginationInfo():
        return 'AdminPaginationInfo';
      case _i4.AdminRole():
        return 'AdminRole';
      case _i5.AdminSigningKey():
        return 'AdminSigningKey';
      case _i6.AnalyticsEvent():
        return 'AnalyticsEvent';
      case _i7.AnalyticsStatistics():
        return 'AnalyticsStatistics';
      case _i8.BatchSubmissionResult():
        return 'BatchSubmissionResult';
      case _i9.CloudLlmCallType():
        return 'CloudLlmCallType';
      case _i10.CloudLlmStructuredRequest():
        return 'CloudLlmStructuredRequest';
      case _i11.CloudLlmStructuredResponse():
        return 'CloudLlmStructuredResponse';
      case _i12.ConsumptionScheduleData():
        return 'ConsumptionScheduleData';
      case _i13.ErrorReport():
        return 'ErrorReport';
      case _i14.ErrorStatistics():
        return 'ErrorStatistics';
      case _i15.FeedbackReport():
        return 'FeedbackReport';
      case _i16.FeedbackStatistics():
        return 'FeedbackStatistics';
      case _i17.FeedbackType():
        return 'FeedbackType';
      case _i18.Notification():
        return 'Notification';
      case _i19.NotificationCreateResult():
        return 'NotificationCreateResult';
      case _i20.NotificationDetails():
        return 'NotificationDetails';
      case _i21.NotificationReceipt():
        return 'NotificationReceipt';
      case _i22.NotificationStatistics():
        return 'NotificationStatistics';
      case _i23.NotificationType():
        return 'NotificationType';
      case _i24.PaginatedAnalyticsEvents():
        return 'PaginatedAnalyticsEvents';
      case _i25.PaginatedErrorReports():
        return 'PaginatedErrorReports';
      case _i26.PaginatedFeedbackReports():
        return 'PaginatedFeedbackReports';
      case _i27.PaginatedNotifications():
        return 'PaginatedNotifications';
      case _i28.PlatformCatalogResponse():
        return 'PlatformCatalogResponse';
      case _i29.PlatformRailEntry():
        return 'PlatformRailEntry';
      case _i30.PlatformRailList():
        return 'PlatformRailList';
      case _i31.RailCatalogEntry():
        return 'RailCatalogEntry';
      case _i32.RailStatus():
        return 'RailStatus';
      case _i33.ServerErrorCode():
        return 'ServerErrorCode';
      case _i34.ServerException():
        return 'ServerException';
      case _i35.SyncAccessInfo():
        return 'SyncAccessInfo';
      case _i36.SyncAccessStatus():
        return 'SyncAccessStatus';
      case _i37.SyncTierBalance():
        return 'SyncTierBalance';
      case _i38.SyncUsageStats():
        return 'SyncUsageStats';
    }
    className = _i40.Protocol().getClassNameForObject(data);
    if (className != null) {
      return 'serverpod_auth_idp.$className';
    }
    className = _i41.Protocol().getClassNameForObject(data);
    if (className != null) {
      return 'serverpod_auth_core.$className';
    }
    className = _i42.Protocol().getClassNameForObject(data);
    if (className != null) {
      return 'quanitya.$className';
    }
    className = _i43.Protocol().getClassNameForObject(data);
    if (className != null) {
      return 'anonaccount.$className';
    }
    className = _i44.Protocol().getClassNameForObject(data);
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
    if (dataClassName == 'AdminActionResult') {
      return deserialize<_i2.AdminActionResult>(data['data']);
    }
    if (dataClassName == 'AdminPaginationInfo') {
      return deserialize<_i3.AdminPaginationInfo>(data['data']);
    }
    if (dataClassName == 'AdminRole') {
      return deserialize<_i4.AdminRole>(data['data']);
    }
    if (dataClassName == 'AdminSigningKey') {
      return deserialize<_i5.AdminSigningKey>(data['data']);
    }
    if (dataClassName == 'AnalyticsEvent') {
      return deserialize<_i6.AnalyticsEvent>(data['data']);
    }
    if (dataClassName == 'AnalyticsStatistics') {
      return deserialize<_i7.AnalyticsStatistics>(data['data']);
    }
    if (dataClassName == 'BatchSubmissionResult') {
      return deserialize<_i8.BatchSubmissionResult>(data['data']);
    }
    if (dataClassName == 'CloudLlmCallType') {
      return deserialize<_i9.CloudLlmCallType>(data['data']);
    }
    if (dataClassName == 'CloudLlmStructuredRequest') {
      return deserialize<_i10.CloudLlmStructuredRequest>(data['data']);
    }
    if (dataClassName == 'CloudLlmStructuredResponse') {
      return deserialize<_i11.CloudLlmStructuredResponse>(data['data']);
    }
    if (dataClassName == 'ConsumptionScheduleData') {
      return deserialize<_i12.ConsumptionScheduleData>(data['data']);
    }
    if (dataClassName == 'ErrorReport') {
      return deserialize<_i13.ErrorReport>(data['data']);
    }
    if (dataClassName == 'ErrorStatistics') {
      return deserialize<_i14.ErrorStatistics>(data['data']);
    }
    if (dataClassName == 'FeedbackReport') {
      return deserialize<_i15.FeedbackReport>(data['data']);
    }
    if (dataClassName == 'FeedbackStatistics') {
      return deserialize<_i16.FeedbackStatistics>(data['data']);
    }
    if (dataClassName == 'FeedbackType') {
      return deserialize<_i17.FeedbackType>(data['data']);
    }
    if (dataClassName == 'Notification') {
      return deserialize<_i18.Notification>(data['data']);
    }
    if (dataClassName == 'NotificationCreateResult') {
      return deserialize<_i19.NotificationCreateResult>(data['data']);
    }
    if (dataClassName == 'NotificationDetails') {
      return deserialize<_i20.NotificationDetails>(data['data']);
    }
    if (dataClassName == 'NotificationReceipt') {
      return deserialize<_i21.NotificationReceipt>(data['data']);
    }
    if (dataClassName == 'NotificationStatistics') {
      return deserialize<_i22.NotificationStatistics>(data['data']);
    }
    if (dataClassName == 'NotificationType') {
      return deserialize<_i23.NotificationType>(data['data']);
    }
    if (dataClassName == 'PaginatedAnalyticsEvents') {
      return deserialize<_i24.PaginatedAnalyticsEvents>(data['data']);
    }
    if (dataClassName == 'PaginatedErrorReports') {
      return deserialize<_i25.PaginatedErrorReports>(data['data']);
    }
    if (dataClassName == 'PaginatedFeedbackReports') {
      return deserialize<_i26.PaginatedFeedbackReports>(data['data']);
    }
    if (dataClassName == 'PaginatedNotifications') {
      return deserialize<_i27.PaginatedNotifications>(data['data']);
    }
    if (dataClassName == 'PlatformCatalogResponse') {
      return deserialize<_i28.PlatformCatalogResponse>(data['data']);
    }
    if (dataClassName == 'PlatformRailEntry') {
      return deserialize<_i29.PlatformRailEntry>(data['data']);
    }
    if (dataClassName == 'PlatformRailList') {
      return deserialize<_i30.PlatformRailList>(data['data']);
    }
    if (dataClassName == 'RailCatalogEntry') {
      return deserialize<_i31.RailCatalogEntry>(data['data']);
    }
    if (dataClassName == 'RailStatus') {
      return deserialize<_i32.RailStatus>(data['data']);
    }
    if (dataClassName == 'ServerErrorCode') {
      return deserialize<_i33.ServerErrorCode>(data['data']);
    }
    if (dataClassName == 'ServerException') {
      return deserialize<_i34.ServerException>(data['data']);
    }
    if (dataClassName == 'SyncAccessInfo') {
      return deserialize<_i35.SyncAccessInfo>(data['data']);
    }
    if (dataClassName == 'SyncAccessStatus') {
      return deserialize<_i36.SyncAccessStatus>(data['data']);
    }
    if (dataClassName == 'SyncTierBalance') {
      return deserialize<_i37.SyncTierBalance>(data['data']);
    }
    if (dataClassName == 'SyncUsageStats') {
      return deserialize<_i38.SyncUsageStats>(data['data']);
    }
    if (dataClassName.startsWith('serverpod_auth_idp.')) {
      data['className'] = dataClassName.substring(19);
      return _i40.Protocol().deserializeByClassName(data);
    }
    if (dataClassName.startsWith('serverpod_auth_core.')) {
      data['className'] = dataClassName.substring(20);
      return _i41.Protocol().deserializeByClassName(data);
    }
    if (dataClassName.startsWith('quanitya.')) {
      data['className'] = dataClassName.substring(9);
      return _i42.Protocol().deserializeByClassName(data);
    }
    if (dataClassName.startsWith('anonaccount.')) {
      data['className'] = dataClassName.substring(12);
      return _i43.Protocol().deserializeByClassName(data);
    }
    if (dataClassName.startsWith('anonaccred.')) {
      data['className'] = dataClassName.substring(11);
      return _i44.Protocol().deserializeByClassName(data);
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
      return _i40.Protocol().mapRecordToJson(record);
    } catch (_) {}
    try {
      return _i41.Protocol().mapRecordToJson(record);
    } catch (_) {}
    try {
      return _i42.Protocol().mapRecordToJson(record);
    } catch (_) {}
    try {
      return _i43.Protocol().mapRecordToJson(record);
    } catch (_) {}
    try {
      return _i44.Protocol().mapRecordToJson(record);
    } catch (_) {}
    throw Exception('Unsupported record type ${record.runtimeType}');
  }
}
