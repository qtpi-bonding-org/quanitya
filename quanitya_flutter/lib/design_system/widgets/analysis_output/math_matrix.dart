import 'package:flutter/material.dart';

import '../../primitives/app_spacings.dart';
import '../../primitives/app_sizes.dart';
import '../../primitives/quanitya_palette.dart';
import '../../../support/extensions/context_extensions.dart';

/// Math-style matrix with bracket notation.
///
/// Shows first 3 row pairs vertically with ellipsis, label and row count.
class MathMatrix extends StatelessWidget {
  final String label;
  final List<dynamic> data;
  final int rows;
  static const _previewCount = 3;

  const MathMatrix({
    super.key,
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
