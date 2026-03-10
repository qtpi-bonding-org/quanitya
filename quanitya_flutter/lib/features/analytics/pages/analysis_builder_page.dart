import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cubit_ui_flow/cubit_ui_flow.dart';
import 'package:get_it/get_it.dart';

import '../../../app/bootstrap.dart';
import '../../../design_system/primitives/quanitya_palette.dart';
import '../../../design_system/primitives/app_spacings.dart';
import '../../../design_system/primitives/app_sizes.dart';
import '../../../design_system/widgets/ai/ai_prompt_widget.dart';
import '../../../design_system/widgets/quanitya_icon_button.dart';
import '../../../design_system/widgets/quanitya_text_field.dart';
import '../../../infrastructure/feedback/base_state_message_mapper.dart';
import '../../settings/cubits/llm_provider/llm_provider_cubit.dart';
import '../../../logic/analytics/cubits/analysis_builder_cubit.dart';
import '../../../logic/analytics/cubits/analysis_builder_state.dart';
import '../../../logic/analytics/cubits/analysis_builder_message_mapper.dart';
import '../../../logic/analytics/enums/time_resolution.dart';
import '../../../support/extensions/context_extensions.dart';
import '../../app_operating_mode/cubits/app_operating_cubit.dart';
import '../../app_operating_mode/models/app_operating_mode.dart';
import '../widgets/live_results_panel.dart';

/// Analysis pipeline builder — write or AI-generate JavaScript analysis code.
class AnalysisBuilderPage extends StatefulWidget {
  final String fieldId;
  final String? templateId;
  final TimeResolution timeResolution;

  const AnalysisBuilderPage({
    super.key,
    this.fieldId = 'demo-field',
    this.templateId,
    this.timeResolution = TimeResolution.day,
  });

  @override
  State<AnalysisBuilderPage> createState() => _AnalysisBuilderPageState();
}

class _AnalysisBuilderPageState extends State<AnalysisBuilderPage> {
  bool _isGenerating = false;

  @override
  Widget build(BuildContext context) {
    final palette = QuanityaPalette.primary;

    return BlocProvider(
      create: (context) => getIt<AnalysisBuilderCubit>()
        ..initializeForField(widget.fieldId, widget.timeResolution,
            templateId: widget.templateId),
      child: UiFlowStateListener<AnalysisBuilderCubit, AnalysisBuilderState>(
        mapper: BaseStateMessageMapper<AnalysisBuilderState>(
          exceptionMapper: getIt<IExceptionKeyMapper>(),
          domainMapper: getIt<AnalysisBuilderMessageMapper>(),
        ),
        uiService: getIt<IUiFlowService>(),
        child: BlocBuilder<AnalysisBuilderCubit, AnalysisBuilderState>(
          builder: (context, state) {
            final cubit = context.read<AnalysisBuilderCubit>();

            return Scaffold(
              appBar: AppBar(
                title: Text(
                  context.l10n.analysisBuilderTitle,
                  style: context.text.headlineMedium,
                ),
                backgroundColor: palette.backgroundPrimary,
                elevation: 0,
                actions: [
                  if (state.snippet.isNotEmpty)
                    QuanityaIconButton(
                      onPressed: () => cubit.toggleLivePreview(),
                      icon: state.livePreviewEnabled
                          ? Icons.visibility
                          : Icons.visibility_off,
                      color: state.livePreviewEnabled
                          ? palette.successColor
                          : palette.textSecondary,
                      tooltip: state.livePreviewEnabled
                          ? context.l10n.analysisBuilderTooltipHidePreview
                          : context.l10n.analysisBuilderTooltipShowPreview,
                    ),
                  if (state.snippet.isNotEmpty)
                    QuanityaIconButton(
                      onPressed: () => _showSaveDialog(context, cubit),
                      icon: Icons.save_outlined,
                      color: palette.interactableColor,
                      tooltip: 'Save Pipeline',
                    ),
                ],
              ),
              body: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: _buildMainContent(context, state, cubit),
                  ),
                  if (state.livePreviewEnabled && state.liveResults != null)
                    Expanded(
                      flex: 2,
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border(
                            left: BorderSide(
                              color:
                                  palette.textSecondary.withValues(alpha: 0.2),
                              width: 1,
                            ),
                          ),
                        ),
                        child: LiveResultsPanel(
                          results: state.liveResults,
                          column: 0,
                          row: 0,
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildMainContent(
    BuildContext context,
    AnalysisBuilderState state,
    AnalysisBuilderCubit cubit,
  ) {
    final palette = QuanityaPalette.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // AI Prompt Section
        Padding(
          padding: AppPadding.page,
          child: AiPromptWidget(
            title: context.l10n.analysisBuilderJsTitle,
            hintText: 'Describe the analysis you want...',
            isLoading: _isGenerating,
            onGenerate: (prompt) => _generateFromAi(context, prompt),
          ),
        ),

        // Header with output mode badge
        if (state.snippet.isNotEmpty) ...[
          Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSizes.space * 2),
            child: Row(
              children: [
                Icon(
                  Icons.code,
                  color: palette.interactableColor,
                  size: AppSizes.iconMedium,
                ),
                HSpace.x1,
                Text(
                  context.l10n.analysisBuilderJsTitle,
                  style: context.text.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: palette.textPrimary,
                  ),
                ),
                const Spacer(),
                _OutputModeBadge(mode: state.outputMode.name),
              ],
            ),
          ),
          if (state.reasoning.isNotEmpty) ...[
            VSpace.x05,
            Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSizes.space * 2),
              child: Text(
                state.reasoning,
                style: context.text.bodySmall?.copyWith(
                  color: palette.textSecondary,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
          VSpace.x2,
        ],

        // Code editor area
        Expanded(
          child: state.snippet.isEmpty
              ? _buildEmptyState(context)
              : Container(
                  // VS Code dark theme — intentionally hardcoded for IDE aesthetic
                  color: const Color(0xFF1E1E1E),
                  padding: AppPadding.allDouble,
                  child: SingleChildScrollView(
                    child: SelectableText(
                      state.snippet,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: AppSizes.fontSmall,
                        height: 1.6,
                        // VS Code text color — intentionally hardcoded
                        color: const Color(0xFFD4D4D4),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final palette = QuanityaPalette.primary;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.code_off,
            size: AppSizes.iconLarge * 2,
            color: palette.textSecondary.withValues(alpha: 0.5),
          ),
          VSpace.x2,
          Text(
            context.l10n.analysisBuilderEmptyTitle,
            style: context.text.headlineSmall?.copyWith(
              color: palette.textSecondary,
            ),
          ),
          VSpace.x1,
          Text(
            'Use the AI prompt above to generate an analysis pipeline.',
            style: context.text.bodyMedium?.copyWith(
              color: palette.textSecondary.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _generateFromAi(BuildContext context, String prompt) async {
    if (prompt.isEmpty || _isGenerating) return;

    final cubit = context.read<AnalysisBuilderCubit>();
    final state = cubit.state;
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
      await cubit.generateAndApplyAiPipeline(
        fieldId: state.fieldId ?? widget.fieldId,
        userIntent: prompt,
        llmConfig: config,
      );
    } finally {
      if (mounted) {
        setState(() => _isGenerating = false);
      }
    }
  }

  Future<void> _showSaveDialog(
    BuildContext context,
    AnalysisBuilderCubit cubit,
  ) async {
    final controller = TextEditingController();
    final palette = QuanityaPalette.primary;

    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          'Save Pipeline',
          style: context.text.headlineSmall,
        ),
        content: QuanityaTextField(
          controller: controller,
          hintText: 'Pipeline name...',
          autofocus: true,
          onSubmitted: (_) =>
              Navigator.of(dialogContext).pop(controller.text.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(
              'Cancel',
              style: TextStyle(color: palette.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () =>
                Navigator.of(dialogContext).pop(controller.text.trim()),
            child: Text(
              'Save',
              style: TextStyle(color: palette.interactableColor),
            ),
          ),
        ],
      ),
    );

    controller.dispose();

    if (name != null && name.isNotEmpty) {
      await cubit.savePipeline(name);
    }
  }
}

class _OutputModeBadge extends StatelessWidget {
  final String mode;
  const _OutputModeBadge({required this.mode});

  @override
  Widget build(BuildContext context) {
    final color = mode == 'scalar'
        ? QuanityaPalette.primary.successColor
        : mode == 'vector'
            ? QuanityaPalette.primary.interactableColor
            : QuanityaPalette.primary.warningColor;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSizes.space,
        vertical: AppSizes.space * 0.25,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
        border: Border.all(color: color, width: 1),
      ),
      child: Text(
        mode.toUpperCase(),
        style: context.text.bodySmall?.copyWith(
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
