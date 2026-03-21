import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

import '../../../../logic/templates/enums/field_enum.dart';
import '../../../../logic/templates/enums/field_enum_extensions.dart';
import '../../../../logic/templates/models/shared/template_field.dart';
import '../../../../design_system/structures/column.dart';
import '../../../../design_system/structures/row.dart';
import '../../../../design_system/structures/group.dart';
import '../../../../design_system/primitives/app_spacings.dart';
import '../../../../design_system/primitives/app_sizes.dart';
import '../../../../design_system/primitives/quanitya_palette.dart';
import '../../../../design_system/widgets/quanitya/general/notebook_fold.dart';
import '../../../../design_system/widgets/quanitya/general/post_it_toast.dart';
import '../../../../design_system/widgets/quanitya/general/loose_insert_sheet.dart';
import '../../../../design_system/widgets/quanitya/general/quanitya_text_button.dart';
import '../../../../design_system/widgets/quanitya_confirmation_dialog.dart';
import '../../../../support/extensions/context_extensions.dart';
import '../../../../app_router.dart';
import '../../../../data/repositories/template_with_aesthetics_repository.dart';
import '../../cubits/editor/template_editor_cubit.dart';
import '../../cubits/editor/template_editor_state.dart';
import '../../cubits/generator/template_generator_cubit.dart';
import '../../../../design_system/widgets/ai/ai_prompt_widget.dart';
import '../../../settings/cubits/llm_provider/llm_provider_cubit.dart';
import '../../../../app/bootstrap.dart';
import '../../../guided_tour/guided_tour_service.dart';
import '../../../guided_tour/designer_tour.dart';
import 'color_palette_editor.dart';
import 'container_style_editor.dart';
import 'field_editor_list.dart';
import 'inline_field_editor.dart';
import 'schedule_section.dart';
import 'template_basic_info_editor.dart';
import 'template_icon_editor.dart';
import 'typography_editor.dart';

/// Main form for editing template structure and fields
class TemplateEditorForm extends StatefulWidget {
  final VoidCallback onPreview;
  final VoidCallback onSave;

  const TemplateEditorForm({
    super.key,
    required this.onPreview,
    required this.onSave,
  });

  @override
  State<TemplateEditorForm> createState() => _TemplateEditorFormState();
}

class _TemplateEditorFormState extends State<TemplateEditorForm> {
  bool _isGenerating = false;

  @override
  void initState() {
    super.initState();
    _maybeShowDesignerTour();
  }

  Future<void> _maybeShowDesignerTour() async {
    final tourService = getIt<GuidedTourService>();
    if (!await tourService.shouldShowTour(GuidedTourService.designerKey)) return;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      // Only show in create mode (no existing template loaded)
      final state = context.read<TemplateEditorCubit>().state;
      if (state.template != null) return; // edit mode — skip

      showDesignerTour(
        context,
        aiPromptKey: DesignerTourKeys.aiPrompt,
        nameFieldKey: DesignerTourKeys.nameField,
        fieldsSectionKey: DesignerTourKeys.fieldsSection,
        scheduleFoldKey: DesignerTourKeys.scheduleFold,
        previewButtonKey: DesignerTourKeys.previewButton,
      );
      await tourService.markTourSeen(GuidedTourService.designerKey);
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TemplateEditorCubit, TemplateEditorState>(
      buildWhen: (p, c) => p.template != c.template,
      builder: (context, state) {
        final isEditing = state.template != null;

        return Column(
          children: [
            // Scrollable content
            Expanded(
              child: SingleChildScrollView(
                padding: AppPadding.page,
                child: QuanityaColumn(
                  crossAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // AI prompt — only shown when creating, no fold needed
                    if (!isEditing)
                      KeyedSubtree(
                        key: DesignerTourKeys.aiPrompt,
                        child: AiPromptWidget(
                          title: context.l10n.aiGeneratorTitle,
                          hintText: context.l10n.aiGeneratorHint,
                          isLoading: _isGenerating,
                          onGenerate: (prompt) =>
                              _generateFromAi(context, prompt),
                        ),
                      ),

                    // Identity fold — always expanded
                    KeyedSubtree(
                      key: DesignerTourKeys.nameField,
                      child: NotebookFold(
                        initiallyExpanded: true,
                        header: Text(
                          context.l10n.templateNameLabel,
                          style: context.text.titleMedium?.copyWith(
                            color: context.colors.textPrimary,
                          ),
                        ),
                        child: QuanityaColumn(
                          crossAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const TemplateIconEditor(),
                            VSpace.x3,
                            const TemplateBasicInfoEditor(),
                          ],
                        ),
                      ),
                    ),

                    // Fields fold — always expanded
                    KeyedSubtree(
                      key: DesignerTourKeys.fieldsSection,
                      child: NotebookFold(
                        initiallyExpanded: true,
                        header: _buildFieldsHeader(context, state),
                        child: QuanityaColumn(
                          crossAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const FieldEditorList(),
                            VSpace.x3,
                            _buildAddFieldList(context),
                          ],
                        ),
                      ),
                    ),

                    // Aesthetics fold — collapsed by default (optional)
                    NotebookFold(
                      initiallyExpanded: false,
                      header: Text(
                        '${context.l10n.aestheticsSection} (${context.l10n.optionalLabel})',
                        style: context.text.titleMedium?.copyWith(
                          color: context.colors.textPrimary,
                        ),
                      ),
                      child: QuanityaColumn(
                        crossAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const ColorPaletteEditor(),
                          VSpace.x3,
                          const TypographyEditor(),
                          VSpace.x3,
                          const ContainerStyleEditor(),
                        ],
                      ),
                    ),

                    // Schedule fold — collapsed by default (optional)
                    KeyedSubtree(
                      key: DesignerTourKeys.scheduleFold,
                      child: NotebookFold(
                        initiallyExpanded: false,
                        header: Text(
                          '${context.l10n.scheduleTitle} (${context.l10n.optionalLabel})',
                          style: context.text.titleMedium?.copyWith(
                            color: context.colors.textPrimary,
                          ),
                        ),
                        child: ScheduleSection(
                          frequency: state.scheduleFrequency,
                          reminderTime: state.scheduleHour != null
                              ? TimeOfDay(hour: state.scheduleHour!, minute: state.scheduleMinute ?? 0)
                              : null,
                          weeklyDays: state.scheduleWeeklyDays,
                          onFrequencyChanged: (freq) => context
                              .read<TemplateEditorCubit>()
                              .updateScheduleFrequency(freq),
                          onTimeChanged: (time) => context
                              .read<TemplateEditorCubit>()
                              .updateScheduleTime(time.hour, time.minute),
                          onWeeklyDaysChanged: (days) => context
                              .read<TemplateEditorCubit>()
                              .updateScheduleWeeklyDays(days),
                        ),
                      ),
                    ),

                    // Privacy toggle
                    if (isEditing)
                      _buildPrivateToggle(context, state),

                    // Extra space at bottom so content isn't hidden behind sticky bar
                    VSpace.x4,
                  ],
                ),
              ),
            ),

            // Sticky bottom action bar
            _buildStickyBottomBar(context, state),
          ],
        );
      },
    );
  }

  Widget _buildFieldsHeader(BuildContext context, TemplateEditorState state) {
    return QuanityaRow(
      alignment: CrossAxisAlignment.center,
      start: Text(
        context.l10n.templateFieldsSection,
        style: context.text.titleMedium?.copyWith(
          color: context.colors.textPrimary,
        ),
      ),
      end: Text(
        context.l10n.fieldsCount(state.fields.length),
        style: context.text.bodyMedium?.copyWith(
          color: context.colors.textSecondary,
        ),
      ),
    );
  }

  Widget _buildStickyBottomBar(
      BuildContext context, TemplateEditorState state) {
    final isEditing = state.template != null;

    return SafeArea(
      top: false,
      child: Padding(
        padding: AppPadding.allDouble,
        child: QuanityaRow(
          spacing: HSpace.x2,
          start: isEditing
              ? QuanityaTextButton(
                  text: context.l10n.actionDelete,
                  onPressed: () => _confirmDeleteTemplate(context, state),
                  isDestructive: true,
                )
              : QuanityaTextButton(
                  text: context.l10n.discardAction,
                  onPressed: () {
                    context.read<TemplateEditorCubit>().discard();
                    AppNavigation.back(context);
                  },
                  isDestructive: true,
                ),
          middle: KeyedSubtree(
            key: DesignerTourKeys.previewButton,
            child: QuanityaTextButton(
              text: context.l10n.previewAction,
              onPressed: state.canSave ? widget.onPreview : null,
            ),
          ),
          end: QuanityaTextButton(
            text: context.l10n.actionSave,
            onPressed: state.canSave ? widget.onSave : null,
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDeleteTemplate(
    BuildContext context,
    TemplateEditorState state,
  ) async {
    final templateId = state.template?.id;
    if (templateId == null) return;

    QuanityaConfirmationDialog.show(
      context: context,
      title: context.l10n.actionDelete,
      message: context.l10n.confirmDeleteTemplate,
      confirmText: context.l10n.actionDelete,
      isDestructive: true,
      onConfirm: () async {
        final repo = GetIt.I<TemplateWithAestheticsRepository>();
        await repo.archive(templateId);
        if (context.mounted) {
          PostItToast.show(context,
              message: context.l10n.templateDeleted,
              type: PostItType.success);
          AppNavigation.back(context);
        }
      },
    );
  }

  Widget _buildPrivateToggle(
    BuildContext context,
    TemplateEditorState state,
  ) {
    final isHidden = state.template?.isHidden ?? false;
    return Padding(
      padding: AppPadding.verticalSingle,
      child: Row(
        children: [
          Icon(
            isHidden ? Icons.lock : Icons.lock_open,
            size: AppSizes.iconMedium,
            color: context.colors.textSecondary,
          ),
          HSpace.x2,
          Expanded(
            child: Text(
              context.l10n.templatePrivateLabel,
              style: context.text.bodyMedium?.copyWith(
                color: context.colors.textPrimary,
              ),
            ),
          ),
          Switch.adaptive(
            value: isHidden,
            activeTrackColor: context.colors.interactableColor,
            onChanged: (_) =>
                context.read<TemplateEditorCubit>().toggleHidden(),
          ),
        ],
      ),
    );
  }

  Widget _buildAddFieldList(BuildContext context) {
    // Reference fields are not yet implemented — hide from picker
    final types = FieldEnum.values
        .where((t) => t != FieldEnum.reference)
        .toList();
    return QuanityaGroup(
      child: Column(
        children: [
          for (int i = 0; i < types.length; i++) ...[
            if (i > 0)
              Divider(
                  height: AppSizes.borderWidth,
                  color: context.colors.textSecondary.withValues(alpha: 0.1)),
            _buildAddFieldOption(
                context, types[i].displayName, types[i].icon, types[i]),
          ],
        ],
      ),
    );
  }

  Widget _buildAddFieldOption(
    BuildContext context,
    String label,
    IconData icon,
    FieldEnum type,
  ) {
    return Semantics(
      button: true,
      label: 'Add $label field',
      child: InkWell(
        onTap: () => _showFieldEditorSheet(context, type),
        child: Padding(
          padding: EdgeInsets.all(AppSizes.space * 2),
          child: QuanityaRow(
            spacing: HSpace.x2,
            alignment: CrossAxisAlignment.center,
            start: Icon(icon,
                size: AppSizes.size20, color: context.colors.textSecondary),
            middle: Text(
              label,
              style: context.text.bodyMedium?.copyWith(
                color: context.colors.textSecondary,
              ),
            ),
            end: Icon(Icons.add,
                size: AppSizes.size20, color: context.colors.interactableColor),
          ),
        ),
      ),
    );
  }

  void _showFieldEditorSheet(BuildContext context, FieldEnum type) {
    final editorCubit = context.read<TemplateEditorCubit>();
    LooseInsertSheet.show(
      context: context,
      title: context.l10n.addFieldTitle,
      builder: (sheetContext) => SingleChildScrollView(
        child: InlineFieldEditor(
          fieldType: type,
          onSave: (field) {
            editorCubit.addFieldFromTemplate(field);
            Navigator.pop(sheetContext);
          },
          onCancel: () => Navigator.pop(sheetContext),
        ),
      ),
    );
  }

  Future<void> _generateFromAi(BuildContext context, String prompt) async {
    if (prompt.isEmpty || _isGenerating) return;

    final editorCubit = context.read<TemplateEditorCubit>();

    final llmCubit = GetIt.I<LlmProviderCubit>();
    final config = await llmCubit.buildLlmConfig();
    if (config == null) {
      if (context.mounted) {
        PostItToast.show(context,
            message: context.l10n.llmProviderConfigureLlm,
            type: PostItType.warning);
      }
      return;
    }

    setState(() => _isGenerating = true);

    try {
      final generatorCubit = GetIt.I<TemplateGeneratorCubit>();
      await generatorCubit.generate(prompt, config);

      final preview = generatorCubit.state.preview;
      if (preview != null && mounted) {
        editorCubit.loadTemplate(preview);
      }
    } finally {
      if (mounted) {
        setState(() => _isGenerating = false);
      }
    }
  }
}

