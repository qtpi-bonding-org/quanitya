import 'package:flutter/material.dart';

import '../primitives/app_sizes.dart';
import '../primitives/quanitya_palette.dart';
import '../../support/extensions/color_extensions.dart';
import '../../support/utils/icon_resolver.dart';

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
      child: _buildContent(),
    );
  }

  Widget _buildContent() {
    final iconColor = accentColorHex != null
        ? accentColorHex!.toColor()
        : QuanityaPalette.primary.textSecondary;

    // Priority: icon > emoji > fallback
    if (iconString != null && iconString!.contains(':')) {
      final iconData = IconResolver.resolve(iconString);
      if (iconData != null) {
        return Icon(iconData, size: AppSizes.iconMedium, color: iconColor);
      }
    }

    if (emoji != null && emoji!.isNotEmpty) {
      return Text(emoji!, style: TextStyle(fontSize: AppSizes.iconMedium));
    }

    return Icon(fallbackIcon, size: AppSizes.iconMedium, color: iconColor);
  }
}
