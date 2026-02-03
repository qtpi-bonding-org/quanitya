import 'package:flutter/material.dart';
import 'package:flutter_color_palette/flutter_color_palette.dart';
import 'package:injectable/injectable.dart';

import '../engine/page_configuration.dart';
import 'template_aesthetics.dart';
import 'tracker_template.dart';

/// Converts DB storage models → runtime UI models.
///
/// Centralizes all model conversion logic in one place instead of
/// scattering it across extensions. Makes the coupling explicit and testable.
///
/// Data flow:
/// ```
/// DB Models (storage)                      →  Runtime Models (UI)
/// ─────────────────────────────────────────────────────────────────
/// TrackerTemplateModel + Aesthetics        →  PageTemplateConfig
/// ColorPaletteData                         →  AppColorPalette
/// FontConfigData                           →  FontsConfig
/// ColorPaletteData + slot                  →  Color
/// Aesthetics + uiElement                   →  Map&lt;String, Color&gt;
/// ```
@injectable
class ModelRuntimeConverter {
  /// Convert DB models → runtime PageTemplateConfig.
  ///
  /// Combines template name with aesthetics icon.
  /// Priority: icon → emoji → default
  PageTemplateConfig toPageConfig(
    TrackerTemplateModel template,
    TemplateAestheticsModel aesthetics,
  ) {
    return PageTemplateConfig(
      title: template.name,
      iconEmoji: aesthetics.emoji ?? '📝', // Use emoji field for PageTemplateConfig
    );
  }

  /// Convert DB palette → runtime AppColorPalette.
  ///
  /// Maps accent/tone colors to the enumerated color slots:
  /// - accents → colors (color1, color2, etc.)
  /// - tones → neutrals (neutral1, neutral2, etc.)
  AppColorPalette toColorPalette(ColorPaletteData palette) {
    return AppColorPalette.enumerated(
      colors: palette.accents.map(_hexToColor).toList(),
      neutrals: palette.tones.map(_hexToColor).toList(),
    );
  }

  /// Convert DB font config → runtime FontsConfig.
  FontsConfig toFontsConfig(FontConfigData fontConfig) {
    return FontsConfig(
      titleFontFamily: fontConfig.titleFontFamily,
      subtitleFontFamily: fontConfig.subtitleFontFamily,
      bodyFontFamily: fontConfig.bodyFontFamily,
      titleWeight: fontConfig.titleWeight,
      subtitleWeight: fontConfig.subtitleWeight,
      bodyWeight: fontConfig.bodyWeight,
    );
  }

  /// Resolve a color slot reference to a Flutter Color.
  ///
  /// [palette] - The color palette data
  /// [slot] - Color slot name (e.g., "color1", "neutral2")
  /// Returns the resolved Color, or null if slot not found.
  Color? resolveColor(ColorPaletteData palette, String slot) {
    final hex = palette.getColor(slot);
    if (hex == null) return null;
    return _hexToColor(hex);
  }

  /// Resolve widget color configuration to Flutter Colors.
  ///
  /// [aesthetics] - The aesthetics model with color mappings
  /// [uiElement] - UI element name (e.g., "slider", "stepper", "textField")
  /// Returns a map of color role → Color, or null if no mapping exists.
  Map<String, Color>? resolveWidgetColors(
    TemplateAestheticsModel aesthetics,
    String uiElement,
  ) {
    final mapping = aesthetics.colorMappings[uiElement];
    if (mapping == null) return null;

    final resolved = <String, Color>{};
    for (final entry in mapping.entries) {
      final color = resolveColor(aesthetics.palette, entry.value);
      if (color != null) {
        resolved[entry.key] = color;
      }
    }
    return resolved.isEmpty ? null : resolved;
  }

  /// Converts a hex string (e.g., "#1976D2") to a Flutter Color.
  Color _hexToColor(String hex) {
    final cleanHex = hex.replaceFirst('#', '');
    return Color(int.parse(cleanHex, radix: 16) + 0xFF000000);
  }
}
