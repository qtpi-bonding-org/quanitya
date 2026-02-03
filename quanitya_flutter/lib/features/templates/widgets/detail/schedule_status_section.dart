import 'package:flutter/material.dart';
import '../../../../design_system/structures/column.dart';
import '../../../../design_system/structures/row.dart';
import '../../../../design_system/structures/group.dart';
import '../../../../design_system/primitives/app_sizes.dart';
import '../../../../design_system/primitives/quanitya_palette.dart';
import '../../../../support/extensions/context_extensions.dart';
import '../../../../logic/schedules/models/schedule.dart';

class ScheduleStatusSection extends StatelessWidget {
  final List<ScheduleModel> schedules;
  final VoidCallback? onAdd;
  final VoidCallback? onManage;

  const ScheduleStatusSection({
    super.key,
    required this.schedules,
    this.onAdd,
    this.onManage,
  });

  @override
  Widget build(BuildContext context) {
    return QuanityaColumn(
      crossAlignment: CrossAxisAlignment.stretch,
      children: [
        QuanityaRow(
          alignment: CrossAxisAlignment.center,
          start: Text(context.l10n.scheduleTitle, style: context.text.titleSmall), // 14px header
          // Only show Manage if there are schedules
          end: schedules.isNotEmpty
              ? TextButton(
                  onPressed: onManage,
                  child: Text(context.l10n.manage),
                )
              : null,
        ),

        if (schedules.isEmpty)
          ElevatedButton(
            onPressed: onAdd,
            child: Text(context.l10n.addSchedule),
          )
        else
          ...schedules.map((schedule) => _ScheduleItem(schedule: schedule)),
      ],
    );
  }
}

class _ScheduleItem extends StatelessWidget {
  final ScheduleModel schedule;
  const _ScheduleItem({required this.schedule});

  @override
  Widget build(BuildContext context) {
    // Basic representation - No Cards, just Group (Padding) + Row
    return QuanityaGroup(
      child: QuanityaRow(
        start: Icon(Icons.schedule, size: AppSizes.size20, color: context.colors.primaryColor),
        middle: Text("Rule: ${schedule.recurrenceRule}", style: context.text.bodyLarge), // 16px
        end: Text(
            schedule.isActive ? context.l10n.active : context.l10n.inactive,
            style: context.text.labelMedium!.copyWith( // 14px metadata
                color: schedule.isActive ? context.colors.successColor : context.colors.textSecondary,
            ),
        ),
      ),
    );
  }
}
