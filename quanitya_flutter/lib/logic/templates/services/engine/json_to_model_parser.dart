import 'package:flutter/material.dart';
import 'package:injectable/injectable.dart';

import '../../enums/ai/template_preset.dart';
import '../../enums/field_enum.dart';
import '../../enums/measurement_unit.dart';
import '../../enums/ui_element_enum.dart';
import '../../models/shared/field_validator.dart';
import '../../models/shared/template_aesthetics.dart';
import '../../models/shared/template_field.dart';
import '../../models/shared/tracker_template.dart';
import '../../exceptions/template_parsing_exception.dart';
import '../shared/default_value_handler.dart';
import '../shared/wcag_compliance_validator.dart';

/// Result of parsing AI-generated JSON into data models.
///
/// Pure data container - no convenience methods.
/// Use extension methods on individual models for runtime conversions:
/// - `aesthetics.toAppColorPalette()` → Flutter Colors
/// - `aesthetics.toFontsConfig()` → FontsConfig
/// - `aesthetics.toPageTemplateConfig(template.name)` → PageTemplateConfig
class ParsedAiTemplate {
  final TrackerTemplateModel template;
  final TemplateAestheticsModel aesthetics;

  const ParsedAiTemplate({
    required this.template,
    required this.aesthetics,
  });
}

/// Parses AI-generated JSON responses into finalized data models.
///
/// Handles the JSON structure produced by UnifiedSchemaGenerator:
/// ```json
/// {
///   "fields": [
///     {"label": "Weight", "fieldType": "integer", "uiElement": "slider", ...},
///     ...
///   ],
///   "colorPalette": {"colors": ["#1976D2", ...], "neutrals": ["#212121", ...]},
///   "fontConfiguration": {"titleWeight": 600, ...}
/// }
/// ```
///
/// Outputs:
/// - TrackerTemplateModel with TemplateField list (PII - encrypted via DualDAO)
/// - TemplateAestheticsModel with palette, fonts, colorMappings (non-PII - direct storage)
///
/// Note: LogEntryModel is NOT created here - users fill that out when logging data.
@injectable
class JsonToModelParser {
  final WcagComplianceValidatorImpl _wcagValidator;
  final DefaultValueHandler _defaultHandler;

  JsonToModelParser(this._wcagValidator, this._defaultHandler);

  static final _hexColorRegex = RegExp(r'^#[0-9A-Fa-f]{6}$');

  /// Parses AI JSON response into TrackerTemplateModel + TemplateAestheticsModel.
  ///
  /// [aiJson] - Raw JSON from AI response
  /// [templateName] - User-provided name for the template
  /// [emoji] - Optional emoji icon for the template (fallback when no icon selected)
  /// [themeName] - Optional theme name for the aesthetics (e.g., "Ocean Vibes")
  ///
  /// Throws [TemplateParsingException] if JSON is invalid.
  ParsedAiTemplate parse({
    required Map<String, dynamic> aiJson,
    required String templateName,
    String? emoji,
    String? themeName,
  }) {
    _validateStructure(aiJson);

    // Parse fields → TrackerTemplateModel
    final fieldsJson = aiJson['fields'] as List<dynamic>;
    final fields = _parseFields(fieldsJson);

    final template = TrackerTemplateModel.create(
      name: templateName,
      fields: fields,
    );

    // Parse aesthetics → TemplateAestheticsModel
    final palette = _parseColorPalette(
      aiJson['colorPalette'] as Map<String, dynamic>,
    );
    final fontConfig = _parseFontConfiguration(
      aiJson['fontConfiguration'] as Map<String, dynamic>?,
    );
    final colorMappings = _extractColorMappings(fieldsJson);
    
    // Parse template container style
    final containerStyle = _parseTemplateContainerStyle(aiJson['templateContainerStyle'] as String?);

    // Parse icon from AI (takes priority over emoji parameter)
    final aiIcon = aiJson['icon'] as String?;

    final aesthetics = TemplateAestheticsModel.create(
      templateId: template.id,
      themeName: themeName,
      icon: aiIcon, // Use AI-generated icon
      emoji: emoji, // Fallback emoji
      palette: palette,
      fontConfig: fontConfig,
      colorMappings: colorMappings,
      containerStyle: containerStyle,
    );

    return ParsedAiTemplate(template: template, aesthetics: aesthetics);
  }

  /// Validates top-level JSON structure
  void _validateStructure(Map<String, dynamic> json) {
    if (!json.containsKey('fields')) {
      throw TemplateParsingException.missingField('fields');
    }

    final fields = json['fields'];
    if (fields is! List || fields.isEmpty) {
      throw TemplateParsingException.invalidField('fields', fields);
    }

    if (!json.containsKey('colorPalette')) {
      throw TemplateParsingException.missingField('colorPalette');
    }
  }

  /// Parses fields array into TemplateField list
  List<TemplateField> _parseFields(List<dynamic> fieldsJson) {
    final results = <TemplateField>[];

    for (int i = 0; i < fieldsJson.length; i++) {
      try {
        final fieldJson = fieldsJson[i] as Map<String, dynamic>;
        final field = _parseField(fieldJson);
        results.add(field);
      } catch (e) {
        if (e is TemplateParsingException) {
          throw TemplateParsingException(
            e.message,
            originalException: e.originalException,
            stackTrace: e.stackTrace,
            jsonPath: 'fields[$i]',
          );
        }
        throw TemplateParsingException(
          'Failed to parse field at index $i: $e',
          originalException: e,
          jsonPath: 'fields[$i]',
        );
      }
    }

    return results;
  }

  /// Parses a single field from AI JSON
  TemplateField _parseField(Map<String, dynamic> fieldJson) {
    final label = fieldJson['label'] as String? ?? 'Untitled';
    final fieldTypeName = fieldJson['fieldType'] as String?;

    if (fieldTypeName == null) {
      throw TemplateParsingException.missingField('fieldType');
    }

    final fieldType = _parseFieldType(fieldTypeName);
    final validators = _createValidators(fieldType, fieldJson);
    
    // Parse isList flag
    final isList = fieldJson['isList'] as bool? ?? false;
    
    // Parse list bounds and add list validator if meaningful
    // Treat 0 as "no minimum" and 10 as "no maximum" (unbounded)
    if (isList) {
      final listMinItems = fieldJson['listMinItems'] as int?;
      final listMaxItems = fieldJson['listMaxItems'] as int?;
      
      // Only add validator if there are actual constraints
      // 0 = no min, 10 = no max (effectively unbounded)
      final effectiveMin = (listMinItems != null && listMinItems > 0) ? listMinItems : null;
      final effectiveMax = (listMaxItems != null && listMaxItems < 10) ? listMaxItems : null;
      
      if (effectiveMin != null || effectiveMax != null) {
        validators.add(
          FieldValidator.create(
            validatorType: ValidatorType.list,
            validatorData: {
              if (effectiveMin != null) 'minItems': effectiveMin,
              if (effectiveMax != null) 'maxItems': effectiveMax,
            },
          ),
        );
      }
    }
    
    // Parse uiElement - directly from enum name (rigorously derived from symbolic combinations)
    final uiElementName = fieldJson['uiElement'] as String?;
    final uiElement = _parseUiElementFromName(uiElementName);
    
    // Parse options for enumerated and multiEnum fields
    final options = (fieldType == FieldEnum.enumerated || fieldType == FieldEnum.multiEnum)
        ? (fieldJson['options'] as List<dynamic>?)?.cast<String>()
        : null;
    
    // Parse unit for dimension fields
    final MeasurementUnit? unit;
    if (fieldType == FieldEnum.dimension) {
      final unitName = fieldJson['unit'] as String?;
      if (unitName == null) {
        throw TemplateParsingException(
          'Dimension field "$label" requires a unit',
          jsonPath: 'unit',
        );
      }
      try {
        unit = MeasurementUnit.values.firstWhere((u) => u.name == unitName);
      } catch (_) {
        throw TemplateParsingException.invalidField('unit', unitName);
      }
    } else {
      unit = null;
    }

    // Parse sub-fields for group type
    List<TemplateField>? parsedSubFields;
    if (fieldType == FieldEnum.group) {
      final subFieldsJson = fieldJson['subFields'] as List<dynamic>?;
      if (subFieldsJson == null || subFieldsJson.isEmpty) {
        throw TemplateParsingException(
          'Group field "$label" requires subFields',
          jsonPath: 'subFields',
        );
      }
      parsedSubFields = _parseFields(subFieldsJson);
      // Enforce one-level nesting
      for (final sf in parsedSubFields) {
        if (sf.type == FieldEnum.group) {
          throw TemplateParsingException(
            'Nested groups not allowed: "${sf.label}" inside "$label"',
            jsonPath: 'subFields',
          );
        }
      }
    }

    // Parse and validate defaultValue (AI only sends for int/float/text)
    final rawDefault = fieldJson['defaultValue'];
    final defaultValue = _defaultHandler.parseDefault(rawDefault, fieldType);

    // Build field first to validate default against it
    final field = TemplateField.create(
      label: label,
      type: fieldType,
      uiElement: uiElement,
      isList: isList,
      unit: unit,
      validators: validators,
      options: options,
      defaultValue: defaultValue,
      subFields: parsedSubFields,
    );
    
    // Validate default if present
    if (defaultValue != null) {
      final error = _defaultHandler.validateDefault(defaultValue, field);
      if (error != null) {
        throw TemplateParsingException(
          'Invalid defaultValue for "$label": $error',
          jsonPath: 'defaultValue',
        );
      }
    }

    return field;
  }

  /// Parses UI element enum directly from enum name (e.g., "slider", "textField")
  UiElementEnum? _parseUiElementFromName(String? uiElementName) {
    if (uiElementName == null) return null;

    try {
      return UiElementEnum.values.firstWhere((e) => e.name == uiElementName);
    } catch (e) {
      return null; // Invalid enum name
    }
  }

  /// Parses field type enum from string
  FieldEnum _parseFieldType(String fieldTypeName) {
    try {
      return FieldEnum.values.firstWhere((e) => e.name == fieldTypeName);
    } catch (e) {
      throw TemplateParsingException.invalidField('fieldType', fieldTypeName);
    }
  }


  /// Creates validators based on field type and AI-provided constraints
  List<FieldValidator> _createValidators(
    FieldEnum fieldType,
    Map<String, dynamic> fieldJson,
  ) {
    final validators = <FieldValidator>[];
    final rawArgs = fieldJson['args'];
    final args = rawArgs is Map
        ? Map<String, dynamic>.from(rawArgs)
        : <String, dynamic>{};

    switch (fieldType) {
      case FieldEnum.integer:
      case FieldEnum.float:
        final validatorData = <String, dynamic>{};
        if (args.containsKey('min')) validatorData['min'] = args['min'];
        if (args.containsKey('max')) validatorData['max'] = args['max'];
        if (args.containsKey('step')) validatorData['step'] = args['step'];

        if (validatorData.isNotEmpty) {
          validators.add(
            FieldValidator.create(
              validatorType: ValidatorType.numeric,
              validatorData: validatorData,
            ),
          );
        }

      case FieldEnum.text:
        final validatorData = <String, dynamic>{};
        if (args.containsKey('minLength')) {
          validatorData['minLength'] = args['minLength'];
        }
        if (args.containsKey('maxLength')) {
          validatorData['maxLength'] = args['maxLength'];
        }

        if (validatorData.isNotEmpty) {
          validators.add(
            FieldValidator.create(
              validatorType: ValidatorType.text,
              validatorData: validatorData,
            ),
          );
        }

      case FieldEnum.enumerated:
      case FieldEnum.multiEnum:
        final options = fieldJson['options'] as List<dynamic>?;
        if (options != null) {
          validators.add(
            FieldValidator.create(
              validatorType: ValidatorType.enumerated,
              validatorData: {'options': options},
            ),
          );
        }

      case FieldEnum.dimension:
        // Dimension fields are numeric with a unit — support min/max validation
        final dimValidatorData = <String, dynamic>{};
        if (args.containsKey('min')) dimValidatorData['min'] = args['min'];
        if (args.containsKey('max')) dimValidatorData['max'] = args['max'];

        if (dimValidatorData.isNotEmpty) {
          validators.add(
            FieldValidator.create(
              validatorType: ValidatorType.numeric,
              validatorData: dimValidatorData,
            ),
          );
        }

      case FieldEnum.boolean:
      case FieldEnum.datetime:
      case FieldEnum.reference:
      case FieldEnum.location:
      case FieldEnum.group:
        // No additional validators needed
        break;
    }

    return validators;
  }

  /// Parses color palette from AI JSON and applies WCAG AA compliance adjustment.
  ///
  /// All colors are adjusted to meet contrast requirements against Washi White background.
  /// - Accents: adjusted for interactive elements (3:1 ratio)
  /// - Tones: adjusted for text (4.5:1 ratio)
  ///
  /// Accepts both new format (accents/tones) and legacy format (colors/neutrals).
  ColorPaletteData _parseColorPalette(Map<String, dynamic> paletteJson) {
    // Support both new (accents/tones) and legacy (colors/neutrals) formats
    final accentsJson =
        paletteJson['accents'] as List<dynamic>? ??
        paletteJson['colors'] as List<dynamic>?;
    final tonesJson =
        paletteJson['tones'] as List<dynamic>? ??
        paletteJson['neutrals'] as List<dynamic>?;

    if (accentsJson == null || accentsJson.isEmpty) {
      throw TemplateParsingException.colorPalette(
        'accents (or colors) array is required',
      );
    }

    // Parse and adjust accent colors (interactive elements - 3:1 ratio)
    final accents = accentsJson.map((c) {
      final hex = _validateHexColor(c as String);
      final color = _hexToColor(hex);
      final adjusted = _wcagValidator.adjustForWashiWhite(color, isText: false);
      return _colorToHex(adjusted);
    }).toList();

    // Parse and adjust tone colors (text - 4.5:1 ratio)
    final tones = (tonesJson ?? ['#4D5B60', '#7A8A8F']).map((c) {
      final hex = _validateHexColor(c as String);
      final color = _hexToColor(hex);
      final adjusted = _wcagValidator.adjustForWashiWhite(color, isText: true);
      return _colorToHex(adjusted);
    }).toList();

    return ColorPaletteData(accents: accents, tones: tones);
  }

  /// Converts hex string to Flutter Color
  Color _hexToColor(String hex) {
    final hexCode = hex.replaceFirst('#', '');
    return Color(int.parse('FF$hexCode', radix: 16));
  }

  /// Converts Flutter Color to hex string
  String _colorToHex(Color color) {
    final r = (color.r * 255.0).round().clamp(0, 255).toRadixString(16).padLeft(2, '0');
    final g = (color.g * 255.0).round().clamp(0, 255).toRadixString(16).padLeft(2, '0');
    final b = (color.b * 255.0).round().clamp(0, 255).toRadixString(16).padLeft(2, '0');
    return '#${r.toUpperCase()}${g.toUpperCase()}${b.toUpperCase()}';
  }

  /// Validates and normalizes hex color string
  String _validateHexColor(String color) {
    final normalized = color.toUpperCase();
    if (!_hexColorRegex.hasMatch(normalized)) {
      throw TemplateParsingException.colorPalette('Invalid hex color: $color');
    }
    return normalized;
  }

  /// Parses font configuration from AI JSON
  FontConfigData _parseFontConfiguration(Map<String, dynamic>? fontJson) {
    if (fontJson == null) return FontConfigData.defaults();

    return FontConfigData(
      titleFontFamily: fontJson['titleFontFamily'] as String?,
      subtitleFontFamily: fontJson['subtitleFontFamily'] as String?,
      bodyFontFamily: fontJson['bodyFontFamily'] as String?,
      titleWeight: _parseFontWeight(fontJson['titleWeight'], 600),
      subtitleWeight: _parseFontWeight(fontJson['subtitleWeight'], 400),
      bodyWeight: _parseFontWeight(fontJson['bodyWeight'], 400),
    );
  }

  /// Parses font weight, handling both int and string formats
  int _parseFontWeight(dynamic weight, int defaultWeight) {
    if (weight == null) return defaultWeight;
    if (weight is int) return weight.clamp(100, 900);
    if (weight is String) {
      final parsed = int.tryParse(weight.replaceAll('w', ''));
      return parsed?.clamp(100, 900) ?? defaultWeight;
    }
    return defaultWeight;
  }

  /// Parses template container style from AI JSON
  TemplateContainerStyle? _parseTemplateContainerStyle(String? styleName) {
    debugPrint('🎨 Parsing templateContainerStyle: $styleName');
    if (styleName == null) {
      debugPrint('🎨 templateContainerStyle is null');
      return null;
    }
    final result = TemplateContainerStyleX.fromName(styleName);
    debugPrint('🎨 Parsed templateContainerStyle result: $result');
    return result;
  }

  /// Extracts color mappings from fields (first unique per uiElement)
  ///
  /// AI provides colorConfiguration per field. We store only the first
  /// unique mapping per uiElement to avoid redundancy.
  Map<String, Map<String, String>> _extractColorMappings(
    List<dynamic> fieldsJson,
  ) {
    final mappings = <String, Map<String, String>>{};

    for (final fieldJson in fieldsJson) {
      final field = fieldJson as Map<String, dynamic>;
      final uiElement = field['uiElement'] as String?;
      final colorConfig = field['colorConfiguration'] as Map<String, dynamic>?;

      if (uiElement != null &&
          colorConfig != null &&
          !mappings.containsKey(uiElement)) {
        // Convert to Map<String, String> (color slot references)
        mappings[uiElement] = colorConfig.map(
          (key, value) => MapEntry(key, value.toString()),
        );
      }
    }

    return mappings;
  }
}
