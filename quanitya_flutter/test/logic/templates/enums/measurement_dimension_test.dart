import 'package:flutter_test/flutter_test.dart';
import 'package:quanitya_flutter/logic/templates/enums/measurement_dimension.dart';
import 'package:quanitya_flutter/logic/templates/models/dimension.dart';

void main() {
  group('MeasurementDimension', () {
    test('mass carries Dimension.M', () {
      expect(MeasurementDimension.mass.dimension, equals(Dimension.M));
    });

    test('length carries Dimension.L', () {
      expect(MeasurementDimension.length.dimension, equals(Dimension.L));
    });

    test('volume carries Dimension.volume (L cubed)', () {
      expect(MeasurementDimension.volume.dimension, equals(Dimension.volume));
    });

    test('time carries Dimension.T', () {
      expect(MeasurementDimension.time.dimension, equals(Dimension.T));
    });

    test('all values have unique dimensions', () {
      final dimensions =
          MeasurementDimension.values.map((d) => d.dimension).toSet();
      expect(dimensions.length, equals(MeasurementDimension.values.length));
    });
  });
}
