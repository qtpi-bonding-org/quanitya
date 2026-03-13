import 'package:flutter/material.dart';
import '../../../primitives/quanitya_palette.dart';
import '../../../primitives/app_sizes.dart';

/// Tappable emoji with teal shadow to indicate interactivity.
///
/// Use for template icons, category selectors, etc.
/// Shadow provides affordance without changing the emoji itself.
///
/// - Default: Teal shadow - "tap me" signal
/// - Destructive: Red shadow - danger signal
/// - Disabled: No shadow
class QuanityaEmojiButton extends StatelessWidget {
  final String emoji;
  final VoidCallback? onPressed;
  final double size;
  final bool isDestructive;
  final String? tooltip;

  const QuanityaEmojiButton({
    super.key,
    required this.emoji,
    required this.onPressed,
    this.size = 32.0,
    this.isDestructive = false,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final palette = QuanityaPalette.primary;
    final shadowColor = isDestructive
        ? palette.destructiveColor
        : palette.interactableColor;

    Widget button = GestureDetector(
      onTap: onPressed,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: AppSizes.buttonHeight, // 48px touch target
        height: AppSizes.buttonHeight,
        child: Center(
          child: Text(
            emoji,
            style: TextStyle(
              fontSize: size,
              shadows: onPressed != null
                  ? [
                      Shadow(
                        color: shadowColor.withValues(alpha: 0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
          ),
        ),
      ),
    );

    if (tooltip != null) {
      button = Tooltip(
        message: tooltip!,
        child: button,
      );
    }

    return Semantics(
      button: true,
      label: tooltip ?? emoji,
      child: button,
    );
  }
}
