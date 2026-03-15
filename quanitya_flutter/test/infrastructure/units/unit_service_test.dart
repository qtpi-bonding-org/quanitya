import 'package:flutter_test/flutter_test.dart';
import 'package:quanitya_flutter/infrastructure/units/unit_service.dart';
import 'package:quanitya_flutter/logic/templates/enums/measurement_unit.dart';
import 'package:quanitya_flutter/logic/templates/models/dimension.dart';

void main() {
  late UnitService service;

  setUp(() {
    service = UnitService();
  });

  group('UnitService', () {
    group('getUnitsForDimension', () {
      test('returns mass units for Dimension.M', () {
        final units = service.getUnitsForDimension(Dimension.M);
        expect(units, contains(MeasurementUnit.kilograms));
        expect(units, contains(MeasurementUnit.pounds));
        expect(units, contains(MeasurementUnit.grams));
        expect(units, contains(MeasurementUnit.ounces));
        expect(units, contains(MeasurementUnit.stones));
        expect(units, contains(MeasurementUnit.tons));
        expect(units.length, equals(6));
      });

      test('returns length units for Dimension.L', () {
        final units = service.getUnitsForDimension(Dimension.L);
        expect(units, contains(MeasurementUnit.meters));
        expect(units, contains(MeasurementUnit.feet));
        expect(units, contains(MeasurementUnit.inches));
        expect(units, contains(MeasurementUnit.centimeters));
        expect(units, contains(MeasurementUnit.kilometers));
        expect(units, contains(MeasurementUnit.miles));
        expect(units.length, equals(8));
      });

      test('returns volume units for Dimension.volume (L³)', () {
        final units = service.getUnitsForDimension(Dimension.volume);
        expect(units, contains(MeasurementUnit.liters));
        expect(units, contains(MeasurementUnit.gallons));
        expect(units, contains(MeasurementUnit.milliliters));
        expect(units, contains(MeasurementUnit.cups));
        expect(units.length, equals(7));
      });

      test('returns time units for Dimension.T', () {
        final units = service.getUnitsForDimension(Dimension.T);
        expect(units, contains(MeasurementUnit.seconds));
        expect(units, contains(MeasurementUnit.minutes));
        expect(units, contains(MeasurementUnit.hours));
        expect(units, contains(MeasurementUnit.days));
        expect(units.length, equals(7));
      });

      test('returns empty list for compound dimensions without units', () {
        final units = service.getUnitsForDimension(Dimension.velocity);
        expect(units, isEmpty);
      });
    });

    group('isValidUnitForDimension', () {
      test('kilograms is valid for mass dimension', () {
        expect(
          service.isValidUnitForDimension(MeasurementUnit.kilograms, Dimension.M),
          isTrue,
        );
      });

      test('meters is valid for length dimension', () {
        expect(
          service.isValidUnitForDimension(MeasurementUnit.meters, Dimension.L),
          isTrue,
        );
      });

      test('liters is valid for volume dimension', () {
        expect(
          service.isValidUnitForDimension(MeasurementUnit.liters, Dimension.volume),
          isTrue,
        );
      });

      test('kilograms is NOT valid for length dimension', () {
        expect(
          service.isValidUnitForDimension(MeasurementUnit.kilograms, Dimension.L),
          isFalse,
        );
      });

      test('meters is NOT valid for mass dimension', () {
        expect(
          service.isValidUnitForDimension(MeasurementUnit.meters, Dimension.M),
          isFalse,
        );
      });
    });

    group('format', () {
      test('formats whole numbers without decimals', () {
        expect(service.format(100, MeasurementUnit.kilograms), equals('100 kg'));
        expect(service.format(5, MeasurementUnit.meters), equals('5 m'));
      });

      test('formats large numbers without decimals', () {
        expect(service.format(150.7, MeasurementUnit.pounds), equals('151 lbs'));
      });

      test('formats medium numbers with 1 decimal', () {
        expect(service.format(75.55, MeasurementUnit.kilograms), equals('75.5 kg'));
      });

      test('formats small numbers with 2 decimals', () {
        expect(service.format(5.555, MeasurementUnit.meters), equals('5.55 m'));
      });

      test('formats very small numbers with 3 decimals', () {
        expect(service.format(0.5555, MeasurementUnit.liters), equals('0.555 L'));
      });

      test('uses correct unit symbols', () {
        expect(service.format(1, MeasurementUnit.kilograms), equals('1 kg'));
        expect(service.format(1, MeasurementUnit.pounds), equals('1 lbs'));
        expect(service.format(1, MeasurementUnit.meters), equals('1 m'));
        expect(service.format(1, MeasurementUnit.feet), equals('1 ft'));
        expect(service.format(1, MeasurementUnit.liters), equals('1 L'));
        expect(service.format(1, MeasurementUnit.seconds), equals('1 s'));
        expect(service.format(1, MeasurementUnit.hours), equals('1 h'));
      });
    });

    group('getDimension', () {
      test('returns correct dimension for mass units', () {
        expect(service.getDimension(MeasurementUnit.kilograms), equals(Dimension.M));
        expect(service.getDimension(MeasurementUnit.pounds), equals(Dimension.M));
      });

      test('returns correct dimension for length units', () {
        expect(service.getDimension(MeasurementUnit.meters), equals(Dimension.L));
        expect(service.getDimension(MeasurementUnit.feet), equals(Dimension.L));
      });

      test('returns correct dimension for volume units', () {
        expect(
          service.getDimension(MeasurementUnit.liters),
          equals(Dimension.volume),
        );
        expect(
          service.getDimension(MeasurementUnit.gallons),
          equals(Dimension.volume),
        );
      });

      test('returns correct dimension for time units', () {
        expect(service.getDimension(MeasurementUnit.seconds), equals(Dimension.T));
        expect(service.getDimension(MeasurementUnit.hours), equals(Dimension.T));
      });
    });

    group('areCompatible', () {
      test('mass units are compatible with each other', () {
        expect(
          service.areCompatible(MeasurementUnit.kilograms, MeasurementUnit.pounds),
          isTrue,
        );
        expect(
          service.areCompatible(MeasurementUnit.grams, MeasurementUnit.ounces),
          isTrue,
        );
      });

      test('length units are compatible with each other', () {
        expect(
          service.areCompatible(MeasurementUnit.meters, MeasurementUnit.feet),
          isTrue,
        );
        expect(
          service.areCompatible(MeasurementUnit.kilometers, MeasurementUnit.miles),
          isTrue,
        );
      });

      test('mass and length units are NOT compatible', () {
        expect(
          service.areCompatible(MeasurementUnit.kilograms, MeasurementUnit.meters),
          isFalse,
        );
      });

      test('volume and length units are NOT compatible', () {
        // Volume is L³, length is L¹ - different dimensions
        expect(
          service.areCompatible(MeasurementUnit.liters, MeasurementUnit.meters),
          isFalse,
        );
      });
    });
  });
}
