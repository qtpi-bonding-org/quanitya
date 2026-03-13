import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../primitives/app_sizes.dart';
import '../../primitives/quanitya_palette.dart';

/// Data point for boolean heatmap.
///
/// When [intensity] is provided (0.0–1.0), the cell renders with variable
/// opacity instead of a solid true/false color. This enables contribution-
/// style heatmaps that reuse the same grid layout.
class BooleanPoint {
  final DateTime date;
  final bool value;
  final double? intensity;

  const BooleanPoint({required this.date, required this.value, this.intensity});
}

/// Boolean heatmap chart - shows true/false pattern over time.
/// 
/// Similar to GitHub contribution graph but for boolean values.
/// Green = true, Gray = false, Empty = no entry.
class BooleanHeatmapChart extends StatelessWidget {
  final List<BooleanPoint> data;
  final String title;
  final double height;
  final Color? trueColor;
  final Color? falseColor;
  final int weeks;

  /// Optional accessibility summary for screen readers.
  /// When provided, wraps the chart in a [Semantics] label.
  final String? semanticSummary;

  const BooleanHeatmapChart({
    super.key,
    required this.data,
    required this.title,
    this.height = 160, // Increased from 120 to 160
    this.trueColor,
    this.falseColor,
    this.weeks = 12,
    this.semanticSummary,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final positiveColor = trueColor ?? QuanityaPalette.primary.successColor;
    final negativeColor = falseColor ?? theme.disabledColor;
    
    // Build date -> point map
    final pointMap = <DateTime, BooleanPoint>{};
    for (final point in data) {
      final dateOnly = DateTime(point.date.year, point.date.month, point.date.day);
      pointMap[dateOnly] = point;
    }

    // Generate grid data for last N weeks
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final startOfWeek = today.subtract(Duration(days: today.weekday % 7));
    final startDate = startOfWeek.subtract(Duration(days: (weeks - 1) * 7));

    final chart = SizedBox(
      height: height,
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Calculate cell size based on available height (7 days + padding)
          final availableHeight = constraints.maxHeight;
          final cellHeight = availableHeight / 7;
          final cellPadding = 1.0; // Fixed minimal padding
          final actualCellSize = cellHeight - cellPadding * 2;

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Day labels
              SizedBox(
                width: 20,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: ['S', 'M', 'T', 'W', 'T', 'F', 'S']
                      .map((d) => SizedBox(
                            height: cellHeight,
                            child: Center(
                              child: Text(
                                d,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.textTheme.bodySmall?.color,
                                ),
                              ),
                            ),
                          ))
                      .toList(),
                ),
              ),
              SizedBox(width: AppSizes.space * 0.5),
              // Grid
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  reverse: true,
                  child: Row(
                    children: List.generate(weeks, (weekIndex) {
                      final weekStart = startDate.add(Duration(days: weekIndex * 7));
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: List.generate(7, (dayIndex) {
                          final date = weekStart.add(Duration(days: dayIndex));
                          final point = pointMap[date];

                          Color cellColor;
                          String tooltipSuffix;
                          if (point == null) {
                            cellColor = theme.dividerColor.withValues(alpha: 0.2);
                            tooltipSuffix = 'No entry';
                          } else if (point.intensity != null) {
                            cellColor = positiveColor.withValues(
                              alpha: point.intensity!.clamp(0.2, 1.0),
                            );
                            tooltipSuffix = '${(point.intensity! * 100).round()}%';
                          } else if (point.value) {
                            cellColor = positiveColor;
                            tooltipSuffix = 'Yes';
                          } else {
                            cellColor = negativeColor.withValues(alpha: 0.5);
                            tooltipSuffix = 'No';
                          }

                          return Padding(
                            padding: EdgeInsets.all(cellPadding),
                            child: Tooltip(
                              message: '${DateFormat('MMM d').format(date)}: $tooltipSuffix',
                              child: Container(
                                width: actualCellSize,
                                height: actualCellSize,
                                decoration: BoxDecoration(
                                  color: cellColor,
                                  borderRadius: BorderRadius.circular(AppSizes.radiusTiny),
                                ),
                              ),
                            ),
                          );
                        }),
                      );
                    }),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );

    final defaultLabel = 'Boolean heatmap: $title';
    return Semantics(
      label: semanticSummary ?? defaultLabel,
      child: ExcludeSemantics(child: chart),
    );
  }
}
