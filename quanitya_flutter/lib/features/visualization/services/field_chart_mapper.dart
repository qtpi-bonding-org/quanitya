import '../../../logic/templates/enums/field_enum.dart';

/// Chart types available for field visualization.
enum ChartType {
  /// Line chart for numeric trends (integer, float, dimension)
  line,
  
  /// Boolean heatmap for yes/no patterns
  booleanHeatmap,
  
  /// Categorical scatter for enumerated fields
  categoricalScatter,
  
  /// Field type not visualizable
  none,
}

/// Maps field types to appropriate chart visualizations.
class FieldChartMapper {
  /// Returns the best chart type for a given field type.
  static ChartType getChartType(FieldEnum fieldType) {
    return switch (fieldType) {
      FieldEnum.integer => ChartType.line,
      FieldEnum.float => ChartType.line,
      FieldEnum.dimension => ChartType.line,
      FieldEnum.boolean => ChartType.booleanHeatmap,
      FieldEnum.enumerated => ChartType.categoricalScatter,
      FieldEnum.text => ChartType.none,
      FieldEnum.datetime => ChartType.none,
      FieldEnum.reference => ChartType.none,
      FieldEnum.location => ChartType.none,
    };
  }

  /// Returns true if the field type can be visualized.
  static bool isVisualizable(FieldEnum fieldType) {
    return getChartType(fieldType) != ChartType.none;
  }

  /// Returns all visualizable field types.
  static List<FieldEnum> get visualizableTypes => [
    FieldEnum.integer,
    FieldEnum.float,
    FieldEnum.dimension,
    FieldEnum.boolean,
    FieldEnum.enumerated,
  ];

  /// Returns a human-readable chart name.
  static String getChartName(ChartType type) {
    return switch (type) {
      ChartType.line => 'Trend',
      ChartType.booleanHeatmap => 'Completion',
      ChartType.categoricalScatter => 'Categories',
      ChartType.none => 'N/A',
    };
  }
}
