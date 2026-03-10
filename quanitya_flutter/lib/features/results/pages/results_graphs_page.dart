import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:cubit_ui_flow/cubit_ui_flow.dart';

import '../../../data/repositories/data_retrieval_service.dart';
import '../../../design_system/primitives/app_spacings.dart';
import '../../../design_system/primitives/app_sizes.dart';
import '../../../design_system/primitives/quanitya_palette.dart';
import '../../../design_system/structures/column.dart';
import '../../../design_system/widgets/charts/time_series_chart.dart';
import '../../../design_system/widgets/charts/boolean_heatmap_chart.dart';
import '../../../design_system/widgets/charts/categorical_scatter_chart.dart';
import '../../../design_system/widgets/charts/contribution_heatmap.dart';
import '../../../design_system/widgets/quanitya_empty_state.dart';
import '../../../support/extensions/context_extensions.dart';
import '../../visualization/cubits/visualization_cubit.dart';

/// Graphs page for the Results section.
///
/// Receives a [templateId] and displays visualization charts for that template.
/// When no template is selected, shows an empty state.
class ResultsGraphsPage extends StatelessWidget {
  final String? templateId;

  const ResultsGraphsPage({super.key, this.templateId});

  @override
  Widget build(BuildContext context) {
    if (templateId == null) {
      return const _EmptyTemplateState(
        message: 'Select an experiment to view results',
      );
    }

    return BlocProvider(
      key: ValueKey(templateId),
      create: (_) => GetIt.I<VisualizationCubit>()..loadForTemplate(templateId!),
      child: const _GraphsContent(),
    );
  }
}

class _GraphsContent extends StatelessWidget {
  const _GraphsContent();

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
              Row(
                children: [
                  Icon(
                    Icons.bar_chart,
                    size: AppSizes.iconMedium,
                    color: palette.textPrimary,
                  ),
                  HSpace.x1,
                  Expanded(
                    child: Text(
                      data.template.name,
                      style: context.text.headlineSmall,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              VSpace.x1,
              Text(
                context.l10n.visualizationLast30Days(data.template.name),
                style: context.text.bodyMedium?.copyWith(
                  color: palette.textSecondary,
                ),
              ),
              VSpace.x4,
              ...data.numericFields.map(
                (field) => _NumericChartSection(fieldData: field),
              ),
              ...data.booleanFields.map(
                (field) => _BooleanChartSection(fieldData: field),
              ),
              ...data.categoricalFields.map(
                (field) => _CategoricalChartSection(fieldData: field),
              ),
              VSpace.x4,
              _StatsSummary(
                totalEntries: data.completedEntries,
                consistencyRate: state.consistencyRate,
                loggedDates: data.loggedDates,
              ),
              VSpace.x4,
            ],
          ),
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
              lineColor: palette.primaryColor,
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
                      (p) => CategoricalPoint(date: p.date, category: p.category),
                    )
                    .toList(),
                categories: fieldData.categories,
                height: AppSizes.space * 5 +
                    (fieldData.categories.length * AppSizes.space * 4),
                dotColor: palette.primaryColor,
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
    for (final date in loggedDates) {
      final dateOnly = DateTime(date.year, date.month, date.day);
      dateCounts[dateOnly] = (dateCounts[dateOnly] ?? 0) + 1;
    }
    final contributionData = dateCounts.entries
        .map((e) => ContributionPoint(date: e.key, count: e.value))
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
        ContributionHeatmap(
          data: contributionData,
          weeks: 12,
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

class _EmptyTemplateState extends StatelessWidget {
  final String message;
  const _EmptyTemplateState({required this.message});

  @override
  Widget build(BuildContext context) {
    final palette = QuanityaPalette.primary;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const QuanityaEmptyState(size: 80, opacity: 0.2),
          VSpace.x2,
          Text(
            message,
            style: context.text.bodyMedium?.copyWith(
              color: palette.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
