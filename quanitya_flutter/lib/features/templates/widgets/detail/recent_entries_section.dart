import 'package:flutter/material.dart';
import '../../../../app_router.dart';
import '../../../../support/extensions/context_extensions.dart';
import '../../../../design_system/primitives/app_sizes.dart';
import '../../../../design_system/primitives/quanitya_palette.dart';
import '../../../../logic/log_entries/models/log_entry.dart';
import '../../../../logic/templates/models/shared/tracker_template.dart';
import '../../../../design_system/structures/column.dart';
import '../../../../design_system/structures/row.dart';
import '../../../../design_system/widgets/quanitya/general/quanitya_text_button.dart';
import '../../../log_entry/widgets/log_entry_item.dart';

class RecentEntriesSection extends StatelessWidget {
  final TrackerTemplateModel template;
  final List<LogEntryModel> entries;

  const RecentEntriesSection({
    super.key,
    required this.template,
    required this.entries,
  });

  @override
  Widget build(BuildContext context) {
    return QuanityaColumn(
      crossAlignment: CrossAxisAlignment.stretch,
      children: [
        QuanityaRow(
          alignment: CrossAxisAlignment.center,
          start: Text(
            context.l10n.recentEntriesTitle,
            style: context.text.titleSmall,
          ), // 14px header
          end: QuanityaTextButton(
            text: context.l10n.viewAll,
            onPressed: () => AppNavigation.toLogHistory(context, template.id),
          ),
        ),

        if (entries.isEmpty)
          Padding(
            padding: EdgeInsets.symmetric(vertical: AppSizes.space * 2),
            child: Text(
              context.l10n.logEntryNoEntries,
              style: context.text.bodyLarge!.copyWith(
                color: context.colors.textSecondary,
              ),
            ), // 16px
          ),

        ...entries
            .take(5)
            .map(
              (entry) => LogEntryItem(
                entry: entry,
                template: template,
              ),
            ),
      ],
    );
  }
}
