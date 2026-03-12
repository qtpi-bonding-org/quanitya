import 'package:flutter/material.dart';

import '../../../design_system/widgets/quanitya/general/loose_insert_sheet.dart';
import '../../../logic/templates/models/shared/tracker_template.dart';
import '../../../support/extensions/context_extensions.dart';

/// Shows a LooseInsertSheet listing all templates for the user to pick from.
class TemplateSelectorSheet {
  static Future<String?> show(
    BuildContext context,
    List<TrackerTemplateModel> templates,
  ) {
    return LooseInsertSheet.show<String>(
      context: context,
      title: context.l10n.selectExperiment,
      builder: (context) => ListView.builder(
        shrinkWrap: true,
        itemCount: templates.length,
        itemBuilder: (context, index) {
          final template = templates[index];
          return ListTile(
            title: Text(template.name),
            onTap: () => Navigator.of(context).pop(template.id),
          );
        },
      ),
    );
  }
}
