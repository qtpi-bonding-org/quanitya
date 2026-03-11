import 'package:cubit_ui_flow/cubit_ui_flow.dart';
import 'package:flutter/material.dart';
import 'package:flutter_adaptable_group/flutter_adaptable_group.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

import '../../../app_router.dart';
import '../../../data/repositories/data_retrieval_service.dart';
import '../../../design_system/primitives/app_spacings.dart';
import '../../../design_system/primitives/app_sizes.dart';
import '../../../design_system/primitives/quanitya_palette.dart';
import '../../../design_system/structures/column.dart';
import '../../../design_system/widgets/analysis_output/analysis_output.dart';
import '../../../design_system/widgets/charts/multi_series_chart.dart';
import '../../../design_system/widgets/charts/time_series_chart.dart';
import '../../../design_system/widgets/quanitya_empty_state.dart';
import '../../../logic/analytics/models/matrix_vector_scalar/time_series_matrix.dart';
import '../../../support/extensions/context_extensions.dart';
import '../../visualization/cubits/visualization_cubit.dart';

/// Analysis page for the Results section.
///
/// Receives a [templateId] and displays analysis pipeline results.
/// When no template is selected, shows an empty state.
class ResultsAnalysisPage extends StatelessWidget {
  final String? templateId;

  const ResultsAnalysisPage({super.key, this.templateId});

  @override
  Widget build(BuildContext context) {
    if (templateId == null) {
      return const _EmptyTemplateState();
    }

    return BlocProvider(
      key: ValueKey(templateId),
      create: (_) =>
          GetIt.I<VisualizationCubit>()..loadForTemplate(templateId!),
      child: const _AnalysisContent(),
    );
  }
}

class _AnalysisContent extends StatelessWidget {
  const _AnalysisContent();

  @override
  Widget build(BuildContext context) {
    final palette = QuanityaPalette.primary;

    return BlocBuilder<VisualizationCubit, VisualizationState>(
      builder: (context, state) {
        if (state.status == UiFlowStatus.loading) {
          return const Center(child: CircularProgressIndicator());
        }

        final data = state.data;
        if (data == null) {
          return const QuanityaEmptyState();
        }

        return SingleChildScrollView(
          padding: AppPadding.page,
          child: QuanityaColumn(
            crossAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Icon(
                    Icons.analytics_outlined,
                    size: AppSizes.iconMedium,
                    color: palette.textPrimary,
                  ),
                  HSpace.x1,
                  Expanded(
                    child: Text(
                      data.template.name,
                      style: context.text.headlineSmall,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ],
              ),
              VSpace.x1,
              Text(
                'Analysis pipelines for ${data.template.name}',
                style: context.text.bodyMedium?.copyWith(
                  color: palette.textSecondary,
                ),
              ),
              VSpace.x4,

              // Analysis Results Section
              if (state.analysisResults.isNotEmpty) ...[
                _AnalysisResultsSection(
                  analysisResults: state.analysisResults,
                ),
                VSpace.x4,
              ],

              // Numeric Field Selector — launch analysis builder
              if (data.numericFields.isNotEmpty) ...[
                Row(
                  children: [
                    Icon(
                      Icons.functions,
                      size: AppSizes.iconMedium,
                      color: palette.textPrimary,
                    ),
                    HSpace.x1,
                    Text(
                      'Analyze Fields',
                      style: context.text.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: palette.textPrimary,
                      ),
                    ),
                  ],
                ),
                VSpace.x1,
                Text(
                  'Select a numeric field to create or view analysis pipelines',
                  style: context.text.bodyMedium?.copyWith(
                    color: palette.textSecondary,
                  ),
                ),
                VSpace.x2,
                ...data.numericFields.map(
                  (fieldData) => _FieldAnalysisCard(
                    fieldData: fieldData,
                    templateId: data.template.id,
                  ),
                ),
                VSpace.x4,
              ],

              // Empty state when no analysis results and no numeric fields
              if (state.analysisResults.isEmpty &&
                  data.numericFields.isEmpty) ...[
                _NoAnalysisPlaceholder(),
              ],
            ],
          ),
        );
      },
    );
  }
}

/// Displays executed analysis pipeline results.
class _AnalysisResultsSection extends StatelessWidget {
  final Map<String, dynamic> analysisResults;

  const _AnalysisResultsSection({required this.analysisResults});

  @override
  Widget build(BuildContext context) {
    final palette = QuanityaPalette.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.insights,
              size: AppSizes.iconMedium,
              color: palette.textPrimary,
            ),
            HSpace.x1,
            Text(
              'Pipeline Results',
              style: context.text.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: palette.textPrimary,
              ),
            ),
          ],
        ),
        VSpace.x1,
        Text(
          'Results from executed analysis pipelines',
          style: context.text.bodyMedium?.copyWith(
            color: palette.textSecondary,
          ),
        ),
        VSpace.x3,
        ...analysisResults.entries.map((entry) {
          final pipelineData = entry.value as Map<String, dynamic>;
          final pipeline = pipelineData['pipeline'];
          final result = pipelineData['result'];

          return _AnalysisResultCard(
            pipeline: pipeline,
            result: result,
          );
        }),
      ],
    );
  }
}

/// Individual analysis result card.
class _AnalysisResultCard extends StatelessWidget {
  final dynamic pipeline;
  final dynamic result;

  const _AnalysisResultCard({
    required this.pipeline,
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
            pipeline.name,
            style: context.text.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: palette.textPrimary,
            ),
          ),
          if (pipeline.reasoning != null) ...[
            VSpace.x05,
            Text(
              pipeline.reasoning,
              style: context.text.bodySmall?.copyWith(
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

  Widget _buildResultDisplay(BuildContext context, dynamic result) {
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
    final palette = QuanityaPalette.primary;

    if (vectors.isEmpty) {
      return Text(
        'No vector data',
        style: context.text.bodyMedium?.copyWith(color: palette.textSecondary),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: vectors.map((vector) {
          return Padding(
            padding: EdgeInsets.only(right: AppSizes.space * 2),
            child: MathVector(
              label: vector.label ?? 'Vector',
              values: (vector.values as List).cast<double>(),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMatrixDisplay(BuildContext context, List<dynamic> matrices) {
    final palette = QuanityaPalette.primary;

    if (matrices.isEmpty) {
      return Text(
        'No matrix data',
        style: context.text.bodyMedium?.copyWith(color: palette.textSecondary),
      );
    }

    // Distinct chart colors — standard data visualization palette
    const chartColors = [
      Color(0xFF1F77B4), // blue
      Color(0xFFFF7F0E), // orange
      Color(0xFF2CA02C), // green
      Color(0xFFD62728), // red
      Color(0xFF9467BD), // purple
      Color(0xFF8C564B), // brown
      Color(0xFFE377C2), // pink
      Color(0xFF7F7F7F), // gray
    ];

    final series = <ChartSeries>[];
    for (var i = 0; i < matrices.length; i++) {
      final matrix = matrices[i] as TimeSeriesMatrix;
      if (matrix.data.isEmpty) continue;

      final timestamps = matrix.timestampVector.timestamps;
      final valueCol = matrix.fieldNames.isNotEmpty
          ? matrix.getColumnByName(matrix.fieldNames.first).values
          : <num>[];

      final points = <({DateTime date, num value})>[];
      for (var j = 0; j < timestamps.length && j < valueCol.length; j++) {
        points.add((date: timestamps[j], value: valueCol[j]));
      }

      series.add(ChartSeries(
        label: matrix.fieldNames.isNotEmpty ? matrix.fieldNames.first : 'Series ${i + 1}',
        points: points,
        color: chartColors[i % chartColors.length],
      ));
    }

    // Single series: use TimeSeriesChart (graphic lib needs >= 2 for ColorEncode)
    if (series.length == 1) {
      final s = series.first;
      return TimeSeriesChart(
        data: s.points.map((p) => {'date': p.date, 'value': p.value}).toList(),
        valueLabel: s.label,
        lineColor: s.color,
      );
    }

    return MultiSeriesChart(series: series);
  }
}

/// Chip showing the output mode of a pipeline.
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
          onTap: () {
            AppNavigation.toAnalysisBuilder(
              context,
              fieldId: fieldData.field.label,
              templateId: templateId,
            );
          },
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
                          fontWeight: FontWeight.w600,
                          color: palette.textPrimary,
                        ),
                      ),
                      VSpace.x05,
                      Text(
                        '${fieldData.points.length} data points',
                        style: context.text.bodySmall?.copyWith(
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
    );
  }
}

/// Placeholder when there are no analysis pipelines or numeric fields.
class _NoAnalysisPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final palette = QuanityaPalette.primary;

    return Center(
      child: Padding(
        padding: AppPadding.allTriple,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.analytics_outlined,
              size: 64,
              color: palette.textSecondary.withValues(alpha: 0.5),
            ),
            VSpace.x2,
            Text(
              'No Analysis Available',
              style: context.text.headlineSmall?.copyWith(
                color: palette.textPrimary,
              ),
            ),
            VSpace.x1,
            Text(
              'Add numeric fields to your template to enable analysis pipelines.',
              textAlign: TextAlign.center,
              style: context.text.bodyMedium?.copyWith(
                color: palette.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyTemplateState extends StatelessWidget {
  const _EmptyTemplateState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: QuanityaEmptyState(size: 80, opacity: 0.2),
    );
  }
}
