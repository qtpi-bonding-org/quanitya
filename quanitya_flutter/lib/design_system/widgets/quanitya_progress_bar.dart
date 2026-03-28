import 'package:flutter/material.dart';
import '../primitives/app_sizes.dart';
import '../primitives/quanitya_palette.dart';

/// A simple black-filled progress bar using design system tokens.
class QuanityaProgressBar extends StatelessWidget {
  /// Progress value from 0.0 to 1.0.
  final double progress;

  const QuanityaProgressBar({super.key, required this.progress});

  @override
  Widget build(BuildContext context) {
    final palette = QuanityaPalette.primary;

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
      child: SizedBox(
        height: AppSizes.space,
        child: LinearProgressIndicator(
          value: progress.clamp(0.0, 1.0),
          backgroundColor: palette.textSecondary.withValues(alpha: 0.2),
          valueColor: AlwaysStoppedAnimation<Color>(palette.textPrimary),
        ),
      ),
    );
  }
}
