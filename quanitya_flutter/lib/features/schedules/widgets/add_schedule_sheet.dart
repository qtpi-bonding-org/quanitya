import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../../../data/dao/template_query_dao.dart';
import '../../../design_system/primitives/app_sizes.dart';
import '../../../design_system/primitives/app_spacings.dart';
import '../../../design_system/primitives/quanitya_palette.dart';
import '../../../design_system/widgets/quanitya/general/loose_insert_sheet.dart';
import '../../../design_system/widgets/quanitya/general/quanitya_text_button.dart';
import '../../../logic/schedules/models/schedule.dart';
import '../../../logic/templates/models/shared/tracker_template.dart';
import '../../../support/extensions/context_extensions.dart';
import '../../templates/widgets/editor/schedule_section.dart';

/// Bottom sheet for creating a new schedule from the +t panel.
///
/// Two-step flow:
/// 1. Pick a template (only templates without existing schedules)
/// 2. Configure frequency/time/days via [ScheduleSection]
class AddScheduleSheet extends StatefulWidget {
  /// Template IDs that already have schedules (excluded from picker).
  final Set<String> scheduledTemplateIds;

  const AddScheduleSheet({
    super.key,
    required this.scheduledTemplateIds,
  });

  /// Show the add schedule sheet and return a new [ScheduleModel] or null.
  static Future<ScheduleModel?> show(
    BuildContext context, {
    required Set<String> scheduledTemplateIds,
  }) {
    return LooseInsertSheet.show<ScheduleModel>(
      context: context,
      title: context.l10n.addSchedule,
      builder: (_) => AddScheduleSheet(
        scheduledTemplateIds: scheduledTemplateIds,
      ),
    );
  }

  @override
  State<AddScheduleSheet> createState() => _AddScheduleSheetState();
}

class _AddScheduleSheetState extends State<AddScheduleSheet> {
  List<TrackerTemplateModel>? _templates;
  TrackerTemplateModel? _selectedTemplate;
  ScheduleFrequency _frequency = ScheduleFrequency.daily;
  TimeOfDay _time = const TimeOfDay(hour: 9, minute: 0);
  List<String> _weeklyDays = [];

  @override
  void initState() {
    super.initState();
    _loadTemplates();
  }

  Future<void> _loadTemplates() async {
    final dao = GetIt.I<TemplateQueryDao>();
    final all = await dao.find(isArchived: false);
    final available = all
        .where((t) => !widget.scheduledTemplateIds.contains(t.id))
        .toList();
    if (mounted) {
      setState(() => _templates = available);
    }
  }

  String _buildRrule() {
    if (_frequency == ScheduleFrequency.daily) {
      return 'FREQ=DAILY;BYHOUR=${_time.hour};BYMINUTE=${_time.minute}';
    } else if (_frequency == ScheduleFrequency.weekly) {
      final daysStr = _weeklyDays.isNotEmpty ? _weeklyDays.join(',') : 'MO';
      return 'FREQ=WEEKLY;BYDAY=$daysStr;BYHOUR=${_time.hour};BYMINUTE=${_time.minute}';
    }
    return 'FREQ=DAILY;BYHOUR=${_time.hour};BYMINUTE=${_time.minute}';
  }

  @override
  Widget build(BuildContext context) {
    if (_templates == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Template picker
        _buildTemplatePicker(context),

        VSpace.x3,

        // Schedule config (disabled until template selected)
        AnimatedOpacity(
          opacity: _selectedTemplate != null ? 1.0 : 0.3,
          duration: const Duration(milliseconds: 150),
          child: IgnorePointer(
            ignoring: _selectedTemplate == null,
            child: ScheduleSection(
              frequency: _frequency,
              reminderTime: _time,
              weeklyDays: _weeklyDays,
              onFrequencyChanged: (f) => setState(() => _frequency = f),
              onTimeChanged: (t) => setState(() => _time = t),
              onWeeklyDaysChanged: (days) => setState(() => _weeklyDays = days),
            ),
          ),
        ),

        VSpace.x4,

        // Actions
        Row(
          children: [
            Expanded(
              child: QuanityaTextButton(
                text: context.l10n.actionCancel,
                onPressed: () => Navigator.pop(context),
              ),
            ),
            HSpace.x2,
            Expanded(
              child: QuanityaTextButton(
                text: context.l10n.actionSave,
                onPressed: _canSave() ? _save : null,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTemplatePicker(BuildContext context) {
    final palette = QuanityaPalette.primary;
    final templates = _templates!;

    if (templates.isEmpty) {
      return Text(
        context.l10n.webhooksCreateTemplateFirst,
        style: context.text.bodyMedium?.copyWith(
          color: palette.textSecondary,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.webhookSelectTemplate,
          style: context.text.titleMedium?.copyWith(
            color: palette.textPrimary,
          ),
        ),
        VSpace.x1,
        SizedBox(
          height: AppSizes.size56,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: templates.length,
            separatorBuilder: (_, _) => HSpace.x1,
            itemBuilder: (context, index) {
              final template = templates[index];
              final isSelected = _selectedTemplate?.id == template.id;
              return GestureDetector(
                onTap: () => setState(() => _selectedTemplate = template),
                child: Semantics(
                  button: true,
                  selected: isSelected,
                  label: template.name,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: AppSizes.space * 1.5,
                      vertical: AppSizes.space * 0.5,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: isSelected
                            ? palette.textPrimary
                            : palette.textSecondary.withValues(alpha: 0.3),
                        width: isSelected
                            ? AppSizes.borderWidth * 2
                            : AppSizes.borderWidth,
                      ),
                      borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
                    ),
                    child: Center(
                      child: Text(
                        template.name,
                        style: context.text.bodyMedium?.copyWith(
                          color: isSelected
                              ? palette.textPrimary
                              : palette.textSecondary,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  bool _canSave() {
    return _selectedTemplate != null &&
        _frequency != ScheduleFrequency.off;
  }

  void _save() {
    final rrule = _buildRrule();
    final schedule = ScheduleModel.create(
      templateId: _selectedTemplate!.id,
      recurrenceRule: rrule,
    );
    Navigator.pop(context, schedule);
  }
}
