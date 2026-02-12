import 'package:cubit_ui_flow/cubit_ui_flow.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

import '../../../app_router.dart';
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
import '../../../design_system/widgets/quanitya_icon_button.dart';
import '../../../logic/templates/models/shared/tracker_template.dart';
import '../../../support/extensions/context_extensions.dart';
import '../cubits/visualization_cubit.dart';

/// Visualization Page - Shows charts for all visualizable fields.
class VisualizationPage extends StatelessWidget {
  final String? templateId;

  const VisualizationPage({super.key, this.templateId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) {
        final cubit = GetIt.I<VisualizationCubit>();
        if (templateId != null) {
          cubit.loadForTemplate(templateId!);
        }
        return cubit;
      },
      child: const _VisualizationContent(),
    );
  }
}

class _VisualizationContent extends StatelessWidget {
  const _VisualizationContent();

  @override
  Widget build(BuildContext context) {
    final palette = QuanityaPalette.primary;
    
    return BlocBuilder<VisualizationCubit, VisualizationState>(
      builder: (context, state) {
        if (state.status == UiFlowStatus.loading) {
          return Scaffold(
            backgroundColor: Colors.transparent,
            appBar: _buildAppBar(context, null),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        final data = state.data;
        if (data == null) {
          return Scaffold(
            backgroundColor: Colors.transparent,
            appBar: _buildAppBar(context, null),
            body: const QuanityaEmptyState(),
          );
        }

        return Scaffold(
          backgroundColor: Colors.transparent,
          appBar: _buildAppBar(context, data.template.name),
          body: SafeArea(
            top: false, // AppBar handles top
            child: SingleChildScrollView(
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
                    Text(
                      context.l10n.visualizationDataTitle,
                      style: context.text.headlineSmall,
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
                ...data.numericFields
                    .map((field) => _NumericChartSection(fieldData: field)),
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
          ),
          ),
        );
      },
    );
  }

  AppBar _buildAppBar(BuildContext context, String? title) {
    final palette = QuanityaPalette.primary;
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: QuanityaIconButton(
        icon: Icons.arrow_back,
        onPressed: () => AppNavigation.back(context),
      ),
      title: Text(
        title ?? context.l10n.visualizationTitle,
        style: context.text.headlineMedium?.copyWith(
          color: palette.textPrimary,
        ),
      ),
      actions: [
        // Add "Analyze" button when we have data
        if (title != null) // Only show when we have template data loaded
          QuanityaIconButton(
            icon: Icons.analytics_outlined,
            onPressed: () => _showAnalysisOptions(context),
            tooltip: 'Analyze Data',
          ),
      ],
    );
  }

  void _showAnalysisOptions(BuildContext context) {
    final cubit = context.read<VisualizationCubit>();
    final state = cubit.state;
    final data = state.data;
    
    if (data == null) return;
    
    // Show bottom sheet with field selection for analysis
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => _AnalysisFieldSelector(
        template: data.template,
        numericFields: data.numericFields,
      ),
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
          _SectionHeader(
            title: fieldData.field.label,
            subtitle: context.l10n.visualizationTrend,
          ),
          VSpace.x2,
          if (fieldData.isEmpty)
            const _NoDataMessage()
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
          _SectionHeader(
            title: fieldData.field.label,
            subtitle: context.l10n.visualizationCompletion,
          ),
          VSpace.x2,
          if (fieldData.isEmpty)
            const _NoDataMessage()
          else
            Center(
              child: BooleanHeatmapChart(
                data: fieldData.points
                    .map((p) => BooleanPoint(date: p.date, value: p.value))
                    .toList(),
                height: AppSizes.space * 20, // Increased from 15 to 20 (160px)
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
          _SectionHeader(
            title: fieldData.field.label,
            subtitle: context.l10n.visualizationCategories,
          ),
          VSpace.x2,
          if (fieldData.isEmpty || fieldData.categories.isEmpty)
            const _NoDataMessage()
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

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  const _SectionHeader({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    final palette = QuanityaPalette.primary;
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: context.text.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: palette.textPrimary,
          ),
        ),
        Text(
          subtitle,
          style: context.text.bodySmall?.copyWith(
            color: palette.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _NoDataMessage extends StatelessWidget {
  const _NoDataMessage();

  @override
  Widget build(BuildContext context) {
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
    
    // Build contribution data from logged dates
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
        // Stats row - simple text, no boxes
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
        // GitHub-style contribution grid
        ContributionHeatmap(
          data: contributionData,
          weeks: 12,
        ),
      ],
    );
  }
}

/// Bottom sheet for selecting which field to analyze
class _AnalysisFieldSelector extends StatelessWidget {
  final TrackerTemplateModel template;
  final List<NumericFieldData> numericFields;

  const _AnalysisFieldSelector({
    required this.template,
    required this.numericFields,
  });

  @override
  Widget build(BuildContext context) {
    final palette = QuanityaPalette.primary;
    
    return Container(
      padding: AppPadding.allDouble,
      decoration: BoxDecoration(
        color: palette.backgroundPrimary,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(Icons.analytics_outlined, color: palette.textPrimary),
                HSpace.x1,
                Text(
                  'Analyze Field Data',
                  style: context.text.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: palette.textPrimary,
                  ),
                ),
                const Spacer(),
                QuanityaIconButton(
                  icon: Icons.close,
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            VSpace.x1,
            Text(
              'Select a numeric field to create analysis pipelines',
              style: context.text.bodyMedium?.copyWith(
                color: palette.textSecondary,
              ),
            ),
            VSpace.x3,
            
            // Field list
            if (numericFields.isEmpty)
              Container(
                padding: AppPadding.allDouble,
                decoration: BoxDecoration(
                  color: palette.textSecondary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: palette.textSecondary),
                    HSpace.x1,
                    Expanded(
                      child: Text(
                        'No numeric fields available for analysis. Add numeric fields to your template to enable analysis.',
                        style: context.text.bodyMedium?.copyWith(
                          color: palette.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else
              ...numericFields.map((fieldData) => _FieldAnalysisOption(
                fieldData: fieldData,
                templateId: template.id,
              )),
            
            VSpace.x2,
          ],
        ),
      ),
    );
  }
}

/// Individual field option for analysis
class _FieldAnalysisOption extends StatelessWidget {
  final NumericFieldData fieldData;
  final String templateId;

  const _FieldAnalysisOption({
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
            Navigator.pop(context);
            // Navigate to pipeline builder with this field
            AppNavigation.toAnalysisBuilder(
              context,
              fieldId: fieldData.field.id,
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
                // Field info
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
                
                // Analysis icon
                Container(
                  padding: AppPadding.allSingle,
                  decoration: BoxDecoration(
                    color: palette.interactableColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
                  ),
                  child: Icon(
                    Icons.trending_up,
                    color: palette.interactableColor,
                    size: AppSizes.iconMedium,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
