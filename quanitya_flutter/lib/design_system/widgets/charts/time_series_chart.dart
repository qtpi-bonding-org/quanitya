import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:graphic/graphic.dart';
import '../../primitives/quanitya_date_format.dart';
import '../../../support/extensions/context_extensions.dart';
import '../../primitives/quanitya_palette.dart';

/// A simple time series line chart widget.
/// 
/// Displays a value over time with a line connecting data points.
/// Uses the graphic library's grammar of graphics approach.
class TimeSeriesChart extends StatelessWidget {
  /// The data points to display.
  /// Each map should have 'date' (DateTime) and 'value' (num) keys.
  final List<Map<String, dynamic>> data;
  
  /// Label for the Y axis (the value being tracked).
  final String valueLabel;
  
  /// Color for the line. Defaults to primary color from QuanityaPalette.
  final Color? lineColor;
  
  /// Height of the chart.
  final double height;

  /// Optional accessibility summary for screen readers.
  /// When provided, wraps the chart in a [Semantics] label.
  final String? semanticSummary;

  const TimeSeriesChart({
    super.key,
    required this.data,
    required this.valueLabel,
    this.lineColor,
    this.height = 200,
    this.semanticSummary,
  });

  @override
  Widget build(BuildContext context) {
    final color = lineColor ?? QuanityaPalette.category10[0];

    if (data.isEmpty) {
      return SizedBox(
        height: height,
        child: Center(child: Text(context.l10n.chartNoData)),
      );
    }

    // Calculate min/max from data for Y-axis range
    final values = data.map((d) => d['value'] as num).toList();
    final minValue = values.reduce(math.min);
    final maxValue = values.reduce(math.max);

    // Add small padding to range (5%)
    final range = maxValue - minValue;
    final padding = range == 0 ? 1.0 : range * 0.05;
    final yMin = minValue - padding;
    final yMax = maxValue + padding;

    final chart = SizedBox(
      height: height,
      child: Chart(
        data: data,
        variables: {
          'date': Variable(
            accessor: (Map map) => map['date'] as DateTime,
            scale: TimeScale(
              tickCount: 5,
              formatter: _formatDate,
            ),
          ),
          'value': Variable(
            accessor: (Map map) => map['value'] as num,
            scale: LinearScale(
              min: yMin,
              max: yMax,
              tickCount: 5,
              formatter: _formatNumber,
            ),
          ),
        },
        marks: [
          LineMark(
            shape: ShapeEncode(value: BasicLineShape(smooth: true)),
            color: ColorEncode(value: color),
            size: SizeEncode(value: 2),
          ),
          PointMark(
            color: ColorEncode(value: color),
            size: SizeEncode(value: 4),
          ),
        ],
        axes: [
          Defaults.horizontalAxis,
          Defaults.verticalAxis,
        ],
        selections: {
          'touchMove': PointSelection(
            on: {GestureType.scaleUpdate, GestureType.tapDown, GestureType.longPressMoveUpdate},
            dim: Dim.x,
          ),
        },
        tooltip: TooltipGuide(
          followPointer: [false, true],
          align: Alignment.topLeft,
        ),
        crosshair: CrosshairGuide(followPointer: [false, true]),
      ),
    );

    final defaultLabel = 'Line chart: $valueLabel';
    return Semantics(
      label: semanticSummary ?? defaultLabel,
      child: ExcludeSemantics(child: chart),
    );
  }
  
  static String _formatDate(DateTime date) {
    return QuanityaDateFormat.monthDayCompact(date);
  }
  
  /// Format number with 3 significant figures, using scientific notation if needed
  static String _formatNumber(num value) {
    if (value == 0) return '0';
    
    final absValue = value.abs();
    
    // Use scientific notation for very large or very small numbers
    if (absValue >= 10000 || (absValue < 0.01 && absValue > 0)) {
      return value.toStringAsExponential(2);
    }
    
    // For normal range, use up to 3 significant figures
    if (absValue >= 100) {
      return value.round().toString();
    } else if (absValue >= 10) {
      return value.toStringAsFixed(1);
    } else if (absValue >= 1) {
      return value.toStringAsFixed(2);
    } else {
      return value.toStringAsFixed(3);
    }
  }
}
