import 'package:freezed_annotation/freezed_annotation.dart';
import 'analysis_data_type.dart';
import 'time_series_matrix.dart';
import 'value_vector.dart';
import 'timestamp_vector.dart';
import 'stat_scalar.dart';
import 'category_vector.dart';
import '../../exceptions/analysis_exceptions.dart';

part 'mvs_union.freezed.dart';
part 'mvs_union.g.dart';

/// Union type for matrix-vector-scalar pipeline results.
///
/// Replaces the old AnalysisResultMvs with clearer naming.
/// Enables infinite field extensibility and type safety.
@freezed
class MvsUnion with _$MvsUnion {
  const factory MvsUnion.timeSeriesMatrix(TimeSeriesMatrix matrix) = _MvsTimeSeriesMatrix;
  const factory MvsUnion.valueVector(ValueVector vector) = _MvsValueVector;
  const factory MvsUnion.timestampVector(TimestampVector vector) = _MvsTimestampVector;
  const factory MvsUnion.statScalar(StatScalar scalar) = _MvsStatScalar;
  const factory MvsUnion.categoryVector(CategoryVector vector) = _MvsCategoryVector;
  
  factory MvsUnion.fromJson(Map<String, dynamic> json) =>
      _$MvsUnionFromJson(json);
}

/// Helper extension for type-safe operations on MvsUnion.
extension MvsUnionExt on MvsUnion {
  /// Get the current data type
  AnalysisDataType get dataType => map(
    timeSeriesMatrix: (_) => AnalysisDataType.timeSeriesMatrix,
    valueVector: (_) => AnalysisDataType.valueVector,
    timestampVector: (_) => AnalysisDataType.timestampVector,
    statScalar: (_) => AnalysisDataType.statScalar,
    categoryVector: (_) => AnalysisDataType.categoryVector,
  );
  
  /// Type-safe unwrapping: Get TimeSeriesMatrix or throw
  TimeSeriesMatrix get asTimeSeriesMatrix => map(
    timeSeriesMatrix: (m) => m.matrix,
    valueVector: (_) => throw AnalysisException(
      'Expected TimeSeriesMatrix, got ValueVector'
    ),
    timestampVector: (_) => throw AnalysisException(
      'Expected TimeSeriesMatrix, got TimestampVector'
    ),
    statScalar: (_) => throw AnalysisException(
      'Expected TimeSeriesMatrix, got StatScalar'
    ),
    categoryVector: (_) => throw AnalysisException(
      'Expected TimeSeriesMatrix, got CategoryVector'
    ),
  );
  
  /// Type-safe unwrapping: Get ValueVector or throw
  ValueVector get asValueVector => map(
    timeSeriesMatrix: (_) => throw AnalysisException(
      'Expected ValueVector, got TimeSeriesMatrix'
    ),
    valueVector: (v) => v.vector,
    timestampVector: (_) => throw AnalysisException(
      'Expected ValueVector, got TimestampVector'
    ),
    statScalar: (_) => throw AnalysisException(
      'Expected ValueVector, got StatScalar'
    ),
    categoryVector: (_) => throw AnalysisException(
      'Expected ValueVector, got CategoryVector'
    ),
  );
  
  /// Type-safe unwrapping: Get TimestampVector or throw
  TimestampVector get asTimestampVector => map(
    timeSeriesMatrix: (_) => throw AnalysisException(
      'Expected TimestampVector, got TimeSeriesMatrix'
    ),
    valueVector: (_) => throw AnalysisException(
      'Expected TimestampVector, got ValueVector'
    ),
    timestampVector: (t) => t.vector,
    statScalar: (_) => throw AnalysisException(
      'Expected TimestampVector, got StatScalar'
    ),
    categoryVector: (_) => throw AnalysisException(
      'Expected TimestampVector, got CategoryVector'
    ),
  );
  
  /// Type-safe unwrapping: Get StatScalar or throw
  StatScalar get asStatScalar => map(
    timeSeriesMatrix: (_) => throw AnalysisException(
      'Expected StatScalar, got TimeSeriesMatrix'
    ),
    valueVector: (_) => throw AnalysisException(
      'Expected StatScalar, got ValueVector'
    ),
    timestampVector: (_) => throw AnalysisException(
      'Expected StatScalar, got TimestampVector'
    ),
    statScalar: (s) => s.scalar,
    categoryVector: (_) => throw AnalysisException(
      'Expected StatScalar, got CategoryVector'
    ),
  );
  
  /// Type-safe unwrapping: Get CategoryVector or throw
  CategoryVector get asCategoryVector => map(
    timeSeriesMatrix: (_) => throw AnalysisException(
      'Expected CategoryVector, got TimeSeriesMatrix'
    ),
    valueVector: (_) => throw AnalysisException(
      'Expected CategoryVector, got ValueVector'
    ),
    timestampVector: (_) => throw AnalysisException(
      'Expected CategoryVector, got TimestampVector'
    ),
    statScalar: (_) => throw AnalysisException(
      'Expected CategoryVector, got StatScalar'
    ),
    categoryVector: (c) => c.vector,
  );
  
  /// Check if result is of specific type
  bool get isTimeSeriesMatrix => dataType == AnalysisDataType.timeSeriesMatrix;
  bool get isValueVector => dataType == AnalysisDataType.valueVector;
  bool get isTimestampVector => dataType == AnalysisDataType.timestampVector;
  bool get isStatScalar => dataType == AnalysisDataType.statScalar;
  bool get isCategoryVector => dataType == AnalysisDataType.categoryVector;
}
