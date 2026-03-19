import 'package:flutter/material.dart';
import '../primitives/app_sizes.dart';
import '../primitives/quanitya_palette.dart';

/// Clean icon button with variable visual size but consistent 48px touch target.
/// 
/// Design principles:
/// - No floating elements
/// - No cards or containers
/// - Clean, minimal appearance
/// - Accessible touch target (48px minimum)
/// 
/// Color logic:
/// - Default: interactableColor (teal) - "tap me" signal
/// - Destructive: destructiveColor (red) - danger signal
/// - Disabled: textSecondary (gray)
/// - Custom: use `color` parameter to override
class QuanityaIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final double iconSize;
  final Color? color;
  final bool isDestructive;
  final String? tooltip;
  final EdgeInsetsGeometry? padding;

  const QuanityaIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.iconSize = 24.0,
    this.color,
    this.isDestructive = false,
    this.tooltip,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final palette = QuanityaPalette.primary;
    
    // Color priority: custom > destructive > interactable > disabled
    final Color effectiveColor;
    if (onPressed == null) {
      effectiveColor = palette.textSecondary.withValues(alpha: 0.38);
    } else if (color != null) {
      effectiveColor = color!;
    } else if (isDestructive) {
      effectiveColor = palette.destructiveColor;
    } else {
      effectiveColor = palette.interactableColor;
    }

    Widget button = SizedBox(
      width: AppSizes.buttonHeight, // 48px touch target
      height: AppSizes.buttonHeight,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(AppSizes.buttonHeight / 2),
          child: Padding(
            padding: padding ?? EdgeInsets.all((AppSizes.buttonHeight - iconSize) / 2),
            child: Icon(
              icon,
              size: iconSize,
              color: effectiveColor,
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
      label: tooltip,
      child: button,
    );
  }
}

/// Convenience constructors for common sizes
extension QuanityaIconButtonSizes on QuanityaIconButton {
  /// Small icon (18px visual, 48px touch)
  static QuanityaIconButton small({
    required IconData icon,
    required VoidCallback? onPressed,
    Color? color,
    bool isDestructive = false,
    String? tooltip,
  }) {
    return QuanityaIconButton(
      icon: icon,
      onPressed: onPressed,
      iconSize: AppSizes.iconSmall,
      color: color,
      isDestructive: isDestructive,
      tooltip: tooltip,
    );
  }

  /// Medium icon (22px visual, 48px touch)
  static QuanityaIconButton medium({
    required IconData icon,
    required VoidCallback? onPressed,
    Color? color,
    bool isDestructive = false,
    String? tooltip,
  }) {
    return QuanityaIconButton(
      icon: icon,
      onPressed: onPressed,
      iconSize: AppSizes.iconSmall * 1.25, // 20px
      color: color,
      isDestructive: isDestructive,
      tooltip: tooltip,
    );
  }

  /// Large icon (32px visual, 48px touch)
  static QuanityaIconButton large({
    required IconData icon,
    required VoidCallback? onPressed,
    Color? color,
    bool isDestructive = false,
    String? tooltip,
  }) {
    return QuanityaIconButton(
      icon: icon,
      onPressed: onPressed,
      iconSize: AppSizes.iconLarge,
      color: color,
      isDestructive: isDestructive,
      tooltip: tooltip,
    );
  }
}