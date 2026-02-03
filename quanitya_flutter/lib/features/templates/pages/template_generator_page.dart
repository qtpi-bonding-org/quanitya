import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

import '../../../data/repositories/template_with_aesthetics_repository.dart';
import '../../../design_system/widgets/ui_flow_listener.dart';
import '../../../support/extensions/context_extensions.dart';
import '../../../app_router.dart';
import '../cubits/editor/template_editor_cubit.dart';
import '../cubits/editor/template_editor_state.dart';
import '../../../logic/templates/services/shared/template_editor_message_mapper.dart';
import '../widgets/editor/template_editor_form.dart';

/// Template generator page.
///
/// Simple and agnostic approach:
/// - TemplateGeneratorPage() - Create new template
/// - TemplateGeneratorPage(templateWithAesthetics) - Edit existing template
class TemplateGeneratorPage extends StatelessWidget {
  final TemplateWithAesthetics? templateWithAesthetics;

  const TemplateGeneratorPage({
    super.key,
    this.templateWithAesthetics,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) {
        final cubit = GetIt.I<TemplateEditorCubit>();

        // Initialize based on whether we have a template
        if (templateWithAesthetics != null) {
          cubit.loadTemplate(templateWithAesthetics!);
        } else {
          cubit.createNew();
        }

        return cubit;
      },
      child: UiFlowListener<TemplateEditorCubit, TemplateEditorState>(
        mapper: GetIt.I<TemplateEditorMessageMapper>(),
        child: Scaffold(
          appBar: _buildAppBar(context),
          body: BlocBuilder<TemplateEditorCubit, TemplateEditorState>(
            builder: (context, state) {
              return TemplateEditorForm(
                onPreview: state.completeTemplate != null
                    ? () => AppNavigation.toTemplatePreview(
                          context,
                          state.completeTemplate!,
                          initialValues: state.previewValues,
                          editorCubit: context.read<TemplateEditorCubit>(),
                        )
                    : () {}, // Empty callback when no complete template
                onSave: () => context.read<TemplateEditorCubit>().save(),
              );
            },
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      title: BlocBuilder<TemplateEditorCubit, TemplateEditorState>(
        builder: (context, state) {
          // Simple title based on whether we're editing or creating
          final title = state.template != null
              ? context.l10n.editTemplateTitle
              : context.l10n.createTemplateTitle;
          return Text(title, style: context.text.headlineMedium); // 24px
        },
      ),
    );
  }
}
