import 'package:flutter/material.dart';

import '../../../design_system/primitives/app_spacings.dart';
import '../../../design_system/primitives/app_sizes.dart';
import '../../../design_system/primitives/quanitya_palette.dart';
import '../../../design_system/widgets/quanitya/general/quanitya_text_button.dart';
import '../../../logic/schedules/models/schedule.dart';
import '../../../support/extensions/context_extensions.dart';
import '../../templates/widgets/editor/schedule_section.dart';

/// Bottom sheet for editing an existing schedule.
/// Reuses ScheduleSection from template editor.
class EditScheduleSheet extends StatefulWidget {
  final ScheduleModel schedule;
  final String templateName;

  const EditScheduleSheet({
    super.key,
    required this.schedule,
    required this.templateName,
  });

  /// Show the edit sheet and return updated schedule or null if cancelled.
  static Future<ScheduleModel?> show(
    BuildContext context, {
    required ScheduleModel schedule,
    required String templateName,
  }) {
    return showModalBottomSheet<ScheduleModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => EditScheduleSheet(
        schedule: schedule,
        templateName: templateName,
      ),
    );
  }

  @override
  State<EditScheduleSheet> createState() => _EditScheduleSheetState();
}

class _EditScheduleSheetState extends State<EditScheduleSheet> {
  late ScheduleFrequency _frequency;
  late TimeOfDay _time;
  late List<String> _weeklyDays;

  @override
  void initState() {
    super.initState();
    _parseSchedule();
  }

  void _parseSchedule() {
    final rruleString = widget.schedule.recurrenceRule;
    
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
      _frequency = ScheduleFrequency.custom;
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

  String _buildUpdatedRrule() {
    if (_frequency == ScheduleFrequency.daily) {
      return 'FREQ=DAILY;BYHOUR=${_time.hour};BYMINUTE=${_time.minute}';
    } else if (_frequency == ScheduleFrequency.weekly) {
      final daysStr = _weeklyDays.isNotEmpty ? _weeklyDays.join(',') : 'MO';
      return 'FREQ=WEEKLY;BYDAY=$daysStr;BYHOUR=${_time.hour};BYMINUTE=${_time.minute}';
    } else {
      // Keep existing for custom/off
      return widget.schedule.recurrenceRule;
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = QuanityaPalette.primary;
    
    return Container(
      decoration: BoxDecoration(
        color: palette.backgroundPrimary,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSizes.radiusMedium),
        ),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        child: Padding(
          padding: AppPadding.page,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: AppPadding.verticalSingle,
                  decoration: BoxDecoration(
                    color: palette.textSecondary.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
                  ),
                ),
              ),
              
              VSpace.x2,
              
              // Title
              Text(
                widget.templateName,
                style: context.text.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              
              VSpace.x3,
              
              // Reuse ScheduleSection
              ScheduleSection(
                frequency: _frequency,
                reminderTime: _time,
                weeklyDays: _weeklyDays,
                onFrequencyChanged: (f) => setState(() => _frequency = f),
                onTimeChanged: (t) => setState(() => _time = t),
                onWeeklyDaysChanged: (days) => setState(() => _weeklyDays = days),
              ),
              
              VSpace.x4,
              
              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: QuanityaTextButton(text: 
                      onPressed: () => Navigator.pop(context),
                      label: context.l10n.actionCancel,
                    ),
                  ),
                  HSpace.x2,
                  Expanded(
                    child: QuanityaTextButton(text: 
                      onPressed: () {
                        final newRrule = _buildUpdatedRrule();
                        final updated = widget.schedule.updateRule(newRrule);
                        Navigator.pop(context, updated);
                      },
                      label: context.l10n.actionSave,
                    ),
                  ),
                ],
              ),
              
              VSpace.x2,
            ],
          ),
        ),
      ),
    );
  }
}
