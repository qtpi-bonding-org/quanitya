import 'package:flutter/material.dart';

import '../../../../support/extensions/context_extensions.dart';
import '../../../design_system/primitives/quanitya_palette.dart';
import '../../../design_system/widgets/quanitya/general/quanitya_text_button.dart';

/// Human-friendly labels for SQL table names.
String _humanize(String tableName) {
  return tableName
      .split('_')
      .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
      .join(' ');
}

/// Reusable dialog that lets the user select which tables to export/import.
///
/// All tables are checked by default. Returns the selected table names
/// as a `Set<String>`, or null if cancelled.
class TableSelectionDialog extends StatefulWidget {
  final List<String> tableNames;
  final String title;
  final String confirmButtonText;

  const TableSelectionDialog({
    super.key,
    required this.tableNames,
    required this.title,
    required this.confirmButtonText,
  });

  /// Show the dialog and return selected table names, or null if cancelled.
  static Future<Set<String>?> show(
    BuildContext context, {
    required List<String> tableNames,
    required String title,
    required String confirmButtonText,
  }) {
    return showDialog<Set<String>>(
      context: context,
      builder: (_) => TableSelectionDialog(
        tableNames: tableNames,
        title: title,
        confirmButtonText: confirmButtonText,
      ),
    );
  }

  @override
  State<TableSelectionDialog> createState() => _TableSelectionDialogState();
}

class _TableSelectionDialogState extends State<TableSelectionDialog> {
  late final Set<String> _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.tableNames.toSet();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.title,
        style: context.text.titleLarge,
      ),
      content: SizedBox(
        width: double.maxFinite,
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
      actions: [
        QuanityaTextButton(
          text: context.l10n.cancel,
          onPressed: () => Navigator.of(context).pop(),
        ),
        QuanityaTextButton(
          text: widget.confirmButtonText,
          onPressed: _selected.isEmpty
              ? null
              : () => Navigator.of(context).pop(_selected),
        ),
      ],
    );
  }
}
