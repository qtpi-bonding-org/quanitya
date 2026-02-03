import 'package:flutter/material.dart';
import '../primitives/app_spacings.dart';
import '../primitives/app_sizes.dart';
import '../primitives/quanitya_palette.dart';

/// A tappable group container following the manuscript aesthetic.
/// 
/// When tappable (onTap provided):
/// - Shows optional chevron in interactableColor to signal "tap me"
/// - Provides ripple feedback on tap
/// 
/// Use `showChevron: true` for navigation items (lists, cards that go somewhere).
class QuanityaGroup extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsets? padding;
  final bool showChevron; // Show teal chevron to indicate tappable

  const QuanityaGroup({
    super.key,
    required this.child,
    this.onTap,
    this.padding,
    this.showChevron = false,
  });

  @override
  Widget build(BuildContext context) {
    final palette = QuanityaPalette.primary;
    final effectivePadding = padding ?? AppPadding.listItem;

    // If it's clickable, use InkWell for the ripple (feedback is necessary)
    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        splashColor: palette.textSecondary.withValues(alpha: 0.1),
        child: Padding(
          padding: effectivePadding,
          child: showChevron
              ? Row(
                  children: [
                    Expanded(child: child),
                    HSpace.x1,
                    Icon(
                      Icons.chevron_right,
                      size: AppSizes.size20,
                      color: palette.interactableColor,
                    ),
                  ],
                )
              : child,
        ),
      );
    }

    // Otherwise, just a padding wrapper
    return Padding(
      padding: effectivePadding,
      child: child,
    );
  }
}
