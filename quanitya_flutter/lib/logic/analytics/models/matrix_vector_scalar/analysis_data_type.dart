/// Analysis data types for the matrix-vector-scalar type system.
///
/// Replaces the old timeSeries/collection/scalar enum with mathematically
/// precise types that enable infinite field extensibility.
enum AnalysisDataType {
  /// Time series matrix with timestamps and values: [{x,t}]
  timeSeriesMatrix,
  
  /// Array of numeric values: [x]
  valueVector,
  
  /// Array of timestamps: [t]
  timestampVector,
  
  /// Single statistical result: x
  statScalar,
  
  /// Array of categorical values: ['light', 'medium', 'heavy']
  categoryVector,
}