import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:cubit_ui_flow/cubit_ui_flow.dart';

import '../../../app_router.dart';
import '../../../support/extensions/context_extensions.dart';
import '../../../design_system/primitives/app_spacings.dart';
import '../../../design_system/primitives/quanitya_palette.dart';
import '../../../design_system/widgets/quanitya_icon_button.dart';
import '../../../design_system/widgets/quanitya/general/quanitya_text_button.dart';
import '../../../design_system/widgets/quanitya_text_field.dart';

import '../cubits/sharing/template_sharing_import_cubit.dart';
import '../cubits/sharing/template_sharing_import_state.dart';
import '../widgets/shared/template_preview.dart';

class TemplateImportPage extends StatelessWidget {
  const TemplateImportPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => GetIt.instance<TemplateSharingImportCubit>(),
      child: const _TemplateImportView(),
    );
  }
}

class _TemplateImportView extends StatefulWidget {
  const _TemplateImportView();

  @override
  State<_TemplateImportView> createState() => _TemplateImportViewState();
}

class _TemplateImportViewState extends State<_TemplateImportView> {
  final _urlController = TextEditingController();

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          context.l10n.importTemplateTitle,
          style: context.text.headlineMedium,
        ),
        leading: QuanityaIconButton(
          icon: Icons.arrow_back,
          onPressed: () => AppNavigation.back(context),
        ),
      ),
      body: Padding(
        padding: AppPadding.page,
        child: BlocConsumer<TemplateSharingImportCubit,
            TemplateSharingImportState>(
          listener: (context, state) {
            // Navigate back after successful import
            if (state.status == UiFlowStatus.success &&
                state.lastOperation ==
                    TemplateSharingImportOperation.confirmImport) {
              AppNavigation.back(context);
            }
          },
          builder: (context, state) {
            return ListView(
              children: [
                // URL input
                Text(
                  context.l10n.importTemplateUrlSection,
                  style: context.text.titleMedium?.copyWith(
                    color: context.colors.textPrimary,
                  ),
                ),
                VSpace.x1,
                Text(
                  context.l10n.importTemplateUrlDescription,
                  style: context.text.bodyMedium?.copyWith(
                    color: context.colors.textSecondary,
                  ),
                ),
                VSpace.x3,

                QuanityaTextField(
                  controller: _urlController,
                  hintText: context.l10n.templateImportUrlHint,
                  keyboardType: TextInputType.url,
                  onSubmitted: (_) => _preview(context),
                ),
                VSpace.x3,

                QuanityaTextButton(
                  text: context.l10n.previewAction,
                  onPressed: state.status == UiFlowStatus.loading
                      ? null
                      : () => _preview(context),
                ),

                // Loading
                if (state.status == UiFlowStatus.loading) ...[
                  VSpace.x4,
                  const Center(child: CircularProgressIndicator()),
                ],

                // Error
                if (state.status == UiFlowStatus.failure &&
                    state.error != null) ...[
                  VSpace.x4,
                  Text(
                    state.error.toString(),
                    style: context.text.bodySmall?.copyWith(
                      color: context.colors.errorColor,
                    ),
                  ),
                ],

                // Preview
                if (state.previewTemplate != null) ...[
                  VSpace.x4,
                  TemplatePreview.imported(
                    template: state.previewTemplate!.template,
                    aesthetics: state.previewTemplate!.aesthetics,
                    importLabel: context.l10n.templatePreviewImport,
                    cancelLabel: context.l10n.actionCancel,
                    onImport: () => context
                        .read<TemplateSharingImportCubit>()
                        .confirmImport(),
                    onCancel: () => context
                        .read<TemplateSharingImportCubit>()
                        .clearPreview(),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  void _preview(BuildContext context) {
    final url = _urlController.text.trim();
    if (url.isNotEmpty) {
      context.read<TemplateSharingImportCubit>().previewFromUrl(url);
    }
  }
}
