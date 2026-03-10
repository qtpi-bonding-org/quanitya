import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

import '../../../../logic/templates/enums/field_enum.dart';
import '../../../../design_system/structures/column.dart';
import '../../../../design_system/structures/row.dart';
import '../../../../design_system/structures/group.dart';
import '../../../../design_system/primitives/app_spacings.dart';
import '../../../../design_system/primitives/app_sizes.dart';
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
import '../../../app_operating_mode/cubits/app_operating_cubit.dart';
import '../../../app_operating_mode/models/app_operating_mode.dart';
import 'field_editor_list.dart';
import 'template_basic_info_editor.dart';
import 'schedule_section.dart';
import 'inline_field_editor.dart';

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
  
  /// Field type currently being added (null if not adding)
  FieldEnum? _addingFieldType;

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TemplateEditorCubit, TemplateEditorState>(
      builder: (context, state) {
        return Column(
          children: [
            // Scrollable content
            Expanded(
              child: SingleChildScrollView(
                padding: AppPadding.page,
                child: QuanityaColumn(
                  crossAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // AI Generation Section (at the top)
                    AiPromptWidget(
                      title: context.l10n.aiGeneratorTitle,
                      hintText: context.l10n.aiGeneratorHint,
                      isLoading: _isGenerating,
                      onGenerate: (prompt) => _generateFromAi(context, prompt),
                    ),

                    VSpace.x4,

                    // Basic Info Section (Now includes detailed theme editor)
                    const TemplateBasicInfoEditor(),

                    VSpace.x3,

                    // Fields Section Header - title font, bigger, black
                    QuanityaRow(
                      alignment: CrossAxisAlignment.center,
                      start: Text(
                        context.l10n.templateFieldsSection,
                        style: context.text.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: context.colors.textPrimary,
                        ),
                      ),
                      end: Text(
                        context.l10n.fieldsCount(state.fields.length),
                        style: context.text.bodyMedium?.copyWith(
                          color: context.colors.textSecondary,
                        ),
                      ),
                    ),

                    // Fields List
                    const FieldEditorList(),

                    VSpace.x3,

                    // Add Field List (New Design)
                    _buildAddFieldList(context),

                    VSpace.x4,
                    
                    // Schedule/Reminder Section
                    ScheduleSection(
                      frequency: state.scheduleFrequency,
                      reminderTime: state.scheduleTime,
                      weeklyDays: state.scheduleWeeklyDays,
                      onFrequencyChanged: (freq) => 
                          context.read<TemplateEditorCubit>().updateScheduleFrequency(freq),
                      onTimeChanged: (time) => 
                          context.read<TemplateEditorCubit>().updateScheduleTime(time),
                      onWeeklyDaysChanged: (days) => 
                          context.read<TemplateEditorCubit>().updateScheduleWeeklyDays(days),
                    ),

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

  Widget _buildStickyBottomBar(BuildContext context, TemplateEditorState state) {
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
          middle: QuanityaTextButton(
            text: context.l10n.previewAction,
            onPressed: state.canSave ? widget.onPreview : null,
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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.l10n.templateDeleted)),
          );
          AppNavigation.back(context);
        }
      },
    );
  }

  Widget _buildAddFieldList(BuildContext context) {
    // If adding a field, show inline editor instead of options
    if (_addingFieldType != null) {
      return InlineFieldEditor(
        fieldType: _addingFieldType!,
        onSave: (field) {
          context.read<TemplateEditorCubit>().addFieldFromTemplate(field);
          setState(() => _addingFieldType = null);
        },
        onCancel: () => setState(() => _addingFieldType = null),
      );
    }
    
    return QuanityaGroup(
      child: Column(
        children: [
          _buildAddFieldOption(context, context.l10n.fieldNumber, Icons.numbers, FieldEnum.integer),
          Divider(height: 1, color: context.colors.textSecondary.withValues(alpha: 0.1)),
          _buildAddFieldOption(context, context.l10n.fieldText, Icons.text_fields, FieldEnum.text),
          Divider(height: 1, color: context.colors.textSecondary.withValues(alpha: 0.1)),
          _buildAddFieldOption(context, context.l10n.fieldToggle, Icons.toggle_on, FieldEnum.boolean),
          Divider(height: 1, color: context.colors.textSecondary.withValues(alpha: 0.1)),
          _buildAddFieldOption(context, context.l10n.fieldDate, Icons.calendar_today, FieldEnum.datetime),
          Divider(height: 1, color: context.colors.textSecondary.withValues(alpha: 0.1)),
          _buildAddFieldOption(context, context.l10n.fieldChoice, Icons.list, FieldEnum.enumerated),
          Divider(height: 1, color: context.colors.textSecondary.withValues(alpha: 0.1)),
          _buildAddFieldOption(context, context.l10n.fieldFloat, Icons.numbers, FieldEnum.float),
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
    return InkWell(
      onTap: () => setState(() => _addingFieldType = type),
      child: Padding(
        padding: EdgeInsets.all(AppSizes.space * 2),
        child: QuanityaRow(
          spacing: HSpace.x2,
          alignment: CrossAxisAlignment.center,
          start: Icon(icon, size: AppSizes.size20, color: context.colors.textSecondary),
          middle: Text(
            label,
            style: context.text.bodyMedium?.copyWith(
              color: context.colors.textSecondary,
            ),
          ),
          end: Icon(Icons.add, size: AppSizes.size20, color: context.colors.interactableColor),
        ),
      ),
    );
  }

  Future<void> _generateFromAi(BuildContext context, String prompt) async {
    if (prompt.isEmpty || _isGenerating) return;

    final editorCubit = context.read<TemplateEditorCubit>();
    final useCloudProxy =
        context.read<AppOperatingCubit>().state.mode == AppOperatingMode.cloud;

    final llmCubit = GetIt.I<LlmProviderCubit>();
    final config = await llmCubit.buildLlmConfig(useCloudProxy: useCloudProxy);
    if (config == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.llmProviderConfigureLlm)),
        );
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
