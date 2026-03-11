import 'package:injectable/injectable.dart';

import '../../enums/field_enum.dart';
import '../../enums/ui_element_enum.dart';
import '../../models/shared/field_validator.dart';
import '../../exceptions/template_generation_exception.dart';
import '../engine/unified_schema_generator.dart';
import '../engine/symbolic_combination_generator.dart';

/// Main service that orchestrates the complete AI template generation script.
///
/// Provides a simple public API for generating AI constraint schemas.
/// Uses the simplified direct enum processing approach that eliminates
/// intermediate WidgetTemplateGenerator objects.
///
/// SIMPLIFIED SCRIPT:
/// ```
/// SymbolicCombinationGenerator → UnifiedSchemaGenerator
///         ↓                              ↓
///   (FieldEnum,                    JSON Schema for AI
///    UiElementEnum,
///    List&lt;ValidatorType&gt;)
/// ```
///
/// FOCUS: OpenAI/Anthropic only - Gemini tier is not supported.
///
/// NOTE: Widget rendering is handled by DynamicFieldBuilder, not this class.
/// AI output is parsed into data models (TrackerTemplateModel + TemplateAestheticsModel)
/// and saved to the database. Forms are rendered later from saved models.
@injectable
class AiTemplateGenerator {
  final SymbolicCombinationGenerator _combinationGenerator;
  final UnifiedSchemaGenerator _unifiedSchemaGenerator;

  AiTemplateGenerator(
    this._combinationGenerator,
    this._unifiedSchemaGenerator,
  );

  /// Generates complete JSON Schema for AI constraints using simplified script.
  ///
  /// Orchestrates the enum combination → schema script to create
  /// a comprehensive JSON Schema that includes field schemas, color palette
  /// constraints, and font configuration constraints.
  ///
  /// SIMPLIFIED FLOW:
  /// 1. enumCombos = generator.generateAllValidEnumCombinations()
  /// 2. schema = unifiedSchema.generateSchema(combos)
  ///
  /// Returns a complete JSON Schema suitable for AI template generation.
  ///
  /// Throws [TemplateGenerationException] if any step in the script fails.
  ///
  /// Example:
  /// ```dart
  /// final generator = getIt&lt;AiTemplateGenerator&gt;();
  /// final schema = generator.generateSchema();
  /// // Returns complete JSON Schema with field combinations, colors, fonts
  /// ```
  Map<String, dynamic> generateSchema() {
    try {
      // Step 1: Generate all valid enum combinations
      final enumCombinations = _generateEnumCombinations();

      // Step 2: Convert enum combinations directly to final schema
      final schema = _convertToSchema(enumCombinations);

      return schema;
    } catch (e, stackTrace) {
      throw TemplateGenerationException.scriptOrchestration(
        'Failed to generate complete schema: ${e.toString()}',
        originalException: e,
        context: {
          'stackTrace': stackTrace.toString(),
          'operation': 'generateSchema',
        },
      );
    }
  }

  /// Generates enum combinations with proper error handling.
  List<(FieldEnum, UiElementEnum, List<ValidatorType>)>
  _generateEnumCombinations() {
    try {
      return _combinationGenerator.generateAllValidEnumCombinations();
    } catch (e, stackTrace) {
      throw TemplateGenerationException.combinationGeneration(
        'Failed to generate valid field-widget combinations: ${e.toString()}',
        originalException: e,
        context: {
          'stackTrace': stackTrace.toString(),
          'generatorType': _combinationGenerator.runtimeType.toString(),
        },
      );
    }
  }

  /// Converts enum combinations to schema with proper error handling.
  Map<String, dynamic> _convertToSchema(
    List<(FieldEnum, UiElementEnum, List<ValidatorType>)> enumCombinations,
  ) {
    try {
      return _unifiedSchemaGenerator.generateSchema(enumCombinations);
    } catch (e, stackTrace) {
      throw TemplateGenerationException.schemaConversion(
        'Failed to convert enum combinations to JSON Schema: ${e.toString()}',
        originalException: e,
        context: {
          'stackTrace': stackTrace.toString(),
          'combinationCount': enumCombinations.length,
          'generatorType': _unifiedSchemaGenerator.runtimeType.toString(),
        },
      );
    }
  }
}
