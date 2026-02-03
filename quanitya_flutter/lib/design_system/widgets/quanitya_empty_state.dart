import 'package:flutter/material.dart';
import '../primitives/app_sizes.dart';
import '../primitives/quanitya_palette.dart';
import '../../support/extensions/context_extensions.dart';

/// A watermark-style empty state widget showing the Quanitya logo.
/// Use this when a list or section has no content.
class QuanityaEmptyState extends StatelessWidget {
  final double? size;
  final double opacity;

  const QuanityaEmptyState({
    super.key,
    this.size,
    this.opacity = 0.35,
  });

  @override
  Widget build(BuildContext context) {
    final logoSize = size ?? AppSizes.iconXLarge * 3;
    
    return Center(
      child: Image.asset(
        'assets/quanitya.png',
        width: logoSize,
        height: logoSize,
        color: context.colors.textSecondary.withValues(alpha: opacity),
      ),
    );
  }
}
