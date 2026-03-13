import 'package:flutter/material.dart';

import '../../primitives/app_spacings.dart';
import '../../primitives/app_sizes.dart';
import '../../primitives/quanitya_palette.dart';
import '../../../support/extensions/context_extensions.dart';

/// Math-style vertical vector with bracket notation.
///
/// Shows first 3 values + vertical ellipsis, with label and count.
class MathVector extends StatelessWidget {
  final String label;
  final List<double> values;
  static const _previewCount = 3;

  const MathVector({super.key, required this.label, required this.values});

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
