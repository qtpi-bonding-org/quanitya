import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../primitives/app_sizes.dart';
import '../../primitives/quanitya_palette.dart';

/// Data point for contribution heatmap - count of entries per day.
class ContributionPoint {
  final DateTime date;
  final int count;
  
  const ContributionPoint({required this.date, required this.count});
}

/// GitHub-style contribution heatmap showing logging frequency.
/// 
/// Intensity varies based on entry count per day.
/// Uses QuanityaPalette colors for consistency.
class ContributionHeatmap extends StatelessWidget {
  final List<ContributionPoint> data;
  final int weeks;

  const ContributionHeatmap({
    super.key,
    required this.data,
    this.weeks = 12,
  });

  @override
  Widget build(BuildContext context) {
    final palette = QuanityaPalette.primary;
    
    // Build date -> count map
    final countMap = <DateTime, int>{};
    int maxCount = 1;
    for (final point in data) {
      final dateOnly = DateTime(point.date.year, point.date.month, point.date.day);
      countMap[dateOnly] = point.count;
      if (point.count > maxCount) maxCount = point.count;
    }

    // Generate grid data for last N weeks
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final startOfWeek = today.subtract(Duration(days: today.weekday % 7));
    final startDate = startOfWeek.subtract(Duration(days: (weeks - 1) * 7));

    const cellSize = 12.0;
    const cellPadding = 2.0;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      reverse: true,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: List.generate(weeks, (weekIndex) {
          final weekStart = startDate.add(Duration(days: weekIndex * 7));
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(7, (dayIndex) {
              final date = weekStart.add(Duration(days: dayIndex));
              final count = countMap[date] ?? 0;
              final isFuture = date.isAfter(today);
              
              // Calculate intensity (0.0 to 1.0)
              final intensity = count > 0 ? (count / maxCount).clamp(0.2, 1.0) : 0.0;
              
              Color cellColor;
              if (isFuture) {
                cellColor = palette.textSecondary.withValues(alpha: 0.05);
              } else if (count == 0) {
                cellColor = palette.textSecondary.withValues(alpha: 0.1);
              } else {
                cellColor = palette.primaryColor.withValues(alpha: intensity);
              }

              return Padding(
                padding: const EdgeInsets.all(cellPadding),
                child: Tooltip(
                  message: isFuture 
                      ? DateFormat('MMM d').format(date)
                      : '${DateFormat('MMM d').format(date)}: $count ${count == 1 ? 'entry' : 'entries'}',
                  child: Container(
                    width: cellSize,
                    height: cellSize,
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
    );
  }
}
