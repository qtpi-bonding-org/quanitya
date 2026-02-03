import 'package:flutter_test/flutter_test.dart';
import 'package:quanitya_flutter/logic/templates/models/dimension.dart';

void main() {
  group('Dimension', () {
    group('base dimensions', () {
      test('dimensionless has all zero exponents', () {
        expect(Dimension.dimensionless.isDimensionless, isTrue);
        expect(Dimension.dimensionless.length, equals(0));
        expect(Dimension.dimensionless.mass, equals(0));
        expect(Dimension.dimensionless.time, equals(0));
      });

      test('base dimensions are correctly defined', () {
        expect(Dimension.L.length, equals(1));
        expect(Dimension.L.mass, equals(0));

        expect(Dimension.M.mass, equals(1));
        expect(Dimension.M.length, equals(0));

        expect(Dimension.T.time, equals(1));
        expect(Dimension.T.mass, equals(0));
      });

      test('base dimensions are identified as base', () {
        expect(Dimension.L.isBase, isTrue);
        expect(Dimension.M.isBase, isTrue);
        expect(Dimension.T.isBase, isTrue);
        expect(Dimension.I.isBase, isTrue);
        expect(Dimension.theta.isBase, isTrue);
        expect(Dimension.N.isBase, isTrue);
        expect(Dimension.J.isBase, isTrue);
      });
    });

    group('multiplication', () {
      test('L * L = L²', () {
        final area = Dimension.L * Dimension.L;
        expect(area.length, equals(2));
        expect(area, equals(Dimension.area));
      });

      test('L * L * L = L³', () {
        final volume = Dimension.L * Dimension.L * Dimension.L;
        expect(volume.length, equals(3));
        expect(volume, equals(Dimension.volume));
      });

      test('M * L / T² = force', () {
        final force = Dimension.M * Dimension.L / (Dimension.T * Dimension.T);
        expect(force, equals(Dimension.force));
        expect(force.mass, equals(1));
        expect(force.length, equals(1));
        expect(force.time, equals(-2));
      });
    });

    group('division', () {
      test('L / T = velocity', () {
        final velocity = Dimension.L / Dimension.T;
        expect(velocity, equals(Dimension.velocity));
        expect(velocity.length, equals(1));
        expect(velocity.time, equals(-1));
      });

      test('velocity / T = acceleration', () {
        final acceleration = Dimension.velocity / Dimension.T;
        expect(acceleration, equals(Dimension.acceleration));
        expect(acceleration.length, equals(1));
        expect(acceleration.time, equals(-2));
      });
    });

    group('pow', () {
      test('L.pow(2) = area', () {
        expect(Dimension.L.pow(2), equals(Dimension.area));
      });

      test('L.pow(3) = volume', () {
        expect(Dimension.L.pow(3), equals(Dimension.volume));
      });

      test('T.pow(-1) = frequency', () {
        expect(Dimension.T.pow(-1), equals(Dimension.frequency));
      });
    });

    group('inverse', () {
      test('T.inverse() = frequency', () {
        expect(Dimension.T.inverse(), equals(Dimension.frequency));
      });

      test('velocity.inverse() = T/L', () {
        final inverse = Dimension.velocity.inverse();
        expect(inverse.length, equals(-1));
        expect(inverse.time, equals(1));
      });
    });

    group('equality', () {
      test('same dimensions are equal', () {
        final d1 = Dimension(length: 1, time: -1);
        final d2 = Dimension(length: 1, time: -1);
        expect(d1, equals(d2));
        expect(d1.hashCode, equals(d2.hashCode));
      });

      test('different dimensions are not equal', () {
        expect(Dimension.L, isNot(equals(Dimension.M)));
        expect(Dimension.velocity, isNot(equals(Dimension.acceleration)));
      });
    });

    group('toString', () {
      test('dimensionless returns "1"', () {
        expect(Dimension.dimensionless.toString(), equals('1'));
      });

      test('base dimensions format correctly', () {
        expect(Dimension.L.toString(), equals('L'));
        expect(Dimension.M.toString(), equals('M'));
        expect(Dimension.T.toString(), equals('T'));
      });

      test('compound dimensions format with superscripts', () {
        expect(Dimension.area.toString(), equals('L²'));
        expect(Dimension.volume.toString(), equals('L³'));
        expect(Dimension.velocity.toString(), equals('L·T⁻¹'));
        expect(Dimension.acceleration.toString(), equals('L·T⁻²'));
        // Order is L, M, T (alphabetical by symbol position in toString)
        expect(Dimension.force.toString(), equals('L·M·T⁻²'));
      });
    });

    group('toReadableString', () {
      test('returns common names for known dimensions', () {
        expect(Dimension.L.toReadableString(), equals('length'));
        expect(Dimension.M.toReadableString(), equals('mass'));
        expect(Dimension.velocity.toReadableString(), equals('velocity'));
        expect(Dimension.force.toReadableString(), equals('force'));
        expect(Dimension.energy.toReadableString(), equals('energy'));
      });

      test('returns formula for unknown dimensions', () {
        final custom = Dimension(length: 2, time: -1);
        expect(custom.toReadableString(), equals('L²·T⁻¹'));
      });
    });

    group('serialization', () {
      test('toJson only includes non-zero exponents', () {
        expect(Dimension.dimensionless.toJson(), equals({}));
        expect(Dimension.L.toJson(), equals({'L': 1}));
        expect(Dimension.velocity.toJson(), equals({'L': 1, 'T': -1}));
      });

      test('fromJson creates correct dimension', () {
        expect(Dimension.fromJson({}), equals(Dimension.dimensionless));
        expect(Dimension.fromJson({'L': 1}), equals(Dimension.L));
        expect(
          Dimension.fromJson({'L': 1, 'T': -1}),
          equals(Dimension.velocity),
        );
        expect(
          Dimension.fromJson({'M': 1, 'L': 1, 'T': -2}),
          equals(Dimension.force),
        );
      });

      test('roundtrip serialization', () {
        final dimensions = [
          Dimension.dimensionless,
          Dimension.L,
          Dimension.M,
          Dimension.velocity,
          Dimension.force,
          Dimension.energy,
          Dimension(length: 2, mass: 1, time: -3, current: -1), // voltage
        ];

        for (final dim in dimensions) {
          expect(Dimension.fromJson(dim.toJson()), equals(dim));
        }
      });
    });

    group('practical examples', () {
      test('energy = force * distance', () {
        final energy = Dimension.force * Dimension.L;
        expect(energy, equals(Dimension.energy));
      });

      test('power = energy / time', () {
        final power = Dimension.energy / Dimension.T;
        expect(power, equals(Dimension.power));
      });

      test('pressure = force / area', () {
        final pressure = Dimension.force / Dimension.area;
        expect(pressure, equals(Dimension.pressure));
      });

      test('density = mass / volume', () {
        final density = Dimension.M / Dimension.volume;
        expect(density, equals(Dimension.density));
      });

      test('rate = amount / time (calories per day)', () {
        final rate = Dimension.N / Dimension.T;
        expect(rate, equals(Dimension.rate));
      });
    });
  });
}
