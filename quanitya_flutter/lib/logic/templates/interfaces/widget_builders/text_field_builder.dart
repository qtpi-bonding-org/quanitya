import 'package:flutter/material.dart';
import '../widget_builder.dart';
import '../../models/engine/widget_rendering_context.dart';
import '../../enums/field_enum.dart';

/// Interface for building text field widgets from atomic field decisions.
/// 
/// Handles TextFieldProfile: TextField + Pattern/Length validation (tightly coupled)
/// Can be used for text fields or numeric text input.
abstract class ITextFieldBuilder extends IWidgetBuilder {
  @override
  String get uiElementType => 'textField';
  
  @override
  List<String> getRequiredColorRoles() => ['background', 'border', 'text'];
  
  /// Validates that the context has appropriate text field properties.
  /// 
  /// Checks for:
  /// - Compatible field type (text, integer, float)
  /// - Optional validation properties (pattern, length, min/max for numeric)
  /// - Required color roles (background, border, text)
  bool validateTextFieldProperties(WidgetRenderingContext context) {
    // Check field type compatibility
    final fieldType = context.field.type;
    final validTypes = [FieldEnum.text, FieldEnum.integer, FieldEnum.float];
    if (!validTypes.contains(fieldType)) return false;
    
    // Check required colors
    for (final role in getRequiredColorRoles()) {
      if (!context.resolvedColors.containsKey(role)) return false;
    }
    
    return true;
  }
  
  /// Determines input type based on field type
  TextInputType getInputType(String fieldType) {
    return switch (fieldType) {
      'integer' => TextInputType.number,
      'float' => const TextInputType.numberWithOptions(decimal: true),
      'text' => TextInputType.text,
      _ => TextInputType.text,
    };
  }
}