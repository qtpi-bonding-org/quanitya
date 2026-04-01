import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

import '../../../design_system/widgets/ui_flow_listener.dart';
import '../../../design_system/widgets/quanitya_icon_button.dart';
import '../../../design_system/widgets/quanitya/general/loose_insert_sheet.dart';
import '../../../design_system/widgets/quanitya/general/quanitya_page_wrapper.dart';
import '../../../support/extensions/context_extensions.dart';
import '../cubits/editor/template_editor_cubit.dart';
import '../cubits/editor/template_editor_state.dart';
import '../../../logic/templates/services/shared/template_editor_message_mapper.dart';
import '../cubits/sharing/template_sharing_export_cubit.dart';
import '../../../logic/templates/models/shared/shareable_template.dart';
import '../widgets/editor/template_editor_form.dart';
import '../widgets/shared/template_preview.dart';
import '../widgets/editor/template_browse_sheet.dart';

/// Template designer page — create or edit tracker templates.
///
/// The TemplateEditorCubit is provided at the route level in app_router.dart.
class TemplateDesignerPage extends StatelessWidget {
  const TemplateDesignerPage({super.key});

  @override
  Widget build(BuildContext context) {
    return UiFlowListener<TemplateEditorCubit, TemplateEditorState>(
      mapper: context.read<TemplateEditorMessageMapper>(),
      child: QuanityaPageWrapper(
        child: Scaffold(
          appBar: _buildAppBar(context),
          body: BlocBuilder<TemplateEditorCubit, TemplateEditorState>(
            buildWhen: (p, c) =>
                p.completeTemplate != c.completeTemplate,
            builder: (context, state) {
              return TemplateEditorForm(
                onPreview: state.completeTemplate != null
                    ? () => _showPreview(context, state)
                    : () {},
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
      centerTitle: true,
      title: BlocBuilder<TemplateEditorCubit, TemplateEditorState>(
        buildWhen: (p, c) => p.template != c.template,
        builder: (context, state) {
          final title = state.template != null
              ? context.l10n.editTemplateTitle
              : context.l10n.createTemplateTitle;
          return Text(title, style: context.text.headlineMedium);
        },
      ),
      actions: [
        BlocBuilder<TemplateEditorCubit, TemplateEditorState>(
          buildWhen: (p, c) => p.template != c.template,
          builder: (context, state) {
            if (state.template != null) {
              // Edit mode: show share
              return QuanityaIconButton(
                icon: Icons.ios_share,
                onPressed: () => _shareTemplate(context, state),
              );
            } else {
              // Create mode: show import
              return QuanityaIconButton(
                icon: Icons.download,
                onPressed: () => TemplateBrowseSheet.show(context),
              );
            }
          },
        ),
      ],
    );
  }

  void _showPreview(BuildContext context, TemplateEditorState state) {
    final completeTemplate = state.completeTemplate!;
    final cubit = context.read<TemplateEditorCubit>();

    LooseInsertSheet.show(
      context: context,
      title: completeTemplate.template.name,
      builder: (sheetContext) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.85,
        child: TemplatePreview.editor(
          template: completeTemplate.template,
          aesthetics: completeTemplate.aesthetics,
          editLabel: context.l10n.templatePreviewEdit,
          saveLabel: context.l10n.templatePreviewSave,
          initialValues: state.previewValues,
          onEdit: () => Navigator.pop(sheetContext),
          onSave: () {
            cubit.save();
            Navigator.pop(sheetContext);
          },
          onValuesChanged: (values) {
            for (final entry in values.entries) {
              cubit.updatePreviewValue(entry.key, entry.value);
            }
          },
        ),
      ),
    );
  }

  void _shareTemplate(BuildContext context, TemplateEditorState state) {
    final completeTemplate = state.completeTemplate;
    if (completeTemplate == null) return;
    final exportCubit = GetIt.instance<TemplateSharingExportCubit>();
    exportCubit.exportTemplate(
      templateWithAesthetics: completeTemplate,
      author: AuthorCredit.create(name: context.l10n.templateDefaultAuthor),
    );
  }
}
