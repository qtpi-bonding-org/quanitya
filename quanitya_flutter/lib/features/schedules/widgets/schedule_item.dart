import 'package:flutter/material.dart';

import '../../../design_system/primitives/app_sizes.dart';
import '../../../design_system/primitives/app_spacings.dart';
import '../../../design_system/primitives/quanitya_palette.dart';
import '../../../design_system/structures/group.dart';
import '../../../design_system/widgets/quanitya/general/pen_circled_chip.dart';
import '../../../support/extensions/context_extensions.dart';
import '../../../support/utils/icon_resolver.dart';
import '../../templates/widgets/editor/schedule_section.dart';
import '../cubits/schedule_list_state.dart';

/// A single schedule item for the Future page.
/// 
/// Shows inline editing controls:
/// - Template icon/emoji and name
/// - Frequency selector (Off/Daily/Weekly)
/// - Time picker
/// - Day selector (for weekly)
class ScheduleItem extends StatefulWidget {
  final ScheduleWithContext scheduleWithContext;
  final bool isFirst;
  final bool isLast;
  final VoidCallback? onTap;
  final void Function(ScheduleFrequency frequency, TimeOfDay time, List<String> weeklyDays)? onScheduleChanged;

  const ScheduleItem({
    super.key,
    required this.scheduleWithContext,
    this.isFirst = false,
    this.isLast = false,
    this.onTap,
    this.onScheduleChanged,
  });

  @override
  State<ScheduleItem> createState() => _ScheduleItemState();
}

class _ScheduleItemState extends State<ScheduleItem> {
  late ScheduleFrequency _frequency;
  late TimeOfDay _time;
  late List<String> _weeklyDays;

  @override
  void initState() {
    super.initState();
    _parseSchedule();
  }

  @override
  void didUpdateWidget(ScheduleItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.scheduleWithContext.schedule.recurrenceRule != 
        widget.scheduleWithContext.schedule.recurrenceRule) {
      _parseSchedule();
    }
  }

  void _parseSchedule() {
    final rruleString = widget.scheduleWithContext.schedule.recurrenceRule;
    
    // Parse the RRULE string directly
    final parts = <String, String>{};
    final cleanRule = rruleString.replaceFirst(RegExp(r'^RRULE:', caseSensitive: false), '');
    for (final part in cleanRule.split(';')) {
      final keyValue = part.split('=');
      if (keyValue.length == 2) {
        parts[keyValue[0].toUpperCase()] = keyValue[1];
      }
    }
    
    // Parse frequency
    final freq = parts['FREQ']?.toUpperCase();
    if (freq == 'DAILY') {
      _frequency = ScheduleFrequency.daily;
    } else if (freq == 'WEEKLY') {
      _frequency = ScheduleFrequency.weekly;
    } else {
      _frequency = ScheduleFrequency.daily; // Default to daily for display
    }

    // Parse time from BYHOUR/BYMINUTE or default
    final hour = int.tryParse(parts['BYHOUR'] ?? '') ?? 9;
    final minute = int.tryParse(parts['BYMINUTE'] ?? '') ?? 0;
    _time = TimeOfDay(hour: hour, minute: minute);

    // Parse weekly days from BYDAY
    final byDay = parts['BYDAY'];
    if (byDay != null && byDay.isNotEmpty) {
      _weeklyDays = byDay.split(',').map((d) => d.toUpperCase()).toList();
    } else {
      _weeklyDays = [];
    }
  }

  void _onFrequencyChanged(ScheduleFrequency frequency) {
    setState(() => _frequency = frequency);
    _notifyChange();
  }

  void _onTimeChanged(TimeOfDay time) {
    setState(() => _time = time);
    _notifyChange();
  }

  void _onWeeklyDaysChanged(List<String> days) {
    setState(() => _weeklyDays = days);
    _notifyChange();
  }

  void _notifyChange() {
    widget.onScheduleChanged?.call(_frequency, _time, _weeklyDays);
  }

  @override
  Widget build(BuildContext context) {
    final palette = QuanityaPalette.primary;
    final template = widget.scheduleWithContext.template;
    final aesthetics = widget.scheduleWithContext.aesthetics;

    // Get icon - priority: icon > emoji > default
    final iconString = aesthetics?.icon;
    final iconEmoji = aesthetics?.emoji;

    // Use neutral1 (blue-grey) for all timeline icons
    final iconColor = palette.textSecondary;

    return QuanityaGroup(
      onTap: widget.onTap,
      showChevron: false,
      padding: EdgeInsets.zero,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Timeline Column
            SizedBox(
              width: AppSizes.size56,
              child: Column(
                children: [
                  // Top Connector
                  SizedBox(
                    height: AppSizes.space * 2,
                    child: widget.isFirst
                        ? const SizedBox.shrink()
                        : Container(
                            width: AppSizes.borderWidth,
                            color: palette.textSecondary.withValues(alpha: 0.3),
                          ),
                  ),
                  // Icon Bubble
                  Container(
                    width: AppSizes.size36,
                    height: AppSizes.size36,
                    decoration: BoxDecoration(
                      color: palette.backgroundPrimary,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: palette.textSecondary.withValues(alpha: 0.3),
                        width: AppSizes.borderWidth,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: _buildIcon(iconString, iconEmoji, iconColor),
                  ),
                  // Bottom Connector
                  Expanded(
                    child: widget.isLast
                        ? const SizedBox.shrink()
                        : Container(
                            width: AppSizes.borderWidth,
                            color: palette.textSecondary.withValues(alpha: 0.3),
                          ),
                  ),
                ],
              ),
            ),
            HSpace.x2,
            // Content Column
            Expanded(
              child: Padding(
                padding: AppPadding.verticalDouble,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header: Template Name
                    Text(
                      template.name,
                      style: context.text.bodyLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: palette.textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    VSpace.x2,
                    
                    // Inline schedule controls
                    _InlineScheduleControls(
                      frequency: _frequency,
                      time: _time,
                      weeklyDays: _weeklyDays,
                      onFrequencyChanged: _onFrequencyChanged,
                      onTimeChanged: _onTimeChanged,
                      onWeeklyDaysChanged: _onWeeklyDaysChanged,
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

  /// Build icon widget - priority: icon > emoji > default icon
  Widget _buildIcon(String? iconString, String? emoji, Color color) {
    // Try to resolve icon from "packname:iconname" format
    if (iconString != null && iconString.contains(':')) {
      final iconData = _parseIconFromString(iconString);
      if (iconData != null) {
        return Icon(
          iconData,
          size: AppSizes.iconMedium,
          color: color,
        );
      }
    }

    // Fallback to emoji if provided
    if (emoji != null && emoji.isNotEmpty) {
      return Text(
        emoji,
        style: TextStyle(fontSize: AppSizes.iconMedium),
      );
    }

    // Final fallback to calendar icon
    return Icon(
      Icons.calendar_today,
      size: AppSizes.iconMedium,
      color: color,
    );
  }

  /// Parse icon from "packname:iconname" format
  IconData? _parseIconFromString(String? iconString) {
    return IconResolver.resolve(iconString);
  }
}

/// Compact inline schedule controls for the schedule item.
class _InlineScheduleControls extends StatelessWidget {
  final ScheduleFrequency frequency;
  final TimeOfDay time;
  final List<String> weeklyDays;
  final ValueChanged<ScheduleFrequency> onFrequencyChanged;
  final ValueChanged<TimeOfDay> onTimeChanged;
  final ValueChanged<List<String>> onWeeklyDaysChanged;

  const _InlineScheduleControls({
    required this.frequency,
    required this.time,
    required this.weeklyDays,
    required this.onFrequencyChanged,
    required this.onTimeChanged,
    required this.onWeeklyDaysChanged,
  });

  static const _days = [
    ('MO', 'M'),
    ('TU', 'T'),
    ('WE', 'W'),
    ('TH', 'T'),
    ('FR', 'F'),
    ('SA', 'S'),
    ('SU', 'S'),
  ];

  @override
  Widget build(BuildContext context) {
    final palette = QuanityaPalette.primary;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Frequency chips - Off / Daily / Weekly
        Wrap(
          spacing: AppSizes.space,
          runSpacing: AppSizes.space,
          children: [
            PenCircledChip(
              label: context.l10n.scheduleOff,
              isSelected: frequency == ScheduleFrequency.off,
              onTap: () => onFrequencyChanged(ScheduleFrequency.off),
            ),
            PenCircledChip(
              label: context.l10n.scheduleDaily,
              isSelected: frequency == ScheduleFrequency.daily,
              onTap: () => onFrequencyChanged(ScheduleFrequency.daily),
            ),
            PenCircledChip(
              label: context.l10n.scheduleWeekly,
              isSelected: frequency == ScheduleFrequency.weekly,
              onTap: () => onFrequencyChanged(ScheduleFrequency.weekly),
            ),
          ],
        ),
        
        VSpace.x2,
        
        // Time picker - disabled when off
        AnimatedOpacity(
          opacity: frequency != ScheduleFrequency.off ? 1.0 : 0.3,
          duration: const Duration(milliseconds: 150),
          child: IgnorePointer(
            ignoring: frequency == ScheduleFrequency.off,
            child: Semantics(
              button: true,
              label: 'Change time',
              child: GestureDetector(
                onTap: () async {
                  final picked = await showTimePicker(
                    context: context,
                    initialTime: time,
                  );
                  if (picked != null) {
                    onTimeChanged(picked);
                  }
                },
                behavior: HitTestBehavior.opaque,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      context.l10n.scheduleTimeLabel,
                      style: context.text.bodySmall?.copyWith(
                        color: palette.textSecondary,
                      ),
                    ),
                    HSpace.x1,
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: AppSizes.space,
                        vertical: AppSizes.space * 0.5,
                      ),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: palette.textSecondary.withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                      ),
                      child: Text(
                        time.format(context),
                        style: context.text.bodySmall?.copyWith(
                          color: palette.textPrimary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        
        VSpace.x2,
        
        // Weekly day selector - disabled when not weekly
        AnimatedOpacity(
          opacity: frequency == ScheduleFrequency.weekly ? 1.0 : 0.3,
          duration: const Duration(milliseconds: 150),
          child: IgnorePointer(
            ignoring: frequency != ScheduleFrequency.weekly,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: _days.map((day) {
                final isSelected = weeklyDays.contains(day.$1);
                return Padding(
                  padding: EdgeInsets.only(right: AppSizes.space * 0.5),
                  child: PenCircledDot(
                    label: day.$2,
                    isSelected: isSelected,
                    onTap: () {
                      final newDays = List<String>.from(weeklyDays);
                      if (isSelected) {
                        newDays.remove(day.$1);
                      } else {
                        newDays.add(day.$1);
                      }
                      onWeeklyDaysChanged(newDays);
                    },
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }
}
