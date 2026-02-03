import 'package:flutter_test/flutter_test.dart';
import 'package:quanitya_flutter/logic/analytics/models/matrix_vector_scalar/matrix_vector_scalar.dart';
import 'package:quanitya_flutter/logic/analytics/models/matrix_vector_scalar/field_value.dart';
import 'package:quanitya_flutter/logic/analytics/enums/calculation.dart';
import 'package:quanitya_flutter/logic/analytics/exceptions/analysis_exceptions.dart';

void main() {
  group('Matrix-Vector-Scalar Type System', () {
    group('TimeSeriesMatrix', () {
      test('creates matrix with single field', () {
        final matrix = TimeSeriesMatrix.fromFieldData(
          timestamps: [
            DateTime(2024, 1, 1),
            DateTime(2024, 1, 2),
          ],
          fieldData: {
            'mood': [FieldValue.numeric(7.5), FieldValue.numeric(8.2)],
          },
        );

        expect(matrix.rows, equals(2));
        expect(matrix.columns, equals(2)); // timestamp + 1 field
        expect(matrix.fieldNames, equals(['mood']));
        expect(matrix.fieldCount, equals(1));
        expect(matrix.hasField('mood'), isTrue);
        expect(matrix.hasValidStructure, isTrue);
      });

      test('creates matrix with multiple fields', () {
        final matrix = TimeSeriesMatrix.fromFieldData(
          timestamps: [DateTime(2024, 1, 1)],
          fieldData: {
            'mood': [FieldValue.numeric(7.5)],
            'energy': [FieldValue.numeric(8.1)],
            'sleep': [FieldValue.numeric(7.2)],
          },
        );

        expect(matrix.columns, equals(4)); // timestamp + 3 fields
        expect(matrix.fieldNames, equals(['mood', 'energy', 'sleep']));
        expect(matrix.fieldCount, equals(3));
        expect(matrix.hasField('mood'), isTrue);
        expect(matrix.hasField('energy'), isTrue);
        expect(matrix.hasField('sleep'), isTrue);
      });

      test('validates field data length matches timestamps', () {
        expect(
          () => TimeSeriesMatrix.fromFieldData(
            timestamps: [DateTime.now(), DateTime.now()],
            fieldData: {
              'mood': [
                FieldValue.numeric(7.5),
              ], // Only 1 value for 2 timestamps
            },
          ),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('requires at least one value field', () {
        expect(
          () => TimeSeriesMatrix.fromFieldData(
            timestamps: [DateTime.now()],
            fieldData: {}, // Empty field data
          ),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('provides guaranteed timestamp access', () {
        final timestamps = [DateTime(2024, 1, 1), DateTime(2024, 1, 2)];
        final matrix = TimeSeriesMatrix.fromFieldData(
          timestamps: timestamps,
          fieldData: {
            'mood': [FieldValue.numeric(7.5), FieldValue.numeric(8.2)],
          },
        );

        final timestampVector = matrix.timestampVector;
        expect(timestampVector.timestamps, equals(timestamps));
        expect(timestampVector.length, equals(2));
      });

      test('provides type-safe column access', () {
        final matrix = TimeSeriesMatrix.fromFieldData(
          timestamps: [DateTime(2024, 1, 1)],
          fieldData: {
            'mood': [FieldValue.numeric(7.5)],
          },
        );

        final moodVector = matrix.getColumnByName('mood');
        expect(moodVector.values, equals([7.5]));

        expect(
          () => matrix.getColumnByName('nonexistent'),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('supports legacy TimeSeriesPoint conversion', () {
        final points = [
          (date: DateTime(2024, 1, 1), value: 7.5),
          (date: DateTime(2024, 1, 2), value: 8.2),
        ];

        final matrix = TimeSeriesMatrix.fromTimeSeriesPoints(
          points,
          fieldName: 'mood',
        );

        expect(matrix.fieldNames, equals(['mood']));
        expect(matrix.getColumnByName('mood').values, equals([7.5, 8.2]));
      });
    });

    group('ValueVector', () {
      test('provides mathematical operations', () {
        final vector = ValueVector([7.5, 8.2, 6.9]);

        expect(vector.length, equals(3));
        expect(vector.sum.value, equals(22.6));
        expect(vector.mean.value, closeTo(7.53, 0.01));
        expect(vector.min.value, equals(6.9));
        expect(vector.max.value, equals(8.2));
        expect(vector.range.value, closeTo(1.3, 0.01));
      });

      test('handles empty vector gracefully', () {
        final vector = ValueVector([]);

        expect(vector.isEmpty, isTrue);
        expect(vector.mean.value, equals(0));
        expect(vector.min.value, equals(0));
        expect(vector.max.value, equals(0));
      });

      test('supports functional operations', () {
        final vector = ValueVector([7.5, 8.2, 6.9, 8.1]);

        final filtered = vector.where((v) => v > 7.0);
        expect(filtered.values, equals([7.5, 8.2, 8.1]));

        final doubled = vector.map((v) => v * 2);
        expect(doubled.values, equals([15.0, 16.4, 13.8, 16.2]));
      });
    });

    group('TimestampVector', () {
      test('provides time-specific operations', () {
        final timestamps = TimestampVector([
          DateTime(2024, 1, 1, 9, 30), // Monday 9:30 AM
          DateTime(2024, 1, 2, 14, 15), // Tuesday 2:15 PM
          DateTime(2024, 1, 3, 8, 45), // Wednesday 8:45 AM
        ]);

        expect(timestamps.length, equals(3));
        expect(
          timestamps.timeSpan.inDays,
          equals(1),
        ); // Jan 1 to Jan 3 = 1 full day + partial days
        expect(timestamps.dayOfWeekVector.values, equals([1, 2, 3]));
        expect(timestamps.hourOfDayVector.values, equals([9, 14, 8]));
        expect(timestamps.isSorted, isTrue);
      });

      test('handles empty timestamp vector', () {
        final timestamps = TimestampVector([]);

        expect(timestamps.isEmpty, isTrue);
        expect(timestamps.timeSpan, equals(Duration.zero));
      });
    });

    group('StatScalar', () {
      test('provides convenience methods', () {
        final scalar = StatScalar(7.567);

        expect(scalar.asDouble, equals(7.567));
        expect(scalar.asInt, equals(7));
        expect(scalar.formatted, equals('7.57'));
        expect(scalar.isPositive, isTrue);
        expect(scalar.isNegative, isFalse);
        expect(scalar.isZero, isFalse);
      });

      test('handles zero and negative values', () {
        final zero = StatScalar(0);
        final negative = StatScalar(-5.2);

        expect(zero.isZero, isTrue);
        expect(zero.isPositive, isFalse);
        expect(zero.isNegative, isFalse);

        expect(negative.isNegative, isTrue);
        expect(negative.isPositive, isFalse);
        expect(negative.isZero, isFalse);
      });
    });

    group('AnalysisResultMvs', () {
      test('provides type-safe unwrapping', () {
        final matrix = TimeSeriesMatrix.fromFieldData(
          timestamps: [DateTime.now()],
          fieldData: {
            'mood': [FieldValue.numeric(7.5)],
          },
        );
        final result = MvsUnion.timeSeriesMatrix(matrix);

        expect(result.dataType, equals(AnalysisDataType.timeSeriesMatrix));
        expect(result.isTimeSeriesMatrix, isTrue);
        expect(result.isValueVector, isFalse);

        final unwrapped = result.asTimeSeriesMatrix;
        expect(unwrapped.fieldNames, equals(['mood']));

        expect(
          () => result.asValueVector,
          throwsA(
            isA<AnalysisException>().having(
              (e) => e.toString(),
              'message',
              contains('Expected ValueVector, got TimeSeriesMatrix'),
            ),
          ),
        );
      });
    });

    group('OperationRegistry', () {
      test('provides operation definitions', () {
        final registry = OperationRegistry.instance;

        final extractFieldDef = registry.getDefinition(
          Calculation.extractField,
        );
        expect(extractFieldDef, isNotNull);
        expect(
          extractFieldDef!.inputType,
          equals(AnalysisDataType.timeSeriesMatrix),
        );
        expect(
          extractFieldDef.outputType,
          equals(AnalysisDataType.valueVector),
        );
        expect(extractFieldDef.requiredParams, contains('fieldName'));
      });

      test('finds compatible operations', () {
        final registry = OperationRegistry.instance;

        final compatibleOps = registry.getCompatibleOperations(
          Calculation.extractField,
        );
        expect(compatibleOps.isNotEmpty, isTrue);

        // extractField outputs ValueVector, so compatible ops should accept ValueVector
        for (final entry in compatibleOps) {
          expect(entry.value.inputType, equals(AnalysisDataType.valueVector));
        }
      });

      test('validates operation sequences', () {
        final registry = OperationRegistry.instance;

        // Valid sequence: Matrix → Vector → Scalar
        final validSequence = [
          Calculation.extractField,
          Calculation.vectorMean,
        ];
        expect(registry.validateOperationSequence(validSequence), isTrue);

        // Invalid sequence: incompatible types
        final invalidSequence = [
          Calculation.extractField, // outputs ValueVector
          Calculation.extractTimestamps, // expects TimeSeriesMatrix
        ];
        expect(registry.validateOperationSequence(invalidSequence), isFalse);
      });

      test('categorizes operations correctly', () {
        final registry = OperationRegistry.instance;

        final matrixExtractors = registry.getOperationsByCategory(
          'Matrix Extractors',
        );
        expect(
          matrixExtractors.any((e) => e.key == Calculation.extractField),
          isTrue,
        );

        final vectorAggregators = registry.getOperationsByCategory(
          'Vector Aggregators',
        );
        expect(
          vectorAggregators.any((e) => e.key == Calculation.vectorMean),
          isTrue,
        );

        final categories = registry.categories;
        expect(categories, contains('Matrix Extractors'));
        expect(categories, contains('Vector Aggregators'));
        expect(categories, isNot(contains('Legacy')));
      });
    });

    group('Integration Tests', () {
      test('complete pipeline flow: Matrix → Vector → Scalar', () {
        // Create initial matrix
        final matrix = TimeSeriesMatrix.fromFieldData(
          timestamps: [
            DateTime(2024, 1, 1),
            DateTime(2024, 1, 2),
            DateTime(2024, 1, 3),
          ],
          fieldData: {
            'mood': [
              FieldValue.numeric(7.5),
              FieldValue.numeric(8.2),
              FieldValue.numeric(6.9),
            ],
          },
        );

        // Step 1: Extract field
        final result1 = MvsUnion.timeSeriesMatrix(matrix);
        expect(result1.dataType, equals(AnalysisDataType.timeSeriesMatrix));

        // Simulate extractField operation
        final extractedVector = matrix.getColumnByName('mood');
        final result2 = MvsUnion.valueVector(extractedVector);
        expect(result2.dataType, equals(AnalysisDataType.valueVector));

        // Step 2: Calculate mean
        final meanScalar = extractedVector.mean;
        final result3 = MvsUnion.statScalar(meanScalar);
        expect(result3.dataType, equals(AnalysisDataType.statScalar));

        // Verify final result
        final finalValue = result3.asStatScalar;
        expect(finalValue.value, closeTo(7.53, 0.01));
      });

      test(
        'time pattern analysis flow: Matrix → TimestampVector → ValueVector',
        () {
          final matrix = TimeSeriesMatrix.fromFieldData(
            timestamps: [
              DateTime(2024, 1, 1), // Monday
              DateTime(2024, 1, 2), // Tuesday
              DateTime(2024, 1, 3), // Wednesday
            ],
            fieldData: {
              'mood': [
                FieldValue.numeric(7.5),
                FieldValue.numeric(8.2),
                FieldValue.numeric(6.9),
              ],
            },
          );

          // Extract timestamps
          final timestampVector = matrix.timestampVector;
          expect(timestampVector.length, equals(3));

          // Extract day-of-week pattern
          final dayOfWeekVector = timestampVector.dayOfWeekVector;
          expect(dayOfWeekVector.values, equals([1, 2, 3])); // Mon, Tue, Wed
        },
      );

      test('multi-field analysis', () {
        final matrix = TimeSeriesMatrix.fromFieldData(
          timestamps: [DateTime(2024, 1, 1), DateTime(2024, 1, 2)],
          fieldData: {
            'mood': [FieldValue.numeric(7.5), FieldValue.numeric(8.2)],
            'energy': [FieldValue.numeric(8.1), FieldValue.numeric(7.9)],
            'sleep': [FieldValue.numeric(7.2), FieldValue.numeric(8.0)],
          },
        );

        // Analyze each field
        final allFields = matrix.valueColumns;
        expect(allFields.keys, equals(['mood', 'energy', 'sleep']));

        for (final entry in allFields.entries) {
          final vector = entry.value;
          final mean = vector.mean;

          expect(vector.length, equals(2));
          expect(mean.value, greaterThan(0));
          // Debug output: $fieldName mean: ${mean.formatted}
        }
      });
    });
  });
}
