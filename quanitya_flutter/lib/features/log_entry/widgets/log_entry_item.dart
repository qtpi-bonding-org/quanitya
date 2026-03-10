import 'package:flutter/material.dart';
import '../../../../design_system/primitives/app_sizes.dart';
import '../../../../support/extensions/context_extensions.dart';
import '../../../../design_system/primitives/app_spacings.dart';
import '../../../../design_system/primitives/quanitya_palette.dart';
import '../../../../logic/log_entries/models/log_entry.dart';
import '../../../../logic/templates/models/shared/tracker_template.dart';
import '../../../../design_system/structures/column.dart';
import '../../../../design_system/structures/row.dart';
import '../../../../design_system/structures/group.dart';
import '../../../../design_system/widgets/quanitya/general/notebook_fold.dart';

class LogEntryItem extends StatelessWidget {
  final LogEntryModel entry;
  final TrackerTemplateModel? template;

  const LogEntryItem({
    super.key,
    required this.entry,
    this.template,
  });

  @override
  Widget build(BuildContext context) {
    final date = entry.displayTimestamp;
    final now = DateTime.now();
    final isToday = date.year == now.year && date.month == now.month && date.day == now.day;
    final timeStr = "${isToday ? 'Today' : '${date.month}/${date.day}'}, ${date.hour}:${date.minute.toString().padLeft(2, '0')}";

    final headerRow = Text(
      timeStr,
      style: context.text.labelMedium,
    );

    if (template == null) {
      return QuanityaGroup(
        child: QuanityaColumn(
          crossAlignment: CrossAxisAlignment.stretch,
          children: [headerRow],
        ),
      );
    }

    final keys = entry.data.keys.toList();

    // If 2 or fewer fields, show everything directly — no fold needed.
    if (keys.length <= 2) {
      return QuanityaGroup(
        child: QuanityaColumn(
          crossAlignment: CrossAxisAlignment.stretch,
          children: [
            headerRow,
            ..._buildFieldWidgets(context, keys, 0, keys.length, expanded: true),
          ],
        ),
      );
    }

    // More than 2 fields: use NotebookFold.
    // Header shows timestamp + first 2 fields summary + "+N more" hint.
    // Child shows remaining fields.
    return QuanityaGroup(
      child: QuanityaColumn(
        crossAlignment: CrossAxisAlignment.stretch,
        children: [
          headerRow,
          if (entry.data.isEmpty)
            Text(context.l10n.logEntryNoData, style: context.text.bodySmall)
          else
            NotebookFold(
              initiallyExpanded: false,
              header: QuanityaColumn(
                children: [
                  ..._buildFieldWidgets(context, keys, 0, 2, expanded: false),
                  Padding(
                    padding: EdgeInsets.only(left: AppSizes.space),
                    child: Text(
                      "... +${keys.length - 2} more",
                      style: context.text.labelMedium,
                    ),
                  ),
                ],
              ),
              child: QuanityaColumn(
                children: _buildFieldWidgets(context, keys, 2, keys.length, expanded: true),
              ),
            ),
        ],
      ),
    );
  }

  List<Widget> _buildFieldWidgets(
    BuildContext context,
    List<String> keys,
    int start,
    int end, {
    required bool expanded,
  }) {
    if (entry.data.isEmpty) {
      return [Text(context.l10n.logEntryNoData, style: context.text.bodySmall)];
    }

    final fields = <Widget>[];
    final data = entry.data;

    for (var i = start; i < end; i++) {
      final key = keys[i];
      final value = data[key];
      final fieldDef = template!.fields.firstWhere(
        (f) => f.id == key,
        orElse: () => template!.fields.first,
      );
      final label = fieldDef.id == key ? fieldDef.label : key;

      fields.add(
        Padding(
          padding: EdgeInsets.only(left: AppSizes.space),
          child: QuanityaRow(
            spacing: HSpace.x1,
            alignment: CrossAxisAlignment.start,
            start: Text(
              "$label:",
              style: context.text.bodyLarge!.copyWith(color: context.colors.textSecondary),
            ),
            middle: Text(
              value.toString(),
              style: context.text.bodyLarge,
              maxLines: expanded ? null : 1,
              overflow: expanded ? null : TextOverflow.ellipsis,
            ),
          ),
        ),
      );
    }

    return fields;
  }
}
