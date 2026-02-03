import 'package:injectable/injectable.dart';

import '../../../../infrastructure/core/try_operation.dart';
import '../../models/type_transition_group.dart';
import '../../models/matrix_vector_scalar/analysis_data_type.dart';
import '../../models/matrix_vector_scalar/operation_registry.dart';
import '../../enums/calculation.dart';
import '../../exceptions/analysis_exceptions.dart';
import '../type_transition_registry.dart';

/// Generates dynamic JSON schemas from the operation registry using type transition groups.
///
/// Uses TypeTransitionRegistry to:
/// - Generate anyOf schemas that enforce valid type transitions
/// - Provide valid operations for AI prompts
/// - Group operations for UI pickers
///
/// This ensures schemas automatically evolve with the codebase.
@injectable
class MvsGraphSchemaGenerator {
  final TypeTransitionRegistry _transitionRegistry;
  final OperationRegistry _operationRegistry;

  MvsGraphSchemaGenerator(this._transitionRegistry, this._operationRegistry);

  /// Factory for testing with custom registries
  factory MvsGraphSchemaGenerator.withRegistries(
    TypeTransitionRegistry transitionRegistry,
    OperationRegistry operationRegistry,
  ) {
    return MvsGraphSchemaGenerator(transitionRegistry, operationRegistry);
  }

  /// Generate JSON Schema that enforces valid type transitions for AI using anyOf groups
  Future<Map<String, dynamic>> generatePipelineSchema(
    AnalysisDataType startType,
  ) {
    return tryMethod(
      () async {
        return {
          '\$schema': 'https://json-schema.org/draft/2020-12/schema',
          'type': 'object',
          'properties': {
            'name': {
              'type': 'string',
              'maxLength': 50,
              'description': 'Short descriptive name for the analysis',
            },
            'description': {
              'type': 'string',
              'maxLength': 200,
              'description': 'What this analysis reveals about the data',
            },
            'reasoning': {
              'type': 'string',
              'maxLength': 300,
              'description': 'Why this analysis is useful for this field type',
            },
            'steps': _generateStepsSchema(startType),
            'useCase': {
              'type': 'string',
              'enum': [
                'trend_analysis',
                'frequency_analysis',
                'summary_stats',
                'pattern_detection',
                'data_quality',
              ],
              'description': 'Primary use case category',
            },
            'confidence': {
              'type': 'number',
              'minimum': 0.0,
              'maximum': 1.0,
              'description': 'Confidence in suggestion quality (0.0-1.0)',
            },
          },
          'required': [
            'name',
            'description',
            'reasoning',
            'steps',
            'useCase',
            'confidence',
          ],
        };
      },
      AnalysisException.new,
      'generatePipelineSchema',
    );
  }

  /// Generate steps schema with anyOf groups for valid type transitions.
  /// Each group represents operations with the same input→output type transition.
  Map<String, dynamic> _generateStepsSchema(AnalysisDataType startType) {
    final reachableGroups = _transitionRegistry.getReachableGroups(startType);

    return {
      'type': 'array',
      'items': {
        'anyOf': reachableGroups.map(_buildGroupSchema).toList(),
      },
      'minItems': 1,
      'maxItems': 4,
      'description': 'Serial steps that chain together',
    };
  }

  /// Build schema for a single transition group
  Map<String, dynamic> _buildGroupSchema(TypeTransitionGroup group) {
    return {
      'type': 'object',
      'properties': {
        'function': {
          'type': 'string',
          'enum': group.operations.map((c) => c.name).toList(),
          'description':
              '${group.fromType.name} → ${group.toType.name} operations',
        },
        'inputKeys': {
          'type': 'array',
          'items': {'type': 'string'},
          'description': 'Keys to read from context (empty for first step)',
        },
        'outputKey': {
          'type': 'string',
          'pattern': r'^[a-zA-Z][a-zA-Z0-9_]*$',
          'description': 'Unique key to store result in context',
        },
        'params': {
          'type': 'object',
          'additionalProperties': true,
          'description': 'Operation parameters (e.g., fieldName)',
        },
      },
      'required': ['function', 'inputKeys', 'outputKey'],
      'additionalProperties': false,
    };
  }

  /// Get all valid operation names reachable from startType (for documentation)
  List<String> _getValidOperationNames(AnalysisDataType startType) {
    final reachableGroups = _transitionRegistry.getReachableGroups(startType);
    final operations = <String>{};

    for (final group in reachableGroups) {
      for (final op in group.operations) {
        operations.add(op.name);
      }
    }

    return operations.toList()..sort();
  }

  /// Generate operation documentation for AI prompt
  Future<Map<String, dynamic>> generateOperationDocs(
    AnalysisDataType startType,
  ) {
    return tryMethod(
      () async {
        final validOperations = _getValidOperationNames(startType);
        final docs = <String, Map<String, dynamic>>{};
        final registry = _operationRegistry;

        for (final opName in validOperations) {
          final calc = Calculation.values
              .where((c) => c.name == opName)
              .firstOrNull;
          if (calc == null) {
            throw AnalysisException('Unknown calculation operation: $opName');
          }

          final definition = registry.getDefinition(calc);
          if (definition == null) {
            throw AnalysisException(
              'No definition found for calculation: ${calc.name}',
            );
          }

          docs[opName] = {
            'label': definition.label,
            'inputType': definition.inputType.name,
            'outputType': definition.outputType.name,
            'description': definition.description,
            'category': definition.category,
            'requiredParams': definition.requiredParams,
            'examples': _getOperationExamples(calc),
            'parameterSchemas': _generateParameterSchemas(
              definition.requiredParams,
            ),
          };
        }

        return docs;
      },
      AnalysisException.new,
      'generateOperationDocs',
    );
  }

  /// Generate parameter schemas for operation
  Map<String, dynamic> _generateParameterSchemas(List<String> requiredParams) {
    final properties = <String, dynamic>{};

    for (final param in requiredParams) {
      properties[param] = switch (param) {
        'fieldName' => {
          'type': 'string',
          'description': 'Name of the field to extract',
        },
        'percentile' => {
          'type': 'number',
          'minimum': 0,
          'maximum': 100,
          'description': 'Percentile value (0-100)',
        },
        'windowDays' => {
          'type': 'integer',
          'minimum': 1,
          'description': 'Rolling window size in days',
        },
        'category' => {
          'type': 'string',
          'description': 'Category value to filter',
        },
        'mapping' => {
          'type': 'object',
          'additionalProperties': {'type': 'string'},
          'description': 'Category mapping (old → new)',
        },
        'operator' => {
          'type': 'string',
          'enum': ['equals', 'greaterThan', 'lessThan', 'contains'],
        },
        'value' => {
          'oneOf': [
            {'type': 'string'},
            {'type': 'number'},
          ],
        },
        _ => {'type': 'string'},
      };
    }

    return {
      'type': 'object',
      'properties': properties,
      'required': requiredParams,
    };
  }

  /// Get example usages for operation
  List<String> _getOperationExamples(Calculation calc) {
    return switch (calc) {
      Calculation.extractField => [
        "Extract weight values: {function: 'extractField', params: {fieldName: 'weight'}}",
      ],
      Calculation.vectorMean => [
        "Calculate average: {function: 'vectorMean', inputKeys: ['values'], outputKey: 'average'}",
      ],
      Calculation.vectorMedian => [
        "Find median: {function: 'vectorMedian', inputKeys: ['values'], outputKey: 'median'}",
      ],
      Calculation.dayOfWeek => [
        "Analyze weekly pattern: {function: 'dayOfWeek', inputKeys: ['timestamps']}",
      ],
      _ => [
        "Use ${calc.name} for ${_transitionRegistry.getGroupForOperation(calc)?.label ?? 'data transformation'}",
      ],
    };
  }

  /// Validate AI-generated pipeline for correct input key chaining.
  /// Type validation is now done by the anyOf schema.
  bool validateAiPipeline(
    List<Map<String, dynamic>> steps,
    AnalysisDataType startType,
  ) {
    if (steps.isEmpty) return false;

    String? previousOutputKey;

    for (int i = 0; i < steps.length; i++) {
      final step = steps[i];

      // Validate required fields
      if (!step.containsKey('function') ||
          !step.containsKey('inputKeys') ||
          !step.containsKey('outputKey')) {
        return false;
      }

      final functionName = step['function'] as String?;
      final inputKeys = step['inputKeys'] as List<dynamic>?;
      final outputKey = step['outputKey'] as String?;

      if (functionName == null || inputKeys == null || outputKey == null) {
        return false;
      }

      // Verify operation exists
      final calc = Calculation.values
          .where((c) => c.name == functionName)
          .firstOrNull;
      if (calc == null) return false;

      // Validate input keys chaining
      if (i == 0) {
        // First step should have empty inputKeys
        if (inputKeys.isNotEmpty) return false;
      } else {
        // Subsequent steps should reference previous outputKey
        if (inputKeys.length != 1 || inputKeys[0] != previousOutputKey) {
          return false;
        }
      }

      previousOutputKey = outputKey;
    }

    return true;
  }

  /// Generate example pipeline for AI prompt
  Map<String, dynamic> generateExamplePipeline(AnalysisDataType startType) {
    final groups = _transitionRegistry.getGroupsFromType(startType);
    if (groups.isEmpty) {
      return _getBasicExample(startType);
    }

    // Find first extractor operation
    final extractorGroup = groups.firstWhere(
      (g) =>
          g.toType == AnalysisDataType.valueVector ||
          g.toType == AnalysisDataType.timestampVector,
      orElse: () => groups.first,
    );

    final firstOp = extractorGroup.operations.first;
    final firstDef = _operationRegistry.getDefinition(firstOp);

    // Build first step
    final step1 = {
      'function': firstOp.name,
      'inputKeys': <String>[],
      'outputKey': 'step1_result',
      'params': _getDefaultParams(firstOp),
    };

    final steps = <Map<String, dynamic>>[step1];

    // Find aggregator for second step if available
    final nextGroups = _transitionRegistry.getGroupsFromType(
      extractorGroup.toType,
    );
    final aggregatorGroup = nextGroups.firstWhere(
      (g) => g.toType == AnalysisDataType.statScalar,
      orElse: () => nextGroups.isNotEmpty ? nextGroups.first : extractorGroup,
    );

    if (nextGroups.isNotEmpty && aggregatorGroup != extractorGroup) {
      final secondOp = aggregatorGroup.operations.first;
      steps.add({
        'function': secondOp.name,
        'inputKeys': ['step1_result'],
        'outputKey': 'step2_result',
        'params': _getDefaultParams(secondOp),
      });
    }

    return {
      'name': 'Example ${firstDef?.label ?? firstOp.name} Analysis',
      'description': 'Analyze ${startType.name} data',
      'reasoning': 'Provides insights into your tracking data',
      'steps': steps,
      'useCase': 'summary_stats',
      'confidence': 0.8,
    };
  }

  Map<String, dynamic> _getDefaultParams(Calculation calc) {
    final def = _operationRegistry.getDefinition(calc);
    if (def == null || def.requiredParams.isEmpty) return {};

    final params = <String, dynamic>{};
    for (final param in def.requiredParams) {
      params[param] = switch (param) {
        'fieldName' => 'FIELD_NAME',
        'percentile' => 50,
        'windowDays' => 7,
        'category' => 'CATEGORY',
        _ => 'VALUE',
      };
    }
    return params;
  }

  Map<String, dynamic> _getBasicExample(AnalysisDataType startType) {
    return {
      'name': 'Basic Analysis',
      'description': 'Perform basic analysis on the data',
      'reasoning': 'Provides fundamental insights into your tracking data',
      'steps': <Map<String, dynamic>>[],
      'useCase': 'summary_stats',
      'confidence': 0.7,
    };
  }

  /// Get available operations grouped by category for UI
  Map<String, List<String>> getAvailableOperationsByCategory(
    AnalysisDataType startType,
  ) {
    return _transitionRegistry
        .getOperationsByCategory(startType)
        .map(
          (category, operations) =>
              MapEntry(category, operations.map((c) => c.name).toList()),
        );
  }
}
