import 'package:flutter/material.dart';
import 'package:flutter_adaptable_group/flutter_adaptable_group.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cubit_ui_flow/cubit_ui_flow.dart';

import '../../../data/repositories/data_retrieval_service.dart';
import '../../../design_system/primitives/app_spacings.dart';
import '../../../design_system/primitives/app_sizes.dart';
import '../../../design_system/primitives/quanitya_palette.dart';
import '../../../design_system/structures/column.dart';
import '../../../design_system/widgets/charts/time_series_chart.dart';
import '../../../design_system/widgets/charts/boolean_heatmap_chart.dart';
import '../../../design_system/widgets/charts/categorical_scatter_chart.dart';
import '../../../support/extensions/context_extensions.dart';
import '../../../design_system/widgets/quanitya_empty_state.dart';
import '../../visualization/cubits/visualization_cubit.dart';
import '../cubits/results_list_cubit.dart';
import '../widgets/results_template_fold.dart';

/// Graphs page for the Results section.
///
/// Shows a scrollable list of [NotebookFold] widgets, one per template.
/// Each fold lazily loads its visualization data on first expand.
class ResultsGraphsPage extends StatelessWidget {
  const ResultsGraphsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ResultsListCubit, ResultsListState>(
      builder: (context, state) {
        if (state.status == UiFlowStatus.loading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state.templates.isEmpty) {
          return const QuanityaEmptyState();
        }

        return SingleChildScrollView(
          padding: AppPadding.page,
          child: Column(
            children: [
              for (final item in state.templates)
                ResultsTemplateFold(
                  item: item,
                  bodyBuilder: () => const _GraphsFoldBody(),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _GraphsFoldBody extends StatelessWidget {
  const _GraphsFoldBody();

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

        return QuanityaColumn(
          crossAlignment: CrossAxisAlignment.start,
          children: [
            LayoutGroup.grid(
              minItemWidth: 30,
              children: [
                ...data.numericFields
                    .map((field) => _NumericChartSection(fieldData: field)),
                ...data.booleanFields
                    .map((field) => _BooleanChartSection(fieldData: field)),
                ...data.categoricalFields
                    .map((field) => _CategoricalChartSection(fieldData: field)),
              ],
            ),
            VSpace.x4,
            _StatsSummary(
              totalEntries: data.completedEntries,
              consistencyRate: state.consistencyRate,
              loggedDates: data.loggedDates,
            ),
          ],
        );
      },
    );
  }
}

class _NumericChartSection extends StatelessWidget {
  final NumericFieldData fieldData;
  const _NumericChartSection({required this.fieldData});

  @override
  Widget build(BuildContext context) {
    final palette = QuanityaPalette.primary;
    return Padding(
      padding: EdgeInsets.only(bottom: AppSizes.space * 3),
      child: QuanityaColumn(
        crossAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            fieldData.field.label,
            style: context.text.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: palette.textPrimary,
            ),
          ),
          VSpace.x2,
          if (fieldData.isEmpty)
            _noDataPlaceholder(context)
          else
            TimeSeriesChart(
              data: fieldData.points
                  .map((p) => {'date': p.date, 'value': p.value})
                  .toList(),
              valueLabel: fieldData.field.label,
              lineColor: QuanityaPalette.category10[0],
              height: AppSizes.space * 22.5,
            ),
        ],
      ),
    );
  }
}

class _BooleanChartSection extends StatelessWidget {
  final BooleanFieldData fieldData;
  const _BooleanChartSection({required this.fieldData});

  @override
  Widget build(BuildContext context) {
    final palette = QuanityaPalette.primary;
    return Padding(
      padding: EdgeInsets.only(bottom: AppSizes.space * 3),
      child: QuanityaColumn(
        crossAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            fieldData.field.label,
            style: context.text.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: palette.textPrimary,
            ),
          ),
          VSpace.x2,
          if (fieldData.isEmpty)
            _noDataPlaceholder(context)
          else
            Center(
              child: BooleanHeatmapChart(
                data: fieldData.points
                    .map((p) => BooleanPoint(date: p.date, value: p.value))
                    .toList(),
                height: AppSizes.space * 20,
                trueColor: palette.successColor,
                weeks: 12,
              ),
            ),
        ],
      ),
    );
  }
}

class _CategoricalChartSection extends StatelessWidget {
  final CategoricalFieldData fieldData;
  const _CategoricalChartSection({required this.fieldData});

  @override
  Widget build(BuildContext context) {
    final palette = QuanityaPalette.primary;
    return Padding(
      padding: EdgeInsets.only(bottom: AppSizes.space * 3),
      child: QuanityaColumn(
        crossAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            fieldData.field.label,
            style: context.text.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: palette.textPrimary,
            ),
          ),
          VSpace.x2,
          if (fieldData.isEmpty || fieldData.categories.isEmpty)
            _noDataPlaceholder(context)
          else
            Center(
              child: CategoricalScatterChart(
                data: fieldData.points
                    .map(
                      (p) =>
                          CategoricalPoint(date: p.date, category: p.category),
                    )
                    .toList(),
                categories: fieldData.categories,
                height: AppSizes.space * 5 +
                    (fieldData.categories.length * AppSizes.space * 4),
                dotColor: QuanityaPalette.category10[0],
              ),
            ),
        ],
      ),
    );
  }
}

class _StatsSummary extends StatelessWidget {
  final int totalEntries;
  final double consistencyRate;
  final List<DateTime> loggedDates;

  const _StatsSummary({
    required this.totalEntries,
    required this.consistencyRate,
    required this.loggedDates,
  });

  @override
  Widget build(BuildContext context) {
    final palette = QuanityaPalette.primary;
    final consistencyPercent = (consistencyRate * 100).round();

    final dateCounts = <DateTime, int>{};
    int maxCount = 1;
    for (final date in loggedDates) {
      final dateOnly = DateTime(date.year, date.month, date.day);
      dateCounts[dateOnly] = (dateCounts[dateOnly] ?? 0) + 1;
      if (dateCounts[dateOnly]! > maxCount) maxCount = dateCounts[dateOnly]!;
    }
    final contributionData = dateCounts.entries
        .map((e) => BooleanPoint(
              date: e.key,
              value: true,
              intensity: e.value / maxCount,
            ))
        .toList();

    return QuanityaColumn(
      crossAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              '$totalEntries',
              style: context.text.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: palette.textPrimary,
              ),
            ),
            HSpace.x05,
            Text(
              context.l10n.visualizationEntries,
              style: context.text.bodyMedium?.copyWith(
                color: palette.textSecondary,
              ),
            ),
            HSpace.x3,
            Text(
              '$consistencyPercent%',
              style: context.text.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: palette.textPrimary,
              ),
            ),
            HSpace.x05,
            Text(
              context.l10n.visualizationConsistency,
              style: context.text.bodyMedium?.copyWith(
                color: palette.textSecondary,
              ),
            ),
          ],
        ),
        VSpace.x3,
        Center(
          child: BooleanHeatmapChart(
            data: contributionData,
            height: AppSizes.space * 20,
            trueColor: QuanityaPalette.category10[0],
            weeks: 12,
          ),
        ),
      ],
    );
  }
}

Widget _noDataPlaceholder(BuildContext context) {
  final palette = QuanityaPalette.primary;
  return Container(
    height: AppSizes.space * 10,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: palette.textSecondary.withValues(alpha: 0.05),
      borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
    ),
    child: Text(
      context.l10n.visualizationNoData,
      style: context.text.bodyMedium?.copyWith(
        color: palette.textSecondary,
      ),
    ),
  );
}
