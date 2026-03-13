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
  final Widget? action;

  const PostItToast({
    super.key,
    required this.message,
    required this.type,
    this.action,
  });

  /// Show a PostItToast via ScaffoldMessenger as a floating, styled SnackBar.
  static void show(
    BuildContext context, {
    required String message,
    PostItType type = PostItType.info,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: PostItToast(message: message, type: type),
        backgroundColor: Colors.transparent,
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        padding: EdgeInsets.zero,
        duration: type == PostItType.error
            ? const Duration(seconds: 5)
            : const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = QuanityaPalette.primary;

    return Semantics(
      liveRegion: true,
      label: message,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 280),
        decoration: BoxDecoration(
          color: _colorForType(type),
          // NO borderRadius - sharp corners like real post-its!
          boxShadow: [
            BoxShadow(
              color: QuanityaPalette.primary.textPrimary.withValues(alpha: 0.15),
              offset: const Offset(2, 3),
              blurRadius: 4,
            ),
          ],
        ),
        padding: EdgeInsets.symmetric(
          horizontal: AppSizes.space * 1.5,
          vertical: AppSizes.space,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: QuanityaFonts.headerFamily,
                fontSize: AppSizes.fontSmall,
                fontWeight: FontWeight.w500,
                color: palette.textPrimary,
              ),
            ),
            if (action != null) ...[
              SizedBox(height: AppSizes.space * 0.5),
              action!,
            ],
          ],
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
