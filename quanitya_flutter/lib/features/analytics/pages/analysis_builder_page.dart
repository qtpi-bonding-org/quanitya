import 'package:flutter/material.dart';
import 'package:flutter_adaptable_group/flutter_adaptable_group.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:flutter_highlight/themes/vs2015.dart';
import 'package:highlight/languages/javascript.dart';
import 'package:cubit_ui_flow/cubit_ui_flow.dart';
import 'package:get_it/get_it.dart';

import '../../../design_system/primitives/quanitya_palette.dart';
import '../../../design_system/primitives/app_spacings.dart';
import '../../../design_system/primitives/app_sizes.dart';
import '../../../design_system/widgets/ai/ai_prompt_widget.dart';
import '../../../design_system/widgets/analysis_output/analysis_output.dart';
import '../../../design_system/widgets/quanitya_text_field.dart';
import '../../../design_system/widgets/quanitya/general/loose_insert_sheet.dart';
import '../../../design_system/widgets/quanitya/general/notebook_fold.dart';
import '../../../design_system/widgets/quanitya/general/pen_circled_chip.dart';
import '../../../design_system/widgets/quanitya_confirmation_dialog.dart';
import '../../../design_system/widgets/quanitya/general/quanitya_page_wrapper.dart';
import '../../../design_system/widgets/quanitya/general/quanitya_text_button.dart';
import '../../../design_system/widgets/ui_flow_listener.dart';
import '../../settings/cubits/llm_provider/llm_provider_cubit.dart';
import '../../../logic/analysis/cubits/analysis_builder_cubit.dart';
import '../../../logic/analysis/cubits/analysis_builder_state.dart';
import '../../../logic/analysis/cubits/analysis_builder_message_mapper.dart';
import '../../../logic/analysis/enums/analysis_output_mode.dart';
import '../../../logic/analysis/enums/time_resolution.dart';
import '../../../logic/analysis/models/analysis_output.dart';
import '../../../support/extensions/context_extensions.dart';

/// Analysis script builder — write or AI-generate JavaScript analysis code.
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
  static const _codeEditorFontFamily = 'monospace';
  static const _codeEditorLineHeight = 1.6;

  bool _isGenerating = false;
  late final CodeController _codeController;
  String _lastSnippet = '';

  @override
  void initState() {
    super.initState();
    _codeController = CodeController(language: javascript);
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = QuanityaPalette.primary;

    return UiFlowListener<AnalysisBuilderCubit, AnalysisBuilderState>(
      mapper: context.read<AnalysisBuilderMessageMapper>(),
      child: BlocBuilder<AnalysisBuilderCubit, AnalysisBuilderState>(
        builder: (context, state) {
          final cubit = context.read<AnalysisBuilderCubit>();

          return QuanityaPageWrapper(
            child: Scaffold(
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
            ),
          );
        },
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
              hintText: context.l10n.analysisDescribeHint,
              isLoading: _isGenerating,
              onGenerate: (prompt) => _generateFromAi(context, prompt),
            ),
          ),

          // New script button
          Padding(
            padding: AppPadding.pageHorizontal,
            child: QuanityaTextButton(
              text: context.l10n.analysisNewScript,
              onPressed: () => cubit.newScript(),
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
          VSpace.x1,

          // Entry range control
          Padding(
            padding: AppPadding.pageHorizontal,
            child: _EntryRangeControl(
              start: state.entryRangeStart,
              end: state.entryRangeEnd,
              entryCount: state.entryCount,
              onChanged: (start, end) =>
                  cubit.setEntryRange(start: start, end: end),
            ),
          ),
          VSpace.x2,

          // Script selector — PenCircledChips in a wrapping row
          if (state.availableScripts.isNotEmpty) ...[
            Padding(
              padding: AppPadding.pageHorizontal,
              child: Wrap(
                spacing: AppSizes.space,
                runSpacing: AppSizes.space,
                children: state.availableScripts.map((p) => PenCircledChip(
                      label: p.name,
                      isSelected: p.id == state.selectedScriptId,
                      onTap: () => cubit.selectScript(p.id),
                    )).toList(),
              ),
            ),
            VSpace.x2,
          ],

          // Reasoning (from AI or saved script)
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
                      color: palette.textPrimary,
                    ),
                    HSpace.x1,
                    Text(
                      context.l10n.analysisResults,
                      style: context.text.titleMedium?.copyWith(
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
                if (state.selectedScriptId != null) ...[
                  QuanityaTextButton(
                    text: context.l10n.analysisDeleteScript,
                    isDestructive: true,
                    onPressed: () => _confirmDelete(context, cubit),
                  ),
                  HSpace.x2,
                ],
                if (state.snippet.isNotEmpty) ...[
                  QuanityaTextButton(
                    text: context.l10n.analysisRun,
                    onPressed: () => cubit.runScript(),
                  ),
                  HSpace.x2,
                  QuanityaTextButton(
                    text: context.l10n.actionSave,
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
      _codeController.text = state.snippet;
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
      child: CodeTheme(
        data: CodeThemeData(styles: vs2015Theme),
        child: CodeField(
          controller: _codeController,
          minLines: 8,
          maxLines: null,
          onChanged: (value) {
            _lastSnippet = value;
            cubit.updateSnippet(value);
          },
          textStyle: context.text.bodySmall?.copyWith(
            fontFamily: _codeEditorFontFamily,
            height: _codeEditorLineHeight,
            color: context.colors.textSecondary,
          ),
          gutterStyle: GutterStyle(
            showLineNumbers: true,
            showFoldingHandles: false,
            showErrors: false,
            textStyle: context.text.labelSmall?.copyWith(
              fontFamily: _codeEditorFontFamily,
              color: QuanityaPalette.primary.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _generateFromAi(BuildContext context, String prompt) async {
    if (prompt.isEmpty || _isGenerating) return;

    final cubit = context.read<AnalysisBuilderCubit>();
    final state = cubit.state;

    final llmCubit = GetIt.I<LlmProviderCubit>();
    final config = await llmCubit.buildLlmConfig();
    if (config == null) {
      if (context.mounted) {
        GetIt.I<IFeedbackService>().show(FeedbackMessage(
            message: context.l10n.llmProviderConfigureLlm,
            type: MessageType.warning));
      }
      return;
    }

    setState(() => _isGenerating = true);

    try {
      await cubit.generateAndApplyAiScript(
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

  Future<void> _confirmDelete(
    BuildContext context,
    AnalysisBuilderCubit cubit,
  ) async {
    final confirmed = await QuanityaConfirmationDialog.show(
      context: context,
      title: context.l10n.analysisDeleteConfirmTitle,
      message: context.l10n.analysisDeleteConfirmMessage,
      confirmText: context.l10n.actionDelete,
      isDestructive: true,
      onConfirm: () {},
    );
    if (confirmed == true && context.mounted) {
      await cubit.deleteScript();
    }
  }

  void _showSaveSheet(
    BuildContext context,
    AnalysisBuilderCubit cubit,
  ) {
    LooseInsertSheet.show<String>(
      context: context,
      title: context.l10n.analysisSaveScript,
      builder: (_) => _SaveScriptForm(
        onSave: (name) {
          Navigator.of(context).pop();
          cubit.saveScript(name);
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
            .map((s) => ScalarCard(
                  label: s.label,
                  value: s.value,
                  unit: s.unit,
                ))
            .toList(),
      ),
      vector: (vectors) {
        if (vectors.isEmpty) {
          return Text(
            context.l10n.analysisNoVectorData,
            style: context.text.bodyMedium
                ?.copyWith(color: palette.textSecondary),
          );
        }
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: vectors.map((v) {
              return Padding(
                padding: EdgeInsets.only(right: AppSizes.space * 2),
                child: MathVector(label: v.label, values: v.values),
              );
            }).toList(),
          ),
        );
      },
      matrix: (matrices) {
        if (matrices.isEmpty) {
          return Text(
            context.l10n.analysisNoMatrixData,
            style: context.text.bodyMedium
                ?.copyWith(color: palette.textSecondary),
          );
        }
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: matrices.map((m) {
              final name = m.columnNames.length > 1
                  ? m.columnNames[1]
                  : context.l10n.analysisMatrix;
              return Padding(
                padding: EdgeInsets.only(right: AppSizes.space * 2),
                child: MathMatrix(label: name, data: m.data, rows: m.data.length),
              );
            }).toList(),
          ),
        );
      },
    );
  }

}

class _SaveScriptForm extends StatefulWidget {
  final ValueChanged<String> onSave;
  const _SaveScriptForm({required this.onSave});

  @override
  State<_SaveScriptForm> createState() => _SaveScriptFormState();
}

class _SaveScriptFormState extends State<_SaveScriptForm> {
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
          hintText: context.l10n.analysisScriptNameHint,
          autofocus: true,
          onSubmitted: (_) => _submit(),
        ),
        VSpace.x2,
        QuanityaTextButton(
          text: context.l10n.actionSave,
          onPressed: _submit,
        ),
      ],
    );
  }
}

/// Controls entry range [start:end] for analysis data fetching.
///
/// Empty fields = all entries. Filled = slice to [start:end].
/// Entries are 0-indexed, ordered by date descending (0 = most recent).
class _EntryRangeControl extends StatefulWidget {
  static const _max = 10000;

  final int? start;
  final int? end;
  final int entryCount;
  final void Function(int? start, int? end) onChanged;

  const _EntryRangeControl({
    required this.start,
    required this.end,
    required this.entryCount,
    required this.onChanged,
  });

  @override
  State<_EntryRangeControl> createState() => _EntryRangeControlState();
}

class _EntryRangeControlState extends State<_EntryRangeControl> {
  late TextEditingController _startController;
  late TextEditingController _endController;

  @override
  void initState() {
    super.initState();
    _startController = TextEditingController(
      text: widget.start?.toString() ?? '',
    );
    _endController = TextEditingController(
      text: widget.end?.toString() ?? '',
    );
  }

  @override
  void didUpdateWidget(_EntryRangeControl old) {
    super.didUpdateWidget(old);
    final newStart = widget.start?.toString() ?? '';
    final newEnd = widget.end?.toString() ?? '';
    if (_startController.text != newStart) _startController.text = newStart;
    if (_endController.text != newEnd) _endController.text = newEnd;
  }

  @override
  void dispose() {
    _startController.dispose();
    _endController.dispose();
    super.dispose();
  }

  void _commitValues() {
    final s = int.tryParse(_startController.text);
    final e = int.tryParse(_endController.text);
    widget.onChanged(
      s != null ? s.clamp(0, _EntryRangeControl._max) : null,
      e != null ? e.clamp(0, _EntryRangeControl._max) : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = QuanityaPalette.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(context.l10n.analysisEntriesCount(widget.entryCount), style: context.text.bodySmall?.copyWith(
          color: palette.textSecondary,
        )),
        VSpace.x1,
        Row(
          children: [
            Expanded(
          child: QuanityaTextField(
            controller: _startController,
            keyboardType: TextInputType.number,
            hintText: '0',
            onChanged: (_) => _commitValues(),
          ),
        ),
        HSpace.x1,
        Text(':', style: context.text.bodySmall?.copyWith(
          color: palette.textSecondary,
        )),
        HSpace.x1,
        Expanded(
          child: QuanityaTextField(
            controller: _endController,
            keyboardType: TextInputType.number,
            hintText: '${widget.entryCount}',
            onChanged: (_) => _commitValues(),
          ),
        ),
          ],
        ),
      ],
    );
  }
}
