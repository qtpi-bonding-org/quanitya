import 'package:flutter_test/flutter_test.dart';
import 'package:quanitya_flutter/logic/analytics/services/ai/mvs_graph_schema_generator.dart';
import 'package:quanitya_flutter/logic/analytics/services/type_transition_registry.dart';
import 'package:quanitya_flutter/logic/analytics/models/matrix_vector_scalar/analysis_data_type.dart';
import 'package:quanitya_flutter/logic/analytics/models/matrix_vector_scalar/operation_registry.dart';
import 'package:quanitya_flutter/logic/analytics/enums/calculation.dart';

void main() {
  group('MvsGraphSchemaGenerator', () {
    late MvsGraphSchemaGenerator generator;

    setUp(() {
      generator = MvsGraphSchemaGenerator(
        TypeTransitionRegistry.instance,
        OperationRegistry.instance,
      );
    });

    group('Schema Generation with anyOf', () {
      test(
        'generates valid JSON schema for timeSeriesMatrix start type',
        () async {
          // Act
          final schema = await generator.generatePipelineSchema(
            AnalysisDataType.timeSeriesMatrix,
          );

          // Assert
          expect(schema, isA<Map<String, dynamic>>());
          expect(
            schema['\$schema'],
            equals('https://json-schema.org/draft/2020-12/schema'),
          );
          expect(schema['type'], equals('object'));

          final properties = schema['properties'] as Map<String, dynamic>;
          expect(
            properties.keys,
            containsAll([
              'name',
              'description',
              'reasoning',
              'steps',
              'useCase',
              'confidence',
            ]),
          );

          final steps = properties['steps'] as Map<String, dynamic>;
          expect(steps['type'], equals('array'));
          expect(steps['minItems'], equals(1));
          expect(steps['maxItems'], equals(4));
        },
      );

      test('generates anyOf structure for steps items', () async {
        // Act
        final schema = await generator.generatePipelineSchema(
          AnalysisDataType.timeSeriesMatrix,
        );

        // Assert - Steps should have anyOf structure
        final steps = schema['properties']['steps'] as Map<String, dynamic>;
        final items = steps['items'] as Map<String, dynamic>;

        expect(items, contains('anyOf'));
        final anyOfGroups = items['anyOf'] as List;
        expect(anyOfGroups.isNotEmpty, isTrue);

        // Each group should have function enum and required fields
        for (final group in anyOfGroups) {
          final groupMap = group as Map<String, dynamic>;
          expect(groupMap['type'], equals('object'));
          expect(groupMap['properties'], contains('function'));
          expect(groupMap['properties'], contains('inputKeys'));
          expect(groupMap['properties'], contains('outputKey'));
          expect(
            groupMap['required'],
            containsAll(['function', 'inputKeys', 'outputKey']),
          );

          final functionProp =
              groupMap['properties']['function'] as Map<String, dynamic>;
          expect(functionProp['type'], equals('string'));
          expect(functionProp['enum'], isA<List>());
          expect((functionProp['enum'] as List).isNotEmpty, isTrue);
        }
      });

      test(
        'generates different anyOf groups for different start types',
        () async {
          // Act
          final matrixSchema = await generator.generatePipelineSchema(
            AnalysisDataType.timeSeriesMatrix,
          );
          final vectorSchema = await generator.generatePipelineSchema(
            AnalysisDataType.valueVector,
          );

          // Assert - Should have different anyOf groups
          final matrixAnyOf =
              matrixSchema['properties']['steps']['items']['anyOf'] as List;
          final vectorAnyOf =
              vectorSchema['properties']['steps']['items']['anyOf'] as List;

          // Extract all operations from each schema
          final matrixOps = _extractAllOperations(matrixAnyOf);
          final vectorOps = _extractAllOperations(vectorAnyOf);

          expect(matrixOps, isNot(equals(vectorOps)));

          // Matrix should include extractors, vector should not
          expect(matrixOps, contains('extractField'));
          expect(vectorOps, isNot(contains('extractField')));
        },
      );

      test('groups operations by type transition in anyOf', () async {
        // Act
        final schema = await generator.generatePipelineSchema(
          AnalysisDataType.timeSeriesMatrix,
        );
        final anyOfGroups =
            schema['properties']['steps']['items']['anyOf'] as List;

        // Assert - Each group should contain operations with same input/output type
        for (final group in anyOfGroups) {
          final functionProp =
              (group as Map<String, dynamic>)['properties']['function'];
          final operations = (functionProp['enum'] as List).cast<String>();
          final description = functionProp['description'] as String;

          // Description should contain type transition info
          expect(description, contains('→'));

          // All operations in group should have same type transition
          final registry = OperationRegistry.instance;
          String? expectedInputType;
          String? expectedOutputType;

          for (final opName in operations) {
            final calc = Calculation.values
                .where((c) => c.name == opName)
                .first;
            final def = registry.getDefinition(calc);

            if (expectedInputType == null) {
              expectedInputType = def!.inputType.name;
              expectedOutputType = def.outputType.name;
            } else {
              expect(
                def!.inputType.name,
                equals(expectedInputType),
                reason: 'All operations in group should have same input type',
              );
              expect(
                def.outputType.name,
                equals(expectedOutputType),
                reason: 'All operations in group should have same output type',
              );
            }
          }
        }
      });

      test('excludes combiner operations (inputCount > 1)', () async {
        // Act
        final schema = await generator.generatePipelineSchema(
          AnalysisDataType.statScalar,
        );
        final anyOfGroups =
            schema['properties']['steps']['items']['anyOf'] as List;
        final allOps = _extractAllOperations(anyOfGroups);

        // Assert - Should not include scalar combiners
        expect(allOps, isNot(contains('scalarAdd')));
        expect(allOps, isNot(contains('scalarSubtract')));
        expect(allOps, isNot(contains('scalarMultiply')));
        expect(allOps, isNot(contains('scalarDivide')));
      });
    });

    group('Type Transition Registry Integration', () {
      test('includes operations reachable from start type', () async {
        // Act
        final schema = await generator.generatePipelineSchema(
          AnalysisDataType.timeSeriesMatrix,
        );
        final allOps = _extractAllOperations(
          schema['properties']['steps']['items']['anyOf'] as List,
        );

        // Assert - Should include matrix extractors and derived operations
        final registry = OperationRegistry.instance;
        final allSerialOps = <String>[];

        for (final calc in Calculation.values) {
          final def = registry.getDefinition(calc);
          if (def != null && def.inputCount == 1) {
            allSerialOps.add(calc.name);
          }
        }

        // Should include at least some operations
        expect(allOps.length, greaterThan(5));

        // All operations should exist in registry
        for (final op in allOps) {
          final calc = Calculation.values
              .where((c) => c.name == op)
              .firstOrNull;
          expect(
            calc,
            isNotNull,
            reason: 'Operation $op should exist in Calculation enum',
          );

          final def = registry.getDefinition(calc!);
          expect(
            def,
            isNotNull,
            reason: 'Operation $op should have definition in registry',
          );
          expect(
            def!.inputCount,
            equals(1),
            reason: 'Operation $op should be serial (inputCount=1)',
          );
        }
      });

      test('respects reachability from start type', () async {
        // Act
        final matrixOps = _extractAllOperations(
          (await generator.generatePipelineSchema(
                AnalysisDataType.timeSeriesMatrix,
              ))['properties']['steps']['items']['anyOf']
              as List,
        );
        final scalarOps = _extractAllOperations(
          (await generator.generatePipelineSchema(
                AnalysisDataType.statScalar,
              ))['properties']['steps']['items']['anyOf']
              as List,
        );

        // Assert - Matrix should have more reachable operations than scalar
        expect(matrixOps.length, greaterThan(scalarOps.length));

        // Matrix should include extractors that scalar cannot use
        expect(matrixOps, contains('extractField'));
        expect(scalarOps, isNot(contains('extractField')));
      });
    });

    group('Operation Documentation', () {
      test('generates operation docs for valid operations', () async {
        // Act
        final docs = await generator.generateOperationDocs(
          AnalysisDataType.timeSeriesMatrix,
        );

        // Assert
        expect(docs, isA<Map<String, dynamic>>());
        expect(docs.isNotEmpty, isTrue);

        // Check structure of first doc
        final firstDoc = docs.values.first as Map<String, dynamic>;
        expect(
          firstDoc.keys,
          containsAll([
            'label',
            'inputType',
            'outputType',
            'description',
            'category',
            'examples',
          ]),
        );

        final examples = firstDoc['examples'] as List;
        expect(examples.isNotEmpty, isTrue);
        expect(examples.first, isA<String>());
      });

      test(
        'includes parameter schemas for operations with required params',
        () async {
          // Act
          final docs = await generator.generateOperationDocs(
            AnalysisDataType.timeSeriesMatrix,
          );

          // Assert - Find an operation with required params
          final extractFieldDoc = docs['extractField'] as Map<String, dynamic>?;
          if (extractFieldDoc != null) {
            final paramSchemas =
                extractFieldDoc['parameterSchemas'] as Map<String, dynamic>;
            expect(paramSchemas['type'], equals('object'));

            final properties =
                paramSchemas['properties'] as Map<String, dynamic>?;
            if (properties != null) {
              expect(properties['fieldName'], isNotNull);
              expect(properties['fieldName']['type'], equals('string'));
            }
          }
        },
      );
    });

    group('Pipeline Validation', () {
      test('validates correct pipeline structure', () {
        // Arrange
        final validPipeline = [
          {
            'function': 'extractField',
            'inputKeys': <String>[],
            'outputKey': 'values',
            'params': {'fieldName': 'test_field'},
          },
          {
            'function': 'vectorMean',
            'inputKeys': ['values'],
            'outputKey': 'average',
            'params': <String, dynamic>{},
          },
        ];

        // Act
        final isValid = generator.validateAiPipeline(
          validPipeline,
          AnalysisDataType.timeSeriesMatrix,
        );

        // Assert
        expect(isValid, isTrue);
      });

      test('rejects pipeline with incorrect input key chaining', () {
        // Arrange - Second step references wrong key
        final invalidPipeline = [
          {
            'function': 'extractField',
            'inputKeys': <String>[],
            'outputKey': 'values',
            'params': {'fieldName': 'test_field'},
          },
          {
            'function': 'vectorMean',
            'inputKeys': ['wrong_key'], // Should be 'values'
            'outputKey': 'average',
            'params': <String, dynamic>{},
          },
        ];

        // Act
        final isValid = generator.validateAiPipeline(
          invalidPipeline,
          AnalysisDataType.timeSeriesMatrix,
        );

        // Assert
        expect(isValid, isFalse);
      });

      test('rejects pipeline with non-empty inputKeys on first step', () {
        // Arrange
        final invalidPipeline = [
          {
            'function': 'extractField',
            'inputKeys': ['some_key'], // First step should have empty inputKeys
            'outputKey': 'values',
            'params': {'fieldName': 'test_field'},
          },
        ];

        // Act
        final isValid = generator.validateAiPipeline(
          invalidPipeline,
          AnalysisDataType.timeSeriesMatrix,
        );

        // Assert
        expect(isValid, isFalse);
      });

      test('rejects empty pipeline', () {
        // Act
        final isValid = generator.validateAiPipeline(
          [],
          AnalysisDataType.timeSeriesMatrix,
        );

        // Assert
        expect(isValid, isFalse);
      });

      test('rejects pipeline with unknown operation', () {
        // Arrange
        final invalidPipeline = [
          {
            'function': 'unknownOperation',
            'inputKeys': <String>[],
            'outputKey': 'values',
            'params': <String, dynamic>{},
          },
        ];

        // Act
        final isValid = generator.validateAiPipeline(
          invalidPipeline,
          AnalysisDataType.timeSeriesMatrix,
        );

        // Assert
        expect(isValid, isFalse);
      });
    });

    group('Example Generation', () {
      test('generates valid example pipeline for each start type', () {
        for (final startType in AnalysisDataType.values) {
          // Act
          final example = generator.generateExamplePipeline(startType);

          // Assert
          expect(example, isA<Map<String, dynamic>>());
          expect(
            example.keys,
            containsAll([
              'name',
              'description',
              'reasoning',
              'steps',
              'useCase',
              'confidence',
            ]),
          );

          final steps = example['steps'] as List;
          final name = example['name'] as String;
          final description = example['description'] as String;

          expect(name.isNotEmpty, isTrue);
          expect(description.isNotEmpty, isTrue);
          expect(example['confidence'], isA<double>());
          expect(example['confidence'], greaterThanOrEqualTo(0.0));
          expect(example['confidence'], lessThanOrEqualTo(1.0));

          // If steps exist, validate they form a valid pipeline
          if (steps.isNotEmpty) {
            final isValid = generator.validateAiPipeline(
              steps.cast<Map<String, dynamic>>(),
              startType,
            );
            expect(
              isValid,
              isTrue,
              reason: 'Generated example for $startType should be valid',
            );
          }
        }
      });
    });

    group('Available Operations by Category', () {
      test('groups operations by category correctly', () async {
        // Act
        final operationsByCategory = generator.getAvailableOperationsByCategory(
          AnalysisDataType.timeSeriesMatrix,
        );

        // Assert
        expect(operationsByCategory, isA<Map<String, List<String>>>());
        expect(operationsByCategory.isNotEmpty, isTrue);

        // Should have Matrix Extractors category for timeSeriesMatrix
        expect(operationsByCategory.keys, contains('Matrix Extractors'));

        final extractors = operationsByCategory['Matrix Extractors']!;
        expect(extractors, contains('extractField'));

        // All operations should be valid
        for (final category in operationsByCategory.keys) {
          final operations = operationsByCategory[category]!;
          expect(operations.isNotEmpty, isTrue);

          for (final op in operations) {
            final calc = Calculation.values
                .where((c) => c.name == op)
                .firstOrNull;
            expect(calc, isNotNull);
          }
        }
      });
    });

    group('Integration with OperationRegistry', () {
      test('automatically includes new operations added to registry', () async {
        // Act
        final schema = await generator.generatePipelineSchema(
          AnalysisDataType.timeSeriesMatrix,
        );
        final allOps = _extractAllOperations(
          schema['properties']['steps']['items']['anyOf'] as List,
        );

        // Assert - Should include operations that exist in current registry
        final registry = OperationRegistry.instance;

        // Check that some known operations are included
        expect(allOps, contains('extractField'));
        expect(allOps, contains('vectorMean'));
        expect(allOps, contains('vectorMax'));

        // Verify all included operations exist in registry
        for (final op in allOps) {
          final calc = Calculation.values
              .where((c) => c.name == op)
              .firstOrNull;
          expect(
            calc,
            isNotNull,
            reason: 'Operation $op should exist in Calculation enum',
          );

          final def = registry.getDefinition(calc!);
          expect(
            def,
            isNotNull,
            reason: 'Operation $op should have definition',
          );
        }
      });
    });
  });
}

/// Helper to extract all operation names from anyOf groups
Set<String> _extractAllOperations(List<dynamic> anyOfGroups) {
  final operations = <String>{};
  for (final group in anyOfGroups) {
    final groupMap = group as Map<String, dynamic>;
    final functionProp =
        groupMap['properties']['function'] as Map<String, dynamic>;
    final ops = (functionProp['enum'] as List).cast<String>();
    operations.addAll(ops);
  }
  return operations;
}
