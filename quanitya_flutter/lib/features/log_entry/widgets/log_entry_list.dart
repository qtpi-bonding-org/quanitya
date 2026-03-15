import 'package:flutter/material.dart';
import '../../../../design_system/primitives/app_sizes.dart';
import '../../../../design_system/primitives/app_spacings.dart';
import '../../../../support/extensions/context_extensions.dart';
import '../../../../design_system/primitives/quanitya_palette.dart';
import '../../../../logic/log_entries/models/log_entry.dart';
import '../../../../logic/templates/models/shared/tracker_template.dart';
import 'log_entry_item.dart';

class LogEntryList extends StatelessWidget {
  final List<LogEntryModel> entries;
  final TrackerTemplateModel? template;
  final Future<void> Function() onRefresh;
  final void Function(LogEntryModel entry)? onEntryTap;

  const LogEntryList({
    super.key,
    required this.entries,
    required this.onRefresh,
    this.template,
    this.onEntryTap,
  });

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: AppSizes.iconXLarge, color: context.colors.textSecondary.withValues(alpha: 0.3)),
            VSpace.x2,
            Text(context.l10n.logEntryNoEntries, style: context.text.bodyLarge?.copyWith(color: context.colors.textSecondary)), // 16px
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      color: context.colors.primaryColor,
      child: ListView.separated(
        padding: AppPadding.page,
        itemCount: entries.length,
        separatorBuilder: (_, _) => VSpace.x3,
        itemBuilder: (context, index) {
          final entry = entries[index];
          return Semantics(
            button: onEntryTap != null,
            label: context.l10n.logEntryViewLabel,
            child: GestureDetector(
              onTap: onEntryTap != null ? () => onEntryTap!(entry) : null,
              behavior: HitTestBehavior.opaque,
              child: LogEntryItem(entry: entry, template: template),
            ),
          );
        },
      ),
    );
  }
}
