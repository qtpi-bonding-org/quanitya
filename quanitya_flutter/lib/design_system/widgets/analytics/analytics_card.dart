import 'package:flutter/material.dart';
import '../../primitives/app_sizes.dart';
import '../../primitives/quanitya_palette.dart';
import '../../../support/extensions/context_extensions.dart';

/// Standard analytics card following the zen grid pattern
/// 
/// Uses the standardized 2×5 unit size (2 units tall, 5 units wide)
/// with Quanitya design tokens and simple squircle styling.
class AnalyticsCard extends StatelessWidget {
  final String label;
  final bool isResult;
  
  const AnalyticsCard({
    super.key,
    required this.label,
    this.isResult = false,
  });
  
  @override
  Widget build(BuildContext context) {
    final borderColor = isResult 
        ? QuanityaPalette.primary.interactableColor.withValues(alpha: 0.4)
        : QuanityaPalette.primary.textSecondary.withValues(alpha: 0.2);
    
    final textColor = isResult
        ? QuanityaPalette.primary.interactableColor
        : QuanityaPalette.primary.textPrimary;
    
    return Semantics(
      label: label,
      child: Container(
        decoration: BoxDecoration(
          color: QuanityaPalette.primary.backgroundPrimary,
          border: Border.all(color: borderColor),
          borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: context.text.bodyMedium?.copyWith(color: textColor),
        ),
      ),
    );
  }
}