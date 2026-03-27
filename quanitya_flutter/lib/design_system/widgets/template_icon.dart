import 'package:flutter/material.dart';

import '../../support/utils/icon_resolver.dart';

/// Renders a template's visual identity: icon, emoji, or fallback.
///
/// Priority: icon (material) → emoji → fallback icon.
/// No container or decoration — just the content.
/// Wrap in your own Container/Circle as needed.
class TemplateIcon extends StatelessWidget {
  final String? iconString;
  final String? emoji;
  final double size;
  final Color? color;
  final IconData fallbackIcon;

  const TemplateIcon({
    super.key,
    this.iconString,
    this.emoji,
    required this.size,
    this.color,
    this.fallbackIcon = Icons.description,
  });

  /// Create from aesthetics model fields directly.
  const TemplateIcon.fromAesthetics({
    super.key,
    this.iconString,
    this.emoji,
    required this.size,
    this.color,
    this.fallbackIcon = Icons.description,
  });

  @override
  Widget build(BuildContext context) {
    // 1. Icon (material:icon_name format)
    if (iconString != null && iconString!.contains(':')) {
      final iconData = IconResolver.resolve(iconString);
      if (iconData != null) {
        return Icon(iconData, size: size, color: color);
      }
    }

    // 2. Emoji
    if (emoji != null && emoji!.isNotEmpty) {
      return Text(emoji!, style: TextStyle(fontSize: size));
    }

    // 3. Fallback
    return Icon(fallbackIcon, size: size, color: color);
  }
}
