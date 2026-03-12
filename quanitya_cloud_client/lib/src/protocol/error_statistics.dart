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
import 'error_report.dart' as _i2;
import 'package:quanitya_cloud_client/src/protocol/protocol.dart' as _i3;

abstract class ErrorStatistics implements _i1.SerializableModel {
  ErrorStatistics._({
    required this.totalErrors,
    required this.errorsByType,
    required this.errorsByCode,
    required this.errorsByPlatform,
    required this.recentErrors,
  });

  factory ErrorStatistics({
    required int totalErrors,
    required Map<String, int> errorsByType,
    required Map<String, int> errorsByCode,
    required Map<String, int> errorsByPlatform,
    required List<_i2.ErrorReport> recentErrors,
  }) = _ErrorStatisticsImpl;

  factory ErrorStatistics.fromJson(Map<String, dynamic> jsonSerialization) {
    return ErrorStatistics(
      totalErrors: jsonSerialization['totalErrors'] as int,
      errorsByType: _i3.Protocol().deserialize<Map<String, int>>(
        jsonSerialization['errorsByType'],
      ),
      errorsByCode: _i3.Protocol().deserialize<Map<String, int>>(
        jsonSerialization['errorsByCode'],
      ),
      errorsByPlatform: _i3.Protocol().deserialize<Map<String, int>>(
        jsonSerialization['errorsByPlatform'],
      ),
      recentErrors: _i3.Protocol().deserialize<List<_i2.ErrorReport>>(
        jsonSerialization['recentErrors'],
      ),
    );
  }

  int totalErrors;

  Map<String, int> errorsByType;

  Map<String, int> errorsByCode;

  Map<String, int> errorsByPlatform;

  List<_i2.ErrorReport> recentErrors;

  /// Returns a shallow copy of this [ErrorStatistics]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  ErrorStatistics copyWith({
    int? totalErrors,
    Map<String, int>? errorsByType,
    Map<String, int>? errorsByCode,
    Map<String, int>? errorsByPlatform,
    List<_i2.ErrorReport>? recentErrors,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'ErrorStatistics',
      'totalErrors': totalErrors,
      'errorsByType': errorsByType.toJson(),
      'errorsByCode': errorsByCode.toJson(),
      'errorsByPlatform': errorsByPlatform.toJson(),
      'recentErrors': recentErrors.toJson(valueToJson: (v) => v.toJson()),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _ErrorStatisticsImpl extends ErrorStatistics {
  _ErrorStatisticsImpl({
    required int totalErrors,
    required Map<String, int> errorsByType,
    required Map<String, int> errorsByCode,
    required Map<String, int> errorsByPlatform,
    required List<_i2.ErrorReport> recentErrors,
  }) : super._(
         totalErrors: totalErrors,
         errorsByType: errorsByType,
         errorsByCode: errorsByCode,
         errorsByPlatform: errorsByPlatform,
         recentErrors: recentErrors,
       );

  /// Returns a shallow copy of this [ErrorStatistics]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  ErrorStatistics copyWith({
    int? totalErrors,
    Map<String, int>? errorsByType,
    Map<String, int>? errorsByCode,
    Map<String, int>? errorsByPlatform,
    List<_i2.ErrorReport>? recentErrors,
  }) {
    return ErrorStatistics(
      totalErrors: totalErrors ?? this.totalErrors,
      errorsByType:
          errorsByType ??
          this.errorsByType.map(
            (
              key0,
              value0,
            ) => MapEntry(
              key0,
              value0,
            ),
          ),
      errorsByCode:
          errorsByCode ??
          this.errorsByCode.map(
            (
              key0,
              value0,
            ) => MapEntry(
              key0,
              value0,
            ),
          ),
      errorsByPlatform:
          errorsByPlatform ??
          this.errorsByPlatform.map(
            (
              key0,
              value0,
            ) => MapEntry(
              key0,
              value0,
            ),
          ),
      recentErrors:
          recentErrors ?? this.recentErrors.map((e0) => e0.copyWith()).toList(),
    );
  }
}
