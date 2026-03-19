/// Matrix-Vector-Scalar type system for analysis pipelines.
///
/// This library provides mathematically precise types that replace the old
/// timeSeries/collection/scalar system with infinite field extensibility.
library;

// Core type definitions
export 'type_definitions.dart';
export 'analysis_data_type.dart';

// Data structures
export 'stat_scalar.dart';
export 'value_vector.dart';
export 'timestamp_vector.dart';
export 'time_series_matrix.dart';

// Analysis system
export 'mvs_union.dart';