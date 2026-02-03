import 'package:flutter/material.dart';
import '../../../../design_system/structures/column.dart';
import '../../../../support/extensions/context_extensions.dart';
import '../../../../data/repositories/template_with_aesthetics_repository.dart';

class TemplateInfoSection extends StatelessWidget {
  final TemplateWithAesthetics template;

  const TemplateInfoSection({super.key, required this.template});

  @override
  Widget build(BuildContext context) {
    // Format date simple
    final date = template.template.updatedAt;
    final dateStr = "${date.day}/${date.month}/${date.year}";

    return QuanityaColumn(
      crossAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(context.l10n.templateInfoTitle, style: context.text.titleSmall), // 14px header
        Text(context.l10n.templateFieldsCount(template.template.fields.length), style: context.text.bodyLarge), // 16px
        Text(context.l10n.templateCreatedDate(dateStr), style: context.text.labelMedium), // 14px metadata
      ],
    );
  }
}
