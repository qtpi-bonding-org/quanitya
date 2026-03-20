import 'package:injectable/injectable.dart';

import '../../../../design_system/widgets/quanitya/generatable/quanitya_widget_registry.dart';
import '../../enums/ai/allowed_font.dart';
import '../../enums/ai/template_preset.dart';
import '../../enums/field_enum.dart';
import '../../enums/measurement_unit.dart';
import '../../enums/ui_element_enum.dart';
import '../../models/shared/field_validator.dart';

/// Unified schema generator that converts enum combinations directly to JSON Schema.
///
/// This class directly converts (FieldEnum, UiElementEnum, List of ValidatorType) tuples
/// to final JSON Schema format, eliminating the need for intermediate WidgetTemplateGenerator.
/// Produces a flattened schema structure compatible with OpenAI strict mode.
///
/// Uses [QuanityaWidgetRegistry] for colorable property definitions, ensuring
/// schema generation stays in sync with native widget implementations.
///
/// Widget-specific args (min/max, keyboardType, etc.) are NOT included in the schema
/// because they are const values AI can't change - widgets handle their own defaults.
@injectable
class UnifiedSchemaGenerator {
  /// Generates complete JSON Schema from enum combinations.
  ///
  /// Takes enum tuples directly from SymbolicCombinationGenerator and creates
  /// a comprehensive JSON Schema that constrains AI output generation.
  ///
  /// The schema includes:
  /// - `fields`: Array of 1-10 field definitions with label + widget config
  /// - `colorPalette`: AI chooses actual hex values for color slots
  /// - `fontConfiguration`: Font constraints
  ///
  /// [combinations] List of (FieldEnum, UiElementEnum, List of ValidatorType) tuples
  ///
  /// Returns a complete JSON Schema suitable for AI template generation.
  Map<String, dynamic> generateSchema(
    List<(FieldEnum, UiElementEnum, List<ValidatorType>)> combinations,
  ) {
    final schema = <String, dynamic>{
      '\$schema': 'http://json-schema.org/draft-07/schema#',
      'type': 'object',
      'properties': <String, dynamic>{},
      'required': <String>[],
      'additionalProperties': false,
    };

    final properties = schema['properties'] as Map<String, dynamic>;
    final required = schema['required'] as List<String>;

    // Generate fields array schema (supports 1-10 fields per template)
    if (combinations.isNotEmpty) {
      properties['fields'] = _generateFieldsArraySchema(combinations);
      required.add('fields');
    }

    // Generate color palette schema (AI defines actual colors)
    properties['colorPalette'] = _generateColorPaletteSchema();
    required.add('colorPalette');

    // Generate font configuration schema
    properties['fontConfiguration'] = _generateFontConfigurationSchema();
    required.add('fontConfiguration');

    // Generate template container style schema
    properties['templateContainerStyle'] = _generateTemplateContainerStyleSchema();
    required.add('templateContainerStyle');

    // Generate icon schema (AI chooses appropriate icon)
    properties['icon'] = _generateIconSchema();
    required.add('icon');

    return schema;
  }

  /// Generates fields array schema supporting multiple fields per template.
  ///
  /// Produces an array schema where each item can be any valid field-widget-validator
  /// combination. Allows AI to generate 1-10 fields for a single template.
  Map<String, dynamic> _generateFieldsArraySchema(
    List<(FieldEnum, UiElementEnum, List<ValidatorType>)> combinations,
  ) {
    final scalarOptions = combinations
        .map(_convertEnumTupleToSchemaOption)
        .toList();

    // Group fields are excluded from AI schema generation — the recursive
    // subFields anyOf roughly doubles schema size and exceeds structured
    // output limits on smaller models (e.g., gpt-4o-mini). Group fields
    // can still be created manually or via the template editor.
    // _generateGroupFieldSchema is retained for future use.

    return {
      'type': 'array',
      'items': {
        'anyOf': scalarOptions,
      },
      'minItems': 1,
      'maxItems': 10,
      'description':
          'Array of fields for this template (1-10 fields supported)',
    };
  }

  /// Converts a single enum tuple to a schema option.
  ///
  /// Transforms (FieldEnum, UiElementEnum, List of ValidatorType) into JSON Schema
  /// format with proper constraints. Uses [QuanityaWidgetRegistry] for colorable
  /// property definitions.
  ///
  /// NOTE: Widget args (min/max, keyboardType, etc.) are NOT included because:
  /// 1. They are const values AI can't change anyway
  /// 2. Widgets have their own sensible defaults
  /// 3. Validators are derived at runtime from field type
  Map<String, dynamic> _convertEnumTupleToSchemaOption(
    (FieldEnum, UiElementEnum, List<ValidatorType>) tuple,
  ) {
    final (fieldType, uiElement, _) = tuple;
    
    final schemaOption = <String, dynamic>{
      'type': 'object',
      'properties': <String, dynamic>{},
      'required': <String>[],
      'additionalProperties': false,
    };

    final properties = schemaOption['properties'] as Map<String, dynamic>;
    final required = schemaOption['required'] as List<String>;

    // Add label field for AI to name each field
    properties['label'] = {
      'type': 'string',
      'description':
          'Human-readable label for this field (e.g., "Weight", "Reps", "Duration")',
      'minLength': 1,
      'maxLength': 50,
    };
    required.add('label');

    // Add isList flag for multi-value fields
    properties['isList'] = {
      'type': 'boolean',
      'description':
          'If true, field accepts multiple values (e.g., workout sets, meal ingredients, medication doses)',
    };
    required.add('isList');

    // Add list bounds (required for strict mode, use 0/10 for unbounded)
    properties['listMinItems'] = {
      'type': 'integer',
      'minimum': 0,
      'maximum': 10,
      'description':
          'Minimum number of list items required when isList is true. Use 0 for no minimum. Ignored when isList is false.',
    };
    required.add('listMinItems');

    properties['listMaxItems'] = {
      'type': 'integer',
      'minimum': 1,
      'maximum': 10,
      'description':
          'Maximum number of list items allowed when isList is true. Use 10 for effectively unlimited. Ignored when isList is false.',
    };
    required.add('listMaxItems');

    // Add field type as const
    properties['fieldType'] = {
      'type': 'string',
      'const': fieldType.name,
    };
    required.add('fieldType');

    // Add UI element as const
    properties['uiElement'] = {
      'type': 'string',
      'const': uiElement.name,
    };
    required.add('uiElement');

    // Add color configuration from QuanityaWidgetRegistry
    final colorConfigSchema = _generateColorConfigurationFromRegistry(
      uiElement.name,
    );
    if (colorConfigSchema != null) {
      properties['colorConfiguration'] = colorConfigSchema;
      required.add('colorConfiguration');
    }

    // Add unit enum for dimension fields (required — every dimension field needs a unit)
    if (fieldType == FieldEnum.dimension) {
      properties['unit'] = {
        'type': 'string',
        'enum': MeasurementUnit.values.map((u) => u.name).toList(),
        'description':
            'Measurement unit for this dimension field. '
            'Choose the most appropriate unit for what the user is tracking '
            '(e.g., "kilograms" for body weight, "milliliters" for water intake).',
      };
      required.add('unit');
    }

    // Add options for enumerated fields
    if (fieldType == FieldEnum.enumerated) {
      properties['options'] = {
        'type': 'array',
        'items': {'type': 'string', 'minLength': 1, 'maxLength': 50},
        'minItems': 2,
        'maxItems': 20,
        'description': 'List of selectable options for this enumerated field',
      };
      required.add('options');
    }

    // NOTE: defaultValue is NOT included in AI schema because OpenAI strict mode
    // requires ALL properties to be in the 'required' array when using
    // additionalProperties: false. Since defaultValue should be optional,
    // we omit it from AI generation. Users can set defaults manually in the editor.

    return schemaOption;
  }

  /// Generates the JSON Schema option for group fields.
  ///
  /// Group fields contain sub-fields that reuse the scalar field schemas.
  /// The group itself has no uiElement — sub-fields define their own.
  Map<String, dynamic> _generateGroupFieldSchema(
    List<Map<String, dynamic>> scalarFieldSchemas,
  ) {
    return {
      'type': 'object',
      'properties': {
        'label': {
          'type': 'string',
          'description':
              'Human-readable label for this group (e.g., "Sets", "Ingredients")',
          'minLength': 1,
          'maxLength': 50,
        },
        'fieldType': {
          'type': 'string',
          'const': 'group',
        },
        'isList': {
          'type': 'boolean',
          'description':
              'If true, field accepts multiple grouped entries (e.g., multiple sets in a workout)',
        },
        'listMinItems': {
          'type': 'integer',
          'minimum': 0,
          'maximum': 10,
          'description':
              'Minimum number of group items when isList is true. Use 0 for no minimum.',
        },
        'listMaxItems': {
          'type': 'integer',
          'minimum': 1,
          'maximum': 10,
          'description':
              'Maximum number of group items when isList is true. Use 10 for no maximum.',
        },
        'subFields': {
          'type': 'array',
          'items': {
            'anyOf': scalarFieldSchemas,
          },
          'minItems': 1,
          'maxItems': 10,
          'description': 'Sub-fields within this group',
        },
      },
      'required': [
        'label',
        'fieldType',
        'isList',
        'listMinItems',
        'listMaxItems',
        'subFields',
      ],
      'additionalProperties': false,
    };
  }

  /// Generates color configuration schema from QuanityaWidgetRegistry.
  ///
  /// Uses the native widget registry to get colorable properties,
  /// ensuring schema stays in sync with widget implementations.
  /// Ensures strict mode compliance with additionalProperties: false and required array.
  Map<String, dynamic>? _generateColorConfigurationFromRegistry(
    String widgetType,
  ) {
    final schema = QuanityaWidgetRegistry.getSchema(widgetType);
    if (schema == null) return null;

    final availableColors = [
      'color1',
      'color2',
      'color3',
      'neutral1',
      'neutral2',
    ];
    
    // Build strict-mode compliant schema manually
    final properties = <String, dynamic>{};
    final required = <String>[];
    
    for (final prop in schema.properties) {
      properties[prop.name] = {
        'type': 'string',
        'enum': availableColors,
        if (prop.description != null) 'description': prop.description,
      };
      required.add(prop.name);
    }

    return {
      'type': 'object',
      'properties': properties,
      'required': required,
      'additionalProperties': false,
      'description':
          'AI chooses which color slots (color1, color2, neutral1, etc.) to use for each widget property',
    };
  }

  /// Generates color palette schema (AI defines actual hex values).
  ///
  /// AI chooses both the color slot assignments AND the actual hex values.
  Map<String, dynamic> _generateColorPaletteSchema() {
    return {
      'type': 'object',
      'properties': {
        'colors': {
          'type': 'array',
          'items': {
            'type': 'string',
            'pattern': r'^#[0-9A-Fa-f]{6}$',
          },
          'minItems': 2,
          'maxItems': 4,
          'description':
              'AI chooses actual hex values for color1, color2, color3, color4',
        },
        'neutrals': {
          'type': 'array',
          'items': {
            'type': 'string',
            'pattern': r'^#[0-9A-Fa-f]{6}$',
          },
          'minItems': 2,
          'maxItems': 3,
          'description':
              'AI chooses actual hex values for neutral1, neutral2, neutral3',
        },
      },
      'required': ['colors', 'neutrals'],
      'additionalProperties': false,
      'description': 'AI defines the actual color palette with hex values',
    };
  }

  /// Generates font configuration schema.
  /// 
  /// Constrains AI to choose from a curated list of Google Fonts defined in
  /// [AllowedFont] enum. This ensures fonts are available and work well
  /// with the Quanitya aesthetic.
  Map<String, dynamic> _generateFontConfigurationSchema() {
    final allowedFonts = AllowedFont.allFontNames;

    return {
      'type': 'object',
      'properties': {
        'titleFontFamily': {
          'type': 'string',
          'enum': allowedFonts,
          'description': 'Google Font family for titles',
        },
        'subtitleFontFamily': {
          'type': 'string',
          'enum': allowedFonts,
          'description': 'Google Font family for subtitles',
        },
        'bodyFontFamily': {
          'type': 'string',
          'enum': allowedFonts,
          'description': 'Google Font family for body text and field labels',
        },
        'titleWeight': {
          'type': 'integer',
          'enum': [400, 500, 600, 700],
          'description': 'Font weight for titles',
        },
        'subtitleWeight': {
          'type': 'integer',
          'enum': [400, 500, 600],
          'description': 'Font weight for subtitles',
        },
        'bodyWeight': {
          'type': 'integer',
          'enum': [400, 500],
          'description': 'Font weight for body text',
        },
      },
      'required': ['titleFontFamily', 'subtitleFontFamily', 'bodyFontFamily', 'titleWeight', 'subtitleWeight', 'bodyWeight'],
      'additionalProperties': false,
    };
  }

  /// Generates template container style schema for AI selection.
  ///
  /// Constrains AI to choose from the [TemplateContainerStyle] enum values.
  /// Each style defines container geometry (borders, radius, fill).
  Map<String, dynamic> _generateTemplateContainerStyleSchema() {
    return {
      'type': 'string',
      'enum': TemplateContainerStyleX.allStyleNames,
      'description': 'Container geometry style for template fields. '
          'zen=invisible/minimal, soft=rounded/subtle-fill, tech=bordered/engineering, '
          'console=sharp/terminal, drafting=dashed/blueprint, diff=left-bar/documentation, '
          'ledger=bottom-line/accounting, brutal=thick-borders/bold, bubble=pill-shaped/playful',
    };
  }

  /// Generates icon schema for AI selection.
  ///
  /// Constrains AI to choose from a curated list of Material Icons
  /// in the format "material:icon_name" (e.g., "material:fitness_center").
  Map<String, dynamic> _generateIconSchema() {
    // Common icons for different template categories
    final commonIcons = [
      'material:fitness_center',    // Fitness/Exercise
      'material:favorite',          // Health/Mood
      'material:restaurant',        // Food/Nutrition
      'material:bedtime',          // Sleep
      'material:work',             // Work/Productivity
      'material:school',           // Learning/Education
      'material:local_pharmacy',   // Medication/Health
      'material:directions_run',   // Running/Cardio
      'material:self_improvement', // Personal Development
      'material:psychology',       // Mental Health
      'material:water_drop',       // Hydration
      'material:scale',            // Weight/Measurements
      'material:timer',            // Time Tracking
      'material:mood',             // Mood/Emotions
      'material:energy_savings_leaf', // Habits/Environment
      'material:monitor_heart',    // Heart Rate/Vitals
      'material:spa',              // Wellness/Relaxation
      'material:sports',           // Sports/Activities
      'material:book',             // Reading/Journaling
      'material:music_note',       // Music/Entertainment
    ];

    return {
      'type': 'string',
      'enum': commonIcons,
      'description': 'Material icon in format "material:icon_name" that best represents this template\'s purpose. '
          'Choose an icon that clearly communicates what users will be tracking.',
    };
  }
}
