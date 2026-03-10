import 'package:flutter/material.dart';
import 'package:graphic/graphic.dart';

import '../../../design_system/primitives/app_sizes.dart';
import '../../../design_system/primitives/app_spacings.dart';
import '../../../design_system/primitives/quanitya_palette.dart';
import '../../../design_system/primitives/quanitya_fonts.dart';
import '../../../design_system/primitives/zen_grid_constants.dart';
import '../../../design_system/widgets/zen_grid_positioned.dart';
import '../../../support/extensions/context_extensions.dart';
import '../../../logic/analytics/models/analysis_output.dart';
import '../../../logic/analytics/models/matrix_vector_scalar/time_series_matrix.dart';

/// Live results panel showing results in real-time
class LiveResultsPanel extends StatelessWidget {
  final AnalysisOutput? results;
  final int column;
  final int row;
  final int widthUnits;
  final VoidCallback? onClose;

  const LiveResultsPanel({
    super.key,
    required this.results,
    required this.column,
    required this.row,
    this.widthUnits = 8,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final gridSpacing = ZenGridConstants.dotSpacing;
    final panelWidth = widthUnits * gridSpacing;

    // Calculate appropriate height based on result type
    final panelHeight = _calculateHeight(gridSpacing);

    return ZenGridPositioned(
      column: column,
      row: row,
      width: panelWidth,
      height: panelHeight,
      child: Container(
        decoration: BoxDecoration(
          color: QuanityaPalette.primary.backgroundPrimary.withValues(
            alpha: 0.95,
          ),
          borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
          border: Border.all(
            color: QuanityaPalette.primary.successColor.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            _buildHeader(context, gridSpacing),

            // Results Content
            Expanded(
              child: results == null
                  ? _buildEmptyState(context, gridSpacing)
                  : _buildResultContent(context, gridSpacing),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, double gridSpacing) {
    return Container(
      padding: EdgeInsets.all(gridSpacing * 0.5),
      decoration: BoxDecoration(
        color: QuanityaPalette.primary.successColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(AppSizes.radiusMedium),
          topRight: Radius.circular(AppSizes.radiusMedium),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.analytics,
            size: gridSpacing * 0.6,
            color: QuanityaPalette.primary.successColor,
          ),
          SizedBox(width: gridSpacing * 0.2),
          Text(
            'Live Preview',
            style: context.text.bodyMedium?.copyWith(
              color: QuanityaPalette.primary.successColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          if (onClose != null)
            GestureDetector(
              onTap: onClose,
              child: Icon(
                Icons.close,
                size: gridSpacing * 0.5,
                color: QuanityaPalette.primary.textSecondary,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildResultContent(BuildContext context, double gridSpacing) {
    return results!.when(
      scalar: (scalars) => _buildScalarList(context, gridSpacing, scalars),
      vector: (vectors) => _buildVectorList(context, gridSpacing, vectors),
      matrix: (matrices) => _buildMatrixList(context, gridSpacing, matrices),
    );
  }

  // --- SCALAR VIEW (List of Cards) ---
  Widget _buildScalarList(
    BuildContext context,
    double gridSpacing,
    List<AnalysisScalar> scalars,
  ) {
    if (scalars.isEmpty) return _buildEmptyState(context, gridSpacing);

    return SingleChildScrollView(
      padding: EdgeInsets.all(gridSpacing * 0.5),
      child: Center(
        child: Wrap(
          spacing: gridSpacing * 0.5,
          runSpacing: gridSpacing * 0.5,
          alignment: WrapAlignment.center,
          children: scalars
              .map((s) => _buildScalarCard(context, gridSpacing, s))
              .toList(),
        ),
      ),
    );
  }

  Widget _buildScalarCard(
    BuildContext context,
    double gridSpacing,
    AnalysisScalar scalar,
  ) {
    return Container(
      padding: EdgeInsets.all(gridSpacing * 0.4),
      decoration: BoxDecoration(
        color: QuanityaPalette.primary.backgroundPrimary,
        borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
        border: Border.all(
          color: QuanityaPalette.primary.textSecondary.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            scalar.label,
            style: context.text.bodySmall?.copyWith(
              color: QuanityaPalette.primary.textSecondary,
            ),
          ),
          VSpace.x025,
          Text(
            _formatValue(scalar.value),
            style: context.text.headlineMedium?.copyWith(
              color: QuanityaPalette.primary.textPrimary,
              fontWeight: FontWeight.bold,
              fontFamily: QuanityaFonts.headerFamily,
            ),
          ),
          if (scalar.unit != null)
            Text(
              scalar.unit!,
              style: context.text.labelSmall?.copyWith(
                color: QuanityaPalette.primary.textSecondary,
              ),
            ),
        ],
      ),
    );
  }

  // --- VECTOR VIEW (List of Charts) ---
  Widget _buildVectorList(
    BuildContext context,
    double gridSpacing,
    List<AnalysisVector> vectors,
  ) {
    if (vectors.isEmpty) return _buildEmptyState(context, gridSpacing);

    return ListView.separated(
      padding: EdgeInsets.all(gridSpacing * 0.5),
      itemCount: vectors.length,
      separatorBuilder: (_, __) => SizedBox(height: gridSpacing),
      itemBuilder: (context, index) {
        final vector = vectors[index];
        final data = vector.values
            .asMap()
            .entries
            .map((e) => {'i': e.key, 'v': e.value})
            .toList();

        return Container(
          height: gridSpacing * 4,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                vector.label,
                style: context.text.bodySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Expanded(
                child: Chart(
                  data: data,
                  variables: {
                    'i': Variable(accessor: (Map map) => map['i'] as num),
                    'v': Variable(accessor: (Map map) => map['v'] as num),
                  },
                  marks: [LineMark()],
                  axes: [Defaults.horizontalAxis, Defaults.verticalAxis],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // --- MATRIX VIEW (List of Matrices) ---
  Widget _buildMatrixList(
    BuildContext context,
    double gridSpacing,
    List<TimeSeriesMatrix> matrices,
  ) {
    if (matrices.isEmpty) return _buildEmptyState(context, gridSpacing);

    return ListView.separated(
      padding: EdgeInsets.all(gridSpacing * 0.5),
      itemCount: matrices.length,
      separatorBuilder: (_, __) => SizedBox(height: gridSpacing),
      itemBuilder: (context, index) {
        final matrix = matrices[index];
        return _buildMatrixCard(context, gridSpacing, matrix);
      },
    );
  }

  Widget _buildMatrixCard(
    BuildContext context,
    double gridSpacing,
    TimeSeriesMatrix matrix,
  ) {
    final colCount = matrix.columnNames.length;
    final rowCount = matrix.data.length;

    return Container(
      padding: EdgeInsets.all(gridSpacing * 0.5),
      decoration: BoxDecoration(
        border: Border.all(
          color: QuanityaPalette.primary.textSecondary.withValues(alpha: 0.2),
        ),
        borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Matrix: ${colCount} cols x ${rowCount} rows",
            style: context.text.bodySmall,
          ),
          SizedBox(height: gridSpacing * 0.2),
          Text(
            "Columns: ${matrix.columnNames.join(', ')}",
            style: context.text.labelSmall,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, double gridSpacing) {
    return Padding(
      padding: EdgeInsets.all(gridSpacing * 0.5),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.hourglass_empty,
              size: gridSpacing * 0.8,
              color: QuanityaPalette.primary.textSecondary,
            ),
            SizedBox(height: gridSpacing * 0.2),
            Text(
              'Waiting for results...',
              style: context.text.bodySmall?.copyWith(
                color: QuanityaPalette.primary.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatValue(double value) {
    if (value.abs() >= 1000) return value.toStringAsFixed(0);
    if (value.abs() >= 10) return value.toStringAsFixed(1);
    return value.toStringAsFixed(2);
  }

  double _calculateHeight(double gridSpacing) {
    if (results == null) return gridSpacing * 6;

    return results!.when(
      scalar: (list) => gridSpacing * 6,
      vector: (list) => gridSpacing * 6 * (list.isNotEmpty ? list.length : 1),
      matrix: (list) => gridSpacing * 6 * (list.isNotEmpty ? list.length : 1),
    );
  }
}
