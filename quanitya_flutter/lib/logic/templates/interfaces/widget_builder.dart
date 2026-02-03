import 'package:flutter/widgets.dart';
import '../models/engine/widget_rendering_context.dart';

/// Base interface for building specific UI element types from atomic field decisions.
///
/// Each UI element type (slider, textField, chips, etc.) has its own builder
/// that knows how to create and configure that specific widget type.
abstract class IWidgetBuilder {
  /// The UI element type this builder handles (matches UiElementEnum values)
  String get uiElementType;

  /// Creates a widget from the rendering context.
  ///
  /// The context contains all atomic field decision data:
  /// - Field type and UI element choice
  /// - Tightly coupled validation properties (min/max for sliders, options for chips)
  /// - Resolved colors with WCAG AA compliance
  /// - Current value and change handlers
  Widget buildWidget(WidgetRenderingContext context);

  /// Validates that this builder can handle the given context.
  ///
  /// Checks that:
  /// - UI element type matches
  /// - Required validation properties are present
  /// - Color mappings are complete
  bool canBuild(WidgetRenderingContext context);

  /// Gets the color roles required by this widget type.
  ///
  /// This should match the WidgetColorRoles mapping for consistency.
  /// Example: slider needs [primary, secondary, text]
  List<String> getRequiredColorRoles();
}
