import 'package:flutter_test/flutter_test.dart';
import 'package:quanitya_flutter/infrastructure/units/unit_service.dart';
import 'package:quanitya_flutter/logic/templates/enums/unit_enum.dart';
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
        expect(units, contains(UnitEnum.kilograms));
        expect(units, contains(UnitEnum.pounds));
        expect(units, contains(UnitEnum.grams));
        expect(units, contains(UnitEnum.ounces));
        expect(units, contains(UnitEnum.stones));
        expect(units, contains(UnitEnum.tons));
        expect(units.length, equals(6));
      });

      test('returns length units for Dimension.L', () {
        final units = service.getUnitsForDimension(Dimension.L);
        expect(units, contains(UnitEnum.meters));
        expect(units, contains(UnitEnum.feet));
        expect(units, contains(UnitEnum.inches));
        expect(units, contains(UnitEnum.centimeters));
        expect(units, contains(UnitEnum.kilometers));
        expect(units, contains(UnitEnum.miles));
        expect(units.length, equals(8));
      });

      test('returns volume units for Dimension.volume (L³)', () {
        final units = service.getUnitsForDimension(Dimension.volume);
        expect(units, contains(UnitEnum.liters));
        expect(units, contains(UnitEnum.gallons));
        expect(units, contains(UnitEnum.milliliters));
        expect(units, contains(UnitEnum.cups));
        expect(units.length, equals(7));
      });

      test('returns time units for Dimension.T', () {
        final units = service.getUnitsForDimension(Dimension.T);
        expect(units, contains(UnitEnum.seconds));
        expect(units, contains(UnitEnum.minutes));
        expect(units, contains(UnitEnum.hours));
        expect(units, contains(UnitEnum.days));
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
          service.isValidUnitForDimension(UnitEnum.kilograms, Dimension.M),
          isTrue,
        );
      });

      test('meters is valid for length dimension', () {
        expect(
          service.isValidUnitForDimension(UnitEnum.meters, Dimension.L),
          isTrue,
        );
      });

      test('liters is valid for volume dimension', () {
        expect(
          service.isValidUnitForDimension(UnitEnum.liters, Dimension.volume),
          isTrue,
        );
      });

      test('kilograms is NOT valid for length dimension', () {
        expect(
          service.isValidUnitForDimension(UnitEnum.kilograms, Dimension.L),
          isFalse,
        );
      });

      test('meters is NOT valid for mass dimension', () {
        expect(
          service.isValidUnitForDimension(UnitEnum.meters, Dimension.M),
          isFalse,
        );
      });
    });

    group('format', () {
      test('formats whole numbers without decimals', () {
        expect(service.format(100, UnitEnum.kilograms), equals('100 kg'));
        expect(service.format(5, UnitEnum.meters), equals('5 m'));
      });

      test('formats large numbers without decimals', () {
        expect(service.format(150.7, UnitEnum.pounds), equals('151 lbs'));
      });

      test('formats medium numbers with 1 decimal', () {
        expect(service.format(75.55, UnitEnum.kilograms), equals('75.5 kg'));
      });

      test('formats small numbers with 2 decimals', () {
        expect(service.format(5.555, UnitEnum.meters), equals('5.55 m'));
      });

      test('formats very small numbers with 3 decimals', () {
        expect(service.format(0.5555, UnitEnum.liters), equals('0.555 L'));
      });

      test('uses correct unit symbols', () {
        expect(service.format(1, UnitEnum.kilograms), equals('1 kg'));
        expect(service.format(1, UnitEnum.pounds), equals('1 lbs'));
        expect(service.format(1, UnitEnum.meters), equals('1 m'));
        expect(service.format(1, UnitEnum.feet), equals('1 ft'));
        expect(service.format(1, UnitEnum.liters), equals('1 L'));
        expect(service.format(1, UnitEnum.seconds), equals('1 s'));
        expect(service.format(1, UnitEnum.hours), equals('1 h'));
      });
    });

    group('getDimension', () {
      test('returns correct dimension for mass units', () {
        expect(service.getDimension(UnitEnum.kilograms), equals(Dimension.M));
        expect(service.getDimension(UnitEnum.pounds), equals(Dimension.M));
      });

      test('returns correct dimension for length units', () {
        expect(service.getDimension(UnitEnum.meters), equals(Dimension.L));
        expect(service.getDimension(UnitEnum.feet), equals(Dimension.L));
      });

      test('returns correct dimension for volume units', () {
        expect(
          service.getDimension(UnitEnum.liters),
          equals(Dimension.volume),
        );
        expect(
          service.getDimension(UnitEnum.gallons),
          equals(Dimension.volume),
        );
      });

      test('returns correct dimension for time units', () {
        expect(service.getDimension(UnitEnum.seconds), equals(Dimension.T));
        expect(service.getDimension(UnitEnum.hours), equals(Dimension.T));
      });
    });

    group('areCompatible', () {
      test('mass units are compatible with each other', () {
        expect(
          service.areCompatible(UnitEnum.kilograms, UnitEnum.pounds),
          isTrue,
        );
        expect(
          service.areCompatible(UnitEnum.grams, UnitEnum.ounces),
          isTrue,
        );
      });

      test('length units are compatible with each other', () {
        expect(
          service.areCompatible(UnitEnum.meters, UnitEnum.feet),
          isTrue,
        );
        expect(
          service.areCompatible(UnitEnum.kilometers, UnitEnum.miles),
          isTrue,
        );
      });

      test('mass and length units are NOT compatible', () {
        expect(
          service.areCompatible(UnitEnum.kilograms, UnitEnum.meters),
          isFalse,
        );
      });

      test('volume and length units are NOT compatible', () {
        // Volume is L³, length is L¹ - different dimensions
        expect(
          service.areCompatible(UnitEnum.liters, UnitEnum.meters),
          isFalse,
        );
      });
    });
  });
}
