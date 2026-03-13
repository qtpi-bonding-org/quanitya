import 'package:flutter/material.dart';
import '../../../design_system/primitives/app_sizes.dart';
import '../../../design_system/primitives/app_spacings.dart';
import '../../../design_system/primitives/quanitya_palette.dart';
import '../../../design_system/widgets/quanitya_empty_or.dart';
import '../../../data/dao/log_entry_query_dao.dart';
import '../cubits/timeline_data_state.dart';

class TimelineWidget extends StatelessWidget {
  final List<TimelineItem> items;
  final String emptyMessage;
  final EdgeInsetsGeometry? padding;
  
  /// Callback when a timeline item is tapped.
  /// Receives the [TimelineItem] for the tapped item.
  final void Function(TimelineItem item)? onItemTap;

  const TimelineWidget({
    super.key,
    required this.items,
    required this.emptyMessage,
    this.padding,
    this.onItemTap,
  });

  @override
  Widget build(BuildContext context) {
    return QuanityaEmptyOr(
      isEmpty: items.isEmpty,
      child: ListView.builder(
        padding: padding ?? EdgeInsets.all(AppSizes.space * 2),
        itemCount: items.length,
        addAutomaticKeepAlives: false, // Reduce memory pressure
        itemBuilder: (context, index) {
          final item = items[index];
          
          return item.when(
            entry: (entryWithContext, isFirst, isLast, showTimeOnly, timeString, dateString, dataPreview, iconWidget, accentColor) {
              return _buildTimelineEntry(
                entryWithContext,
                isFirst,
                isLast,
                timeString,
                dateString,
                dataPreview,
                iconWidget,
                accentColor,
                item,
              );
            },
            dateDivider: (dateKey, isFirst, formattedDate) {
              return _buildDateDivider(formattedDate, isFirst);
            },
          );
        },
      ),
    );
  }

  /// Build optimized timeline entry using pre-computed values
  Widget _buildTimelineEntry(
    LogEntryWithContext entryWithContext,
    bool isFirst,
    bool isLast,
    String timeString,
    String dateString,
    String dataPreview,
    Widget iconWidget,
    Color accentColor,
    TimelineItem item,
  ) {
    final template = entryWithContext.template;
    
    return Semantics(
      button: true,
      label: 'View log entry',
      child: GestureDetector(
        onTap: onItemTap != null ? () => onItemTap!(item) : null,
        child: IntrinsicHeight(
          child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Timeline Column - matches original structure
            SizedBox(
              width: AppSizes.size56,
              child: Column(
                children: [
                  // Top Connector - Expanded to fill space
                  Expanded(
                    child: isFirst
                        ? const SizedBox.shrink()
                        : Container(
                            width: 2,
                            color: QuanityaPalette.primary.textPrimary,
                          ),
                  ),
                  // Icon Bubble - accent-colored icon, interactable border
                  Container(
                    width: AppSizes.size36,
                    height: AppSizes.size36,
                    decoration: BoxDecoration(
                      color: entryWithContext.template.isHidden
                          ? QuanityaPalette.primary.textPrimary
                              .withValues(alpha: 0.25)
                          : Colors.transparent,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: QuanityaPalette.primary.interactableColor,
                        width: 2,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: iconWidget, // Pre-computed widget
                  ),
                  // Bottom Connector - Expanded to fill space
                  Expanded(
                    child: isLast
                        ? const SizedBox.shrink()
                        : Container(
                            width: 2,
                            color: QuanityaPalette.primary.textPrimary,
                          ),
                  ),
                ],
              ),
            ),
            HSpace.x2,
            // Content Column
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(bottom: AppSizes.space * 2),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header: Template Name + Time (pre-computed strings)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            template.name,
                            style: TextStyle(
                              fontSize: AppSizes.fontBig,
                              fontWeight: FontWeight.bold,
                              color: QuanityaPalette.primary.textPrimary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          timeString, // Always show time only since we have date dividers
                          style: TextStyle(
                            fontSize: AppSizes.fontSmall,
                            color: QuanityaPalette.primary.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    VSpace.x05,
                    // Data Summary (pre-computed preview)
                    if (dataPreview.isNotEmpty)
                      Text(
                        dataPreview,
                        style: TextStyle(
                          fontSize: AppSizes.fontStandard,
                          color: QuanityaPalette.primary.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ),
    );
  }

  /// Build a date divider with pre-computed formatted date
  Widget _buildDateDivider(String formattedDate, bool isFirst) {
    final palette = QuanityaPalette.primary;
    
    return SizedBox(
      height: AppSizes.space * 4,
      child: Row(
        children: [
          // Timeline column - continues the line
          SizedBox(
            width: AppSizes.size56,
            child: Center(
              child: Container(
                width: 2,
                height: double.infinity,
                color: palette.textPrimary,
              ),
            ),
          ),
          HSpace.x2,
          // Date label with lines
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 1,
                    color: palette.textSecondary.withValues(alpha: 0.2),
                  ),
                ),
                HSpace.x2,
                Text(
                  formattedDate,
                  style: TextStyle(
                    fontSize: AppSizes.fontMini,
                    color: palette.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                HSpace.x2,
                Expanded(
                  child: Container(
                    height: 1,
                    color: palette.textSecondary.withValues(alpha: 0.2),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
