import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cubit_ui_flow/cubit_ui_flow.dart';
import '../../../app/bootstrap.dart';
import '../../../design_system/primitives/quanitya_palette.dart';
import '../../../design_system/primitives/app_spacings.dart';
import '../../../design_system/primitives/app_sizes.dart';
import '../../../design_system/widgets/quanitya/general/zen_paper_background.dart';
import '../../../design_system/widgets/quanitya_icon_button.dart';
import '../../../infrastructure/feedback/base_state_message_mapper.dart';
import '../../../logic/analytics/cubits/analysis_builder_cubit.dart';
import '../../../logic/analytics/cubits/analysis_builder_state.dart';
import '../../../logic/analytics/cubits/analysis_builder_message_mapper.dart';
import '../../../logic/analytics/enums/time_resolution.dart';
import '../widgets/live_results_panel.dart';

/// Analysis pipeline viewer - displays JavaScript analysis code with syntax highlighting
class AnalysisBuilderPage extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<AnalysisBuilderCubit>()
        ..initializeForField(fieldId, timeResolution, templateId: templateId),
      child:
          UiFlowStateListener<AnalysisBuilderCubit, AnalysisBuilderState>(
            mapper: BaseStateMessageMapper<AnalysisBuilderState>(
              exceptionMapper: getIt<IExceptionKeyMapper>(),
              domainMapper: getIt<AnalysisBuilderMessageMapper>(),
            ),
            uiService: getIt<IUiFlowService>(),
            child:
                BlocBuilder<AnalysisBuilderCubit, AnalysisBuilderState>(
                  builder: (context, state) {
                    final cubit = context.read<AnalysisBuilderCubit>();

                    return Scaffold(
                      appBar: AppBar(
                        title: const Text('Analysis Pipeline Viewer'),
                        backgroundColor:
                            QuanityaPalette.primary.backgroundPrimary,
                        elevation: 0,
                        actions: [
                          // Live preview toggle
                          QuanityaIconButton(
                            onPressed: () => cubit.toggleLivePreview(),
                            icon: state.livePreviewEnabled
                                ? Icons.visibility
                                : Icons.visibility_off,
                            color: state.livePreviewEnabled
                                ? QuanityaPalette.primary.successColor
                                : QuanityaPalette.primary.textSecondary,
                            tooltip: state.livePreviewEnabled
                                ? 'Hide Live Preview'
                                : 'Show Live Preview',
                          ),
                        ],
                      ),
                      body: Row(
                        children: [
                          // Left: Code viewer
                          Expanded(flex: 3, child: _buildCodeViewer(state)),

                          // Right: Live results (if enabled)
                          if (state.livePreviewEnabled &&
                              state.liveResults != null)
                            Expanded(
                              flex: 2,
                              child: Container(
                                decoration: BoxDecoration(
                                  border: Border(
                                    left: BorderSide(
                                      color: QuanityaPalette
                                          .primary
                                          .textSecondary
                                          .withValues(alpha: 0.2),
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

  Widget _buildCodeViewer(AnalysisBuilderState state) {
    return ZenPaperBackground(
      baseColor: QuanityaPalette.primary.backgroundPrimary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: AppPadding.allDouble,
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: QuanityaPalette.primary.textSecondary.withValues(
                    alpha: 0.2,
                  ),
                  width: 1,
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.code,
                      color: QuanityaPalette.primary.interactableColor,
                      size: 20,
                    ),
                    HSpace.x1,
                    Text(
                      'JavaScript Analysis',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: QuanityaPalette.primary.textPrimary,
                      ),
                    ),
                    const Spacer(),
                    _buildOutputModeBadge(state.outputMode.name),
                  ],
                ),
                if (state.reasoning.isNotEmpty) ...[
                  VSpace.x1,
                  Text(
                    state.reasoning,
                    style: TextStyle(
                      fontSize: 14,
                      color: QuanityaPalette.primary.textSecondary,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Code display with IDE-style monospace font
          Expanded(
            child: state.snippet.isEmpty
                ? _buildEmptyState()
                : Container(
                    // VS Code dark theme background (#1E1E1E) - intentionally hardcoded
                    // to match IDE appearance for code display consistency
                    color: const Color(0xFF1E1E1E),
                    padding: AppPadding.allDouble,
                    child: SingleChildScrollView(
                      child: SelectableText(
                        state.snippet,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 14,
                          height: 1.6,
                          // VS Code text color (#D4D4D4) - intentionally hardcoded
                          // to match IDE appearance for code display consistency
                          color: Color(0xFFD4D4D4),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildOutputModeBadge(String mode) {
    final color = mode == 'scalar'
        ? QuanityaPalette.primary.successColor
        : mode == 'vector'
        ? QuanityaPalette.primary.interactableColor
        : QuanityaPalette.primary.warningColor;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: HSpace.x1.width,
        vertical: VSpace.x025.height,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
        border: Border.all(color: color, width: 1),
      ),
      child: Text(
        mode.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.code_off,
            size: 64,
            color: QuanityaPalette.primary.textSecondary.withValues(alpha: 0.5),
          ),
          VSpace.x2,
          Text(
            'No analysis script loaded',
            style: TextStyle(
              fontSize: 16,
              color: QuanityaPalette.primary.textSecondary,
            ),
          ),
          VSpace.x1,
          Text(
            'Load a pipeline to view its JavaScript code',
            style: TextStyle(
              fontSize: 14,
              color: QuanityaPalette.primary.textSecondary.withValues(
                alpha: 0.7,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
