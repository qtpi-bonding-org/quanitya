import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:quanitya_flutter/data/db/app_database.dart';
import 'package:quanitya_flutter/logic/templates/enums/ai/template_preset.dart';
import 'package:quanitya_flutter/logic/templates/models/shared/template_aesthetics.dart';

void main() {
  group('TemplateAesthetics Conversion Tests', () {
    late TemplateAestheticsModel testModel;
    late TemplateAesthetic mockEntity;

    setUp(() {
      // Create a comprehensive test model with all fields populated
      testModel = TemplateAestheticsModel(
        id: 'test-id-123',
        templateId: 'template-id-456',
        themeName: 'Ocean Vibes',
        icon: 'material:fitness_center',
        emoji: '💪',
        palette: ColorPaletteData(
          accents: ['#006280', '#4D5B60'],
          tones: ['#7A8A8F', '#9BA5AA'],
        ),
        fontConfig: FontConfigData(
          titleFontFamily: 'Roboto',
          titleWeight: 600,
          bodyFontFamily: 'Noto Sans Mono',
          bodyWeight: 400,
        ),
        colorMappings: {
          'slider': {'activeColor': 'accent1', 'inactiveColor': 'tone1'},
          'button': {'backgroundColor': 'accent2', 'textColor': 'tone2'},
        },
        containerStyle: TemplateContainerStyle.soft,
        updatedAt: DateTime(2024, 1, 15, 10, 30, 45),
      );

      // Create a mock entity that represents what would come from the database
      mockEntity = TemplateAesthetic(
        id: 'test-id-123',
        templateId: 'template-id-456',
        themeName: 'Ocean Vibes',
        icon: 'material:fitness_center',
        emoji: '💪',
        paletteJson: jsonEncode({
          'accents': ['#006280', '#4D5B60'],
          'tones': ['#7A8A8F', '#9BA5AA'],
        }),
        fontConfigJson: jsonEncode({
          'titleFontFamily': 'Roboto',
          'titleWeight': 600,
          'subtitleFontFamily': null,
          'subtitleWeight': 400,
          'bodyFontFamily': 'Noto Sans Mono',
          'bodyWeight': 400,
        }),
        colorMappingsJson: jsonEncode({
          'slider': {'activeColor': 'accent1', 'inactiveColor': 'tone1'},
          'button': {'backgroundColor': 'accent2', 'textColor': 'tone2'},
        }),
        containerStyle: 'soft',
        updatedAt: DateTime(2024, 1, 15, 10, 30, 45),
      );
    });

    group('toCompanion()', () {
      test('converts all fields correctly', () {
        // Act
        final companion = testModel.toCompanion();

        // Assert - Check all fields are converted
        expect(companion.id.value, equals('test-id-123'));
        expect(companion.templateId.value, equals('template-id-456'));
        expect(companion.themeName.value, equals('Ocean Vibes'));
        expect(companion.icon.value, equals('material:fitness_center'));
        expect(companion.emoji.value, equals('💪'));
        expect(companion.containerStyle.value, equals('soft'));
        expect(companion.updatedAt.value, 
               equals(DateTime(2024, 1, 15, 10, 30, 45)));

        // Check JSON serialization
        final paletteJson = jsonDecode(companion.paletteJson.value);
        expect(paletteJson['accents'], equals(['#006280', '#4D5B60']));
        expect(paletteJson['tones'], equals(['#7A8A8F', '#9BA5AA']));

        final fontConfigJson = jsonDecode(companion.fontConfigJson.value);
        expect(fontConfigJson['titleFontFamily'], equals('Roboto'));
        expect(fontConfigJson['titleWeight'], equals(600));

        final colorMappingsJson = jsonDecode(companion.colorMappingsJson.value);
        expect(colorMappingsJson['slider']['activeColor'], equals('accent1'));
      });

      test('handles null containerStyle correctly', () {
        // Arrange
        final modelWithNullStyle = testModel.copyWith(containerStyle: null);

        // Act
        final companion = modelWithNullStyle.toCompanion();

        // Assert
        expect(companion.containerStyle.value, isNull);
      });

      test('handles null optional fields correctly', () {
        // Arrange
        final minimalModel = TemplateAestheticsModel(
          id: 'minimal-id',
          templateId: 'template-id',
          themeName: null,
          icon: null,
          emoji: null,
          palette: ColorPaletteData.defaults(),
          fontConfig: FontConfigData.defaults(),
          colorMappings: {},
          containerStyle: null,
          updatedAt: DateTime.now(),
        );

        // Act
        final companion = minimalModel.toCompanion();

        // Assert
        expect(companion.themeName.value, isNull);
        expect(companion.icon.value, isNull);
        expect(companion.emoji.value, isNull);
        expect(companion.containerStyle.value, isNull);
      });
    });

    group('fromEntity()', () {
      test('converts all fields correctly', () {
        // Act
        final model = TemplateAestheticsConversion.fromEntity(mockEntity);

        // Assert - Check all fields are converted
        expect(model.id, equals('test-id-123'));
        expect(model.templateId, equals('template-id-456'));
        expect(model.themeName, equals('Ocean Vibes'));
        expect(model.icon, equals('material:fitness_center'));
        expect(model.emoji, equals('💪'));
        expect(model.containerStyle, equals(TemplateContainerStyle.soft));
        expect(model.updatedAt, equals(DateTime(2024, 1, 15, 10, 30, 45)));

        // Check deserialized objects
        expect(model.palette.accents, equals(['#006280', '#4D5B60']));
        expect(model.palette.tones, equals(['#7A8A8F', '#9BA5AA']));
        expect(model.fontConfig.titleFontFamily, equals('Roboto'));
        expect(model.fontConfig.titleWeight, equals(600));
        expect(model.colorMappings['slider']?['activeColor'], equals('accent1'));
      });

      test('handles null containerStyle correctly', () {
        // Arrange
        final entityWithNullStyle = TemplateAesthetic(
          id: mockEntity.id,
          templateId: mockEntity.templateId,
          themeName: mockEntity.themeName,
          icon: mockEntity.icon,
          emoji: mockEntity.emoji,
          paletteJson: mockEntity.paletteJson,
          fontConfigJson: mockEntity.fontConfigJson,
          colorMappingsJson: mockEntity.colorMappingsJson,
          containerStyle: null, // Null container style
          updatedAt: mockEntity.updatedAt,
        );

        // Act
        final model = TemplateAestheticsConversion.fromEntity(entityWithNullStyle);

        // Assert
        expect(model.containerStyle, isNull);
      });

      test('handles empty JSON strings with defaults', () {
        // Arrange
        final entityWithEmptyJson = TemplateAesthetic(
          id: 'test-id',
          templateId: 'template-id',
          themeName: null,
          icon: null,
          emoji: null,
          paletteJson: '', // Empty JSON
          fontConfigJson: '', // Empty JSON
          colorMappingsJson: '', // Empty JSON
          containerStyle: null,
          updatedAt: DateTime.now(),
        );

        // Act
        final model = TemplateAestheticsConversion.fromEntity(entityWithEmptyJson);

        // Assert - Should use defaults
        expect(model.palette, equals(ColorPaletteData.defaults()));
        expect(model.fontConfig, equals(FontConfigData.defaults()));
        expect(model.colorMappings, isEmpty);
      });

      test('handles invalid containerStyle gracefully', () {
        // Arrange
        final entityWithInvalidStyle = TemplateAesthetic(
          id: mockEntity.id,
          templateId: mockEntity.templateId,
          themeName: mockEntity.themeName,
          icon: mockEntity.icon,
          emoji: mockEntity.emoji,
          paletteJson: mockEntity.paletteJson,
          fontConfigJson: mockEntity.fontConfigJson,
          colorMappingsJson: mockEntity.colorMappingsJson,
          containerStyle: 'invalid_style_name', // Invalid style
          updatedAt: mockEntity.updatedAt,
        );

        // Act
        final model = TemplateAestheticsConversion.fromEntity(entityWithInvalidStyle);

        // Assert - Should be null for invalid style
        expect(model.containerStyle, isNull);
      });
    });

    group('Roundtrip Conversion', () {
      test('preserves all fields through complete roundtrip', () {
        // Act - Convert model → companion → entity → model
        final companion = testModel.toCompanion();
        
        // Simulate what the database would return
        final simulatedEntity = TemplateAesthetic(
          id: companion.id.value,
          templateId: companion.templateId.value,
          themeName: companion.themeName.value,
          icon: companion.icon.value,
          emoji: companion.emoji.value,
          paletteJson: companion.paletteJson.value,
          fontConfigJson: companion.fontConfigJson.value,
          colorMappingsJson: companion.colorMappingsJson.value,
          containerStyle: companion.containerStyle.value,
          updatedAt: companion.updatedAt.value,
        );
        
        final restoredModel = TemplateAestheticsConversion.fromEntity(simulatedEntity);

        // Assert - All fields should be preserved
        expect(restoredModel.id, equals(testModel.id));
        expect(restoredModel.templateId, equals(testModel.templateId));
        expect(restoredModel.themeName, equals(testModel.themeName));
        expect(restoredModel.icon, equals(testModel.icon));
        expect(restoredModel.emoji, equals(testModel.emoji));
        expect(restoredModel.containerStyle, equals(testModel.containerStyle));
        expect(restoredModel.updatedAt, equals(testModel.updatedAt));
        
        // Deep equality checks for complex objects
        expect(restoredModel.palette.accents, equals(testModel.palette.accents));
        expect(restoredModel.palette.tones, equals(testModel.palette.tones));
        expect(restoredModel.fontConfig.titleFontFamily, 
               equals(testModel.fontConfig.titleFontFamily));
        expect(restoredModel.fontConfig.titleWeight, 
               equals(testModel.fontConfig.titleWeight));
        expect(restoredModel.colorMappings, equals(testModel.colorMappings));
      });

      test('handles null values correctly in roundtrip', () {
        // Arrange - Model with null values
        final nullModel = TemplateAestheticsModel(
          id: 'null-test',
          templateId: 'template-id',
          themeName: null,
          icon: null,
          emoji: null,
          palette: ColorPaletteData.defaults(),
          fontConfig: FontConfigData.defaults(),
          colorMappings: {},
          containerStyle: null,
          updatedAt: DateTime.now(),
        );

        // Act - Roundtrip conversion
        final companion = nullModel.toCompanion();
        final simulatedEntity = TemplateAesthetic(
          id: companion.id.value,
          templateId: companion.templateId.value,
          themeName: companion.themeName.value,
          icon: companion.icon.value,
          emoji: companion.emoji.value,
          paletteJson: companion.paletteJson.value,
          fontConfigJson: companion.fontConfigJson.value,
          colorMappingsJson: companion.colorMappingsJson.value,
          containerStyle: companion.containerStyle.value,
          updatedAt: companion.updatedAt.value,
        );
        final restoredModel = TemplateAestheticsConversion.fromEntity(simulatedEntity);

        // Assert - Null values preserved
        expect(restoredModel.themeName, isNull);
        expect(restoredModel.icon, isNull);
        expect(restoredModel.emoji, isNull);
        expect(restoredModel.containerStyle, isNull);
      });
    });

    group('Edge Cases', () {
      test('handles all TemplateContainerStyle enum values', () {
        for (final style in TemplateContainerStyle.values) {
          // Arrange
          final modelWithStyle = testModel.copyWith(containerStyle: style);

          // Act - Roundtrip conversion
          final companion = modelWithStyle.toCompanion();
          final simulatedEntity = TemplateAesthetic(
            id: companion.id.value,
            templateId: companion.templateId.value,
            themeName: companion.themeName.value,
            icon: companion.icon.value,
            emoji: companion.emoji.value,
            paletteJson: companion.paletteJson.value,
            fontConfigJson: companion.fontConfigJson.value,
            colorMappingsJson: companion.colorMappingsJson.value,
            containerStyle: companion.containerStyle.value,
            updatedAt: companion.updatedAt.value,
          );
          final restoredModel = TemplateAestheticsConversion.fromEntity(simulatedEntity);

          // Assert
          expect(restoredModel.containerStyle, equals(style),
                 reason: 'Failed for style: ${style.name}');
        }
      });

      test('handles complex color mappings', () {
        // Arrange - Complex nested color mappings
        final complexModel = testModel.copyWith(
          colorMappings: {
            'slider': {
              'activeColor': 'accent1',
              'inactiveColor': 'tone1',
              'thumbColor': 'accent2',
            },
            'button': {
              'backgroundColor': 'accent2',
              'textColor': 'tone2',
              'borderColor': 'accent1',
            },
            'card': {
              'backgroundColor': 'tone1',
              'shadowColor': 'tone2',
            },
          },
        );

        // Act - Roundtrip conversion
        final companion = complexModel.toCompanion();
        final simulatedEntity = TemplateAesthetic(
          id: companion.id.value,
          templateId: companion.templateId.value,
          themeName: companion.themeName.value,
          icon: companion.icon.value,
          emoji: companion.emoji.value,
          paletteJson: companion.paletteJson.value,
          fontConfigJson: companion.fontConfigJson.value,
          colorMappingsJson: companion.colorMappingsJson.value,
          containerStyle: companion.containerStyle.value,
          updatedAt: companion.updatedAt.value,
        );
        final restoredModel = TemplateAestheticsConversion.fromEntity(simulatedEntity);

        // Assert - Complex mappings preserved
        expect(restoredModel.colorMappings['slider']?['thumbColor'], 
               equals('accent2'));
        expect(restoredModel.colorMappings['button']?['borderColor'], 
               equals('accent1'));
        expect(restoredModel.colorMappings['card']?['shadowColor'], 
               equals('tone2'));
      });
    });
  });
}