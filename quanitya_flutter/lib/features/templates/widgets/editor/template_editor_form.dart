import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

import '../../../../logic/templates/enums/field_enum.dart';
import '../../../../design_system/structures/column.dart';
import '../../../../design_system/structures/row.dart';
import '../../../../design_system/structures/group.dart';
import '../../../../design_system/primitives/app_spacings.dart';
import '../../../../design_system/primitives/app_sizes.dart';
import '../../../../design_system/primitives/quanitya_palette.dart';
import '../../../../design_system/widgets/quanitya/general/quanitya_text_button.dart';
import '../../../../support/extensions/context_extensions.dart';
import '../../cubits/editor/template_editor_cubit.dart';
import '../../cubits/editor/template_editor_state.dart';
import '../../cubits/generator/template_generator_cubit.dart';
import '../../../../infrastructure/llm/models/llm_types.dart';
import '../../../../infrastructure/webhooks/api_key_repository.dart';
import '../../../../infrastructure/webhooks/models/api_key_model.dart';
import '../../../../design_system/widgets/ai/ai_prompt_widget.dart';
import '../../../../design_system/widgets/quanitya_text_form_field.dart';
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
                      title: 'AI GENERATOR',
                      hintText: 'Describe what you want to track...',
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
    return SafeArea(
      top: false,
      child: Padding(
        padding: AppPadding.allDouble,
        child: QuanityaRow(
          spacing: HSpace.x2,
          start: QuanityaTextButton(
            text: context.l10n.discardAction,
            onPressed: () => context.read<TemplateEditorCubit>().discard(),
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

    // Capture cubit before any async operations
    final editorCubit = context.read<TemplateEditorCubit>();
    
    // Get API key from repository
    final apiKeyRepo = GetIt.I<ApiKeyRepository>();
    final apiKeys = await apiKeyRepo.getAll();
    
    // Look for an OpenRouter key (by name containing "openrouter" case-insensitive)
    final openRouterKey = apiKeys.where(
      (k) => k.name.toLowerCase().contains('openrouter'),
    ).firstOrNull;
    
    if (openRouterKey == null) {
      // Show dialog to add API key
      if (context.mounted) {
        await _showAddApiKeyDialog(context);
      }
      return;
    }
    
    // Get the actual key value
    final keyValue = await apiKeyRepo.getKeyValue(openRouterKey.id);
    if (keyValue == null || keyValue.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('API key value not found')),
        );
      }
      return;
    }

    setState(() => _isGenerating = true);

    try {
      // Get the generator cubit and generate
      final generatorCubit = GetIt.I<TemplateGeneratorCubit>();
      
      final config = LlmConfig.openRouter(
        apiKey: keyValue,
        model: 'openai/gpt-4o-mini',
        useCloudProxy: context.read<AppOperatingCubit>().state.mode == AppOperatingMode.cloud,
      );
      
      await generatorCubit.generate(prompt, config);
      
      // If generation succeeded, load the preview into the editor
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

  Future<void> _showAddApiKeyDialog(BuildContext context) async {
    final nameController = TextEditingController(text: 'OpenRouter');
    final keyController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          'Add OpenRouter API Key',
          style: context.text.titleLarge,
        ),
        content: SizedBox(
          width: 400,
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'To use AI template generation, add your OpenRouter API key. '
                  'Get one at openrouter.ai',
                  style: context.text.bodyMedium?.copyWith(
                    color: context.colors.textSecondary,
                  ),
                ),
                VSpace.x3,
                QuanityaTextFormField(
                  controller: nameController,
                  labelText: 'Name',
                  hintText: 'OpenRouter',
                ),
                VSpace.x2,
                QuanityaTextFormField(
                  controller: keyController,
                  labelText: 'API Key',
                  hintText: 'sk-or-v1-...',
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'API key is required';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          QuanityaTextButton(
            text: context.l10n.actionCancel,
            onPressed: () => Navigator.of(dialogContext).pop(false),
          ),
          QuanityaTextButton(
            text: context.l10n.actionSave,
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.of(dialogContext).pop(true);
              }
            },
          ),
        ],
      ),
    );
    
    if (result == true && context.mounted) {
      final apiKeyRepo = GetIt.I<ApiKeyRepository>();
      await apiKeyRepo.create(
        name: nameController.text,
        authType: AuthType.bearer,
        keyValue: keyController.text,
      );
      
      // Retry generation would happen here, but we avoid context usage after async gap
      // User can manually retry if needed
    }
    
    nameController.dispose();
    keyController.dispose();
  }
}
