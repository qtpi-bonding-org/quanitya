import 'package:freezed_annotation/freezed_annotation.dart';
import 'type_definitions.dart';
import 'value_vector.dart';
import 'timestamp_vector.dart';
import 'field_value.dart';
import 'category_vector.dart';

part 'time_series_matrix.freezed.dart';
part 'time_series_matrix.g.dart';

/// Time series matrix with guaranteed structure: 1 timestamp + N value columns.
///
/// Supports both numeric and categorical data through automatic encoding.
/// Categorical values are encoded to integers for matrix storage but can be decoded back.
/// Structure: [[timestamp_ms, value1, value2, ...], ...]
/// Column names: ['timestamp', 'field1', 'field2', ...]
@freezed
class TimeSeriesMatrix with _$TimeSeriesMatrix {
  const factory TimeSeriesMatrix._({
    required Matrix data,
    required List<String> columnNames,
    @Default({}) Map<String, Map<String, int>> categoryEncoders,
  }) = _TimeSeriesMatrix;
  
  factory TimeSeriesMatrix.fromJson(Map<String, dynamic> json) => 
      _$TimeSeriesMatrixFromJson(json);
  
  /// Unified constructor - enforces 1 timestamp + at least 1 value field.
  ///
  /// [timestamps] - Array of DateTime objects for the time axis
  /// [fieldData] - Map of field names to their corresponding value arrays (numeric or categorical)
  ///
  /// Throws [ArgumentError] if:
  /// - fieldData is empty (must have at least 1 value field)
  /// - Any field data length doesn't match timestamps length
  factory TimeSeriesMatrix.fromFieldData({
    required List<DateTime> timestamps,
    required Map<String, FieldValueList> fieldData,
  }) {
    // Validation: Must have at least 1 field
    if (fieldData.isEmpty) {
      throw ArgumentError('TimeSeriesMatrix must have at least 1 value field');
    }
    
    // Validation: All field data must have same length as timestamps
    for (final entry in fieldData.entries) {
      if (entry.value.length != timestamps.length) {
        throw ArgumentError(
          'Field "${entry.key}" has ${entry.value.length} values, '
          'but ${timestamps.length} timestamps provided'
        );
      }
    }
    
    // Build category encoders for categorical fields
    final categoryEncoders = <String, Map<String, int>>{};
    for (final entry in fieldData.entries) {
      final fieldName = entry.key;
      final values = entry.value;
      
      // Check if this field contains any categorical values
      final hasCategorical = values.any((v) => v.isCategorical);
      if (hasCategorical) {
        // Build encoder for this field's categories
        final categories = values
            .where((v) => v.isCategorical)
            .map((v) => v.asCategorical)
            .toSet()
            .toList();
        
        categoryEncoders[fieldName] = {
          for (int i = 0; i < categories.length; i++) categories[i]: i
        };
      }
    }
    
    final columnNames = ['timestamp', ...fieldData.keys];
    final rows = <List<Numeric>>[];
    
    for (int i = 0; i < timestamps.length; i++) {
      final row = <Numeric>[timestamps[i].millisecondsSinceEpoch.toDouble()];
      for (final fieldName in fieldData.keys) {
        final fieldValue = fieldData[fieldName]![i];
        final encoder = categoryEncoders[fieldName];
        row.add(fieldValue.toDouble(encoder));
      }
      rows.add(row);
    }
    
    return TimeSeriesMatrix._(
      data: rows, 
      columnNames: columnNames,
      categoryEncoders: categoryEncoders,
    );
  }
  
  /// Create matrix from legacy TimeSeriesPoint format (backward compatibility).
  factory TimeSeriesMatrix.fromTimeSeriesPoints(
    List<({DateTime date, num value})> points, {
    String fieldName = 'value',
  }) {
    return TimeSeriesMatrix.fromFieldData(
      timestamps: points.map((p) => p.date).toList(),
      fieldData: {
        fieldName: points.map((p) => FieldValue.numeric(p.value)).toList(),
      },
    );
  }
  
  /// Create matrix with mixed numeric and categorical data.
  ///
  /// Example:
  /// ```dart
  /// TimeSeriesMatrix.fromMixedData(
  ///   timestamps: [DateTime.now(), DateTime.now().add(Duration(hours: 1))],
  ///   numericFields: {
  ///     'heartRate': [72.0, 75.0],
  ///     'temperature': [98.6, 99.1],
  ///   },
  ///   categoricalFields: {
  ///     'mood': ['happy', 'tired'],
  ///     'activity': ['rest', 'exercise'],
  ///   },
  /// )
  /// ```
  factory TimeSeriesMatrix.fromMixedData({
    required List<DateTime> timestamps,
    Map<String, List<Numeric>>? numericFields,
    Map<String, List<String>>? categoricalFields,
  }) {
    final fieldData = <String, FieldValueList>{};
    
    // Add numeric fields
    if (numericFields != null) {
      for (final entry in numericFields.entries) {
        fieldData[entry.key] = entry.value
            .map((v) => FieldValue.numeric(v))
            .toList();
      }
    }
    
    // Add categorical fields
    if (categoricalFields != null) {
      for (final entry in categoricalFields.entries) {
        fieldData[entry.key] = entry.value
            .map((v) => FieldValue.categorical(v))
            .toList();
      }
    }
    
    return TimeSeriesMatrix.fromFieldData(
      timestamps: timestamps,
      fieldData: fieldData,
    );
  }
}

/// Extension methods for TimeSeriesMatrix operations.
extension TimeSeriesMatrixExt on TimeSeriesMatrix {
  /// Number of rows (data points)
  int get rows => data.length;
  
  /// Number of columns (timestamp + value fields)
  int get columns => data.isEmpty ? 0 : data.first.length;
  
  /// Check if matrix is empty
  bool get isEmpty => data.isEmpty;
  
  /// Check if matrix is not empty
  bool get isNotEmpty => data.isNotEmpty;
  
  /// Validate matrix structure (compile-time guarantees)
  bool get hasValidStructure => 
      columns >= 2 && 
      columnNames.isNotEmpty && 
      columnNames.first == 'timestamp';
  
  /// Get column by index
  ValueVector getColumn(int columnIndex) {
    if (columnIndex < 0 || columnIndex >= columns) {
      throw ArgumentError(
        'Column index $columnIndex out of bounds [0, ${columns - 1}]'
      );
    }
    return ValueVector(data.map((row) => row[columnIndex]).toList());
  }
  
  /// Get column by name
  ValueVector getColumnByName(String columnName) {
    final columnIndex = columnNames.indexOf(columnName);
    if (columnIndex == -1) {
      throw ArgumentError(
        'Column "$columnName" not found. Available: ${columnNames.join(", ")}'
      );
    }
    return getColumn(columnIndex);
  }
  
  /// Get timestamp vector (always column 0)
  TimestampVector get timestampVector {
    if (isEmpty) return const TimestampVector([]);
    
    final timestampColumn = getColumn(0);
    return TimestampVector(
      timestampColumn.values
          .map((ms) => DateTime.fromMillisecondsSinceEpoch(ms.toInt()))
          .toList()
    );
  }
  
  /// Get value field names (excluding timestamp)
  List<String> get fieldNames => columnNames.skip(1).toList();
  
  /// Number of value fields (excluding timestamp)
  int get fieldCount => columns - 1;
  
  /// Check if matrix has specific field
  bool hasField(String fieldName) => fieldNames.contains(fieldName);
  
  /// Check if field contains categorical data
  bool isFieldCategorical(String fieldName) => 
      categoryEncoders.containsKey(fieldName);
  
  /// Get categorical values for a field (decoded from numeric storage)
  CategoryVector getCategoricalField(String fieldName) {
    if (!isFieldCategorical(fieldName)) {
      throw ArgumentError('Field "$fieldName" is not categorical');
    }
    
    final encoder = categoryEncoders[fieldName]!;
    final decoder = {for (final e in encoder.entries) e.value: e.key};
    final columnIndex = columnNames.indexOf(fieldName);
    
    if (columnIndex == -1) {
      throw ArgumentError('Field "$fieldName" not found');
    }
    
    final encodedValues = getColumn(columnIndex);
    final decodedValues = encodedValues.values
        .map((encoded) => decoder[encoded.toInt()]!)
        .toList();
    
    return CategoryVector(decodedValues);
  }
  
  /// Get all categorical field names
  List<String> get categoricalFieldNames => 
      categoryEncoders.keys.toList();
  
  /// Get all numeric field names (excluding timestamp and categorical fields)
  List<String> get numericFieldNames => 
      fieldNames.where((name) => !isFieldCategorical(name)).toList();
  
  /// Get category encoder for a field
  Map<String, int>? getCategoryEncoder(String fieldName) => 
      categoryEncoders[fieldName];
  
  /// Get all categories for a categorical field
  List<String> getCategories(String fieldName) {
    final encoder = categoryEncoders[fieldName];
    if (encoder == null) {
      throw ArgumentError('Field "$fieldName" is not categorical');
    }
    return encoder.keys.toList();
  }
  
  /// Get all value columns as map (excluding timestamp)
  Map<String, ValueVector> get valueColumns {
    final result = <String, ValueVector>{};
    for (int i = 1; i < columns; i++) {
      result[columnNames[i]] = getColumn(i);
    }
    return result;
  }
  
  /// Get first value field (backward compatibility)
  ValueVector get firstFieldVector {
    if (fieldCount == 0) {
      throw StateError('Matrix has no value fields');
    }
    return getColumn(1);
  }
  
  /// Get row at index
  List<Numeric> getRow(int rowIndex) {
    if (rowIndex < 0 || rowIndex >= rows) {
      throw ArgumentError('Row index $rowIndex out of bounds [0, ${rows - 1}]');
    }
    return data[rowIndex];
  }
  
  /// Create new matrix with rows that satisfy predicate
  TimeSeriesMatrix where(bool Function(List<Numeric>) test) {
    final filteredData = data.where(test).toList();
    return TimeSeriesMatrix._(
      data: filteredData,
      columnNames: columnNames,
    );
  }
  
  /// Create new matrix with subset of rows
  TimeSeriesMatrix sublist(int start, [int? end]) {
    final subData = data.sublist(start, end);
    return TimeSeriesMatrix._(
      data: subData,
      columnNames: columnNames,
    );
  }
  
  /// Create new matrix with only specified fields (plus timestamp)
  TimeSeriesMatrix selectFields(List<String> fieldNames) {
    final selectedColumns = ['timestamp', ...fieldNames];
    final columnIndices = selectedColumns
        .map((name) => columnNames.indexOf(name))
        .where((index) => index != -1)
        .toList();
    
    if (columnIndices.isEmpty || columnIndices.first != 0) {
      throw ArgumentError('Invalid field selection - timestamp must be included');
    }
    
    final newData = data.map((row) => 
        columnIndices.map((i) => row[i]).toList()
    ).toList();
    
    final newColumnNames = columnIndices
        .map((i) => columnNames[i])
        .toList();
    
    return TimeSeriesMatrix._(
      data: newData,
      columnNames: newColumnNames,
    );
  }
}