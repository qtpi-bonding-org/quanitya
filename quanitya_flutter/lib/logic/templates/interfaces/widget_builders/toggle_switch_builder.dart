import '../widget_builder.dart';
import '../../models/engine/widget_rendering_context.dart';
import '../../enums/field_enum.dart';

/// Interface for building toggle switch widgets from atomic field decisions.
/// 
/// Handles SwitchProfile: Switch + Boolean validation (tightly coupled)
/// Required for boolean fields with toggleSwitch UI element choice.
abstract class IToggleSwitchBuilder extends IWidgetBuilder {
  @override
  String get uiElementType => 'toggleSwitch';
  
  @override
  List<String> getRequiredColorRoles() => ['primary', 'secondary'];
  
  /// Validates that the context has required switch properties.
  /// 
  /// Checks for:
  /// - Boolean field type
  /// - Required color roles (primary, secondary)
  bool validateSwitchProperties(WidgetRenderingContext context) {
    // Check field type
    if (context.field.type != FieldEnum.boolean) return false;
    
    // Check required colors
    for (final role in getRequiredColorRoles()) {
      if (!context.resolvedColors.containsKey(role)) return false;
    }
    
    return true;
  }
}