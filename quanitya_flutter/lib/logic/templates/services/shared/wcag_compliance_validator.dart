import 'package:flutter/material.dart';
import 'package:flutter_color_palette/flutter_color_palette.dart';
import 'package:injectable/injectable.dart';

import '../../interfaces/wcag_compliance_validator.dart';

/// WCAG AA compliance validator with mathematical color adjustment.
///
/// Uses direct calculation (not iteration) to find compliant colors.
/// Three-phase adjustment: Lightness → Saturation → Hue (preserves as much as possible).
///
/// Fixed background: Washi White (#FAF7F0) - the zen constant.
@lazySingleton
class WcagComplianceValidatorImpl implements IWcagComplianceValidator {
  /// Washi White - the fixed zen background (#FAF7F0)
  /// Intentionally hardcoded as a constant for WCAG contrast calculations.
  /// This matches QuanityaPalette.primary.backgroundPrimary but is kept
  /// as a static constant for performance in contrast ratio computations.
  static const Color washiWhite = Color(0xFFFAF7F0);

  /// WCAG AA minimum contrast ratios
  static const double textContrastRatio = 4.5;
  static const double interactiveContrastRatio = 3.0;

  @override
  bool validateColorCombination(Color foreground, Color background) {
    return ContrastCalculator.meetsWCAG(foreground, background);
  }

  @override
  double getContrastRatio(Color foreground, Color background) {
    return ContrastCalculator.contrastRatio(foreground, background);
  }

  @override
  List<WcagValidationFailure> validateWidgetColors(
    Map<String, Color> resolvedColors,
    String uiElementType,
  ) {
    final failures = <WcagValidationFailure>[];
    final requirements = _getContrastRequirements(uiElementType);

    for (final req in requirements) {
      final fgColor = resolvedColors[req.foregroundRole];
      final bgColor = resolvedColors[req.backgroundRole] ?? washiWhite;

      if (fgColor == null) continue;

      final ratio = getContrastRatio(fgColor, bgColor);
      if (ratio < req.requiredRatio) {
        failures.add(
          WcagValidationFailure(
            foregroundRole: req.foregroundRole,
            backgroundRole: req.backgroundRole,
            actualRatio: ratio,
            requiredRatio: req.requiredRatio,
            message:
                '${req.foregroundRole} on ${req.backgroundRole} fails WCAG AA',
          ),
        );
      }
    }

    return failures;
  }

  @override
  Map<String, Color> suggestCompliantColors(
    Map<String, Color> originalColors,
    String uiElementType,
  ) {
    final adjusted = Map<String, Color>.from(originalColors);
    final requirements = _getContrastRequirements(uiElementType);

    for (final req in requirements) {
      final fgColor = adjusted[req.foregroundRole];
      final bgColor = adjusted[req.backgroundRole] ?? washiWhite;

      if (fgColor == null) continue;

      final ratio = getContrastRatio(fgColor, bgColor);
      if (ratio < req.requiredRatio) {
        adjusted[req.foregroundRole] = adjustForContrast(
          fgColor,
          bgColor,
          req.requiredRatio,
        );
      }
    }

    return adjusted;
  }

  /// Validates a single color against Washi White background.
  ///
  /// Returns the accessibility grade: 'AAA', 'AA', 'AA Large', or 'Fail'
  String validateAgainstBackground(Color color) {
    return ContrastCalculator.getAccessibilityGrade(color, washiWhite);
  }

  /// Adjusts a color to meet WCAG AA against Washi White.
  ///
  /// Returns the original color if already compliant, or an adjusted version.
  /// Set [isText] to true for 4.5:1 ratio, false for 3:1 (interactive elements).
  Color adjustForWashiWhite(Color color, {bool isText = true}) {
    final requiredRatio = isText ? textContrastRatio : interactiveContrastRatio;
    final currentRatio = getContrastRatio(color, washiWhite);

    if (currentRatio >= requiredRatio) {
      return color;
    }

    return adjustForContrast(color, washiWhite, requiredRatio);
  }

  /// Adjusts foreground color to meet target contrast ratio against background.
  ///
  /// Three-phase algorithm (preserves as much of original color as possible):
  /// 1. Adjust lightness only (preserves hue + saturation)
  /// 2. If lightness alone fails, reduce saturation (preserves hue)
  /// 3. If still fails, shift hue (last resort)
  ///
  /// Uses direct mathematical calculation, not iteration.
  Color adjustForContrast(
    Color foreground,
    Color background,
    double targetRatio,
  ) {
    final bgLuminance = background.computeLuminance();
    final fgHsl = HSLColor.fromColor(foreground);

    // Phase 1: Try adjusting lightness only
    final phase1Result = _adjustLightnessForContrast(
      fgHsl,
      bgLuminance,
      targetRatio,
    );
    if (phase1Result != null) {
      return phase1Result.toColor();
    }

    // Phase 2: Reduce saturation (moves toward grey, increases contrast potential)
    final phase2Result = _adjustSaturationForContrast(
      fgHsl,
      bgLuminance,
      targetRatio,
    );
    if (phase2Result != null) {
      return phase2Result.toColor();
    }

    // Phase 3: Shift hue (last resort - find most contrasting hue)
    return _adjustHueForContrast(fgHsl, bgLuminance, targetRatio).toColor();
  }

  /// Phase 1: Adjust lightness to meet contrast.
  ///
  /// Calculates required luminance directly from WCAG formula, then
  /// finds the lightness value that produces that luminance.
  HSLColor? _adjustLightnessForContrast(
    HSLColor color,
    double bgLuminance,
    double targetRatio,
  ) {
    final requiredLuminance = _calculateRequiredLuminance(
      bgLuminance,
      targetRatio,
    );

    // Check if required luminance is achievable (0-1 range)
    if (requiredLuminance < 0 || requiredLuminance > 1) {
      return null; // Can't achieve with lightness alone
    }

    // Find lightness that produces required luminance
    // This requires solving: luminance(hsl_to_rgb(h, s, L)) = requiredLuminance
    // We use binary search since the relationship isn't linear
    final targetLightness = _findLightnessForLuminance(
      color.hue,
      color.saturation,
      requiredLuminance,
    );

    if (targetLightness == null) {
      return null;
    }

    return color.withLightness(targetLightness);
  }

  /// Phase 2: Reduce saturation to increase contrast potential.
  ///
  /// Lower saturation → closer to grey → more contrast achievable.
  HSLColor? _adjustSaturationForContrast(
    HSLColor color,
    double bgLuminance,
    double targetRatio,
  ) {
    // Try reducing saturation in steps
    for (var sat = color.saturation; sat >= 0; sat -= 0.1) {
      final testColor = color.withSaturation(sat.clamp(0.0, 1.0));
      final phase1Result = _adjustLightnessForContrast(
        testColor,
        bgLuminance,
        targetRatio,
      );
      if (phase1Result != null) {
        return phase1Result;
      }
    }

    // Try with zero saturation (pure grey)
    final greyColor = color.withSaturation(0);
    return _adjustLightnessForContrast(greyColor, bgLuminance, targetRatio);
  }

  /// Phase 3: Shift hue to find a contrasting color.
  ///
  /// Last resort - tries to find any hue that can meet contrast.
  HSLColor _adjustHueForContrast(
    HSLColor color,
    double bgLuminance,
    double targetRatio,
  ) {
    // For light backgrounds, we need dark colors → low lightness
    // For dark backgrounds, we need light colors → high lightness
    final targetLightness = bgLuminance > 0.5 ? 0.0 : 1.0;

    // Pure black or white will always have maximum contrast
    return HSLColor.fromAHSL(
      color.alpha,
      color.hue, // Keep original hue
      0.0, // Zero saturation
      targetLightness,
    );
  }

  /// Calculates the required foreground luminance to achieve target contrast.
  ///
  /// WCAG formula: contrast = (L_lighter + 0.05) / (L_darker + 0.05)
  double _calculateRequiredLuminance(double bgLuminance, double targetRatio) {
    if (bgLuminance > 0.5) {
      // Light background → need darker foreground
      // targetRatio = (bgLuminance + 0.05) / (fgLuminance + 0.05)
      // fgLuminance = (bgLuminance + 0.05) / targetRatio - 0.05
      return (bgLuminance + 0.05) / targetRatio - 0.05;
    } else {
      // Dark background → need lighter foreground
      // targetRatio = (fgLuminance + 0.05) / (bgLuminance + 0.05)
      // fgLuminance = targetRatio * (bgLuminance + 0.05) - 0.05
      return targetRatio * (bgLuminance + 0.05) - 0.05;
    }
  }

  /// Finds the HSL lightness value that produces the target luminance.
  ///
  /// Uses binary search since luminance is monotonic with lightness
  /// but the relationship isn't linear (due to gamma correction).
  double? _findLightnessForLuminance(
    double hue,
    double saturation,
    double targetLuminance,
  ) {
    const tolerance = 0.001;
    const maxIterations = 20; // Binary search converges fast

    var low = 0.0;
    var high = 1.0;

    for (var i = 0; i < maxIterations; i++) {
      final mid = (low + high) / 2;
      final testColor = HSLColor.fromAHSL(1.0, hue, saturation, mid).toColor();
      final testLuminance = testColor.computeLuminance();

      if ((testLuminance - targetLuminance).abs() < tolerance) {
        return mid;
      }

      if (testLuminance < targetLuminance) {
        low = mid;
      } else {
        high = mid;
      }
    }

    // Check if we got close enough
    final finalColor = HSLColor.fromAHSL(
      1.0,
      hue,
      saturation,
      (low + high) / 2,
    ).toColor();
    final finalLuminance = finalColor.computeLuminance();

    if ((finalLuminance - targetLuminance).abs() < 0.01) {
      return (low + high) / 2;
    }

    return null; // Couldn't achieve target luminance
  }

  /// Gets contrast requirements for a specific UI element type.
  List<_ContrastRequirement> _getContrastRequirements(String uiElementType) {
    // Text-heavy elements need 4.5:1
    const textElements = {'textField', 'textArea', 'dropdown', 'searchField'};

    // Interactive elements can use 3:1
    const interactiveElements = {
      'slider',
      'stepper',
      'checkbox',
      'toggleSwitch',
      'radio',
      'chips',
    };

    final isTextElement = textElements.contains(uiElementType);
    final ratio = isTextElement ? textContrastRatio : interactiveContrastRatio;

    return [
      _ContrastRequirement('labelColor', 'background', textContrastRatio),
      _ContrastRequirement('valueColor', 'background', textContrastRatio),
      if (interactiveElements.contains(uiElementType))
        _ContrastRequirement('activeColor', 'background', ratio),
      if (interactiveElements.contains(uiElementType))
        _ContrastRequirement('inactiveColor', 'background', ratio),
    ];
  }
}

/// Internal class for contrast requirements.
class _ContrastRequirement {
  final String foregroundRole;
  final String backgroundRole;
  final double requiredRatio;

  const _ContrastRequirement(
    this.foregroundRole,
    this.backgroundRole,
    this.requiredRatio,
  );
}
