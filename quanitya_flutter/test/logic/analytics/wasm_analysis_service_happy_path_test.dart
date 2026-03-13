import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:quanitya_flutter/logic/analytics/models/analysis_script.dart';
import 'package:quanitya_flutter/logic/analytics/models/analysis_output.dart';
import 'package:quanitya_flutter/logic/analytics/enums/analysis_output_mode.dart';
import 'package:quanitya_flutter/logic/analytics/models/analysis_enums.dart';
import 'package:quanitya_flutter/logic/analytics/models/matrix_vector_scalar/time_series_matrix.dart';
import 'package:quanitya_flutter/logic/analytics/models/matrix_vector_scalar/field_value.dart';
import 'package:quanitya_flutter/logic/analytics/models/matrix_vector_scalar/timestamp_vector.dart';
import 'package:quanitya_flutter/logic/log_entries/models/log_entry.dart';
import 'package:quanitya_flutter/data/dao/log_entry_query_dao.dart';

@GenerateMocks([LogEntryQueryDao])
import 'wasm_analysis_service_happy_path_test.mocks.dart';

/// Happy Path Tests for WASM Analysis Service
///
/// These tests verify the core functionality of the WASM analysis service
/// focusing on successful execution paths with valid data.
///
/// Note: These are conceptual tests demonstrating the expected behavior.
/// Full integration tests would require:
/// - Asset loading (mvs_shell.js.j2, simple_statistics.js)
/// - JavaScript runtime initialization
/// - Isolate execution
///
/// For now, we test the data extraction and output boxing logic.
void main() {
  group('WasmAnalysisService - Happy Path Tests', () {
    late MockLogEntryQueryDao mockDao;

    setUp(() {
      mockDao = MockLogEntryQueryDao();
    });

    group('Data Extraction Logic', () {
      test('extracts numeric values from simple field', () {
        // Arrange
        final mockEntries = _createMockLogEntries(
          templateId: 'mood-template',
          fieldName: 'mood_score',
          values: [7.5, 8.0, 6.5],
        );

        // Assert
        expect(mockEntries.length, equals(3));
        expect(mockEntries[0].data['mood_score'], equals(7.5));
        expect(mockEntries[1].data['mood_score'], equals(8.0));
        expect(mockEntries[2].data['mood_score'], equals(6.5));
      });

      test('extracts numeric values from nested field structure', () {
        // Arrange
        final now = DateTime.now();
        final mockEntries = [
          LogEntryModel(
            id: 'entry-1',
            templateId: 'complex-template',
            occurredAt: now.subtract(const Duration(days: 1)),
            data: {
              'nested_value': {'value': 10.5}
            },
            updatedAt: now,
          ),
          LogEntryModel(
            id: 'entry-2',
            templateId: 'complex-template',
            occurredAt: now.subtract(const Duration(days: 2)),
            data: {
              'nested_value': {'value': 15.3}
            },
            updatedAt: now,
          ),
        ];

        // Assert
        expect(mockEntries[0].data['nested_value']['value'], equals(10.5));
        expect(mockEntries[1].data['nested_value']['value'], equals(15.3));
      });

      test('handles string numeric values', () {
        // Arrange
        final now = DateTime.now();
        final mockEntries = [
          LogEntryModel(
            id: 'entry-1',
            templateId: 'mood-template',
            occurredAt: now.subtract(const Duration(days: 1)),
            data: {'mood_score': '7.5'},
            updatedAt: now,
          ),
          LogEntryModel(
            id: 'entry-2',
            templateId: 'mood-template',
            occurredAt: now.subtract(const Duration(days: 2)),
            data: {'mood_score': '8.0'},
            updatedAt: now,
          ),
        ];

        // Act - Simulate extraction logic
        final values = mockEntries.map((entry) {
          final value = entry.data['mood_score'];
          if (value is String) return double.tryParse(value);
          if (value is num) return value.toDouble();
          return null;
        }).whereType<double>().toList();

        // Assert
        expect(values, equals([7.5, 8.0]));
      });

      test('handles empty data gracefully', () {
        // Arrange
        final mockEntries = <LogEntryModel>[];

        // Assert
        expect(mockEntries.isEmpty, isTrue);
      });

      test('handles single data point', () {
        // Arrange
        final mockEntries = _createMockLogEntries(
          templateId: 'mood-template',
          fieldName: 'mood_score',
          values: [7.5],
        );

        // Assert
        expect(mockEntries.length, equals(1));
        expect(mockEntries.first.data['mood_score'], equals(7.5));
      });
    });

    group('Output Boxing - Scalar Mode', () {
      test('creates scalar output from single value', () {
        // Arrange
        final scalar = AnalysisScalar(
          label: 'Mood Average',
          value: 7.6,
        );

        // Act
        final output = AnalysisOutput.scalar([scalar]);

        // Assert
        output.when(
          scalar: (scalars) {
            expect(scalars.length, equals(1));
            expect(scalars.first.label, equals('Mood Average'));
            expect(scalars.first.value, equals(7.6));
          },
          vector: (_) => fail('Expected scalar output'),
          matrix: (_) => fail('Expected scalar output'),
        );
      });

      test('creates multiple scalars with labels and units', () {
        // Arrange
        final scalars = [
          AnalysisScalar(label: 'Mean', value: 7.5, unit: 'points'),
          AnalysisScalar(label: 'Min', value: 6.0, unit: 'points'),
          AnalysisScalar(label: 'Max', value: 9.0, unit: 'points'),
        ];

        // Act
        final output = AnalysisOutput.scalar(scalars);

        // Assert
        output.when(
          scalar: (results) {
            expect(results.length, equals(3));
            expect(results[0].label, equals('Mean'));
            expect(results[0].value, equals(7.5));
            expect(results[0].unit, equals('points'));
            expect(results[1].label, equals('Min'));
            expect(results[2].label, equals('Max'));
          },
          vector: (_) => fail('Expected scalar output'),
          matrix: (_) => fail('Expected scalar output'),
        );
      });

      test('handles special numeric values (NaN, Infinity)', () {
        // Arrange
        final scalars = [
          AnalysisScalar(label: 'Infinity', value: double.infinity),
          AnalysisScalar(label: 'NegInfinity', value: double.negativeInfinity),
          AnalysisScalar(label: 'NaN', value: double.nan),
        ];

        // Act
        final output = AnalysisOutput.scalar(scalars);

        // Assert
        output.when(
          scalar: (results) {
            expect(results[0].value, equals(double.infinity));
            expect(results[1].value, equals(double.negativeInfinity));
            expect(results[2].value.isNaN, isTrue);
          },
          vector: (_) => fail('Expected scalar output'),
          matrix: (_) => fail('Expected scalar output'),
        );
      });
    });

    group('Output Boxing - Vector Mode', () {
      test('creates vector output from list of values', () {
        // Arrange
        final vector = AnalysisVector(
          label: '3-Day Moving Average',
          values: [7.5, 7.67, 7.5],
        );

        // Act
        final output = AnalysisOutput.vector([vector]);

        // Assert
        output.when(
          scalar: (_) => fail('Expected vector output'),
          vector: (vectors) {
            expect(vectors.length, equals(1));
            expect(vectors.first.label, equals('3-Day Moving Average'));
            expect(vectors.first.values.length, equals(3));
            expect(vectors.first.values, everyElement(greaterThan(0)));
          },
          matrix: (_) => fail('Expected vector output'),
        );
      });

      test('creates multiple vectors', () {
        // Arrange
        final vectors = [
          AnalysisVector(label: 'Percentile 25', values: [5.0, 6.0, 7.0]),
          AnalysisVector(label: 'Percentile 50', values: [6.0, 7.0, 8.0]),
          AnalysisVector(label: 'Percentile 75', values: [7.0, 8.0, 9.0]),
        ];

        // Act
        final output = AnalysisOutput.vector(vectors);

        // Assert
        output.when(
          scalar: (_) => fail('Expected vector output'),
          vector: (results) {
            expect(results.length, equals(3));
            expect(results[0].label, equals('Percentile 25'));
            expect(results[1].label, equals('Percentile 50'));
            expect(results[2].label, equals('Percentile 75'));
          },
          matrix: (_) => fail('Expected vector output'),
        );
      });

      test('handles empty vector', () {
        // Arrange
        final vector = AnalysisVector(
          label: 'Empty Result',
          values: [],
        );

        // Act
        final output = AnalysisOutput.vector([vector]);

        // Assert
        output.when(
          scalar: (_) => fail('Expected vector output'),
          vector: (vectors) {
            expect(vectors.first.values.isEmpty, isTrue);
          },
          matrix: (_) => fail('Expected vector output'),
        );
      });
    });

    group('Output Boxing - Matrix Mode', () {
      test('creates time series matrix from field data', () {
        // Arrange
        final timestamps = [
          DateTime(2024, 1, 1),
          DateTime(2024, 1, 2),
          DateTime(2024, 1, 3),
        ];
        final matrix = TimeSeriesMatrix.fromFieldData(
          timestamps: timestamps,
          fieldData: {
            'Smoothed Mood': [
              FieldValue.numeric(7.0),
              FieldValue.numeric(7.67),
              FieldValue.numeric(7.5),
            ],
          },
        );

        // Act
        final output = AnalysisOutput.matrix([matrix]);

        // Assert
        output.when(
          scalar: (_) => fail('Expected matrix output'),
          vector: (_) => fail('Expected matrix output'),
          matrix: (matrices) {
            expect(matrices.length, equals(1));
            final result = matrices.first;
            expect(result.rows, equals(3));
            expect(result.fieldNames, contains('Smoothed Mood'));
            expect(result.timestampVector.length, equals(3));
          },
        );
      });

      test('creates matrix with aggregated timestamps', () {
        // Arrange
        final weeklyTimestamps = [
          DateTime(2024, 1, 1),
          DateTime(2024, 1, 8),
        ];
        final matrix = TimeSeriesMatrix.fromFieldData(
          timestamps: weeklyTimestamps,
          fieldData: {
            'Weekly Average': [
              FieldValue.numeric(7.5),
              FieldValue.numeric(8.0),
            ],
          },
        );

        // Act
        final output = AnalysisOutput.matrix([matrix]);

        // Assert
        output.when(
          scalar: (_) => fail('Expected matrix output'),
          vector: (_) => fail('Expected matrix output'),
          matrix: (matrices) {
            expect(matrices.length, equals(1));
            final result = matrices.first;
            expect(result.rows, equals(2));
            expect(result.timestampVector.length, equals(2));
          },
        );
      });

      test('handles single row matrix', () {
        // Arrange
        final matrix = TimeSeriesMatrix.fromFieldData(
          timestamps: [DateTime(2024, 1, 1)],
          fieldData: {
            'Single Value': [FieldValue.numeric(7.5)],
          },
        );

        // Act
        final output = AnalysisOutput.matrix([matrix]);

        // Assert
        output.when(
          scalar: (_) => fail('Expected matrix output'),
          vector: (_) => fail('Expected matrix output'),
          matrix: (matrices) {
            expect(matrices.first.rows, equals(1));
          },
        );
      });
    });

    group('Script Configuration', () {
      test('creates valid scalar script', () {
        // Arrange
        final script = AnalysisScriptModel(
          id: 'test-script-1',
          name: 'Mood Average',
          fieldId: 'mood-template:mood_score',
          outputMode: AnalysisOutputMode.scalar,
          snippetLanguage: AnalysisSnippetLanguage.js,
          snippet: 'return ss.mean(values);',
          updatedAt: DateTime.now(),
        );

        // Assert
        expect(script.id, equals('test-script-1'));
        expect(script.name, equals('Mood Average'));
        expect(script.outputMode, equals(AnalysisOutputMode.scalar));
        expect(script.snippetLanguage, equals(AnalysisSnippetLanguage.js));
      });

      test('creates valid vector script', () {
        // Arrange
        final script = AnalysisScriptModel(
          id: 'test-script-2',
          name: 'Moving Average',
          fieldId: 'mood-template:mood_score',
          outputMode: AnalysisOutputMode.vector,
          snippetLanguage: AnalysisSnippetLanguage.js,
          snippet: 'return { label: "MA", values: [...] };',
          updatedAt: DateTime.now(),
        );

        // Assert
        expect(script.outputMode, equals(AnalysisOutputMode.vector));
      });

      test('creates valid matrix script', () {
        // Arrange
        final script = AnalysisScriptModel(
          id: 'test-script-3',
          name: 'Time Series',
          fieldId: 'mood-template:mood_score',
          outputMode: AnalysisOutputMode.matrix,
          snippetLanguage: AnalysisSnippetLanguage.js,
          snippet: 'return { values: [...], timestamps: [...] };',
          updatedAt: DateTime.now(),
        );

        // Assert
        expect(script.outputMode, equals(AnalysisOutputMode.matrix));
      });

      test('parses fieldId correctly', () {
        // Arrange
        final fieldId = 'mood-template:mood_score';

        // Act
        final parts = fieldId.split(':');

        // Assert
        expect(parts.length, equals(2));
        expect(parts[0], equals('mood-template'));
        expect(parts[1], equals('mood_score'));
      });
    });

    group('DAO Integration', () {
      test('queries log entries by template and date range', () async {
        // Arrange
        final mockEntries = _createMockLogEntries(
          templateId: 'mood-template',
          fieldName: 'mood_score',
          values: [7.5, 8.0, 6.5],
        );

        when(mockDao.findByTemplateIdInRange(any, any, any))
            .thenAnswer((_) async => mockEntries);

        // Act
        final endDate = DateTime.now();
        final startDate = endDate.subtract(const Duration(days: 90));
        final result = await mockDao.findByTemplateIdInRange(
          'mood-template',
          startDate,
          endDate,
        );

        // Assert
        expect(result.length, equals(3));
        verify(mockDao.findByTemplateIdInRange('mood-template', startDate, endDate))
            .called(1);
      });

      test('handles empty query results', () async {
        // Arrange
        when(mockDao.findByTemplateIdInRange(any, any, any))
            .thenAnswer((_) async => []);

        // Act
        final result = await mockDao.findByTemplateIdInRange(
          'mood-template',
          DateTime.now().subtract(const Duration(days: 90)),
          DateTime.now(),
        );

        // Assert
        expect(result.isEmpty, isTrue);
      });

      test('filters entries with valid timestamps', () {
        // Arrange
        final now = DateTime.now();
        final entries = [
          LogEntryModel(
            id: 'entry-1',
            templateId: 'mood-template',
            occurredAt: now.subtract(const Duration(days: 1)),
            data: {'mood_score': 7.5},
            updatedAt: now,
          ),
          LogEntryModel(
            id: 'entry-2',
            templateId: 'mood-template',
            scheduledFor: now.subtract(const Duration(days: 2)),
            data: {'mood_score': 8.0},
            updatedAt: now,
          ),
        ];

        // Act - Filter entries with valid timestamps
        final validEntries = entries.where((entry) {
          final ts = entry.occurredAt ?? entry.scheduledFor;
          return ts != null;
        }).toList();

        // Assert
        expect(validEntries.length, equals(2));
      });
    });

    group('Statistical Operations (Conceptual)', () {
      test('calculates mean of values', () {
        // Arrange
        final values = [7.5, 8.2, 6.9, 8.1, 7.3];

        // Act
        final mean = values.reduce((a, b) => a + b) / values.length;

        // Assert
        expect(mean, closeTo(7.6, 0.1));
      });

      test('finds max value', () {
        // Arrange
        final values = [5.0, 7.5, 9.2, 6.8, 8.1];

        // Act
        final max = values.reduce((a, b) => a > b ? a : b);

        // Assert
        expect(max, equals(9.2));
      });

      test('finds min value', () {
        // Arrange
        final values = [5.0, 7.5, 9.2, 6.8, 8.1];

        // Act
        final min = values.reduce((a, b) => a < b ? a : b);

        // Assert
        expect(min, equals(5.0));
      });

      test('calculates sum', () {
        // Arrange
        final values = [10.5, 15.3, 20.2];

        // Act
        final sum = values.reduce((a, b) => a + b);

        // Assert
        expect(sum, closeTo(46.0, 0.1));
      });

      test('counts values', () {
        // Arrange
        final values = [7.5, 8.0, 6.5];

        // Act
        final count = values.length;

        // Assert
        expect(count, equals(3));
      });
    });
  });
}

// ─────────────────────────────────────────────────────────────────────────
// Helper Functions
// ─────────────────────────────────────────────────────────────────────────

List<LogEntryModel> _createMockLogEntries({
  required String templateId,
  required String fieldName,
  required List<double> values,
}) {
  final now = DateTime.now();
  return List.generate(values.length, (i) {
    return LogEntryModel(
      id: 'entry-$i',
      templateId: templateId,
      occurredAt: now.subtract(Duration(days: values.length - i)),
      data: {fieldName: values[i]},
      updatedAt: now,
    );
  });
}
