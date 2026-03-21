import 'package:flutter/material.dart';

import '../../../design_system/primitives/app_sizes.dart';
import '../../../design_system/primitives/app_spacings.dart';
import '../../../design_system/primitives/quanitya_palette.dart';
import '../../../support/extensions/context_extensions.dart';

/// A read-only gallery card for community template browsing.
///
/// Simplified version of [TrackerCard] — shows emoji + name only,
/// with a teal checkmark overlay when selected. No action buttons.
class GalleryCard extends StatelessWidget {
  final String emoji;
  final String name;
  final bool isSelected;
  final VoidCallback? onTap;

  const GalleryCard({
    super.key,
    required this.emoji,
    required this.name,
    this.isSelected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final palette = QuanityaPalette.primary;

    return Semantics(
      button: true,
      label: name,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 1. Emoji with optional selection overlay
            Center(
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Text(
                    emoji,
                    style: TextStyle(fontSize: AppSizes.iconXLarge),
                  ),
                  if (isSelected)
                    Positioned(
                      top: -2,
                      right: -6,
                      child: Icon(
                        Icons.check_circle,
                        size: AppSizes.iconMedium,
                        color: palette.interactableColor,
                      ),
                    ),
                ],
              ),
            ),

            VSpace.x05,

            // 2. Name (uppercase, spaced lettering)
            Padding(
              padding: AppPadding.horizontalSingle,
              child: Text(
                name.toUpperCase(),
                style: context.text.labelSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.1,
                  color: isSelected
                      ? palette.interactableColor
                      : context.colors.textPrimary,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            VSpace.x1,
          ],
        ),
      ),
    );
  }
}
