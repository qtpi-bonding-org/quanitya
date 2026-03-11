import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../design_system/primitives/app_spacings.dart';
import '../../../../design_system/primitives/quanitya_palette.dart';
import '../../../../design_system/structures/column.dart';
import '../../../../design_system/widgets/quanitya_text_field.dart';
import '../../../../support/extensions/context_extensions.dart';
import '../../cubits/editor/template_editor_cubit.dart';
import '../../cubits/editor/template_editor_state.dart';

/// Name and description fields for template editing.
class TemplateBasicInfoEditor extends StatefulWidget {
  const TemplateBasicInfoEditor({super.key});

  @override
  State<TemplateBasicInfoEditor> createState() => _TemplateBasicInfoEditorState();
}

class _TemplateBasicInfoEditorState extends State<TemplateBasicInfoEditor> {
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;

  @override
  void initState() {
    super.initState();
    final state = context.read<TemplateEditorCubit>().state;
    _nameController = TextEditingController(text: state.templateName);
    _descriptionController = TextEditingController(text: state.templateDescription);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<TemplateEditorCubit, TemplateEditorState>(
      listenWhen: (previous, current) =>
          previous.templateName != current.templateName ||
          previous.templateDescription != current.templateDescription,
      listener: (context, state) {
        if (_nameController.text != state.templateName) {
          _nameController.text = state.templateName;
        }
        if (_descriptionController.text != state.templateDescription) {
          _descriptionController.text = state.templateDescription;
        }
      },
      child: QuanityaColumn(
        crossAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            context.l10n.templateNameLabel,
            style: context.text.titleMedium?.copyWith(
              color: context.colors.textPrimary,
            ),
          ),
          VSpace.x1,
          QuanityaTextField(
            controller: _nameController,
            style: context.text.bodyLarge,
            hintText: context.l10n.templateNameHint,
            onChanged: (v) => context.read<TemplateEditorCubit>().updateTemplateName(v),
          ),
          VSpace.x3,
          Text(
            context.l10n.templateDescriptionLabel,
            style: context.text.titleMedium?.copyWith(
              color: context.colors.textPrimary,
            ),
          ),
          VSpace.x1,
          QuanityaTextField(
            controller: _descriptionController,
            maxLines: 2,
            hintText: context.l10n.templateDescriptionHint,
            onChanged: (v) => context.read<TemplateEditorCubit>().updateTemplateDescription(v),
          ),
        ],
      ),
    );
  }
}
