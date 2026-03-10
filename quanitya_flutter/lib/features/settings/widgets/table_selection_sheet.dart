import 'package:flutter/material.dart';

import '../../../design_system/primitives/app_spacings.dart';
import '../../../design_system/primitives/quanitya_palette.dart';
import '../../../design_system/widgets/quanitya/general/loose_insert_sheet.dart';
import '../../../design_system/widgets/quanitya/general/quanitya_text_button.dart';
import '../../../support/extensions/context_extensions.dart';

/// Human-friendly labels for SQL table names.
String _humanize(String tableName) {
  return tableName
      .split('_')
      .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
      .join(' ');
}

/// Bottom sheet that lets the user select which tables to export/import.
///
/// All tables are checked by default. Returns the selected table names
/// as a `Set<String>`, or null if cancelled.
class TableSelectionSheet extends StatefulWidget {
  final List<String> tableNames;
  final String confirmButtonText;

  const TableSelectionSheet({
    super.key,
    required this.tableNames,
    required this.confirmButtonText,
  });

  /// Show the sheet and return selected table names, or null if cancelled.
  static Future<Set<String>?> show(
    BuildContext context, {
    required List<String> tableNames,
    required String title,
    required String confirmButtonText,
  }) {
    return LooseInsertSheet.show<Set<String>>(
      context: context,
      title: title,
      builder: (_) => TableSelectionSheet(
        tableNames: tableNames,
        confirmButtonText: confirmButtonText,
      ),
    );
  }

  @override
  State<TableSelectionSheet> createState() => _TableSelectionSheetState();
}

class _TableSelectionSheetState extends State<TableSelectionSheet> {
  late final Set<String> _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.tableNames.toSet();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: widget.tableNames.length,
            itemBuilder: (context, index) {
              final name = widget.tableNames[index];
              return CheckboxListTile(
                title: Text(
                  _humanize(name),
                  style: context.text.bodyMedium,
                ),
                subtitle: Text(
                  name,
                  style: context.text.bodySmall?.copyWith(
                    color: context.colors.textSecondary,
                  ),
                ),
                value: _selected.contains(name),
                onChanged: (checked) {
                  setState(() {
                    if (checked == true) {
                      _selected.add(name);
                    } else {
                      _selected.remove(name);
                    }
                  });
                },
                activeColor: context.colors.interactableColor,
                controlAffinity: ListTileControlAffinity.leading,
                dense: true,
              );
            },
          ),
        ),
        VSpace.x3,

        // Action buttons
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            QuanityaTextButton(
              text: context.l10n.actionCancel,
              onPressed: () => Navigator.of(context).pop(),
            ),
            HSpace.x2,
            QuanityaTextButton(
              text: widget.confirmButtonText,
              onPressed: _selected.isEmpty
                  ? null
                  : () => Navigator.of(context).pop(_selected),
            ),
          ],
        ),
      ],
    );
  }
}
