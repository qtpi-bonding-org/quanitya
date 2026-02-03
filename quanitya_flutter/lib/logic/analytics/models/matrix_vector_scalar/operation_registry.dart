import 'package:injectable/injectable.dart';

import '../../enums/calculation.dart';
import 'analysis_data_type.dart';
import 'operation_definition.dart';

/// Registry of all available analysis operations with their type definitions.
///
/// Provides metadata for UI builders, validation systems, and pipeline
/// construction tools to ensure type-safe operation sequences.
@lazySingleton
class OperationRegistry {
  static const OperationRegistry _instance = OperationRegistry();
  const OperationRegistry();

  /// Singleton instance for non-DI usage
  static OperationRegistry get instance => _instance;

  /// Complete registry of all operations
  static const Map<Calculation, OperationDefinition> _registry = {
    // === MATRIX EXTRACTORS (Matrix → Vector) ===
    Calculation.extractField: OperationDefinition(
      label: "Extract Field",
      inputType: AnalysisDataType.timeSeriesMatrix,
      outputType: AnalysisDataType.valueVector,
      requiredParams: ['fieldName'],
      description: "Extract values from specified field column",
      category: "Matrix Extractors",
    ),

    Calculation.extractTimestamps: OperationDefinition(
      label: "Extract Timestamps",
      inputType: AnalysisDataType.timeSeriesMatrix,
      outputType: AnalysisDataType.timestampVector,
      description: "Extract timestamp column from time series matrix",
      category: "Matrix Extractors",
    ),

    // === MATRIX TRANSFORMERS (Matrix → Matrix) ===
    Calculation.matrixRollingAverage: OperationDefinition(
      label: "Rolling Average",
      inputType: AnalysisDataType.timeSeriesMatrix,
      outputType: AnalysisDataType.timeSeriesMatrix,
      requiredParams: ['windowDays'],
      description: "Smooth time series with moving average window",
      category: "Matrix Transformers",
    ),

    Calculation.matrixFilter: OperationDefinition(
      label: "Filter Matrix",
      inputType: AnalysisDataType.timeSeriesMatrix,
      outputType: AnalysisDataType.timeSeriesMatrix,
      requiredParams: ['fieldName', 'operator', 'value'],
      description: "Filter matrix rows based on field criteria",
      category: "Matrix Transformers",
    ),

    // === VALUE VECTOR AGGREGATORS (Vector → Scalar) ===
    Calculation.vectorMean: OperationDefinition(
      label: "Average",
      inputType: AnalysisDataType.valueVector,
      outputType: AnalysisDataType.statScalar,
      description: "Calculate arithmetic mean of values",
      category: "Vector Aggregators",
    ),

    Calculation.vectorMedian: OperationDefinition(
      label: "Median",
      inputType: AnalysisDataType.valueVector,
      outputType: AnalysisDataType.statScalar,
      description: "Find middle value when sorted",
      category: "Vector Aggregators",
    ),

    Calculation.vectorMode: OperationDefinition(
      label: "Mode",
      inputType: AnalysisDataType.valueVector,
      outputType: AnalysisDataType.statScalar,
      description: "Find most frequently occurring value",
      category: "Vector Aggregators",
    ),

    Calculation.vectorStandardDev: OperationDefinition(
      label: "Standard Deviation",
      inputType: AnalysisDataType.valueVector,
      outputType: AnalysisDataType.statScalar,
      description: "Measure spread of values around mean",
      category: "Vector Aggregators",
    ),

    Calculation.vectorVariance: OperationDefinition(
      label: "Variance",
      inputType: AnalysisDataType.valueVector,
      outputType: AnalysisDataType.statScalar,
      description: "Measure squared deviation from mean",
      category: "Vector Aggregators",
    ),

    Calculation.vectorMin: OperationDefinition(
      label: "Minimum",
      inputType: AnalysisDataType.valueVector,
      outputType: AnalysisDataType.statScalar,
      description: "Find smallest value in vector",
      category: "Vector Aggregators",
    ),

    Calculation.vectorMax: OperationDefinition(
      label: "Maximum",
      inputType: AnalysisDataType.valueVector,
      outputType: AnalysisDataType.statScalar,
      description: "Find largest value in vector",
      category: "Vector Aggregators",
    ),

    Calculation.vectorSum: OperationDefinition(
      label: "Sum",
      inputType: AnalysisDataType.valueVector,
      outputType: AnalysisDataType.statScalar,
      description: "Add all values together",
      category: "Vector Aggregators",
    ),

    Calculation.vectorRange: OperationDefinition(
      label: "Range",
      inputType: AnalysisDataType.valueVector,
      outputType: AnalysisDataType.statScalar,
      description: "Difference between maximum and minimum",
      category: "Vector Aggregators",
    ),

    Calculation.vectorPercentile: OperationDefinition(
      label: "Percentile",
      inputType: AnalysisDataType.valueVector,
      outputType: AnalysisDataType.statScalar,
      requiredParams: ['percentile'],
      description: "Find value at specified percentile (0-100)",
      category: "Vector Aggregators",
    ),

    // === VALUE VECTOR TRANSFORMERS (Vector → Vector) ===
    Calculation.vectorAbs: OperationDefinition(
      label: "Absolute Values",
      inputType: AnalysisDataType.valueVector,
      outputType: AnalysisDataType.valueVector,
      description: "Convert all values to positive (remove sign)",
      category: "Vector Transformers",
    ),

    Calculation.vectorDifference: OperationDefinition(
      label: "Difference",
      inputType: AnalysisDataType.valueVector,
      outputType: AnalysisDataType.valueVector,
      description: "Calculate difference between consecutive values",
      category: "Vector Transformers",
    ),

    Calculation.vectorPercentChange: OperationDefinition(
      label: "Percent Change",
      inputType: AnalysisDataType.valueVector,
      outputType: AnalysisDataType.valueVector,
      description: "Calculate percent change between consecutive values",
      category: "Vector Transformers",
    ),

    // === TIMESTAMP VECTOR ANALYZERS (TimestampVector → ValueVector) ===
    Calculation.dayOfWeek: OperationDefinition(
      label: "Day of Week Pattern",
      inputType: AnalysisDataType.timestampVector,
      outputType: AnalysisDataType.valueVector,
      description: "Extract day-of-week numbers (1=Monday, 7=Sunday)",
      category: "Timestamp Analyzers",
    ),

    Calculation.hourOfDay: OperationDefinition(
      label: "Hour of Day Pattern",
      inputType: AnalysisDataType.timestampVector,
      outputType: AnalysisDataType.valueVector,
      description: "Extract hour-of-day numbers (0-23)",
      category: "Timestamp Analyzers",
    ),

    Calculation.dayOfMonth: OperationDefinition(
      label: "Day of Month Pattern",
      inputType: AnalysisDataType.timestampVector,
      outputType: AnalysisDataType.valueVector,
      description: "Extract day-of-month numbers (1-31)",
      category: "Timestamp Analyzers",
    ),

    Calculation.monthOfYear: OperationDefinition(
      label: "Month Pattern",
      inputType: AnalysisDataType.timestampVector,
      outputType: AnalysisDataType.valueVector,
      description: "Extract month numbers (1-12)",
      category: "Timestamp Analyzers",
    ),

    // === TIMESTAMP VECTOR AGGREGATORS (TimestampVector → Scalar) ===
    Calculation.timeSpanDays: OperationDefinition(
      label: "Time Span (Days)",
      inputType: AnalysisDataType.timestampVector,
      outputType: AnalysisDataType.statScalar,
      description: "Calculate total time span in days",
      category: "Timestamp Aggregators",
    ),

    Calculation.averageInterval: OperationDefinition(
      label: "Average Interval",
      inputType: AnalysisDataType.timestampVector,
      outputType: AnalysisDataType.statScalar,
      description: "Calculate average time between entries in hours",
      category: "Timestamp Aggregators",
    ),

    // === CATEGORICAL EXTRACTORS ===
    Calculation.extractCategoricalField: OperationDefinition(
      label: "Extract Categorical Field",
      inputType: AnalysisDataType.timeSeriesMatrix,
      outputType: AnalysisDataType.categoryVector,
      requiredParams: ['fieldName'],
      description: "Extract categorical values from specified field column",
      category: "Categorical Extractors",
    ),

    // === CATEGORICAL AGGREGATORS ===
    Calculation.categoryMode: OperationDefinition(
      label: "Most Frequent Category",
      inputType: AnalysisDataType.categoryVector,
      outputType: AnalysisDataType.statScalar,
      description: "Find the count of the most frequent category",
      category: "Categorical Aggregators",
    ),

    Calculation.categoryFrequencies: OperationDefinition(
      label: "Category Frequencies",
      inputType: AnalysisDataType.categoryVector,
      outputType: AnalysisDataType.valueVector,
      description: "Get frequency counts for each unique category",
      category: "Categorical Aggregators",
    ),

    Calculation.categoryUnique: OperationDefinition(
      label: "Unique Categories Count",
      inputType: AnalysisDataType.categoryVector,
      outputType: AnalysisDataType.statScalar,
      description: "Count number of unique categories",
      category: "Categorical Aggregators",
    ),

    // === CATEGORICAL TRANSFORMERS ===
    Calculation.categoryFilter: OperationDefinition(
      label: "Filter by Category",
      inputType: AnalysisDataType.categoryVector,
      outputType: AnalysisDataType.categoryVector,
      requiredParams: ['category'],
      description: "Keep only entries matching specified category",
      category: "Categorical Transformers",
    ),

    Calculation.categoryMap: OperationDefinition(
      label: "Map Categories",
      inputType: AnalysisDataType.categoryVector,
      outputType: AnalysisDataType.categoryVector,
      requiredParams: ['mapping'],
      description: "Transform categories using mapping rules",
      category: "Categorical Transformers",
    ),

    // === NEW VECTOR AGGREGATORS ===
    Calculation.vectorFirst: OperationDefinition(
      label: "First Value",
      inputType: AnalysisDataType.valueVector,
      outputType: AnalysisDataType.statScalar,
      description: "Get the first value in the vector",
      category: "Vector Aggregators",
    ),

    Calculation.vectorLast: OperationDefinition(
      label: "Last Value",
      inputType: AnalysisDataType.valueVector,
      outputType: AnalysisDataType.statScalar,
      description: "Get the last value in the vector",
      category: "Vector Aggregators",
    ),

    Calculation.vectorCount: OperationDefinition(
      label: "Count",
      inputType: AnalysisDataType.valueVector,
      outputType: AnalysisDataType.statScalar,
      description: "Count the number of values in the vector",
      category: "Vector Aggregators",
    ),

    // === TIMESTAMP INTERVAL CALCULATOR ===
    Calculation.calculateIntervals: OperationDefinition(
      label: "Calculate Intervals",
      inputType: AnalysisDataType.timestampVector,
      outputType: AnalysisDataType.valueVector,
      description: "Calculate intervals between consecutive timestamps in days",
      category: "Timestamp Analyzers",
    ),

    // === SCALAR COMBINERS (inputCount: 2) ===
    Calculation.scalarAdd: OperationDefinition(
      label: "Add Scalars",
      inputType: AnalysisDataType.statScalar,
      outputType: AnalysisDataType.statScalar,
      inputCount: 2,
      description: "Add two scalar values: inputKeys[0] + inputKeys[1]",
      category: "Scalar Combiners",
    ),

    Calculation.scalarSubtract: OperationDefinition(
      label: "Subtract Scalars",
      inputType: AnalysisDataType.statScalar,
      outputType: AnalysisDataType.statScalar,
      inputCount: 2,
      description: "Subtract second from first: inputKeys[0] - inputKeys[1]",
      category: "Scalar Combiners",
    ),

    Calculation.scalarMultiply: OperationDefinition(
      label: "Multiply Scalars",
      inputType: AnalysisDataType.statScalar,
      outputType: AnalysisDataType.statScalar,
      inputCount: 2,
      description: "Multiply two scalar values: inputKeys[0] * inputKeys[1]",
      category: "Scalar Combiners",
    ),

    Calculation.scalarDivide: OperationDefinition(
      label: "Divide Scalars",
      inputType: AnalysisDataType.statScalar,
      outputType: AnalysisDataType.statScalar,
      inputCount: 2,
      description: "Divide first by second: inputKeys[0] / inputKeys[1]",
      category: "Scalar Combiners",
    ),
  };

  /// Get operation definition by calculation type
  OperationDefinition? getDefinition(Calculation calculation) {
    return _registry[calculation];
  }

  /// Get all operations for a specific input type
  List<MapEntry<Calculation, OperationDefinition>> getOperationsForInputType(
    AnalysisDataType inputType,
  ) {
    return _registry.entries
        .where((entry) => entry.value.inputType == inputType)
        .toList();
  }

  /// Get all operations for a specific output type
  List<MapEntry<Calculation, OperationDefinition>> getOperationsForOutputType(
    AnalysisDataType outputType,
  ) {
    return _registry.entries
        .where((entry) => entry.value.outputType == outputType)
        .toList();
  }

  /// Get operations that can follow a given operation (type compatibility)
  List<MapEntry<Calculation, OperationDefinition>> getCompatibleOperations(
    Calculation calculation,
  ) {
    final definition = getDefinition(calculation);
    if (definition == null) return [];

    return getOperationsForInputType(definition.outputType);
  }

  /// Get all operations in a specific category
  List<MapEntry<Calculation, OperationDefinition>> getOperationsByCategory(
    String category,
  ) {
    return _registry.entries
        .where((entry) => entry.value.category == category)
        .toList();
  }

  /// Get all unique categories
  List<String> get categories {
    return _registry.values.map((def) => def.category).toSet().toList()..sort();
  }

  /// Get all combiner operations (inputCount > 1)
  List<MapEntry<Calculation, OperationDefinition>> get combinerOperations {
    return _registry.entries
        .where((entry) => entry.value.inputCount > 1)
        .toList();
  }

  /// Check if operation is a combiner (multiple inputs)
  bool isCombiner(Calculation calculation) {
    final definition = getDefinition(calculation);
    return definition != null && definition.inputCount > 1;
  }

  /// Validate if a sequence of operations is type-compatible
  bool validateOperationSequence(List<Calculation> operations) {
    if (operations.isEmpty) return true;

    for (int i = 1; i < operations.length; i++) {
      final current = getDefinition(operations[i - 1]);
      final next = getDefinition(operations[i]);

      if (current == null || next == null) return false;
      if (current.outputType != next.inputType) return false;
    }

    return true;
  }

  /// Get the final output type of an operation sequence
  AnalysisDataType? getFinalOutputType(List<Calculation> operations) {
    if (operations.isEmpty) return null;

    if (!validateOperationSequence(operations)) return null;

    final lastOperation = getDefinition(operations.last);
    return lastOperation?.outputType;
  }
}
