import 'package:flutter/material.dart';
import 'package:flutter_adaptable_group/flutter_adaptable_group.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cubit_ui_flow/cubit_ui_flow.dart';
import 'package:get_it/get_it.dart';

import '../../../app/bootstrap.dart';
import '../../../design_system/primitives/quanitya_palette.dart';
import '../../../design_system/primitives/app_spacings.dart';
import '../../../design_system/primitives/app_sizes.dart';
import '../../../design_system/widgets/ai/ai_prompt_widget.dart';
import '../../../design_system/widgets/quanitya_text_field.dart';
import '../../../design_system/widgets/quanitya/general/loose_insert_sheet.dart';
import '../../../design_system/widgets/quanitya/general/notebook_fold.dart';
import '../../../design_system/widgets/quanitya/general/pen_circled_chip.dart';
import '../../../design_system/widgets/quanitya/general/quanitya_text_button.dart';
import '../../../infrastructure/feedback/base_state_message_mapper.dart';
import '../../settings/cubits/llm_provider/llm_provider_cubit.dart';
import '../../../logic/analytics/cubits/analysis_builder_cubit.dart';
import '../../../logic/analytics/cubits/analysis_builder_state.dart';
import '../../../logic/analytics/cubits/analysis_builder_message_mapper.dart';
import '../../../logic/analytics/enums/analysis_output_mode.dart';
import '../../../logic/analytics/enums/time_resolution.dart';
import '../../../logic/analytics/models/analysis_output.dart';
import '../../../support/extensions/context_extensions.dart';
import '../../app_operating_mode/cubits/app_operating_cubit.dart';
import '../../app_operating_mode/models/app_operating_mode.dart';

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
  final _codeController = TextEditingController();
  String _lastSnippet = '';

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

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
              ),
              body: SafeArea(
                top: false,
                child: _buildMainContent(context, state, cubit),
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

    return SingleChildScrollView(
      child: Column(
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

          // New pipeline button
          Padding(
            padding: AppPadding.pageHorizontal,
            child: QuanityaTextButton(
              text: '+ New',
              onPressed: () => cubit.newPipeline(),
            ),
          ),
          VSpace.x1,

          // Output mode selector
          Padding(
            padding: AppPadding.pageHorizontal,
            child: LayoutGroup.row(
              minChildWidth: 10,
              children: AnalysisOutputMode.values.map((mode) => PenCircledChip(
                    label: mode.name,
                    isSelected: state.outputMode == mode,
                    onTap: () => cubit.setOutputMode(mode),
                  )).toList(),
            ),
          ),
          VSpace.x2,

          // Pipeline selector — PenCircledChips in a wrapping row
          if (state.availablePipelines.isNotEmpty) ...[
            Padding(
              padding: AppPadding.pageHorizontal,
              child: Wrap(
                spacing: AppSizes.space,
                runSpacing: AppSizes.space,
                children: state.availablePipelines.map((p) => PenCircledChip(
                      label: p.name,
                      isSelected: p.id == state.selectedPipelineId,
                      onTap: () => cubit.selectPipeline(p.id),
                    )).toList(),
              ),
            ),
            VSpace.x2,
          ],

          // Reasoning (from AI or saved pipeline)
          if (state.reasoning.isNotEmpty) ...[
            Padding(
              padding: AppPadding.pageHorizontal,
              child: Text(
                state.reasoning,
                style: context.text.bodySmall?.copyWith(
                  color: palette.textSecondary,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
            VSpace.x2,
          ],

          // Code editor area
          Padding(
            padding: AppPadding.page,
            child: _buildCodeEditor(context, state, cubit),
          ),
          VSpace.x2,

          // Results fold — appears after running
          if (state.previewResult != null)
            Padding(
              padding: AppPadding.pageHorizontal,
              child: NotebookFold(
                initiallyExpanded: true,
                header: Row(
                  children: [
                    Icon(
                      Icons.insights,
                      size: AppSizes.iconMedium,
                      color: palette.successColor,
                    ),
                    HSpace.x1,
                    Text(
                      'Results',
                      style: context.text.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: palette.textPrimary,
                      ),
                    ),
                  ],
                ),
                child: _AnalysisResultDisplay(output: state.previewResult!),
              ),
            ),

          VSpace.x2,

          // Action buttons at the bottom
          Padding(
            padding: AppPadding.pageHorizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (state.snippet.isNotEmpty) ...[
                  QuanityaTextButton(
                    text: 'Run',
                    onPressed: () => cubit.runPipeline(),
                  ),
                  HSpace.x2,
                  QuanityaTextButton(
                    text: 'Save',
                    onPressed: () => _showSaveSheet(context, cubit),
                  ),
                ],
              ],
            ),
          ),
          VSpace.x2,
        ],
      ),
    );
  }

  Widget _buildCodeEditor(
    BuildContext context,
    AnalysisBuilderState state,
    AnalysisBuilderCubit cubit,
  ) {
    if (state.snippet != _lastSnippet) {
      _lastSnippet = state.snippet;
      final selection = _codeController.selection;
      _codeController.text = state.snippet;
      if (selection.isValid && selection.end <= state.snippet.length) {
        _codeController.selection = selection;
      } else {
        _codeController.selection = TextSelection.collapsed(
          offset: state.snippet.length,
        );
      }
    }

    final lineCount = state.snippet.isEmpty
        ? 8
        : state.snippet.split('\n').length.clamp(8, 40);
    final lineHeight = AppSizes.fontSmall * 1.6;

    return Container(
      constraints: BoxConstraints(minHeight: lineCount * lineHeight),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E).withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
      ),
      padding: AppPadding.allDouble,
      child: TextField(
        controller: _codeController,
        onChanged: (value) {
          _lastSnippet = value;
          cubit.updateSnippet(value);
        },
        maxLines: null,
        textAlignVertical: TextAlignVertical.top,
        style: TextStyle(
          fontFamily: 'monospace',
          fontSize: AppSizes.fontSmall,
          height: 1.6,
          color: const Color(0xFFD4D4D4),
          letterSpacing: 0.5,
        ),
        cursorColor: const Color(0xFFD4D4D4),
        decoration: InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.zero,
          isDense: true,
          hintText: '// Write your JavaScript analysis here...\n'
              '// Available: data.values, data.timestamps, ss (simple-statistics)',
          hintStyle: TextStyle(
            fontFamily: 'monospace',
            fontSize: AppSizes.fontSmall,
            color: const Color(0xFFD4D4D4).withValues(alpha: 0.3),
            height: 1.6,
          ),
        ),
        keyboardType: TextInputType.multiline,
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

  void _showSaveSheet(
    BuildContext context,
    AnalysisBuilderCubit cubit,
  ) {
    LooseInsertSheet.show<String>(
      context: context,
      title: 'Save Pipeline',
      builder: (_) => _SavePipelineForm(
        onSave: (name) {
          Navigator.of(context).pop();
          cubit.savePipeline(name);
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Supporting Widgets
// ─────────────────────────────────────────────────────────────────────────

/// Renders AnalysisOutput inline — scalar cards, vector values, matrix summary.
class _AnalysisResultDisplay extends StatelessWidget {
  final AnalysisOutput output;
  const _AnalysisResultDisplay({required this.output});

  @override
  Widget build(BuildContext context) {
    final palette = QuanityaPalette.primary;

    return output.when(
      scalar: (scalars) => LayoutGroup.grid(
        minItemWidth: 15,
        children: scalars
            .map((s) => Container(
                  padding: AppPadding.allDouble,
                  decoration: BoxDecoration(
                    color: palette.successColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        s.label,
                        style: context.text.bodySmall?.copyWith(
                          color: palette.textSecondary,
                        ),
                      ),
                      VSpace.x05,
                      Text(
                        s.value.toStringAsFixed(2),
                        style: context.text.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: palette.textPrimary,
                        ),
                      ),
                      if (s.unit != null)
                        Text(
                          s.unit!,
                          style: context.text.bodySmall?.copyWith(
                            color: palette.textSecondary,
                          ),
                        ),
                    ],
                  ),
                ))
            .toList(),
      ),
      vector: (vectors) {
        if (vectors.isEmpty) {
          return Text(
            'No vector data',
            style: context.text.bodyMedium
                ?.copyWith(color: palette.textSecondary),
          );
        }
        final v = vectors.first;
        return Container(
          padding: AppPadding.allDouble,
          decoration: BoxDecoration(
            color: palette.interactableColor.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                v.label,
                style: context.text.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: palette.textPrimary,
                ),
              ),
              VSpace.x1,
              Text(
                '[${v.values.take(8).map((x) => x.toStringAsFixed(2)).join(", ")}${v.values.length > 8 ? " ..." : ""}]',
                style: context.text.bodySmall?.copyWith(
                  fontFamily: 'monospace',
                  color: palette.textSecondary,
                ),
              ),
              VSpace.x05,
              Text(
                '${v.values.length} values',
                style: context.text.bodySmall?.copyWith(
                  color: palette.textSecondary,
                ),
              ),
            ],
          ),
        );
      },
      matrix: (matrices) {
        if (matrices.isEmpty) {
          return Text(
            'No matrix data',
            style: context.text.bodyMedium
                ?.copyWith(color: palette.textSecondary),
          );
        }
        final m = matrices.first;
        return Container(
          padding: AppPadding.allDouble,
          decoration: BoxDecoration(
            color: palette.warningColor.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Matrix Output',
                style: context.text.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: palette.textPrimary,
                ),
              ),
              VSpace.x1,
              Text(
                '${m.data.length} rows × ${m.data.isNotEmpty ? m.data.first.length : 0} cols',
                style: context.text.bodySmall?.copyWith(
                  fontFamily: 'monospace',
                  color: palette.textSecondary,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SavePipelineForm extends StatefulWidget {
  final ValueChanged<String> onSave;
  const _SavePipelineForm({required this.onSave});

  @override
  State<_SavePipelineForm> createState() => _SavePipelineFormState();
}

class _SavePipelineFormState extends State<_SavePipelineForm> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _controller.text.trim();
    if (name.isNotEmpty) {
      widget.onSave(name);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        QuanityaTextField(
          controller: _controller,
          hintText: 'Pipeline name...',
          autofocus: true,
          onSubmitted: (_) => _submit(),
        ),
        VSpace.x2,
        QuanityaTextButton(
          text: 'Save',
          onPressed: _submit,
        ),
      ],
    );
  }
}
