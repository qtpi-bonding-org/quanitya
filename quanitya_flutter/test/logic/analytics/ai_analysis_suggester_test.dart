import 'package:flutter_test/flutter_test.dart';
import 'package:quanitya_flutter/logic/analytics/services/ai/mvs_graph_schema_generator.dart';
import 'package:quanitya_flutter/logic/analytics/services/type_transition_registry.dart';
import 'package:quanitya_flutter/logic/analytics/models/matrix_vector_scalar/operation_registry.dart';
import 'package:quanitya_flutter/logic/analytics/services/field_context_service.dart';
import 'package:quanitya_flutter/logic/analytics/models/field_analysis_context.dart';
import 'package:quanitya_flutter/logic/analytics/models/matrix_vector_scalar/analysis_data_type.dart';
import 'package:quanitya_flutter/logic/templates/enums/field_enum.dart';

void main() {
  group('AI Pipeline Components', () {
    late MvsGraphSchemaGenerator schemaGenerator;
    late FieldContextService fieldContextService;

    setUp(() {
      schemaGenerator = MvsGraphSchemaGenerator(
        TypeTransitionRegistry.instance,
        OperationRegistry.instance,
      );
      fieldContextService = const FieldContextService();
    });

    group('MvsGraphSchemaGenerator', () {
      test('generates valid JSON schema for pipelines', () async {
        // Act
        final schema = await schemaGenerator.generatePipelineSchema(
          AnalysisDataType.timeSeriesMatrix,
        );

        // Assert
        expect(schema, isA<Map<String, dynamic>>());
        expect(schema['type'], equals('object'));
        expect(schema['properties'], isA<Map<String, dynamic>>());
        expect(schema['properties']['name'], isA<Map<String, dynamic>>());
        expect(schema['properties']['steps'], isA<Map<String, dynamic>>());
        expect(schema['required'], contains('name'));
        expect(schema['required'], contains('steps'));
      });

      test('generates operation documentation', () async {
        // Act
        final docs = await schemaGenerator.generateOperationDocs(
          AnalysisDataType.timeSeriesMatrix,
        );

        // Assert
        expect(docs, isA<Map<String, dynamic>>());
        expect(docs.isNotEmpty, isTrue);

        // Should contain at least extractField operation
        expect(docs.keys, contains('extractField'));

        final extractFieldDoc = docs['extractField'] as Map<String, dynamic>;
        expect(extractFieldDoc['inputType'], equals('timeSeriesMatrix'));
        expect(extractFieldDoc['outputType'], equals('valueVector'));
        expect(extractFieldDoc['requiredParams'], contains('fieldName'));
      });

      test('generates example pipeline', () async {
        // Act
        final example = await schemaGenerator.generateExamplePipeline(
          AnalysisDataType.timeSeriesMatrix,
        );

        // Assert
        expect(example, isA<Map<String, dynamic>>());
        expect(example['name'], isA<String>());
        expect(example['steps'], isA<List>());
        expect(example['useCase'], isA<String>());
        expect(example['confidence'], isA<num>());

        final steps = example['steps'] as List;
        expect(steps.isNotEmpty, isTrue);

        final firstStep = steps.first as Map<String, dynamic>;
        expect(firstStep['function'], isA<String>());
        expect(firstStep['inputKeys'], isA<List>());
        expect(firstStep['outputKey'], isA<String>());
      });

      test('validates AI pipeline structure correctly', () {
        // Arrange - Valid pipeline steps
        final validSteps = [
          {
            'function': 'extractField',
            'inputKeys': [],
            'outputKey': 'values',
            'params': {'fieldName': 'mood'},
          },
          {
            'function': 'vectorMean',
            'inputKeys': ['values'],
            'outputKey': 'average',
            'params': {},
          },
        ];

        // Invalid pipeline - broken chaining
        final invalidSteps = [
          {
            'function': 'extractField',
            'inputKeys': [],
            'outputKey': 'values',
            'params': {'fieldName': 'mood'},
          },
          {
            'function': 'vectorMean',
            'inputKeys': ['wrongKey'], // Should be 'values'
            'outputKey': 'average',
            'params': {},
          },
        ];

        // Act & Assert
        expect(
          schemaGenerator.validateAiPipeline(
            validSteps,
            AnalysisDataType.timeSeriesMatrix,
          ),
          isTrue,
        );
        expect(
          schemaGenerator.validateAiPipeline(
            invalidSteps,
            AnalysisDataType.timeSeriesMatrix,
          ),
          isFalse,
        );
      });
    });

    group('FieldContextService', () {
      test('gets field type characteristics for numeric fields', () {
        // Act
        final integerCharacteristics = fieldContextService
            .getFieldTypeCharacteristics(FieldEnum.integer);
        final floatCharacteristics = fieldContextService
            .getFieldTypeCharacteristics(FieldEnum.float);

        // Assert
        expect(integerCharacteristics['dataType'], equals('numeric'));
        expect(integerCharacteristics['operations'], contains('mean'));
        expect(integerCharacteristics['insights'], contains('averages'));

        expect(floatCharacteristics['dataType'], equals('numeric'));
        expect(floatCharacteristics['operations'], contains('precision'));
      });

      test('gets field type characteristics for categorical fields', () {
        // Act
        final characteristics = fieldContextService.getFieldTypeCharacteristics(
          FieldEnum.enumerated,
        );

        // Assert
        expect(characteristics['dataType'], equals('categorical'));
        expect(characteristics['operations'], contains('mode'));
        expect(characteristics['operations'], contains('frequency'));
        expect(characteristics['insights'], contains('most common'));
      });

      test('gets field context with mock data', () async {
        // Act
        final context = await fieldContextService.getFieldContext(
          templateId: 'test_template',
          fieldId: 'mood',
        );

        // Assert
        expect(context.fieldId, equals('mood'));
        expect(context.fieldName, equals('Mood'));
        expect(context.fieldType, equals(FieldEnum.integer));
        expect(context.startType, equals(AnalysisDataType.timeSeriesMatrix));
        expect(context.sampleValues, isNotEmpty);
        expect(context.dataPointCount, greaterThan(0));
      });
    });

    group('FieldAnalysisContext', () {
      test('creates context with FieldEnum correctly', () {
        // Act
        final context = FieldAnalysisContextExt.create(
          fieldId: 'test_field',
          fieldName: 'Test Field',
          fieldType: FieldEnum.float,
          startType: AnalysisDataType.timeSeriesMatrix,
          sampleValues: ['1.5', '2.3', '3.7'],
          dataPointCount: 25,
          description: 'Test description',
        );

        // Assert
        expect(context.fieldId, equals('test_field'));
        expect(context.fieldName, equals('Test Field'));
        expect(context.fieldType, equals(FieldEnum.float));
        expect(context.fieldTypeString, equals('float'));
        expect(context.startType, equals(AnalysisDataType.timeSeriesMatrix));
        expect(context.sampleValues, equals(['1.5', '2.3', '3.7']));
        expect(context.dataPointCount, equals(25));
        expect(context.description, equals('Test description'));
      });

      test('converts to and from JSON correctly', () {
        // Arrange
        final originalContext = FieldAnalysisContextExt.create(
          fieldId: 'test_field',
          fieldName: 'Test Field',
          fieldType: FieldEnum.boolean,
          startType: AnalysisDataType.timeSeriesMatrix,
          sampleValues: ['true', 'false', 'true'],
          dataPointCount: 15,
        );

        // Act
        final json = originalContext.toJson();
        final reconstructedContext = FieldAnalysisContext.fromJson(json);

        // Assert
        expect(reconstructedContext.fieldId, equals(originalContext.fieldId));
        expect(
          reconstructedContext.fieldName,
          equals(originalContext.fieldName),
        );
        expect(
          reconstructedContext.fieldType,
          equals(originalContext.fieldType),
        );
        expect(
          reconstructedContext.startType,
          equals(originalContext.startType),
        );
        expect(
          reconstructedContext.sampleValues,
          equals(originalContext.sampleValues),
        );
        expect(
          reconstructedContext.dataPointCount,
          equals(originalContext.dataPointCount),
        );
      });
    });
  });
}
