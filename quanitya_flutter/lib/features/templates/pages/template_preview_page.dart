import 'package:flutter/material.dart';

import '../../../data/repositories/template_with_aesthetics_repository.dart';
import '../../../support/extensions/context_extensions.dart';
import '../widgets/shared/template_preview.dart';

/// Template Preview Page - Shows interactive preview of a template.
/// 
/// Used for previewing templates during creation/editing process.
class TemplatePreviewPage extends StatelessWidget {
  final TemplateWithAesthetics templateWithAesthetics;
  final Map<String, dynamic>? initialValues;
  final dynamic editorCubit; // TemplateEditorCubit to avoid import

  const TemplatePreviewPage({
    super.key,
    required this.templateWithAesthetics,
    this.initialValues,
    this.editorCubit,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          templateWithAesthetics.template.name,
          style: context.text.headlineMedium,
        ),
      ),
      body: TemplatePreview.editor(
        template: templateWithAesthetics.template,
        aesthetics: templateWithAesthetics.aesthetics,
        initialValues: initialValues ?? {},
        onEdit: () => Navigator.pop(context),
        onSave: () => _saveTemplate(context),
        onValuesChanged: _handleValuesChanged,
      ),
    );
  }

  void _handleValuesChanged(Map<String, dynamic> values) {
    // Update preview values in the editor cubit if available
    if (editorCubit != null) {
      for (final entry in values.entries) {
        // Call updatePreviewValue method dynamically
        (editorCubit as dynamic).updatePreviewValue(entry.key, entry.value);
      }
    }
  }

  void _saveTemplate(BuildContext context) {
    if (editorCubit != null) {
      // Save via the editor cubit
      (editorCubit as dynamic).save();
    }
    Navigator.pop(context);
  }
}