import 'package:flutter/material.dart';

import '../../primitives/app_spacings.dart';
import '../../primitives/app_sizes.dart';
import '../../primitives/quanitya_palette.dart';
import '../../../support/extensions/context_extensions.dart';

/// Scalar result card showing label, value, and optional unit.
class ScalarCard extends StatelessWidget {
  final String label;
  final double value;
  final String? unit;

  const ScalarCard({
    super.key,
    required this.label,
    required this.value,
    this.unit,
  });

  @override
  Widget build(BuildContext context) {
    final palette = QuanityaPalette.primary;
    final semanticLabel = unit != null
        ? '$label: ${value.toStringAsFixed(2)} $unit'
        : '$label: ${value.toStringAsFixed(2)}';

    return Semantics(
      label: semanticLabel,
      child: Container(
        padding: AppPadding.allDouble,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: context.text.bodySmall?.copyWith(
                color: palette.textSecondary,
              ),
            ),
            VSpace.x05,
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value.toStringAsFixed(2),
                  style: context.text.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: palette.textPrimary,
                  ),
                ),
                if (unit != null) ...[
                  HSpace.x05,
                  Text(
                    unit!,
                    style: context.text.bodyMedium?.copyWith(
                      color: palette.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
