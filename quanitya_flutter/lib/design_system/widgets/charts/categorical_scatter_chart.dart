import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../support/extensions/context_extensions.dart';
import '../../primitives/quanitya_palette.dart';
import 'dart:ui' as ui;

/// Data point for categorical scatter chart.
class CategoricalPoint {
  final DateTime date;
  final String category;
  
  const CategoricalPoint({required this.date, required this.category});
}

/// Categorical scatter chart - shows category selections over time.
/// 
/// X axis: time (days)
/// Y axis: categories (discrete)
/// Each dot represents a logged entry with that category on that day.
class CategoricalScatterChart extends StatelessWidget {
  final List<CategoricalPoint> data;
  final List<String> categories;
  final double height;
  final Color? dotColor;
  final String? title;

  /// Optional accessibility summary for screen readers.
  /// When provided, wraps the chart in a [Semantics] label.
  final String? semanticSummary;

  const CategoricalScatterChart({
    super.key,
    required this.data,
    required this.categories,
    this.height = 200,
    this.dotColor,
    this.title,
    this.semanticSummary,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty || categories.isEmpty) {
      return SizedBox(
        height: height,
        child: Center(child: Text(context.l10n.chartNoData)),
      );
    }

    final theme = Theme.of(context);
    final color = dotColor ?? QuanityaPalette.category10[0];

    // Calculate date range
    final dates = data.map((p) => p.date).toList()..sort();
    final minDate = dates.first;
    final maxDate = dates.last;
    final daySpan = maxDate.difference(minDate).inDays + 1;

    final chart = SizedBox(
      height: height,
      child: CustomPaint(
        painter: _CategoricalScatterPainter(
          data: data,
          categories: categories,
          minDate: minDate,
          daySpan: daySpan,
          dotColor: color,
          textColor: theme.textTheme.bodySmall?.color ?? Colors.grey,
          gridColor: theme.dividerColor,
        ),
        size: Size.infinite,
      ),
    );

    final defaultLabel = title != null
        ? 'Scatter chart: $title'
        : 'Scatter chart: ${categories.join(", ")}';
    return Semantics(
      label: semanticSummary ?? defaultLabel,
      child: ExcludeSemantics(child: chart),
    );
  }
}

class _CategoricalScatterPainter extends CustomPainter {
  final List<CategoricalPoint> data;
  final List<String> categories;
  final DateTime minDate;
  final int daySpan;
  final Color dotColor;
  final Color textColor;
  final Color gridColor;

  _CategoricalScatterPainter({
    required this.data,
    required this.categories,
    required this.minDate,
    required this.daySpan,
    required this.dotColor,
    required this.textColor,
    required this.gridColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const leftPadding = 80.0;
    const rightPadding = 16.0;
    const topPadding = 16.0;
    const bottomPadding = 32.0;

    final chartWidth = size.width - leftPadding - rightPadding;
    final chartHeight = size.height - topPadding - bottomPadding;
    final chartLeft = leftPadding;
    final chartTop = topPadding;

    // Draw grid lines and category labels
    final gridPaint = Paint()
      ..color = gridColor.withValues(alpha: 0.3)
      ..strokeWidth = 1;

    final textStyle = TextStyle(color: textColor, fontSize: 11);
    
    for (var i = 0; i < categories.length; i++) {
      final y = chartTop + (i + 0.5) * (chartHeight / categories.length);
      
      // Grid line
      canvas.drawLine(
        Offset(chartLeft, y),
        Offset(chartLeft + chartWidth, y),
        gridPaint,
      );
      
      // Category label
      final textSpan = TextSpan(text: categories[i], style: textStyle);
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: ui.TextDirection.ltr,
      )..layout(maxWidth: leftPadding - 8);
      
      textPainter.paint(
        canvas,
        Offset(leftPadding - textPainter.width - 8, y - textPainter.height / 2),
      );
    }

    // Draw dots
    final dotPaint = Paint()
      ..color = dotColor
      ..style = PaintingStyle.fill;

    for (final point in data) {
      final categoryIndex = categories.indexOf(point.category);
      if (categoryIndex == -1) continue;

      final dayOffset = point.date.difference(minDate).inDays;
      final x = chartLeft + (dayOffset / (daySpan - 1).clamp(1, double.infinity)) * chartWidth;
      final y = chartTop + (categoryIndex + 0.5) * (chartHeight / categories.length);

      canvas.drawCircle(Offset(x, y), 6, dotPaint);
    }

    // Draw date labels (first and last)
    final dateFormat = DateFormat('MMM d');
    final startLabel = TextSpan(text: dateFormat.format(minDate), style: textStyle);
    final startPainter = TextPainter(text: startLabel, textDirection: ui.TextDirection.ltr)..layout();
    startPainter.paint(canvas, Offset(chartLeft, chartTop + chartHeight + 8));

    final endDate = minDate.add(Duration(days: daySpan - 1));
    final endLabel = TextSpan(text: dateFormat.format(endDate), style: textStyle);
    final endPainter = TextPainter(text: endLabel, textDirection: ui.TextDirection.ltr)..layout();
    endPainter.paint(canvas, Offset(chartLeft + chartWidth - endPainter.width, chartTop + chartHeight + 8));
  }

  @override
  bool shouldRepaint(covariant _CategoricalScatterPainter oldDelegate) {
    return data != oldDelegate.data || categories != oldDelegate.categories;
  }
}
