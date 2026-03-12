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
import 'feedback_report.dart' as _i2;
import 'package:quanitya_cloud_client/src/protocol/protocol.dart' as _i3;

abstract class FeedbackStatistics implements _i1.SerializableModel {
  FeedbackStatistics._({
    required this.totalFeedback,
    required this.byType,
    required this.recentFeedback,
  });

  factory FeedbackStatistics({
    required int totalFeedback,
    required Map<String, int> byType,
    required List<_i2.FeedbackReport> recentFeedback,
  }) = _FeedbackStatisticsImpl;

  factory FeedbackStatistics.fromJson(Map<String, dynamic> jsonSerialization) {
    return FeedbackStatistics(
      totalFeedback: jsonSerialization['totalFeedback'] as int,
      byType: _i3.Protocol().deserialize<Map<String, int>>(
        jsonSerialization['byType'],
      ),
      recentFeedback: _i3.Protocol().deserialize<List<_i2.FeedbackReport>>(
        jsonSerialization['recentFeedback'],
      ),
    );
  }

  int totalFeedback;

  Map<String, int> byType;

  List<_i2.FeedbackReport> recentFeedback;

  /// Returns a shallow copy of this [FeedbackStatistics]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  FeedbackStatistics copyWith({
    int? totalFeedback,
    Map<String, int>? byType,
    List<_i2.FeedbackReport>? recentFeedback,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'FeedbackStatistics',
      'totalFeedback': totalFeedback,
      'byType': byType.toJson(),
      'recentFeedback': recentFeedback.toJson(valueToJson: (v) => v.toJson()),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _FeedbackStatisticsImpl extends FeedbackStatistics {
  _FeedbackStatisticsImpl({
    required int totalFeedback,
    required Map<String, int> byType,
    required List<_i2.FeedbackReport> recentFeedback,
  }) : super._(
         totalFeedback: totalFeedback,
         byType: byType,
         recentFeedback: recentFeedback,
       );

  /// Returns a shallow copy of this [FeedbackStatistics]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  FeedbackStatistics copyWith({
    int? totalFeedback,
    Map<String, int>? byType,
    List<_i2.FeedbackReport>? recentFeedback,
  }) {
    return FeedbackStatistics(
      totalFeedback: totalFeedback ?? this.totalFeedback,
      byType:
          byType ??
          this.byType.map(
            (
              key0,
              value0,
            ) => MapEntry(
              key0,
              value0,
            ),
          ),
      recentFeedback:
          recentFeedback ??
          this.recentFeedback.map((e0) => e0.copyWith()).toList(),
    );
  }
}
