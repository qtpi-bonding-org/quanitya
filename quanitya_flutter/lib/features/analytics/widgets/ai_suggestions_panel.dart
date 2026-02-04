import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../design_system/primitives/app_spacings.dart';
import '../../../design_system/primitives/app_sizes.dart';
import '../../../design_system/primitives/quanitya_palette.dart';
import '../../../design_system/widgets/quanitya/general/quanitya_text_button.dart';
import '../../../design_system/widgets/quanitya_icon_button.dart';
import '../../../design_system/widgets/quanitya_text_field.dart';
import '../../../infrastructure/llm/models/llm_types.dart';
import '../../../support/extensions/context_extensions.dart';
import '../../../logic/analytics/cubits/mvs_pipeline_builder_cubit.dart';
import '../../../logic/analytics/cubits/mvs_pipeline_builder_state.dart';
import 'ai_field_selector.dart';

/// Panel for AI-powered pipeline suggestions
class AiSuggestionsPanel extends StatefulWidget {
  final LlmConfig llmConfig;

  const AiSuggestionsPanel({
    super.key,
    required this.llmConfig,
  });

  @override
  State<AiSuggestionsPanel> createState() => _AiSuggestionsPanelState();
}

class _AiSuggestionsPanelState extends State<AiSuggestionsPanel> {
  final _intentController = TextEditingController();
  String? _selectedField;

  @override
  void dispose() {
    _intentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MvsPipelineBuilderCubit, MvsPipelineBuilderState>(
      builder: (context, state) {
        return Container(
          width: double.infinity,
          padding: AppPadding.allDouble,
          decoration: BoxDecoration(
            color: QuanityaPalette.primary.backgroundPrimary,
            borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
            border: Border.all(
              color: QuanityaPalette.primary.interactableColor.withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: QuanityaPalette.primary.interactableColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'AI SUGGESTIONS',
                      style: context.text.labelSmall?.copyWith(
                        color: QuanityaPalette.primary.interactableColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Spacer(),
                  QuanityaIconButton(
                    icon: Icons.auto_awesome,
                    onPressed: () {},
                    color: QuanityaPalette.primary.interactableColor,
                  ),
                ],
              ),
              VSpace.x2,
              
              // Field Selection
              AiFieldSelector(
                availableFields: state.availableFieldNames,
                selectedField: _selectedField ?? state.selectedFieldForAi,
                onFieldChanged: (field) {
                  setState(() => _selectedField = field);
                  context.read<MvsPipelineBuilderCubit>().setSelectedFieldForAi(field);
                },
                enabled: !state.isLoading,
              ),
              VSpace.x2,
              
              // Intent Input
              Text(
                'Analysis Goal',
                style: context.text.bodySmall?.copyWith(
                  color: QuanityaPalette.primary.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              VSpace.x05,
              QuanityaTextField(
                controller: _intentController,
                enabled: !state.isLoading,
                hintText: 'What would you like to analyze? (e.g., "Find weekly patterns", "Calculate averages")',
                maxLines: 2,
              ),
              VSpace.x2,
              
              // Generate & Apply Button
              SizedBox(
                width: double.infinity,
                child: QuanityaTextButton(
                  text: state.isLoading ? 'Generating...' : 'Generate AI Pipeline',
                  onPressed: _canGenerate(state) && !state.isLoading
                      ? () => _generateAndApply(context, state)
                      : null,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  bool _canGenerate(MvsPipelineBuilderState state) {
    final selectedField = _selectedField ?? state.selectedFieldForAi;
    return selectedField != null && 
           _intentController.text.trim().isNotEmpty &&
           state.templateId != null;
  }

  void _generateAndApply(BuildContext context, MvsPipelineBuilderState state) {
    final selectedField = _selectedField ?? state.selectedFieldForAi;
    if (selectedField == null) return;

    context.read<MvsPipelineBuilderCubit>().generateAndApplyAiPipeline(
      fieldId: selectedField,
      userIntent: _intentController.text.trim(),
      llmConfig: widget.llmConfig,
    );
  }
}