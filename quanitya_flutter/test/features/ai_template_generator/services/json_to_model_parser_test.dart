import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:quanitya_flutter/logic/templates/enums/field_enum.dart';
import 'package:quanitya_flutter/logic/templates/models/shared/field_validator.dart';
import 'package:quanitya_flutter/logic/templates/exceptions/template_parsing_exception.dart';
import 'package:quanitya_flutter/logic/templates/services/engine/json_to_model_parser.dart';
import 'package:quanitya_flutter/logic/templates/services/shared/default_value_handler.dart';
import 'package:quanitya_flutter/logic/templates/services/shared/wcag_compliance_validator.dart';
import 'package:flutter/material.dart';

@GenerateMocks([WcagComplianceValidatorImpl, DefaultValueHandler])
import 'json_to_model_parser_test.mocks.dart';

void main() {
  late JsonToModelParser parser;
  late MockWcagComplianceValidatorImpl mockValidator;
  late MockDefaultValueHandler mockDefaultHandler;

  setUp(() {
    mockValidator = MockWcagComplianceValidatorImpl();
    mockDefaultHandler = MockDefaultValueHandler();
    // Mock the validator to return colors unchanged (for testing parsing logic)
    when(mockValidator.adjustForWashiWhite(any, isText: anyNamed('isText')))
        .thenAnswer((invocation) => invocation.positionalArguments[0] as Color);
    // Mock the default handler to parse values correctly
    when(mockDefaultHandler.parseDefault(any, any))
        .thenAnswer((invocation) => invocation.positionalArguments[0]);
    when(mockDefaultHandler.validateDefault(any, any)).thenReturn(null);
    parser = JsonToModelParser(mockValidator, mockDefaultHandler);
  });

  group('JsonToModelParser', () {
    group('parse - valid input', () {
      test('parses minimal valid AI response', () {
        final aiJson = {
          'fields': [
            {
              'label': 'Weight',
              'widgetType': 'slider',
              'fieldType': 'integer',
              'args': {'min': 0, 'max': 500},
            },
          ],
          'colorPalette': {
            'colors': ['#1976D2', '#388E3C'],
            'neutrals': ['#212121', '#F5F5F5'],
          },
        };

        final result = parser.parse(
          aiJson: aiJson,
          templateName: 'Weight Tracker',
        );

        expect(result.template.name, 'Weight Tracker');
        expect(result.template.fields.length, 1);
        expect(result.template.fields[0].label, 'Weight');
        expect(result.template.fields[0].type, FieldEnum.integer);

        expect(result.aesthetics.templateId, result.template.id);
        expect(result.aesthetics.palette.accents.length, 2);
        expect(result.aesthetics.palette.tones.length, 2);
      });

      test('parses multiple fields', () {
        final aiJson = {
          'fields': [
            {
              'label': 'Weight',
              'widgetType': 'slider',
              'fieldType': 'integer',
              'args': {'min': 0, 'max': 500},
            },
            {
              'label': 'Notes',
              'widgetType': 'textField',
              'fieldType': 'text',
              'args': {'maxLength': 500},
            },
            {
              'label': 'Completed',
              'widgetType': 'toggle',
              'fieldType': 'boolean',
            },
          ],
          'colorPalette': {
            'colors': ['#1976D2', '#388E3C'],
            'neutrals': ['#212121', '#F5F5F5'],
          },
        };

        final result = parser.parse(
          aiJson: aiJson,
          templateName: 'Workout Log',
        );

        expect(result.template.fields.length, 3);
        expect(result.template.fields[0].type, FieldEnum.integer);
        expect(result.template.fields[1].type, FieldEnum.text);
        expect(result.template.fields[2].type, FieldEnum.boolean);
      });

      test('parses enumerated field with options', () {
        final aiJson = {
          'fields': [
            {
              'label': 'Mood',
              'widgetType': 'dropdown',
              'fieldType': 'enumerated',
              'options': ['Happy', 'Sad', 'Neutral'],
            },
          ],
          'colorPalette': {
            'colors': ['#1976D2', '#388E3C'],
            'neutrals': ['#212121', '#F5F5F5'],
          },
        };

        final result = parser.parse(
          aiJson: aiJson,
          templateName: 'Mood Tracker',
        );

        expect(result.template.fields[0].type, FieldEnum.enumerated);
        expect(result.template.fields[0].options, ['Happy', 'Sad', 'Neutral']);
      });

      test('parses font configuration', () {
        final aiJson = {
          'fields': [
            {
              'label': 'Value',
              'widgetType': 'stepper',
              'fieldType': 'integer',
            },
          ],
          'colorPalette': {
            'colors': ['#1976D2', '#388E3C'],
            'neutrals': ['#212121', '#F5F5F5'],
          },
          'fontConfiguration': {
            'titleFontFamily': 'Roboto',
            'titleWeight': 700,
            'subtitleWeight': 500,
            'bodyWeight': 400,
          },
        };

        final result = parser.parse(
          aiJson: aiJson,
          templateName: 'Counter',
        );

        expect(result.aesthetics.fontConfig.titleFontFamily, 'Roboto');
        expect(result.aesthetics.fontConfig.titleWeight, 700);
        expect(result.aesthetics.fontConfig.subtitleWeight, 500);
        expect(result.aesthetics.fontConfig.bodyWeight, 400);
      });

      test('uses default font config when not provided', () {
        final aiJson = {
          'fields': [
            {
              'label': 'Value',
              'widgetType': 'stepper',
              'fieldType': 'integer',
            },
          ],
          'colorPalette': {
            'colors': ['#1976D2', '#388E3C'],
            'neutrals': ['#212121', '#F5F5F5'],
          },
        };

        final result = parser.parse(
          aiJson: aiJson,
          templateName: 'Counter',
        );

        expect(result.aesthetics.fontConfig.titleWeight, 600);
        expect(result.aesthetics.fontConfig.subtitleWeight, 400);
        expect(result.aesthetics.fontConfig.bodyWeight, 400);
      });

      test('extracts color mappings from fields', () {
        final aiJson = {
          'fields': [
            {
              'label': 'Weight',
              'uiElement': 'slider',
              'fieldType': 'integer',
              'colorConfiguration': {
                'trackColor': 'accent1',
                'thumbColor': 'accent2',
              },
            },
            {
              'label': 'Reps',
              'uiElement': 'stepper',
              'fieldType': 'integer',
              'colorConfiguration': {
                'buttonColor': 'accent1',
                'textColor': 'tone1',
              },
            },
          ],
          'colorPalette': {
            'accents': ['#1976D2', '#388E3C'],
            'tones': ['#212121', '#F5F5F5'],
          },
        };

        final result = parser.parse(
          aiJson: aiJson,
          templateName: 'Workout',
        );

        expect(result.aesthetics.colorMappings.containsKey('slider'), true);
        expect(result.aesthetics.colorMappings.containsKey('stepper'), true);
        expect(
            result.aesthetics.colorMappings['slider']!['trackColor'], 'accent1');
        expect(
            result.aesthetics.colorMappings['stepper']!['buttonColor'], 'accent1');
      });

      test('stores only first color mapping per uiElement type', () {
        final aiJson = {
          'fields': [
            {
              'label': 'Weight',
              'uiElement': 'slider',
              'fieldType': 'integer',
              'colorConfiguration': {'trackColor': 'accent1'},
            },
            {
              'label': 'Height',
              'uiElement': 'slider',
              'fieldType': 'integer',
              'colorConfiguration': {'trackColor': 'accent2'},
            },
          ],
          'colorPalette': {
            'accents': ['#1976D2', '#388E3C'],
            'tones': ['#212121', '#F5F5F5'],
          },
        };

        final result = parser.parse(
          aiJson: aiJson,
          templateName: 'Body Metrics',
        );

        // Should only have one slider mapping (the first one)
        expect(result.aesthetics.colorMappings['slider']!['trackColor'], 'accent1');
      });

      test('sets emoji when provided', () {
        final aiJson = {
          'fields': [
            {
              'label': 'Value',
              'widgetType': 'stepper',
              'fieldType': 'integer',
            },
          ],
          'colorPalette': {
            'colors': ['#1976D2', '#388E3C'],
            'neutrals': ['#212121', '#F5F5F5'],
          },
        };

        final result = parser.parse(
          aiJson: aiJson,
          templateName: 'Workout',
          emoji: '🏋️',
        );

        expect(result.aesthetics.emoji, '🏋️');
      });

      test('parses group field with sub-fields', () {
        final aiJson = {
          'fields': [
            {
              'label': 'Sets',
              'fieldType': 'group',
              'uiElement': 'stepper',
              'isList': true,
              'listMinItems': 1,
              'listMaxItems': 5,
              'subFields': [
                {
                  'label': 'Weight',
                  'fieldType': 'float',
                  'uiElement': 'slider',
                  'isList': false,
                  'listMinItems': 0,
                  'listMaxItems': 10,
                },
                {
                  'label': 'Reps',
                  'fieldType': 'integer',
                  'uiElement': 'stepper',
                  'isList': false,
                  'listMinItems': 0,
                  'listMaxItems': 10,
                },
              ],
            },
          ],
          'colorPalette': {
            'colors': ['#1976D2', '#388E3C'],
            'neutrals': ['#212121', '#F5F5F5'],
          },
        };

        final result = parser.parse(
          aiJson: aiJson,
          templateName: 'Workout',
        );

        final field = result.template.fields[0];
        expect(field.type, FieldEnum.group);
        expect(field.isList, true);
        expect(field.subFields, isNotNull);
        expect(field.subFields!.length, 2);
        expect(field.subFields![0].label, 'Weight');
        expect(field.subFields![0].type, FieldEnum.float);
        expect(field.subFields![1].label, 'Reps');
        expect(field.subFields![1].type, FieldEnum.integer);
      });

      test('rejects nested groups', () {
        final aiJson = {
          'fields': [
            {
              'label': 'Outer',
              'fieldType': 'group',
              'uiElement': 'stepper',
              'isList': true,
              'listMinItems': 0,
              'listMaxItems': 10,
              'subFields': [
                {
                  'label': 'Inner',
                  'fieldType': 'group',
                  'uiElement': 'stepper',
                  'isList': false,
                  'listMinItems': 0,
                  'listMaxItems': 10,
                  'subFields': [
                    {
                      'label': 'Value',
                      'fieldType': 'integer',
                      'uiElement': 'stepper',
                      'isList': false,
                      'listMinItems': 0,
                      'listMaxItems': 10,
                    },
                  ],
                },
              ],
            },
          ],
          'colorPalette': {
            'colors': ['#1976D2', '#388E3C'],
            'neutrals': ['#212121', '#F5F5F5'],
          },
        };

        expect(
          () => parser.parse(aiJson: aiJson, templateName: 'Test'),
          throwsA(isA<TemplateParsingException>()),
        );
      });

      test('rejects group field without subFields', () {
        final aiJson = {
          'fields': [
            {
              'label': 'Sets',
              'fieldType': 'group',
              'uiElement': 'stepper',
              'isList': true,
              'listMinItems': 0,
              'listMaxItems': 10,
            },
          ],
          'colorPalette': {
            'colors': ['#1976D2', '#388E3C'],
            'neutrals': ['#212121', '#F5F5F5'],
          },
        };

        expect(
          () => parser.parse(aiJson: aiJson, templateName: 'Test'),
          throwsA(isA<TemplateParsingException>()),
        );
      });

      test('normalizes hex colors to uppercase', () {
        final aiJson = {
          'fields': [
            {
              'label': 'Value',
              'widgetType': 'stepper',
              'fieldType': 'integer',
            },
          ],
          'colorPalette': {
            'colors': ['#1976d2', '#388e3c'],
            'neutrals': ['#212121', '#f5f5f5'],
          },
        };

        final result = parser.parse(
          aiJson: aiJson,
          templateName: 'Test',
        );

        expect(result.aesthetics.palette.accents[0], '#1976D2');
        expect(result.aesthetics.palette.accents[1], '#388E3C');
        expect(result.aesthetics.palette.tones[1], '#F5F5F5');
      });
    });

    group('parse - validators', () {
      test('creates numeric validator for integer field with constraints', () {
        final aiJson = {
          'fields': [
            {
              'label': 'Weight',
              'widgetType': 'slider',
              'fieldType': 'integer',
              'args': {'min': 0, 'max': 500, 'step': 1},
            },
          ],
          'colorPalette': {
            'colors': ['#1976D2', '#388E3C'],
            'neutrals': ['#212121', '#F5F5F5'],
          },
        };

        final result = parser.parse(
          aiJson: aiJson,
          templateName: 'Weight Tracker',
        );

        final field = result.template.fields[0];
        expect(field.validators.length, 1);
        expect(field.validators[0].validatorType, ValidatorType.numeric);
        expect(field.validators[0].validatorData['min'], 0);
        expect(field.validators[0].validatorData['max'], 500);
        expect(field.validators[0].validatorData['step'], 1);
      });

      test('creates text validator for text field with constraints', () {
        final aiJson = {
          'fields': [
            {
              'label': 'Notes',
              'widgetType': 'textField',
              'fieldType': 'text',
              'args': {'minLength': 1, 'maxLength': 500},
            },
          ],
          'colorPalette': {
            'colors': ['#1976D2', '#388E3C'],
            'neutrals': ['#212121', '#F5F5F5'],
          },
        };

        final result = parser.parse(
          aiJson: aiJson,
          templateName: 'Notes',
        );

        final field = result.template.fields[0];
        expect(field.validators.length, 1);
        expect(field.validators[0].validatorType, ValidatorType.text);
        expect(field.validators[0].validatorData['minLength'], 1);
        expect(field.validators[0].validatorData['maxLength'], 500);
      });

      test('creates enumerated validator for enumerated field', () {
        final aiJson = {
          'fields': [
            {
              'label': 'Mood',
              'widgetType': 'dropdown',
              'fieldType': 'enumerated',
              'options': ['Happy', 'Sad'],
            },
          ],
          'colorPalette': {
            'colors': ['#1976D2', '#388E3C'],
            'neutrals': ['#212121', '#F5F5F5'],
          },
        };

        final result = parser.parse(
          aiJson: aiJson,
          templateName: 'Mood',
        );

        final field = result.template.fields[0];
        expect(field.validators.length, 1);
        expect(field.validators[0].validatorType, ValidatorType.enumerated);
        expect(field.validators[0].validatorData['options'], ['Happy', 'Sad']);
      });

      test('creates no validators for boolean field', () {
        final aiJson = {
          'fields': [
            {
              'label': 'Completed',
              'widgetType': 'toggle',
              'fieldType': 'boolean',
            },
          ],
          'colorPalette': {
            'colors': ['#1976D2', '#388E3C'],
            'neutrals': ['#212121', '#F5F5F5'],
          },
        };

        final result = parser.parse(
          aiJson: aiJson,
          templateName: 'Task',
        );

        expect(result.template.fields[0].validators, isEmpty);
      });

      test('creates no validators when args is empty', () {
        final aiJson = {
          'fields': [
            {
              'label': 'Value',
              'widgetType': 'stepper',
              'fieldType': 'integer',
              'args': {},
            },
          ],
          'colorPalette': {
            'colors': ['#1976D2', '#388E3C'],
            'neutrals': ['#212121', '#F5F5F5'],
          },
        };

        final result = parser.parse(
          aiJson: aiJson,
          templateName: 'Counter',
        );

        expect(result.template.fields[0].validators, isEmpty);
      });
    });

    group('parse - error handling', () {
      test('throws when fields is missing', () {
        final aiJson = {
          'colorPalette': {
            'colors': ['#1976D2', '#388E3C'],
            'neutrals': ['#212121', '#F5F5F5'],
          },
        };

        expect(
          () => parser.parse(aiJson: aiJson, templateName: 'Test'),
          throwsA(isA<TemplateParsingException>()),
        );
      });

      test('throws when fields is empty', () {
        final aiJson = {
          'fields': [],
          'colorPalette': {
            'colors': ['#1976D2', '#388E3C'],
            'neutrals': ['#212121', '#F5F5F5'],
          },
        };

        expect(
          () => parser.parse(aiJson: aiJson, templateName: 'Test'),
          throwsA(isA<TemplateParsingException>()),
        );
      });

      test('throws when colorPalette is missing', () {
        final aiJson = {
          'fields': [
            {
              'label': 'Value',
              'widgetType': 'stepper',
              'fieldType': 'integer',
            },
          ],
        };

        expect(
          () => parser.parse(aiJson: aiJson, templateName: 'Test'),
          throwsA(isA<TemplateParsingException>()),
        );
      });

      test('throws when colors array is empty', () {
        final aiJson = {
          'fields': [
            {
              'label': 'Value',
              'widgetType': 'stepper',
              'fieldType': 'integer',
            },
          ],
          'colorPalette': {
            'colors': [],
            'neutrals': ['#212121', '#F5F5F5'],
          },
        };

        expect(
          () => parser.parse(aiJson: aiJson, templateName: 'Test'),
          throwsA(isA<TemplateParsingException>()),
        );
      });

      test('throws when fieldType is missing', () {
        final aiJson = {
          'fields': [
            {
              'label': 'Value',
              'widgetType': 'stepper',
            },
          ],
          'colorPalette': {
            'colors': ['#1976D2', '#388E3C'],
            'neutrals': ['#212121', '#F5F5F5'],
          },
        };

        expect(
          () => parser.parse(aiJson: aiJson, templateName: 'Test'),
          throwsA(isA<TemplateParsingException>()),
        );
      });

      test('throws when fieldType is invalid', () {
        final aiJson = {
          'fields': [
            {
              'label': 'Value',
              'widgetType': 'stepper',
              'fieldType': 'invalidType',
            },
          ],
          'colorPalette': {
            'colors': ['#1976D2', '#388E3C'],
            'neutrals': ['#212121', '#F5F5F5'],
          },
        };

        expect(
          () => parser.parse(aiJson: aiJson, templateName: 'Test'),
          throwsA(isA<TemplateParsingException>()),
        );
      });

      test('throws when hex color is invalid', () {
        final aiJson = {
          'fields': [
            {
              'label': 'Value',
              'widgetType': 'stepper',
              'fieldType': 'integer',
            },
          ],
          'colorPalette': {
            'colors': ['#GGGGGG', '#388E3C'],
            'neutrals': ['#212121', '#F5F5F5'],
          },
        };

        expect(
          () => parser.parse(aiJson: aiJson, templateName: 'Test'),
          throwsA(isA<TemplateParsingException>()),
        );
      });

      test('throws when hex color format is wrong', () {
        final aiJson = {
          'fields': [
            {
              'label': 'Value',
              'widgetType': 'stepper',
              'fieldType': 'integer',
            },
          ],
          'colorPalette': {
            'colors': ['1976D2', '#388E3C'], // Missing #
            'neutrals': ['#212121', '#F5F5F5'],
          },
        };

        expect(
          () => parser.parse(aiJson: aiJson, templateName: 'Test'),
          throwsA(isA<TemplateParsingException>()),
        );
      });
    });

    group('parse - edge cases', () {
      test('uses default label when not provided', () {
        final aiJson = {
          'fields': [
            {
              'widgetType': 'stepper',
              'fieldType': 'integer',
            },
          ],
          'colorPalette': {
            'colors': ['#1976D2', '#388E3C'],
            'neutrals': ['#212121', '#F5F5F5'],
          },
        };

        final result = parser.parse(
          aiJson: aiJson,
          templateName: 'Test',
        );

        expect(result.template.fields[0].label, 'Untitled');
      });

      test('uses default tones when not provided', () {
        final aiJson = {
          'fields': [
            {
              'label': 'Value',
              'uiElement': 'stepper',
              'fieldType': 'integer',
            },
          ],
          'colorPalette': {
            'accents': ['#1976D2', '#388E3C'],
          },
        };

        final result = parser.parse(
          aiJson: aiJson,
          templateName: 'Test',
        );

        // Default tones are adjusted for WCAG compliance
        expect(result.aesthetics.palette.tones.length, 2);
      });

      test('handles font weight as string with w prefix', () {
        final aiJson = {
          'fields': [
            {
              'label': 'Value',
              'widgetType': 'stepper',
              'fieldType': 'integer',
            },
          ],
          'colorPalette': {
            'colors': ['#1976D2', '#388E3C'],
            'neutrals': ['#212121', '#F5F5F5'],
          },
          'fontConfiguration': {
            'titleWeight': 'w700',
          },
        };

        final result = parser.parse(
          aiJson: aiJson,
          templateName: 'Test',
        );

        expect(result.aesthetics.fontConfig.titleWeight, 700);
      });

      test('clamps font weight to valid range', () {
        final aiJson = {
          'fields': [
            {
              'label': 'Value',
              'widgetType': 'stepper',
              'fieldType': 'integer',
            },
          ],
          'colorPalette': {
            'colors': ['#1976D2', '#388E3C'],
            'neutrals': ['#212121', '#F5F5F5'],
          },
          'fontConfiguration': {
            'titleWeight': 1000, // Over max
            'subtitleWeight': 50, // Under min
          },
        };

        final result = parser.parse(
          aiJson: aiJson,
          templateName: 'Test',
        );

        expect(result.aesthetics.fontConfig.titleWeight, 900);
        expect(result.aesthetics.fontConfig.subtitleWeight, 100);
      });

      test('handles datetime field type', () {
        final aiJson = {
          'fields': [
            {
              'label': 'Date',
              'widgetType': 'datePicker',
              'fieldType': 'datetime',
            },
          ],
          'colorPalette': {
            'colors': ['#1976D2', '#388E3C'],
            'neutrals': ['#212121', '#F5F5F5'],
          },
        };

        final result = parser.parse(
          aiJson: aiJson,
          templateName: 'Event',
        );

        expect(result.template.fields[0].type, FieldEnum.datetime);
        expect(result.template.fields[0].validators, isEmpty);
      });

      test('handles float field type', () {
        final aiJson = {
          'fields': [
            {
              'label': 'Temperature',
              'widgetType': 'slider',
              'fieldType': 'float',
              'args': {'min': 0.0, 'max': 100.0, 'step': 0.1},
            },
          ],
          'colorPalette': {
            'colors': ['#1976D2', '#388E3C'],
            'neutrals': ['#212121', '#F5F5F5'],
          },
        };

        final result = parser.parse(
          aiJson: aiJson,
          templateName: 'Temperature',
        );

        expect(result.template.fields[0].type, FieldEnum.float);
        expect(result.template.fields[0].validators.length, 1);
        expect(result.template.fields[0].validators[0].validatorData['step'], 0.1);
      });
    });

    group('parse - list fields', () {
      test('parses isList flag when true', () {
        final aiJson = {
          'fields': [
            {
              'label': 'Reps',
              'uiElement': 'stepper',
              'fieldType': 'integer',
              'isList': true,
              'args': {'min': 1, 'max': 50},
            },
          ],
          'colorPalette': {
            'accents': ['#1976D2', '#388E3C'],
            'tones': ['#212121', '#F5F5F5'],
          },
        };

        final result = parser.parse(
          aiJson: aiJson,
          templateName: 'Workout',
        );

        expect(result.template.fields[0].isList, true);
      });

      test('parses isList flag when false', () {
        final aiJson = {
          'fields': [
            {
              'label': 'Weight',
              'uiElement': 'slider',
              'fieldType': 'integer',
              'isList': false,
              'args': {'min': 0, 'max': 500},
            },
          ],
          'colorPalette': {
            'accents': ['#1976D2', '#388E3C'],
            'tones': ['#212121', '#F5F5F5'],
          },
        };

        final result = parser.parse(
          aiJson: aiJson,
          templateName: 'Weight Tracker',
        );

        expect(result.template.fields[0].isList, false);
      });

      test('defaults isList to false when not provided', () {
        final aiJson = {
          'fields': [
            {
              'label': 'Notes',
              'uiElement': 'textField',
              'fieldType': 'text',
            },
          ],
          'colorPalette': {
            'accents': ['#1976D2', '#388E3C'],
            'tones': ['#212121', '#F5F5F5'],
          },
        };

        final result = parser.parse(
          aiJson: aiJson,
          templateName: 'Notes',
        );

        expect(result.template.fields[0].isList, false);
      });

      test('creates list validator with bounds when provided', () {
        final aiJson = {
          'fields': [
            {
              'label': 'Sets',
              'uiElement': 'stepper',
              'fieldType': 'integer',
              'isList': true,
              'listMinItems': 1,
              'listMaxItems': 10,
              'args': {'min': 1, 'max': 50},
            },
          ],
          'colorPalette': {
            'accents': ['#1976D2', '#388E3C'],
            'tones': ['#212121', '#F5F5F5'],
          },
        };

        final result = parser.parse(
          aiJson: aiJson,
          templateName: 'Workout',
        );

        final field = result.template.fields[0];
        expect(field.isList, true);
        
        // Should have both numeric and list validators
        // Note: listMaxItems=10 is treated as "unbounded" so only minItems is stored
        final listValidator = field.validators.firstWhere(
          (v) => v.validatorType == ValidatorType.list,
        );
        expect(listValidator.validatorData['minItems'], 1);
        // maxItems=10 is treated as unbounded, so not stored
        expect(listValidator.validatorData['maxItems'], null);
      });

      test('creates list validator with only minItems', () {
        final aiJson = {
          'fields': [
            {
              'label': 'Ingredients',
              'uiElement': 'textField',
              'fieldType': 'text',
              'isList': true,
              'listMinItems': 1,
            },
          ],
          'colorPalette': {
            'accents': ['#1976D2', '#388E3C'],
            'tones': ['#212121', '#F5F5F5'],
          },
        };

        final result = parser.parse(
          aiJson: aiJson,
          templateName: 'Recipe',
        );

        final field = result.template.fields[0];
        final listValidator = field.validators.firstWhere(
          (v) => v.validatorType == ValidatorType.list,
        );
        expect(listValidator.validatorData['minItems'], 1);
        expect(listValidator.validatorData.containsKey('maxItems'), false);
      });

      test('creates list validator with only maxItems', () {
        final aiJson = {
          'fields': [
            {
              'label': 'Tags',
              'uiElement': 'textField',
              'fieldType': 'text',
              'isList': true,
              'listMaxItems': 5,
            },
          ],
          'colorPalette': {
            'accents': ['#1976D2', '#388E3C'],
            'tones': ['#212121', '#F5F5F5'],
          },
        };

        final result = parser.parse(
          aiJson: aiJson,
          templateName: 'Post',
        );

        final field = result.template.fields[0];
        final listValidator = field.validators.firstWhere(
          (v) => v.validatorType == ValidatorType.list,
        );
        expect(listValidator.validatorData.containsKey('minItems'), false);
        expect(listValidator.validatorData['maxItems'], 5);
      });

      test('does not create list validator when isList is true but no bounds', () {
        final aiJson = {
          'fields': [
            {
              'label': 'Items',
              'uiElement': 'textField',
              'fieldType': 'text',
              'isList': true,
            },
          ],
          'colorPalette': {
            'accents': ['#1976D2', '#388E3C'],
            'tones': ['#212121', '#F5F5F5'],
          },
        };

        final result = parser.parse(
          aiJson: aiJson,
          templateName: 'List',
        );

        final field = result.template.fields[0];
        expect(field.isList, true);
        expect(
          field.validators.any((v) => v.validatorType == ValidatorType.list),
          false,
        );
      });

      test('ignores list bounds when isList is false', () {
        final aiJson = {
          'fields': [
            {
              'label': 'Value',
              'uiElement': 'stepper',
              'fieldType': 'integer',
              'isList': false,
              'listMinItems': 1,
              'listMaxItems': 10,
            },
          ],
          'colorPalette': {
            'accents': ['#1976D2', '#388E3C'],
            'tones': ['#212121', '#F5F5F5'],
          },
        };

        final result = parser.parse(
          aiJson: aiJson,
          templateName: 'Counter',
        );

        final field = result.template.fields[0];
        expect(field.isList, false);
        expect(
          field.validators.any((v) => v.validatorType == ValidatorType.list),
          false,
        );
      });
    });
  });
}
