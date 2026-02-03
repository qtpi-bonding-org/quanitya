import 'package:flutter/material.dart';

/// Interface for validating WCAG AA compliance during widget creation.
/// 
/// This validator ensures that all color combinations in generated widgets
/// meet accessibility standards before the widgets are rendered.
abstract class IWcagComplianceValidator {
  /// Validates that a color combination meets WCAG AA standards.
  /// 
  /// Returns true if the combination passes, false otherwise.
  bool validateColorCombination(Color foreground, Color background);
  
  /// Gets the contrast ratio between two colors.
  /// 
  /// Returns a value where 4.5:1 or higher passes WCAG AA for text,
  /// and 3.0:1 or higher passes for interactive elements.
  double getContrastRatio(Color foreground, Color background);
  
  /// Validates all color combinations for a widget context.
  /// 
  /// Checks all required color role combinations based on widget type.
  /// Returns a list of validation failures, empty if all pass.
  List<WcagValidationFailure> validateWidgetColors(
    Map<String, Color> resolvedColors,
    String uiElementType,
  );
  
  /// Suggests color adjustments to meet WCAG AA compliance.
  /// 
  /// Returns adjusted colors that maintain hue but modify luminance
  /// to achieve required contrast ratios.
  Map<String, Color> suggestCompliantColors(
    Map<String, Color> originalColors,
    String uiElementType,
  );
}

/// Represents a WCAG compliance validation failure.
class WcagValidationFailure {
  final String foregroundRole;
  final String backgroundRole;
  final double actualRatio;
  final double requiredRatio;
  final String message;
  
  const WcagValidationFailure({
    required this.foregroundRole,
    required this.backgroundRole,
    required this.actualRatio,
    required this.requiredRatio,
    required this.message,
  });
  
  @override
  String toString() {
    return 'WCAG Failure: $message (${actualRatio.toStringAsFixed(2)}:1, required ${requiredRatio.toStringAsFixed(2)}:1)';
  }
}