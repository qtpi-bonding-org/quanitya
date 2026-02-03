import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../primitives/app_sizes.dart';

/// Data point for boolean heatmap.
class BooleanPoint {
  final DateTime date;
  final bool value;
  
  const BooleanPoint({required this.date, required this.value});
}

/// Boolean heatmap chart - shows true/false pattern over time.
/// 
/// Similar to GitHub contribution graph but for boolean values.
/// Green = true, Gray = false, Empty = no entry.
class BooleanHeatmapChart extends StatelessWidget {
  final List<BooleanPoint> data;
  final double height;
  final Color? trueColor;
  final Color? falseColor;
  final int weeks;

  const BooleanHeatmapChart({
    super.key,
    required this.data,
    this.height = 160, // Increased from 120 to 160
    this.trueColor,
    this.falseColor,
    this.weeks = 12,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final positiveColor = trueColor ?? Colors.green;
    final negativeColor = falseColor ?? theme.disabledColor;
    
    // Build date -> value map
    final valueMap = <DateTime, bool>{};
    for (final point in data) {
      final dateOnly = DateTime(point.date.year, point.date.month, point.date.day);
      valueMap[dateOnly] = point.value;
    }

    // Generate grid data for last N weeks
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final startOfWeek = today.subtract(Duration(days: today.weekday % 7));
    final startDate = startOfWeek.subtract(Duration(days: (weeks - 1) * 7));

    return SizedBox(
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
                          final hasValue = valueMap.containsKey(date);
                          final value = valueMap[date];
                          
                          Color cellColor;
                          if (!hasValue) {
                            cellColor = theme.dividerColor.withValues(alpha: 0.2);
                          } else if (value == true) {
                            cellColor = positiveColor;
                          } else {
                            cellColor = negativeColor.withValues(alpha: 0.5);
                          }

                          return Padding(
                            padding: EdgeInsets.all(cellPadding),
                            child: Tooltip(
                              message: '${DateFormat('MMM d').format(date)}: ${hasValue ? (value! ? 'Yes' : 'No') : 'No entry'}',
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
  }
}
