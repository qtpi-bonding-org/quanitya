import 'package:flutter/material.dart';

import '../../../../design_system/primitives/app_spacings.dart';
import '../../../../design_system/primitives/app_sizes.dart';
import '../../../../design_system/primitives/quanitya_palette.dart';
import '../../../../design_system/widgets/quanitya/general/pen_circled_chip.dart';
import '../../../../support/extensions/context_extensions.dart';

/// Frequency options for the schedule
enum ScheduleFrequency {
  off,
  daily,
  weekly,
  custom,
}

/// Minimal schedule/reminder section for the template editor.
///
/// Follows ui-guide.md:
/// - No cards, no borders
/// - Uses VSpace/HSpace tokens
/// - "Circled" selection style (pen/pencil aesthetic)
class ScheduleSection extends StatelessWidget {
  final ScheduleFrequency frequency;
  final TimeOfDay? reminderTime;
  final List<String>? weeklyDays;
  final ValueChanged<ScheduleFrequency> onFrequencyChanged;
  final ValueChanged<TimeOfDay> onTimeChanged;
  final ValueChanged<List<String>>? onWeeklyDaysChanged;

  const ScheduleSection({
    super.key,
    required this.frequency,
    this.reminderTime,
    this.weeklyDays,
    required this.onFrequencyChanged,
    required this.onTimeChanged,
    this.onWeeklyDaysChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section label - title style, bigger, black
        Row(
          children: [
            Icon(
              Icons.notifications_outlined,
              size: AppSizes.iconMedium,
              color: context.colors.textPrimary,
            ),
            HSpace.x1,
            Text(
              context.l10n.reminderLabel,
              style: context.text.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: context.colors.textPrimary,
              ),
            ),
          ],
        ),

        VSpace.x2,

        // Frequency chips
        Row(
          children: [
            PenCircledChip(
              label: context.l10n.scheduleOff,
              isSelected: frequency == ScheduleFrequency.off,
              onTap: () => onFrequencyChanged(ScheduleFrequency.off),
            ),
            HSpace.x2,
            PenCircledChip(
              label: context.l10n.scheduleDaily,
              isSelected: frequency == ScheduleFrequency.daily,
              onTap: () => onFrequencyChanged(ScheduleFrequency.daily),
            ),
            HSpace.x2,
            PenCircledChip(
              label: context.l10n.scheduleWeekly,
              isSelected: frequency == ScheduleFrequency.weekly,
              onTap: () => onFrequencyChanged(ScheduleFrequency.weekly),
            ),
          ],
        ),

        VSpace.x2,

        // Time picker - always visible but disabled when off
        AnimatedOpacity(
          opacity: frequency != ScheduleFrequency.off ? 1.0 : 0.3,
          duration: const Duration(milliseconds: 150),
          child: IgnorePointer(
            ignoring: frequency == ScheduleFrequency.off,
            child: _TimePicker(
              time: reminderTime ?? const TimeOfDay(hour: 9, minute: 0),
              onChanged: onTimeChanged,
            ),
          ),
        ),

        VSpace.x2,

        // Weekly day selector - always visible but disabled when not weekly
        AnimatedOpacity(
          opacity: frequency == ScheduleFrequency.weekly ? 1.0 : 0.3,
          duration: const Duration(milliseconds: 150),
          child: IgnorePointer(
            ignoring: frequency != ScheduleFrequency.weekly,
            child: _WeekdaySelector(
              selectedDays: weeklyDays ?? [],
              onChanged: onWeeklyDaysChanged ?? (_) {},
            ),
          ),
        ),
      ],
    );
  }
}

/// Simple time picker that shows current time and opens picker on tap.
class _TimePicker extends StatelessWidget {
  final TimeOfDay time;
  final ValueChanged<TimeOfDay> onChanged;

  const _TimePicker({
    required this.time,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final picked = await showTimePicker(
          context: context,
          initialTime: time,
        );
        if (picked != null) {
          onChanged(picked);
        }
      },
      behavior: HitTestBehavior.opaque,
      child: Row(
        children: [
          Text(
            context.l10n.scheduleTimeLabel,
            style: context.text.bodyMedium?.copyWith(
              color: context.colors.textSecondary,
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
                  color: context.colors.textSecondary.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
            ),
            child: Text(
              time.format(context),
              style: context.text.bodyMedium?.copyWith(
                color: context.colors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Weekday selector for weekly schedules.
class _WeekdaySelector extends StatelessWidget {
  final List<String> selectedDays;
  final ValueChanged<List<String>> onChanged;

  const _WeekdaySelector({
    required this.selectedDays,
    required this.onChanged,
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
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: _days.map((day) {
        final isSelected = selectedDays.contains(day.$1);
        return Padding(
          padding: EdgeInsets.only(right: AppSizes.space),
          child: PenCircledDot(
            label: day.$2,
            isSelected: isSelected,
            onTap: () {
              final newDays = List<String>.from(selectedDays);
              if (isSelected) {
                newDays.remove(day.$1);
              } else {
                newDays.add(day.$1);
              }
              onChanged(newDays);
            },
          ),
        );
      }).toList(),
    );
  }
}
