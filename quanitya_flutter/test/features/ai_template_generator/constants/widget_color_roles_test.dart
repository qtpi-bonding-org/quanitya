import 'package:flutter_test/flutter_test.dart';
import 'package:quanitya_flutter/logic/templates/enums/ai/color_role.dart';
import 'package:quanitya_flutter/logic/templates/enums/ui_element_enum.dart';
import 'package:quanitya_flutter/logic/templates/enums/ai/widget_color_roles.dart';

void main() {
  group('WidgetColorRoles', () {
    test('should have color role requirements for all UI elements', () {
      // Verify that all UiElementEnum values have color roles defined
      for (final uiElement in UiElementEnum.values) {
        final roles = WidgetColorRoles.getRequiredRoles(uiElement);
        expect(roles, isNotEmpty, reason: 'UI element $uiElement should have color role requirements');
      }
    });

    test('should validate color role requirements correctly', () {
      // Test some known UI elements
      expect(WidgetColorRoles.hasColorRoleRequirements(UiElementEnum.slider), isTrue);
      expect(WidgetColorRoles.hasColorRoleRequirements(UiElementEnum.textField), isTrue);
      expect(WidgetColorRoles.hasColorRoleRequirements(UiElementEnum.toggleSwitch), isTrue);
    });

    test('should find UI elements requiring specific color roles', () {
      final primaryElements = WidgetColorRoles.getUiElementsRequiring(ColorRole.primary);
      expect(primaryElements, contains(UiElementEnum.slider));
      expect(primaryElements, contains(UiElementEnum.toggleSwitch));
      
      final textElements = WidgetColorRoles.getUiElementsRequiring(ColorRole.text);
      expect(textElements, contains(UiElementEnum.textField));
      expect(textElements, contains(UiElementEnum.slider));
    });

    test('should return all used color roles', () {
      final allRoles = WidgetColorRoles.getAllUsedColorRoles();
      expect(allRoles, contains(ColorRole.primary));
      expect(allRoles, contains(ColorRole.secondary));
      expect(allRoles, contains(ColorRole.text));
      expect(allRoles, contains(ColorRole.background));
      expect(allRoles, contains(ColorRole.border));
    });

    test('should maintain single source of truth consistency', () {
      // Verify that the static map is the source of truth
      final sliderRoles = WidgetColorRoles.requiredRoles[UiElementEnum.slider];
      final getterRoles = WidgetColorRoles.getRequiredRoles(UiElementEnum.slider);
      
      expect(getterRoles, equals(sliderRoles));
    });
  });
}