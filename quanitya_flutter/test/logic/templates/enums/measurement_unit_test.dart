import 'package:flutter_test/flutter_test.dart';
import 'package:quanitya_flutter/logic/templates/enums/measurement_dimension.dart';
import 'package:quanitya_flutter/logic/templates/enums/measurement_unit.dart';
import 'package:quanitya_flutter/logic/templates/models/dimension.dart';

void main() {
  group('MeasurementUnit', () {
    group('dimension linkage', () {
      test('kilograms belongs to mass dimension', () {
        expect(
          MeasurementUnit.kilograms.measurementDimension,
          equals(MeasurementDimension.mass),
        );
      });

      test('meters belongs to length dimension', () {
        expect(
          MeasurementUnit.meters.measurementDimension,
          equals(MeasurementDimension.length),
        );
      });

      test('liters belongs to volume dimension', () {
        expect(
          MeasurementUnit.liters.measurementDimension,
          equals(MeasurementDimension.volume),
        );
      });

      test('seconds belongs to time dimension', () {
        expect(
          MeasurementUnit.seconds.measurementDimension,
          equals(MeasurementDimension.time),
        );
      });

      test('SI dimension is derivable through chain', () {
        expect(
          MeasurementUnit.kilograms.measurementDimension.dimension,
          equals(Dimension.M),
        );
      });
    });

    group('display', () {
      test('displayName returns short symbol', () {
        expect(MeasurementUnit.kilograms.displayName, equals('kg'));
        expect(MeasurementUnit.pounds.displayName, equals('lbs'));
        expect(MeasurementUnit.meters.displayName, equals('m'));
      });

      test('fullName returns long name', () {
        expect(MeasurementUnit.kilograms.fullName, equals('Kilograms'));
        expect(MeasurementUnit.pounds.fullName, equals('Pounds'));
      });
    });

    group('conversion stubs', () {
      test('toBase returns value unchanged (stub)', () {
        expect(MeasurementUnit.kilograms.toBase(72.5), equals(72.5));
      });

      test('fromBase returns value unchanged (stub)', () {
        expect(MeasurementUnit.kilograms.fromBase(72.5), equals(72.5));
      });
    });

    group('filtering', () {
      test('unitsFor returns only units of given dimension', () {
        final massUnits = MeasurementUnit.unitsFor(MeasurementDimension.mass);
        expect(massUnits, contains(MeasurementUnit.kilograms));
        expect(massUnits, contains(MeasurementUnit.pounds));
        expect(massUnits, isNot(contains(MeasurementUnit.meters)));
      });

      test('unitsFor returns correct count for each dimension', () {
        expect(
          MeasurementUnit.unitsFor(MeasurementDimension.mass).length,
          equals(6),
        );
        expect(
          MeasurementUnit.unitsFor(MeasurementDimension.length).length,
          equals(8),
        );
        expect(
          MeasurementUnit.unitsFor(MeasurementDimension.volume).length,
          equals(7),
        );
        expect(
          MeasurementUnit.unitsFor(MeasurementDimension.time).length,
          equals(7),
        );
      });
    });
  });
}
