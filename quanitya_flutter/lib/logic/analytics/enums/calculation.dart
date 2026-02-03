enum Calculation {
  // === MATRIX EXTRACTORS (Matrix → Vector) ===
  extractField,      // Extract specific field from matrix
  extractTimestamps, // Extract timestamp column from matrix
  
  // === MATRIX TRANSFORMERS (Matrix → Matrix) ===
  matrixRollingAverage, // Rolling average on matrix data
  matrixFilter,         // Filter matrix rows by criteria
  
  // === VALUE VECTOR AGGREGATORS (Vector → Scalar) ===
  vectorMean,           // Mean of vector values
  vectorMedian,         // Median of vector values
  vectorMode,           // Mode of vector values
  vectorStandardDev,    // Standard deviation of vector
  vectorVariance,       // Variance of vector
  vectorMin,            // Minimum value in vector
  vectorMax,            // Maximum value in vector
  vectorSum,            // Sum of vector values
  vectorRange,          // Range (max - min) of vector
  vectorPercentile,     // Percentile of vector (with param)
  vectorFirst,          // First value in vector
  vectorLast,           // Last value in vector
  vectorCount,          // Count of values in vector
  
  // === VALUE VECTOR TRANSFORMERS (Vector → Vector) ===
  vectorAbs,            // Absolute values of vector
  vectorDifference,     // Difference between consecutive values
  vectorPercentChange,  // Percent change between consecutive values
  
  // === TIMESTAMP VECTOR ANALYZERS (TimestampVector → ValueVector) ===
  dayOfWeek,            // Extract day-of-week pattern
  hourOfDay,            // Extract hour-of-day pattern
  dayOfMonth,           // Extract day-of-month pattern
  monthOfYear,          // Extract month pattern
  calculateIntervals,   // Calculate intervals between timestamps in days
  
  // === TIMESTAMP VECTOR AGGREGATORS (TimestampVector → Scalar) ===
  timeSpanDays,         // Total time span in days
  averageInterval,      // Average time between entries
  
  // === CATEGORICAL EXTRACTORS (Matrix → CategoryVector) ===
  extractCategoricalField,    // Extract categorical field from matrix
  
  // === CATEGORICAL AGGREGATORS (CategoryVector → Scalar/Vector) ===
  categoryMode,               // Most frequent category count → StatScalar
  categoryFrequencies,        // Category counts → ValueVector
  categoryUnique,             // Unique category count → StatScalar
  
  // === CATEGORICAL TRANSFORMERS (CategoryVector → CategoryVector) ===
  categoryFilter,             // Filter by specific category
  categoryMap,                // Map categories to new values
  
  // === SCALAR COMBINERS (inputCount: 2) ===
  scalarAdd,            // Add two scalars: inputKeys[0] + inputKeys[1]
  scalarSubtract,       // Subtract: inputKeys[0] - inputKeys[1]
  scalarMultiply,       // Multiply: inputKeys[0] * inputKeys[1]
  scalarDivide,         // Divide: inputKeys[0] / inputKeys[1]
}