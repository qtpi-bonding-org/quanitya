import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:quanitya_flutter/logic/calculations/services/calculation_service.dart';
import 'package:quanitya_flutter/data/repositories/calculation_repository.dart';
import 'package:quanitya_flutter/logic/analytics/models/matrix_vector_scalar/mvs_union.dart';

import 'calculation_service_test.mocks.dart';

@GenerateMocks([CalculationRepository])
void main() {
  late CalculationService service;
  late MockCalculationRepository mockRepo;

  setUp(() {
    mockRepo = MockCalculationRepository();
    service = CalculationService(mockRepo);
  });

  group('CalculationService Legacy Compatibility', () {
    group('basic statistics', () {
      test('mean calculates correctly', () {
        when(mockRepo.mean([1, 2, 3, 4, 5])).thenReturn(3.0);
        when(mockRepo.mean([])).thenReturn(0.0);
        
        expect(service.mean([1, 2, 3, 4, 5]), 3.0);
        expect(service.mean([]), 0.0);
      });

      test('median calculates correctly', () {
        when(mockRepo.median([1, 2, 3, 4, 5])).thenReturn(3.0);
        when(mockRepo.median([1, 2, 3, 4])).thenReturn(2.5);
        
        expect(service.median([1, 2, 3, 4, 5]), 3.0);
        expect(service.median([1, 2, 3, 4]), 2.5);
      });

      test('mode returns most frequent values', () {
        when(mockRepo.mode([1, 2, 2, 3])).thenReturn(2);
        when(mockRepo.mode([1, 2, 3])).thenReturn(null);
        
        expect(service.mode([1, 2, 2, 3]), [2]);
        expect(service.mode([1, 2, 3]), []);
      });

      test('standardDeviation calculates correctly', () {
        when(mockRepo.standardDeviation([2, 4, 4, 4, 5, 5, 7, 9])).thenReturn(2.0);
        
        expect(service.standardDeviation([2, 4, 4, 4, 5, 5, 7, 9]), 2.0);
      });

      test('variance calculates correctly', () {
        when(mockRepo.variance([1, 2, 3, 4, 5])).thenReturn(2.0);
        
        expect(service.variance([1, 2, 3, 4, 5]), 2.0);
      });

      test('percentile calculates correctly', () {
        final values = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10];
        when(mockRepo.percentile(values, 50)).thenReturn(5.5);
        when(mockRepo.percentile(values, 0)).thenReturn(1.0);
        when(mockRepo.percentile(values, 100)).thenReturn(10.0);
        
        expect(service.percentile(values, 50), 5.5);
        expect(service.percentile(values, 0), 1.0);
        expect(service.percentile(values, 100), 10.0);
      });
    });

    group('MVS packaging', () {
      test('scalarToMvs packages single values correctly', () {
        final result = service.scalarToMvs(42.0);
        expect(result.isStatScalar, isTrue);
        expect(result.asStatScalar.value, 42.0);
      });

      test('valuesToMvs packages numeric lists correctly', () {
        final result = service.valuesToMvs([1, 2, 3]);
        expect(result.isValueVector, isTrue);
        expect(result.asValueVector.values, [1, 2, 3]);
      });

      test('categoriesToMvs packages string lists correctly', () {
        final result = service.categoriesToMvs(['a', 'b', 'c']);
        expect(result.isCategoryVector, isTrue);
        expect(result.asCategoryVector.values, ['a', 'b', 'c']);
      });

      test('datesToMvs packages date lists correctly', () {
        final dates = [DateTime(2024, 1, 1), DateTime(2024, 1, 2)];
        final result = service.datesToMvs(dates);
        expect(result.isTimestampVector, isTrue);
        expect(result.asTimestampVector.timestamps, dates);
      });
    });

    group('MVS operations', () {
      test('meanToMvs calculates and packages correctly', () {
        when(mockRepo.mean([1, 2, 3])).thenReturn(2.0);
        
        final result = service.meanToMvs([1, 2, 3]);
        expect(result.isStatScalar, isTrue);
        expect(result.asStatScalar.value, 2.0);
      });

      test('sumToMvs calculates and packages correctly', () {
        when(mockRepo.sum([1, 2, 3])).thenReturn(6.0);
        
        final result = service.sumToMvs([1, 2, 3]);
        expect(result.isStatScalar, isTrue);
        expect(result.asStatScalar.value, 6.0);
      });

      test('countToMvs calculates and packages correctly', () {
        when(mockRepo.count([1, 2, 3])).thenReturn(3);
        
        final result = service.countToMvs([1, 2, 3]);
        expect(result.isStatScalar, isTrue);
        expect(result.asStatScalar.value, 3.0);
      });
    });

    group('repository access', () {
      test('provides direct access to repository', () {
        expect(service.repository, equals(mockRepo));
      });
    });
  });
}
