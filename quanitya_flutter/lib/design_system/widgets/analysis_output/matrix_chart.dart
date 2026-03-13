import 'package:flutter/material.dart';

import '../../../logic/analytics/models/matrix_vector_scalar/time_series_matrix.dart';
import '../../../support/extensions/context_extensions.dart';
import '../../primitives/quanitya_palette.dart';
import '../charts/multi_series_chart.dart';
import '../charts/time_series_chart.dart';

/// Renders a list of [TimeSeriesMatrix] as an overlaid time series chart.
///
/// Single matrix uses [TimeSeriesChart], multiple uses [MultiSeriesChart].
/// Each matrix's first value column becomes a series.
class MatrixChart extends StatelessWidget {
  final List<TimeSeriesMatrix> matrices;

  const MatrixChart({super.key, required this.matrices});

  @override
  Widget build(BuildContext context) {
    final palette = QuanityaPalette.primary;

    if (matrices.isEmpty) {
      return Text(
        'No matrix data',
        style: context.text.bodyMedium?.copyWith(color: palette.textSecondary),
      );
    }

    final series = <ChartSeries>[];
    for (var i = 0; i < matrices.length; i++) {
      final matrix = matrices[i];
      if (matrix.data.isEmpty) continue;

      final timestamps = matrix.timestampVector.timestamps;
      final valueCol = matrix.fieldNames.isNotEmpty
          ? matrix.getColumnByName(matrix.fieldNames.first).values
          : <num>[];

      final points = <({DateTime date, num value})>[];
      for (var j = 0; j < timestamps.length && j < valueCol.length; j++) {
        points.add((date: timestamps[j], value: valueCol[j]));
      }

      series.add(ChartSeries(
        label: matrix.fieldNames.isNotEmpty
            ? matrix.fieldNames.first
            : 'Series ${i + 1}',
        points: points,
        color: QuanityaPalette.category10[i % QuanityaPalette.category10.length],
      ));
    }

    if (series.length == 1) {
      final s = series.first;
      return TimeSeriesChart(
        data: s.points
            .map((p) => {'date': p.date, 'value': p.value})
            .toList(),
        valueLabel: s.label,
        lineColor: s.color,
      );
    }

    return MultiSeriesChart(series: series);
  }
}
