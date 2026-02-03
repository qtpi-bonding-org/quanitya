import '../widget_builder.dart';
import '../../models/engine/widget_rendering_context.dart';
import '../../enums/field_enum.dart';

/// Interface for building chips widgets from atomic field decisions.
/// 
/// Handles ChipsProfile: Chips + Options validation (tightly coupled)
/// Required for enumerated fields with chips UI element choice.
abstract class IChipsBuilder extends IWidgetBuilder {
  @override
  String get uiElementType => 'chips';
  
  @override
  List<String> getRequiredColorRoles() => ['primary', 'secondary', 'text'];
  
  /// Validates that the context has required chips properties.
  /// 
  /// Checks for:
  /// - Enumerated field type
  /// - Options array with minimum 2 items (required for chips)
  /// - Required color roles (primary, secondary, text)
  bool validateChipsProperties(WidgetRenderingContext context) {
    // Check field type
    if (context.field.type != FieldEnum.enumerated) return false;
    
    // Check required options
    final options = context.getEnumeratedOptions();
    if (options.length < 2) return false;
    
    // Check required colors
    for (final role in getRequiredColorRoles()) {
      if (!context.resolvedColors.containsKey(role)) return false;
    }
    
    return true;
  }
}