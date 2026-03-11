import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:graphic/graphic.dart';
import '../../../support/extensions/context_extensions.dart';
import '../../primitives/app_sizes.dart';
import '../../primitives/app_spacings.dart';

/// A data series for the indexed multi-series chart.
class IndexedChartSeries {
  final String label;
  final List<double> values;
  final Color color;

  const IndexedChartSeries({
    required this.label,
    required this.values,
    required this.color,
  });

  bool get isEmpty => values.isEmpty;
}

/// An index-based multi-series line chart (no timestamps).
///
/// X-axis is the value index (0, 1, 2...), Y-axis is the value.
/// Supports overlaying multiple series. For a single series,
/// use with a one-element list.
class IndexedMultiSeriesChart extends StatelessWidget {
  final List<IndexedChartSeries> series;
  final double height;

  const IndexedMultiSeriesChart({
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
        child: Center(child: Text(context.l10n.chartNoData)),
      );
    }

    // Flatten to data format for graphic library
    final data = <Map<String, dynamic>>[];
    for (final s in activeSeries) {
      for (var i = 0; i < s.values.length; i++) {
        data.add({
          'index': i,
          'value': s.values[i],
          'series': s.label,
        });
      }
    }

    // Calculate y-axis range
    final allValues = data.map((d) => d['value'] as num).toList();
    final minValue = allValues.reduce(math.min);
    final maxValue = allValues.reduce(math.max);
    final range = maxValue - minValue;
    final padding = range == 0 ? 1.0 : range * 0.05;
    final yMin = minValue - padding;
    final yMax = maxValue + padding;

    // x-axis range
    final maxIndex = activeSeries.map((s) => s.values.length).reduce(math.max);

    final isSingle = activeSeries.length == 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Legend (only for multi-series)
        if (!isSingle)
          Padding(
            padding: EdgeInsets.only(bottom: AppSizes.space),
            child: Wrap(
              spacing: AppSizes.space * 2,
              runSpacing: AppSizes.space,
              children: activeSeries
                  .map((s) => _LegendItem(label: s.label, color: s.color))
                  .toList(),
            ),
          ),
        SizedBox(
          height: height,
          child: Chart(
            data: data,
            variables: {
              'index': Variable(
                accessor: (Map map) => map['index'] as num,
                scale: LinearScale(
                  min: 0,
                  max: (maxIndex - 1).toDouble(),
                  tickCount: math.min(6, maxIndex),
                  formatter: (v) => v.toInt().toString(),
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
              if (!isSingle)
                'series': Variable(
                  accessor: (Map map) => map['series'] as String,
                ),
            },
            marks: [
              LineMark(
                position: isSingle
                    ? null
                    : Varset('index') * Varset('value') / Varset('series'),
                shape: ShapeEncode(value: BasicLineShape(smooth: true)),
                color: isSingle
                    ? ColorEncode(value: activeSeries.first.color)
                    : ColorEncode(
                        variable: 'series',
                        values: activeSeries.map((s) => s.color).toList(),
                      ),
                size: SizeEncode(value: 2),
              ),
              PointMark(
                color: isSingle
                    ? ColorEncode(value: activeSeries.first.color)
                    : ColorEncode(
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
                on: {
                  GestureType.scaleUpdate,
                  GestureType.tapDown,
                  GestureType.longPressMoveUpdate,
                },
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

  static String _formatNumber(num value) {
    if (value == 0) return '0';
    final absValue = value.abs();
    if (absValue >= 10000 || (absValue < 0.01 && absValue > 0)) {
      return value.toStringAsExponential(2);
    }
    if (absValue >= 100) return value.round().toString();
    if (absValue >= 10) return value.toStringAsFixed(1);
    if (absValue >= 1) return value.toStringAsFixed(2);
    return value.toStringAsFixed(3);
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
