import 'package:flutter/material.dart';
import '../../../primitives/quanitya_palette.dart';
import '../../../primitives/quanitya_fonts.dart';
import '../../../primitives/app_sizes.dart';

/// Toast type for color mapping
enum PostItType { info, success, error, warning }

/// Post-it note styled toast that matches the manuscript aesthetic.
///
/// Features:
/// - Sharp corners (real post-its have crisp edges)
/// - Subtle shadow
/// - Atkinson Hyperlegible font
/// - No border/outline
/// - Tap or swipe to dismiss
class PostItToast extends StatelessWidget {
  final String message;
  final PostItType type;

  const PostItToast({
    super.key,
    required this.message,
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    final palette = QuanityaPalette.primary;

    return Container(
      constraints: const BoxConstraints(maxWidth: 280),
      decoration: BoxDecoration(
        color: _colorForType(type),
        // NO borderRadius - sharp corners like real post-its!
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            offset: const Offset(2, 3),
            blurRadius: 4,
          ),
        ],
      ),
      padding: EdgeInsets.symmetric(
        horizontal: AppSizes.space * 1.5,
        vertical: AppSizes.space,
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontFamily: QuanityaFonts.headerFamily,
          fontSize: AppSizes.fontSmall,
          fontWeight: FontWeight.w500,
          color: palette.textPrimary,
        ),
      ),
    );
  }

  Color _colorForType(PostItType type) {
    final palette = QuanityaPalette.primary;
    return switch (type) {
      PostItType.info => palette.infoColor,
      PostItType.success => palette.successColor,
      PostItType.error => palette.errorColor,
      PostItType.warning => palette.warningColor,
    };
  }
}
