import 'package:flutter/material.dart';

import '../../primitives/app_spacings.dart';
import '../../primitives/app_sizes.dart';
import '../../primitives/quanitya_palette.dart';
import '../../../support/extensions/context_extensions.dart';
import '../../../logic/analysis/enums/scalar_unit.dart';

/// Scalar result card showing label, value, and optional unit.
///
/// Special units (see [ScalarUnit]) are auto-formatted by the card.
/// Any other unit string is displayed as-is below the value.
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
    final special = ScalarUnit.fromKey(unit);

    final displayValue = special != null
        ? special.format(value)
        : value == value.roundToDouble()
            ? value.toInt().toString()
            : value.toStringAsFixed(2);

    final semanticLabel = (special == null && unit != null)
        ? '$label: $displayValue $unit'
        : '$label: $displayValue';

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
            Text(
              displayValue,
              style: context.text.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: palette.textPrimary,
              ),
            ),
            if (special == null && unit != null)
              Text(
                unit!,
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
