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

abstract class ErrorReport implements _i1.SerializableModel {
  ErrorReport._({
    this.id,
    required this.source,
    required this.errorType,
    required this.errorCode,
    required this.stackTrace,
    required this.clientTimestamp,
    this.userMessage,
    required this.serverReceivedAt,
    this.appVersion,
    this.platform,
    this.deviceInfo,
  });

  factory ErrorReport({
    int? id,
    required String source,
    required String errorType,
    required String errorCode,
    required String stackTrace,
    required DateTime clientTimestamp,
    String? userMessage,
    required DateTime serverReceivedAt,
    String? appVersion,
    String? platform,
    String? deviceInfo,
  }) = _ErrorReportImpl;

  factory ErrorReport.fromJson(Map<String, dynamic> jsonSerialization) {
    return ErrorReport(
      id: jsonSerialization['id'] as int?,
      source: jsonSerialization['source'] as String,
      errorType: jsonSerialization['errorType'] as String,
      errorCode: jsonSerialization['errorCode'] as String,
      stackTrace: jsonSerialization['stackTrace'] as String,
      clientTimestamp: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['clientTimestamp'],
      ),
      userMessage: jsonSerialization['userMessage'] as String?,
      serverReceivedAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['serverReceivedAt'],
      ),
      appVersion: jsonSerialization['appVersion'] as String?,
      platform: jsonSerialization['platform'] as String?,
      deviceInfo: jsonSerialization['deviceInfo'] as String?,
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  String source;

  String errorType;

  String errorCode;

  String stackTrace;

  DateTime clientTimestamp;

  String? userMessage;

  DateTime serverReceivedAt;

  String? appVersion;

  String? platform;

  String? deviceInfo;

  /// Returns a shallow copy of this [ErrorReport]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  ErrorReport copyWith({
    int? id,
    String? source,
    String? errorType,
    String? errorCode,
    String? stackTrace,
    DateTime? clientTimestamp,
    String? userMessage,
    DateTime? serverReceivedAt,
    String? appVersion,
    String? platform,
    String? deviceInfo,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'ErrorReport',
      if (id != null) 'id': id,
      'source': source,
      'errorType': errorType,
      'errorCode': errorCode,
      'stackTrace': stackTrace,
      'clientTimestamp': clientTimestamp.toJson(),
      if (userMessage != null) 'userMessage': userMessage,
      'serverReceivedAt': serverReceivedAt.toJson(),
      if (appVersion != null) 'appVersion': appVersion,
      if (platform != null) 'platform': platform,
      if (deviceInfo != null) 'deviceInfo': deviceInfo,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _ErrorReportImpl extends ErrorReport {
  _ErrorReportImpl({
    int? id,
    required String source,
    required String errorType,
    required String errorCode,
    required String stackTrace,
    required DateTime clientTimestamp,
    String? userMessage,
    required DateTime serverReceivedAt,
    String? appVersion,
    String? platform,
    String? deviceInfo,
  }) : super._(
         id: id,
         source: source,
         errorType: errorType,
         errorCode: errorCode,
         stackTrace: stackTrace,
         clientTimestamp: clientTimestamp,
         userMessage: userMessage,
         serverReceivedAt: serverReceivedAt,
         appVersion: appVersion,
         platform: platform,
         deviceInfo: deviceInfo,
       );

  /// Returns a shallow copy of this [ErrorReport]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  ErrorReport copyWith({
    Object? id = _Undefined,
    String? source,
    String? errorType,
    String? errorCode,
    String? stackTrace,
    DateTime? clientTimestamp,
    Object? userMessage = _Undefined,
    DateTime? serverReceivedAt,
    Object? appVersion = _Undefined,
    Object? platform = _Undefined,
    Object? deviceInfo = _Undefined,
  }) {
    return ErrorReport(
      id: id is int? ? id : this.id,
      source: source ?? this.source,
      errorType: errorType ?? this.errorType,
      errorCode: errorCode ?? this.errorCode,
      stackTrace: stackTrace ?? this.stackTrace,
      clientTimestamp: clientTimestamp ?? this.clientTimestamp,
      userMessage: userMessage is String? ? userMessage : this.userMessage,
      serverReceivedAt: serverReceivedAt ?? this.serverReceivedAt,
      appVersion: appVersion is String? ? appVersion : this.appVersion,
      platform: platform is String? ? platform : this.platform,
      deviceInfo: deviceInfo is String? ? deviceInfo : this.deviceInfo,
    );
  }
}
