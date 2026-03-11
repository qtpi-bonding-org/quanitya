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
import '../../../design_system/widgets/quanitya_empty_state.dart';
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
          Row(
            children: [
              Expanded(
                child: Text(
                  pipeline.name,
                  style: context.text.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: palette.textPrimary,
                  ),
                ),
              ),
              _OutputModeChip(mode: pipeline.outputMode),
            ],
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
    final palette = QuanityaPalette.primary;

    return LayoutGroup.grid(
      minItemWidth: 15,
      children: scalars.map((scalar) {
        return Container(
          padding: AppPadding.allDouble,
          decoration: BoxDecoration(
            color: palette.primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                scalar.label,
                style: context.text.bodySmall?.copyWith(
                  color: palette.textSecondary,
                ),
              ),
              VSpace.x05,
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    scalar.value.toStringAsFixed(2),
                    style: context.text.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: palette.textPrimary,
                    ),
                  ),
                  if (scalar.unit != null) ...[
                    HSpace.x05,
                    Text(
                      scalar.unit,
                      style: context.text.bodyMedium?.copyWith(
                        color: palette.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
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
            child: _MathVector(
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

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: matrices.map((matrix) {
          final data = matrix.data as List;
          final cols = matrix.columnNames as List<String>;
          // Use first non-timestamp column name, or fallback
          final name = cols.length > 1 ? cols[1] : 'Matrix';
          return Padding(
            padding: EdgeInsets.only(right: AppSizes.space * 2),
            child: _MathMatrix(
              label: name,
              data: data,
              rows: data.length,
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// Chip showing the output mode of a pipeline.
class _OutputModeChip extends StatelessWidget {
  final dynamic mode;

  const _OutputModeChip({required this.mode});

  @override
  Widget build(BuildContext context) {
    final palette = QuanityaPalette.primary;
    final (label, icon) = _getModeInfo();

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSizes.space,
        vertical: AppSizes.space * 0.5,
      ),
      decoration: BoxDecoration(
        color: palette.primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: AppSizes.iconSmall,
            color: palette.primaryColor,
          ),
          HSpace.x05,
          Text(
            label,
            style: context.text.bodySmall?.copyWith(
              color: palette.primaryColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  (String, IconData) _getModeInfo() {
    final modeStr = mode.toString().split('.').last;
    switch (modeStr) {
      case 'scalar':
        return ('Scalar', Icons.tag);
      case 'vector':
        return ('Vector', Icons.show_chart);
      case 'matrix':
        return ('Matrix', Icons.grid_on);
      default:
        return (modeStr, Icons.help_outline);
    }
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

/// Math-style vertical vector with bracket notation.
///
/// Shows first 3 values + vertical ellipsis, with label and count.
class _MathVector extends StatelessWidget {
  final String label;
  final List<double> values;
  static const _previewCount = 3;

  const _MathVector({required this.label, required this.values});

  @override
  Widget build(BuildContext context) {
    final palette = QuanityaPalette.primary;
    final monoStyle = context.text.bodySmall?.copyWith(
      fontFamily: 'monospace',
      color: palette.textPrimary,
    );
    final preview = values.take(_previewCount).toList();
    final hasMore = values.length > _previewCount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: context.text.bodySmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: palette.textPrimary,
          ),
        ),
        VSpace.x05,
        // Bracket + values
        IntrinsicWidth(
          child: Container(
            decoration: BoxDecoration(
              border: Border.symmetric(
                vertical: BorderSide(
                  color: palette.textSecondary.withValues(alpha: 0.4),
                  width: 1.5,
                ),
              ),
            ),
            padding: EdgeInsets.symmetric(
              horizontal: AppSizes.space,
              vertical: AppSizes.space * 0.5,
            ),
            child: Column(
              children: [
                ...preview.map((v) => Padding(
                      padding: EdgeInsets.symmetric(
                          vertical: AppSizes.space * 0.25),
                      child: Text(
                        v.toStringAsFixed(2),
                        style: monoStyle,
                        textAlign: TextAlign.right,
                      ),
                    )),
                if (hasMore)
                  Padding(
                    padding: EdgeInsets.symmetric(
                        vertical: AppSizes.space * 0.25),
                    child: Text('⋮', style: monoStyle),
                  ),
              ],
            ),
          ),
        ),
        VSpace.x05,
        Text(
          '${values.length}',
          style: context.text.bodySmall?.copyWith(
            color: palette.textSecondary,
          ),
        ),
      ],
    );
  }
}

/// Math-style matrix with bracket notation.
///
/// Shows first 3 row pairs vertically with ellipsis, label and row count.
class _MathMatrix extends StatelessWidget {
  final String label;
  final List<dynamic> data;
  final int rows;
  static const _previewCount = 3;

  const _MathMatrix({
    required this.label,
    required this.data,
    required this.rows,
  });

  @override
  Widget build(BuildContext context) {
    final palette = QuanityaPalette.primary;
    final monoStyle = context.text.bodySmall?.copyWith(
      fontFamily: 'monospace',
      color: palette.textPrimary,
    );

    final preview = data.take(_previewCount).toList();
    final hasMore = rows > _previewCount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: context.text.bodySmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: palette.textPrimary,
          ),
        ),
        VSpace.x05,
        IntrinsicWidth(
          child: Container(
            decoration: BoxDecoration(
              border: Border.symmetric(
                vertical: BorderSide(
                  color: palette.textSecondary.withValues(alpha: 0.4),
                  width: 1.5,
                ),
              ),
            ),
            padding: EdgeInsets.symmetric(
              horizontal: AppSizes.space,
              vertical: AppSizes.space * 0.5,
            ),
            child: Column(
              children: [
                ...preview.map((row) {
                  final cells = (row as List)
                      .map((v) => (v as num).toStringAsFixed(2));
                  return Padding(
                    padding: EdgeInsets.symmetric(
                        vertical: AppSizes.space * 0.25),
                    child: Text(cells.join('  '), style: monoStyle),
                  );
                }),
                if (hasMore)
                  Padding(
                    padding: EdgeInsets.symmetric(
                        vertical: AppSizes.space * 0.25),
                    child: Text('⋮', style: monoStyle),
                  ),
              ],
            ),
          ),
        ),
        VSpace.x05,
        Text(
          '$rows',
          style: context.text.bodySmall?.copyWith(
            color: palette.textSecondary,
          ),
        ),
      ],
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
