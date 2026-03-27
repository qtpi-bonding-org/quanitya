import 'package:flutter/material.dart';

import '../primitives/app_sizes.dart';
import '../primitives/quanitya_palette.dart';
import '../../support/extensions/color_extensions.dart';
import 'template_icon.dart';

/// Circular icon bubble displaying a template's icon, emoji, or fallback.
///
/// Used consistently across schedule items, timeline entries, and results folds.
class TemplateIconBubble extends StatelessWidget {
  final String? iconString;
  final String? emoji;
  final String? accentColorHex;
  final bool isHidden;
  final IconData fallbackIcon;

  const TemplateIconBubble({
    super.key,
    this.iconString,
    this.emoji,
    this.accentColorHex,
    this.isHidden = false,
    this.fallbackIcon = Icons.description,
  });

  @override
  Widget build(BuildContext context) {
    final palette = QuanityaPalette.primary;
    final iconColor = accentColorHex != null
        ? accentColorHex!.toColor()
        : palette.textSecondary;

    return Container(
      width: AppSizes.size36,
      height: AppSizes.size36,
      decoration: BoxDecoration(
        color: isHidden
            ? palette.textPrimary.withValues(alpha: 0.25)
            : Colors.transparent,
        shape: BoxShape.circle,
        border: Border.all(
          color: palette.interactableColor,
          width: AppSizes.borderWidthThick,
        ),
      ),
      alignment: Alignment.center,
      child: TemplateIcon(
        iconString: iconString,
        emoji: emoji,
        size: AppSizes.iconMedium,
        color: iconColor,
        fallbackIcon: fallbackIcon,
      ),
    );
  }
}
