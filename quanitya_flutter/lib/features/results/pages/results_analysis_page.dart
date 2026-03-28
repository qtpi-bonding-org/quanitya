import 'package:cubit_ui_flow/cubit_ui_flow.dart';
import 'package:flutter/material.dart';
import 'package:flutter_adaptable_group/flutter_adaptable_group.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app_router.dart';
import '../../../data/repositories/data_retrieval_service.dart';
import '../../../design_system/primitives/app_spacings.dart';
import '../../../design_system/primitives/app_sizes.dart';
import '../../../design_system/primitives/quanitya_palette.dart';
import '../../../design_system/structures/column.dart';
import '../../../design_system/widgets/analysis_output/analysis_output.dart';
import '../../../logic/analysis/models/analysis_output.dart';
import '../../../logic/analysis/models/analysis_script.dart';
import '../../../logic/analysis/models/matrix_vector_scalar/time_series_matrix.dart';
import '../../../support/extensions/context_extensions.dart';
import '../../../design_system/widgets/quanitya_empty_state.dart';
import '../../visualization/cubits/visualization_cubit.dart';
import '../../hidden_visibility/cubits/hidden_visibility_cubit.dart';
import '../cubits/results_list_cubit.dart';
import '../widgets/results_template_fold.dart';

/// Analysis page for the Results section.
///
/// Shows a scrollable list of NotebookFold widgets, one per template.
/// Each fold lazily loads its analysis data on expand.
class ResultsAnalysisPage extends StatelessWidget {
  const ResultsAnalysisPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ResultsListCubit, ResultsListState>(
      builder: (context, state) {
        if (state.status == UiFlowStatus.loading) {
          return const Center(child: CircularProgressIndicator());
        }

        final showHidden =
            context.watch<HiddenVisibilityCubit>().state.showingHidden;
        final analyzable = state.templates
            .where((item) =>
                item.hasAnalyzableFields &&
                (showHidden || !item.isHidden))
            .toList();

        if (analyzable.isEmpty) {
          return const QuanityaEmptyState();
        }

        return SingleChildScrollView(
          padding: AppPadding.page,
          child: Column(
            children: [
              for (final item in analyzable)
                ResultsTemplateFold(
                  item: item,
                  bodyBuilder: () => const _AnalysisFoldBody(),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _AnalysisFoldBody extends StatelessWidget {
  const _AnalysisFoldBody();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<VisualizationCubit, VisualizationState>(
      builder: (context, state) {
        if (state.status == UiFlowStatus.loading) {
          return Padding(
            padding: EdgeInsets.all(AppSizes.space * 2),
            child: const Center(child: CircularProgressIndicator()),
          );
        }

        final data = state.data;
        if (data == null) return const SizedBox.shrink();

        if (state.analysisResults.isEmpty &&
            data.numericFields.isEmpty &&
            data.groupFields.isEmpty) {
          return const QuanityaEmptyState();
        }

        return QuanityaColumn(
          crossAlignment: CrossAxisAlignment.start,
          children: [
            if (state.analysisResults.isNotEmpty) ...[
              _AnalysisResultsSection(
                  analysisResults: state.analysisResults),
              VSpace.x4,
            ],
            if (data.numericFields.isNotEmpty ||
                data.groupFields.isNotEmpty) ...[
              _AnalyzeFieldsSection(
                numericFields: data.numericFields,
                groupFields: data.groupFields,
                templateId: data.template.id,
              ),
            ],
          ],
        );
      },
    );
  }
}

class _AnalyzeFieldsSection extends StatelessWidget {
  final List<NumericFieldData> numericFields;
  final List<GroupFieldData> groupFields;
  final String templateId;

  const _AnalyzeFieldsSection({
    required this.numericFields,
    required this.groupFields,
    required this.templateId,
  });

  @override
  Widget build(BuildContext context) {
    final palette = QuanityaPalette.primary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Text(
            context.l10n.resultsAnalyzeFields,
            style: context.text.titleLarge?.copyWith(
              color: palette.textSecondary,
            ),
          ),
        ),
        VSpace.x2,
        ...numericFields.map((fieldData) => _FieldAnalysisCard(
              fieldData: fieldData,
              templateId: templateId,
            )),
        ...groupFields.map((groupData) => _GroupAnalysisCard(
              groupData: groupData,
              templateId: templateId,
            )),
      ],
    );
  }
}

/// Displays executed analysis pipeline results.
class _AnalysisResultsSection extends StatelessWidget {
  final Map<String, ScriptResult> analysisResults;

  const _AnalysisResultsSection({required this.analysisResults});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: analysisResults.entries.map((entry) {
        return _AnalysisResultCard(
          script: entry.value.script,
          result: entry.value.result,
        );
      }).toList(),
    );
  }
}

/// Individual analysis result card.
class _AnalysisResultCard extends StatelessWidget {
  final AnalysisScriptModel script;
  final AnalysisOutput result;

  const _AnalysisResultCard({
    required this.script,
    required this.result,
  });

  @override
  Widget build(BuildContext context) {
    final palette = QuanityaPalette.primary;

    return Container(
      margin: EdgeInsets.only(bottom: AppSizes.space * 2),
      padding: AppPadding.allDouble,
      decoration: BoxDecoration(
        color: palette.backgroundPrimary.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
        border: Border.all(
          color: palette.textSecondary.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            script.name,
            style: context.text.titleMedium?.copyWith(
              color: palette.textPrimary,
            ),
          ),
          if (script.reasoning != null) ...[
            VSpace.x05,
            Text(
              script.reasoning!,
              style: context.text.bodyMedium?.copyWith(
                color: palette.textSecondary,
              ),
            ),
          ],
          VSpace.x2,
          _buildResultDisplay(context, result),
        ],
      ),
    );
  }

  Widget _buildResultDisplay(BuildContext context, AnalysisOutput result) {
    return result.when(
      scalar: (scalars) => _buildScalarDisplay(context, scalars),
      vector: (vectors) => _buildVectorDisplay(context, vectors),
      matrix: (matrices) => _buildMatrixDisplay(context, matrices),
    );
  }

  Widget _buildScalarDisplay(BuildContext context, List<dynamic> scalars) {
    return LayoutGroup.grid(
      minItemWidth: 15,
      children: scalars.map((scalar) {
        return ScalarCard(
          label: scalar.label,
          value: scalar.value,
          unit: scalar.unit,
        );
      }).toList(),
    );
  }

  Widget _buildVectorDisplay(BuildContext context, List<dynamic> vectors) {
    return VectorChart(
      vectors: vectors.cast<AnalysisVector>(),
    );
  }

  Widget _buildMatrixDisplay(BuildContext context, List<dynamic> matrices) {
    return MatrixChart(
      matrices: matrices.cast<TimeSeriesMatrix>(),
    );
  }
}

/// Card for selecting a group field to run analysis on.
///
/// Groups are passed as whole objects to the WASM engine (e.g.
/// `[{sleep: 7, mood: "ok"}, ...]`), so they appear as a single entry.
class _GroupAnalysisCard extends StatelessWidget {
  final GroupFieldData groupData;
  final String templateId;

  const _GroupAnalysisCard({
    required this.groupData,
    required this.templateId,
  });

  @override
  Widget build(BuildContext context) {
    final palette = QuanityaPalette.primary;
    final subFieldLabels = groupData.field.subFields
            ?.map((sf) => sf.label)
            .join(', ') ??
        '';

    return Container(
      margin: EdgeInsets.only(bottom: AppSizes.space),
      child: Semantics(
        button: true,
        label: context.l10n.resultsAnalyzeField(groupData.field.label),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
            onTap: () async {
              await AppNavigation.toAnalysisBuilder(
                context,
                fieldId: groupData.field.label,
                templateId: templateId,
              );
              if (context.mounted) {
                context.read<VisualizationCubit>().loadForTemplate(templateId);
              }
            },
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: AppSizes.buttonHeight,
              ),
              child: Container(
                padding: AppPadding.allDouble,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: palette.textSecondary.withValues(alpha: 0.2),
                  ),
                  borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            groupData.field.label,
                            style: context.text.titleMedium?.copyWith(
                              color: palette.textPrimary,
                            ),
                          ),
                          VSpace.x05,
                          Text(
                            '${context.l10n.resultsDataPoints(groupData.entryCount)} · $subFieldLabels',
                            style: context.text.bodyMedium?.copyWith(
                              color: palette.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      color: palette.textSecondary,
                      size: AppSizes.iconMedium,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Card for selecting a numeric field to run analysis on.
class _FieldAnalysisCard extends StatelessWidget {
  final NumericFieldData fieldData;
  final String templateId;

  const _FieldAnalysisCard({
    required this.fieldData,
    required this.templateId,
  });

  @override
  Widget build(BuildContext context) {
    final palette = QuanityaPalette.primary;

    return Container(
      margin: EdgeInsets.only(bottom: AppSizes.space),
      child: Semantics(
        button: true,
        label: context.l10n.resultsAnalyzeField(fieldData.field.label),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
            onTap: () async {
              await AppNavigation.toAnalysisBuilder(
                context,
                fieldId: fieldData.field.label,
                templateId: templateId,
              );
              if (context.mounted) {
                context.read<VisualizationCubit>().loadForTemplate(templateId);
              }
            },
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: AppSizes.buttonHeight,
              ),
              child: Container(
                padding: AppPadding.allDouble,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: palette.textSecondary.withValues(alpha: 0.2),
                  ),
                  borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            fieldData.field.label,
                            style: context.text.titleMedium?.copyWith(
                              color: palette.textPrimary,
                            ),
                          ),
                          VSpace.x05,
                          Text(
                            context.l10n.resultsDataPoints(fieldData.points.length),
                            style: context.text.bodyMedium?.copyWith(
                              color: palette.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      color: palette.textSecondary,
                      size: AppSizes.iconMedium,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

