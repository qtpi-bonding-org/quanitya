import '../widget_builder.dart';
import '../../models/engine/widget_rendering_context.dart';
import '../../enums/field_enum.dart';

/// Interface for building slider widgets from atomic field decisions.
/// 
/// Handles SliderProfile: Slider + Min/Max/Step validation (tightly coupled)
/// Required for integer/float fields with slider UI element choice.
abstract class ISliderBuilder extends IWidgetBuilder {
  @override
  String get uiElementType => 'slider';
  
  @override
  List<String> getRequiredColorRoles() => ['primary', 'secondary', 'text'];
  
  /// Validates that the context has required slider properties.
  /// 
  /// Checks for:
  /// - Numeric field type (integer or float)
  /// - Min/max validation properties (required for sliders)
  /// - Optional step property
  /// - Required color roles (primary, secondary, text)
  bool validateSliderProperties(WidgetRenderingContext context) {
    // Check field type
    final fieldType = context.field.type;
    if (fieldType != FieldEnum.integer && fieldType != FieldEnum.float) return false;
    
    // Check required validation (min/max)
    final bounds = context.getNumericBounds();
    if (bounds.min == null || bounds.max == null) return false;
    
    // Check required colors
    for (final role in getRequiredColorRoles()) {
      if (!context.resolvedColors.containsKey(role)) return false;
    }
    
    return true;
  }
}