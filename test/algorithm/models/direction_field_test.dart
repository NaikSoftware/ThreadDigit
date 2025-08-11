import 'dart:math' as math;
import 'package:flutter_test/flutter_test.dart';
import 'package:thread_digit/algorithm/models/direction_field.dart';

void main() {
  group('DirectionField', () {
    test('validates field data integrity', () {
      const width = 3;
      const height = 3;

      // Valid field
      final validField = DirectionField(
        width: width,
        height: height,
        orientations: List.filled(9, 0.0),
        coherences: List.filled(9, 0.5),
      );
      expect(validField.isValid, isTrue);

      // Invalid field - wrong orientation count
      final invalidOrientations = DirectionField(
        width: width,
        height: height,
        orientations: List.filled(8, 0.0), // Should be 9
        coherences: List.filled(9, 0.5),
      );
      expect(invalidOrientations.isValid, isFalse);

      // Invalid field - coherence out of range
      final invalidCoherence = DirectionField(
        width: width,
        height: height,
        orientations: List.filled(9, 0.0),
        coherences: [0.5, 1.5, 0.3, 0.0, 0.8, 0.2, 0.7, 0.4, 0.6], // 1.5 > 1.0
      );
      expect(invalidCoherence.isValid, isFalse);
    });

    test('gets orientation and coherence at coordinates correctly', () {
      final field = DirectionField(
        width: 3,
        height: 2,
        orientations: [0.1, 0.2, 0.3, 0.4, 0.5, 0.6],
        coherences: [0.1, 0.2, 0.3, 0.4, 0.5, 0.6],
      );

      // Valid coordinates
      expect(field.getOrientation(0, 0), equals(0.1));
      expect(field.getOrientation(2, 0), equals(0.3));
      expect(field.getOrientation(1, 1), equals(0.5));
      expect(field.getCoherence(2, 1), equals(0.6));

      // Out of bounds coordinates return 0
      expect(field.getOrientation(-1, 0), equals(0.0));
      expect(field.getOrientation(3, 0), equals(0.0));
      expect(field.getCoherence(0, 2), equals(0.0));
    });

    test('calculates direction vector correctly', () {
      final field = DirectionField(
        width: 2,
        height: 1,
        orientations: [0.0, math.pi / 2], // 0° and 90°
        coherences: [1.0, 1.0],
      );

      final vector0 = field.getDirectionVector(0, 0);
      expect(vector0.x, closeTo(1.0, 0.001)); // cos(0°) = 1
      expect(vector0.y, closeTo(0.0, 0.001)); // sin(0°) = 0

      final vector90 = field.getDirectionVector(1, 0);
      expect(vector90.x, closeTo(0.0, 0.001)); // cos(90°) = 0
      expect(vector90.y, closeTo(1.0, 0.001)); // sin(90°) = 1
    });

    test('calculates average coherence correctly', () {
      final field = DirectionField(
        width: 4,
        height: 1,
        orientations: [0.0, 0.0, 0.0, 0.0],
        coherences: [0.2, 0.4, 0.6, 0.8],
      );

      expect(field.averageCoherence, equals(0.5));
    });
  });
}