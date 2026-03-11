import 'package:flutter/material.dart';

import '../../../logic/analytics/models/analysis_output.dart';
import '../../../support/extensions/context_extensions.dart';
import '../../primitives/quanitya_palette.dart';
import '../charts/indexed_multi_series_chart.dart';

/// Renders a list of [AnalysisVector] as an overlaid indexed line chart.
class VectorChart extends StatelessWidget {
  final List<AnalysisVector> vectors;

  const VectorChart({super.key, required this.vectors});

  @override
  Widget build(BuildContext context) {
    final palette = QuanityaPalette.primary;

    if (vectors.isEmpty) {
      return Text(
        'No vector data',
        style: context.text.bodyMedium?.copyWith(color: palette.textSecondary),
      );
    }

    final series = vectors.asMap().entries.map((entry) {
      final i = entry.key;
      final v = entry.value;
      return IndexedChartSeries(
        label: v.label,
        values: v.values,
        color: QuanityaPalette.category10[i % QuanityaPalette.category10.length],
      );
    }).toList();

    return IndexedMultiSeriesChart(series: series);
  }
}
