import 'package:injectable/injectable.dart';

import '../../../infrastructure/core/try_operation.dart';
import '../models/matrix_vector_scalar/operation_registry.dart';
import '../models/matrix_vector_scalar/analysis_data_type.dart';
import '../enums/calculation.dart';
import '../exceptions/analysis_exceptions.dart';

/// Generates type-safe JSON Schema for MVS pipeline operations.
///
/// Uses the existing OperationRegistry to create schemas that enforce:
/// - Input/output type compatibility
/// - Required parameter validation
/// - Operation chaining rules
@injectable
class MvsSchemaGenerator {
  final OperationRegistry _operationRegistry;

  const MvsSchemaGenerator(this._operationRegistry);

  /// Generate complete JSON Schema for MVS pipeline operations
  Future<Map<String, dynamic>> generatePipelineSchema() {
    return tryMethod(
      () async {
        return {
          '\$schema': 'https://json-schema.org/draft/2020-12/schema',
          'title': 'MVS Analysis Pipeline',
          'description':
              'Type-safe analysis pipeline with Matrix-Vector-Scalar operations',
          'type': 'object',
          'properties': {
            'steps': {
              'type': 'array',
              'items': {'\$ref': '#/definitions/AnalysisStep'},
              'minItems': 1,
            },
          },
          'required': ['steps'],
          'definitions': {
            'AnalysisStep': _generateStepSchema(),
            'AnalysisDataType': _generateDataTypeSchema(),
            'OperationParams': _generateParamsSchema(),
            ...(_generateOperationSchemas()),
          },
        };
      },
      AnalysisException.new,
      'generatePipelineSchema',
    );
  }

  /// Generate schema for individual analysis step
  Map<String, dynamic> _generateStepSchema() {
    return {
      'type': 'object',
      'properties': {
        'function': {
          'type': 'string',
          'enum': Calculation.values.map((c) => c.name).toList(),
          'description': 'The calculation operation to perform',
        },
        'inputType': {
          '\$ref': '#/definitions/AnalysisDataType',
          'description': 'Expected input data type',
        },
        'outputType': {
          '\$ref': '#/definitions/AnalysisDataType',
          'description': 'Resulting output data type',
        },
        'params': {
          '\$ref': '#/definitions/OperationParams',
          'description': 'Operation-specific parameters',
        },
      },
      'required': ['function', 'inputType', 'outputType'],
      'additionalProperties': false,
    };
  }

  /// Generate schema for data types
  Map<String, dynamic> _generateDataTypeSchema() {
    return {
      'type': 'string',
      'enum': AnalysisDataType.values.map((t) => t.name).toList(),
      'description': 'MVS data type for type-safe operation chaining',
    };
  }

  /// Generate schema for operation parameters
  Map<String, dynamic> _generateParamsSchema() {
    return {
      'type': 'object',
      'properties': {
        'fieldName': {
          'type': 'string',
          'description': 'Name of the field to extract or analyze',
        },
        'percentile': {
          'type': 'number',
          'minimum': 0,
          'maximum': 100,
          'description': 'Percentile value (0-100)',
        },
        'windowDays': {
          'type': 'integer',
          'minimum': 1,
          'description': 'Rolling window size in days',
        },
        'category': {
          'type': 'string',
          'description': 'Category value for filtering',
        },
        'mapping': {
          'type': 'object',
          'additionalProperties': {
            'type': 'string',
          },
          'description': 'Category mapping rules',
        },
        'operator': {
          'type': 'string',
          'enum': ['equals', 'greaterThan', 'lessThan', 'contains'],
          'description': 'Comparison operator for filtering',
        },
        'value': {
          'type': ['string', 'number'],
          'description': 'Value for comparison operations',
        },
      },
      'additionalProperties': false,
    };
  }

  /// Generate individual schemas for each operation
  Map<String, Map<String, dynamic>> _generateOperationSchemas() {
    final schemas = <String, Map<String, dynamic>>{};

    for (final calc in Calculation.values) {
      final definition = _operationRegistry.getDefinition(calc);
      if (definition == null) {
        throw AnalysisException(
          'No definition found for calculation: ${calc.name}',
        );
      }

      schemas[calc.name] = {
        'type': 'object',
        'properties': {
          'function': {
            'const': calc.name,
          },
          'inputType': {
            'const': definition.inputType.name,
          },
          'outputType': {
            'const': definition.outputType.name,
          },
          'params': _generateOperationParamsSchema(definition),
        },
        'required': [
          'function',
          'inputType',
          'outputType',
          if (definition.requiredParams.isNotEmpty) 'params',
        ],
        'additionalProperties': false,
      };
    }

    return schemas;
  }

  /// Generate parameter schema for specific operation
  Map<String, dynamic> _generateOperationParamsSchema(dynamic definition) {
    if (definition.requiredParams.isEmpty) {
      return {
        'type': 'object',
        'additionalProperties': false,
      };
    }

    final properties = <String, dynamic>{};
    final required = <String>[];

    for (final param in definition.requiredParams) {
      required.add(param);

      properties[param] = switch (param) {
        'fieldName' => {
          'type': 'string',
          'minLength': 1,
          'description': 'Field name to extract or analyze',
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
          'minLength': 1,
          'description': 'Category value for filtering',
        },
        'mapping' => {
          'type': 'object',
          'additionalProperties': {'type': 'string'},
          'description': 'Category mapping rules',
        },
        'operator' => {
          'type': 'string',
          'enum': ['equals', 'greaterThan', 'lessThan', 'contains'],
          'description': 'Comparison operator',
        },
        'value' => {
          'type': ['string', 'number'],
          'description': 'Comparison value',
        },
        _ => {
          'type': ['string', 'number'],
          'description': 'Operation parameter',
        },
      };
    }

    return {
      'type': 'object',
      'properties': properties,
      'required': required,
      'additionalProperties': false,
    };
  }

  /// Generate schema for operation sequences (validates type chaining)
  Future<Map<String, dynamic>> generateSequenceSchema() {
    return tryMethod(
      () async {
        return {
          '\$schema': 'https://json-schema.org/draft/2020-12/schema',
          'title': 'MVS Operation Sequence',
          'description': 'Validates that operations chain correctly by type',
          'type': 'array',
          'items': {'\$ref': '#/definitions/AnalysisStep'},
          'minItems': 1,
          // Custom validation would need to be implemented in Dart
          // JSON Schema alone can't validate cross-step type compatibility
          'definitions': {
            'AnalysisStep': _generateStepSchema(),
            'AnalysisDataType': _generateDataTypeSchema(),
          },
        };
      },
      AnalysisException.new,
      'generateSequenceSchema',
    );
  }

  /// Generate schema for specific operation category
  Future<Map<String, dynamic>> generateCategorySchema(String category) {
    return tryMethod(
      () async {
        final operations = _operationRegistry.getOperationsByCategory(category);

        return {
          '\$schema': 'https://json-schema.org/draft/2020-12/schema',
          'title': '$category Operations',
          'description': 'Operations in the $category category',
          'type': 'object',
          'properties': {
            'function': {
              'type': 'string',
              'enum': operations.map((e) => e.key.name).toList(),
            },
          },
          'required': ['function'],
        };
      },
      AnalysisException.new,
      'generateCategorySchema',
    );
  }

  /// Get compatible next operations for a given operation
  Future<List<String>> getCompatibleOperations(String operationName) {
    return tryMethod(
      () async {
        final calculation = Calculation.values
            .where((c) => c.name == operationName)
            .firstOrNull;

        if (calculation == null) {
          throw AnalysisException('Unknown operation: $operationName');
        }

        final compatible = _operationRegistry.getCompatibleOperations(
          calculation,
        );
        return compatible.map((e) => e.key.name).toList();
      },
      AnalysisException.new,
      'getCompatibleOperations',
    );
  }

  /// Validate operation sequence type compatibility
  Future<bool> validateSequence(List<Map<String, dynamic>> steps) {
    return tryMethod(
      () async {
        if (steps.isEmpty) return true;

        for (int i = 1; i < steps.length; i++) {
          final currentOutput = steps[i - 1]['outputType'] as String?;
          final nextInput = steps[i]['inputType'] as String?;

          if (currentOutput == null || nextInput == null) {
            throw AnalysisException(
              'Missing type information in step ${i + 1}',
            );
          }
          if (currentOutput != nextInput) {
            throw AnalysisException(
              'Type mismatch: step $i outputs $currentOutput but step ${i + 1} expects $nextInput',
            );
          }
        }

        return true;
      },
      AnalysisException.new,
      'validateSequence',
    );
  }
}
