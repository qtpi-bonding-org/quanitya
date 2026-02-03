import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../design_system/primitives/app_sizes.dart';
import '../../../design_system/widgets/quanitya_empty_or.dart';
import '../../templates/widgets/editor/schedule_section.dart';
import '../cubits/schedule_list_cubit.dart';
import '../cubits/schedule_list_state.dart';
import 'schedule_item.dart';

/// Widget that displays a list of schedules for the Future page.
/// 
/// Shows all schedules with inline editing controls - users can modify
/// frequency, time, and days directly without any modal.
/// Selecting "Off" deletes the schedule.
class ScheduleListWidget extends StatelessWidget {
  final String emptyMessage;
  final EdgeInsetsGeometry? padding;
  final void Function(ScheduleWithContext schedule)? onItemTap;

  const ScheduleListWidget({
    super.key,
    required this.emptyMessage,
    this.padding,
    this.onItemTap,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ScheduleListCubit, ScheduleListState>(
      builder: (context, state) {
        final schedules = state.schedules;

        return QuanityaEmptyOr(
          isEmpty: schedules.isEmpty,
          child: ListView.builder(
            padding: padding ?? EdgeInsets.all(AppSizes.space * 2),
            itemCount: schedules.length,
            itemBuilder: (context, index) {
              final schedule = schedules[index];
              return ScheduleItem(
                scheduleWithContext: schedule,
                isFirst: index == 0,
                isLast: index == schedules.length - 1,
                onTap: onItemTap != null ? () => onItemTap!(schedule) : null,
                onScheduleChanged: (frequency, time, weeklyDays) {
                  _handleScheduleChange(context, schedule, frequency, time, weeklyDays);
                },
              );
            },
          ),
        );
      },
    );
  }

  void _handleScheduleChange(
    BuildContext context,
    ScheduleWithContext schedule,
    ScheduleFrequency frequency,
    TimeOfDay time,
    List<String> weeklyDays,
  ) {
    final cubit = context.read<ScheduleListCubit>();
    
    // "Off" means delete the schedule
    if (frequency == ScheduleFrequency.off) {
      cubit.delete(schedule.schedule.id);
      return;
    }
    
    // Build new RRULE from the inline controls
    String newRrule;
    if (frequency == ScheduleFrequency.daily) {
      newRrule = 'FREQ=DAILY;BYHOUR=${time.hour};BYMINUTE=${time.minute}';
    } else if (frequency == ScheduleFrequency.weekly) {
      final daysStr = weeklyDays.isNotEmpty ? weeklyDays.join(',') : 'MO';
      newRrule = 'FREQ=WEEKLY;BYDAY=$daysStr;BYHOUR=${time.hour};BYMINUTE=${time.minute}';
    } else {
      // Keep existing for custom
      newRrule = schedule.schedule.recurrenceRule;
    }
    
    // Only update if changed
    if (newRrule != schedule.schedule.recurrenceRule) {
      final updated = schedule.schedule.updateRule(newRrule);
      cubit.update(updated);
    }
  }
}
