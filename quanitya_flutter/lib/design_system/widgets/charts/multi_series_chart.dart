import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:graphic/graphic.dart';
import 'package:intl/intl.dart';
import '../../../design_system/primitives/app_sizes.dart';
import '../../../design_system/primitives/app_spacings.dart';

/// A data series for the multi-series chart.
class ChartSeries {
  final String label;
  final List<({DateTime date, num value})> points;
  final Color color;
  
  const ChartSeries({
    required this.label,
    required this.points,
    required this.color,
  });
  
  bool get isEmpty => points.isEmpty;
}

/// A multi-series time series chart with support for overlaying multiple fields.
/// 
/// Each series gets its own color and appears in the legend.
/// For 2 series, uses dual Y-axes (left and right).
class MultiSeriesChart extends StatelessWidget {
  final List<ChartSeries> series;
  final double height;

  const MultiSeriesChart({
    super.key,
    required this.series,
    this.height = 220,
  });

  @override
  Widget build(BuildContext context) {
    final activeSeries = series.where((s) => !s.isEmpty).toList();
    
    if (activeSeries.isEmpty) {
      return SizedBox(
        height: height,
        child: const Center(child: Text('No data')),
      );
    }

    // Convert to flat data format for graphic library
    final data = <Map<String, dynamic>>[];
    for (final s in activeSeries) {
      for (final point in s.points) {
        data.add({
          'date': point.date,
          'value': point.value,
          'series': s.label,
        });
      }
    }

    // Calculate min/max from all data for Y-axis range
    final allValues = data.map((d) => d['value'] as num).toList();
    final minValue = allValues.reduce(math.min);
    final maxValue = allValues.reduce(math.max);
    
    // Add small padding to range (5%)
    final range = maxValue - minValue;
    final padding = range == 0 ? 1.0 : range * 0.05;
    final yMin = minValue - padding;
    final yMax = maxValue + padding;

    // Build color map
    final colorMap = <String, Color>{};
    for (final s in activeSeries) {
      colorMap[s.label] = s.color;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Legend
        Wrap(
          spacing: AppSizes.space * 2,
          runSpacing: AppSizes.space,
          children: activeSeries.map((s) => _LegendItem(
            label: s.label,
            color: s.color,
          )).toList(),
        ),
        VSpace.x1,
        // Chart
        SizedBox(
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
              'series': Variable(
                accessor: (Map map) => map['series'] as String,
              ),
            },
            marks: [
              LineMark(
                shape: ShapeEncode(value: BasicLineShape(smooth: true)),
                color: ColorEncode(
                  variable: 'series',
                  values: activeSeries.map((s) => s.color).toList(),
                ),
                size: SizeEncode(value: 2),
              ),
              PointMark(
                color: ColorEncode(
                  variable: 'series',
                  values: activeSeries.map((s) => s.color).toList(),
                ),
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
        ),
      ],
    );
  }
  
  /// Format date concisely (e.g., "1/5")
  static String _formatDate(DateTime date) {
    return DateFormat('M/d').format(date);
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

class _LegendItem extends StatelessWidget {
  final String label;
  final Color color;

  const _LegendItem({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: AppSizes.fontMini,
          height: AppSizes.fontMini,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        HSpace.x05,
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}
