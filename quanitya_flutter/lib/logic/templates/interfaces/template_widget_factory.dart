import 'package:flutter/widgets.dart';
import '../models/engine/widget_rendering_context.dart';

/// Interface for creating widgets from AI-generated atomic field decisions.
///
/// This factory consumes parsed atomic field decisions (field type + UI element + validation)
/// and creates appropriate Flutter widgets with dynamic color application.
abstract class ITemplateWidgetFactory {
  /// Creates a widget from the given rendering context.
  ///
  /// The context contains:
  /// - Atomic field decision (fieldType + uiElement + validation)
  /// - AI color mappings resolved to actual colors
  /// - WCAG AA compliance validation results
  ///
  /// Returns a configured Flutter widget ready for form rendering.
  Widget createWidget(WidgetRenderingContext context);

  /// Validates that the factory can handle the given UI element type.
  ///
  /// Returns true if this factory has a builder for the specified UI element.
  bool canHandle(String uiElementName);

  /// Gets the list of UI element types this factory can create widgets for.
  List<String> getSupportedUiElements();
}
