import 'package:flutter/material.dart';
import '../../../design_system/primitives/app_sizes.dart';
import '../../../design_system/primitives/app_spacings.dart';
import '../../../design_system/primitives/quanitya_palette.dart';
import '../../../design_system/structures/group.dart';
import '../../../data/dao/log_entry_query_dao.dart';
import '../../../support/extensions/context_extensions.dart';
import '../../../support/utils/icon_resolver.dart';
import 'package:intl/intl.dart';

class TimelineItem extends StatelessWidget {
  final LogEntryWithContext entryWithContext;
  final bool isLast;
  final bool isFirst;
  final bool showTimeOnly;
  final VoidCallback? onTap;

  const TimelineItem({
    super.key,
    required this.entryWithContext,
    this.isLast = false,
    this.isFirst = false,
    this.showTimeOnly = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final entry = entryWithContext.entry;
    final template = entryWithContext.template;
    final aesthetics = entryWithContext.aesthetics;
    
    // Determine timestamp to show
    final timestamp = entry.occurredAt ?? entry.scheduledFor ?? DateTime.now();
    final timeString = DateFormat('h:mm a').format(timestamp);
    final dateString = DateFormat('MMM d').format(timestamp);

    // Get icon - priority: icon > emoji > default
    final iconString = aesthetics?.icon;
    final iconEmoji = aesthetics?.emoji ?? '📝';
    
    // Use template's accent color if available, otherwise fallback to neutral
    final accentColor = _resolveAccentColor(aesthetics);
    
    // Get title font from aesthetics
    final titleFont = aesthetics?.fontConfig.titleFontFamily;

    return QuanityaGroup(
      onTap: onTap,
      showChevron: onTap != null, // Show chevron when tappable
      padding: EdgeInsets.zero, // Custom layout for timeline
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Timeline Column
            SizedBox(
              width: AppSizes.size56, // Fixed width for timeline column
              child: Column(
                children: [
                  // Top Connector
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
                      color: template.isHidden
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
                    child: _buildIcon(iconString, iconEmoji, accentColor),
                  ),
                  // Bottom Connector
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
                    // Header: Template Name + Time
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          template.name,
                          style: _getTitleStyle(titleFont, context).copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          showTimeOnly ? timeString : '$dateString • $timeString',
                          style: context.text.bodySmall?.copyWith(
                            color: context.colors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    VSpace.x1,
                    // Data Summary (Preview of first valid field)
                    if (entry.data.isNotEmpty)
                      Text(
                        _formatEntryData(context, entry.data),
                        style: context.text.bodyMedium,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  /// Resolve accent color from aesthetics palette
  Color _resolveAccentColor(dynamic aesthetics) {
    if (aesthetics == null) return QuanityaPalette.primary.textSecondary;
    
    final accents = aesthetics.palette.accents as List<String>?;
    if (accents == null || accents.isEmpty) {
      return QuanityaPalette.primary.textSecondary;
    }
    
    final hex = accents.first.replaceFirst('#', '');
    return Color(int.parse(hex, radix: 16) + 0xFF000000);
  }
  
  /// Get title style using only Quanitya standard fonts (ignore template fonts)
  TextStyle _getTitleStyle(String? fontName, BuildContext context) {
    // Timeline always uses Quanitya standard fonts, ignore template font config
    return context.text.bodyLarge ?? const TextStyle();
  }

  String _formatEntryData(BuildContext context, Map<String, dynamic> data) {
    if (data.isEmpty) return context.l10n.timelineNoDetails;
    // Just grab the first value for now as a preview
    final firstValue = data.values.first;
    return firstValue.toString();
  }

  /// Build icon widget - priority: icon > emoji > default
  Widget _buildIcon(String? iconString, String emoji, Color color) {
    // Try to parse icon from "packname:iconname" format
    if (iconString != null && iconString.contains(':')) {
      final iconData = _parseIconFromString(iconString);
      if (iconData != null) {
        return Icon(
          iconData,
          size: AppSizes.fontBig,
          color: color,
        );
      }
    }
    
    // Fallback to emoji if provided
    if (emoji.isNotEmpty) {
      return Text(
        emoji,
        style: TextStyle(fontSize: AppSizes.fontBig),
      );
    }
    
    // Final fallback to document icon
    return Icon(
      Icons.description,
      size: AppSizes.fontBig,
      color: color,
    );
  }

  /// Parse icon from "packname:iconname" format
  IconData? _parseIconFromString(String? iconString) {
    return IconResolver.resolve(iconString);
  }
}
