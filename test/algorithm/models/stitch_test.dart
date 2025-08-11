import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:thread_digit/algorithm/models/stitch.dart';
import 'package:thread_digit/colors/model/thread_color.dart';

void main() {
  group('Stitch', () {
    late ThreadColor testColor;

    setUp(() {
      testColor = const ThreadColor(
        name: 'Test Red',
        code: 'R001',
        red: 255,
        green: 0,
        blue: 0,
        catalog: 'Test',
      );
    });

    group('length calculation', () {
      test('calculates length correctly for horizontal stitch', () {
        final stitch = Stitch(
          start: const math.Point(0.0, 0.0),
          end: const math.Point(5.0, 0.0),
          color: testColor,
        );

        expect(stitch.length, equals(5.0));
      });

      test('calculates length correctly for vertical stitch', () {
        final stitch = Stitch(
          start: const math.Point(0.0, 0.0),
          end: const math.Point(0.0, 4.0),
          color: testColor,
        );

        expect(stitch.length, equals(4.0));
      });

      test('calculates length correctly for diagonal stitch using Pythagorean theorem', () {
        final stitch = Stitch(
          start: const math.Point(0.0, 0.0),
          end: const math.Point(3.0, 4.0),
          color: testColor,
        );

        expect(stitch.length, equals(5.0));
      });

      test('calculates length correctly with negative coordinates', () {
        final stitch = Stitch(
          start: const math.Point(-2.0, -1.0),
          end: const math.Point(1.0, 3.0),
          color: testColor,
        );

        expect(stitch.length, equals(5.0));
      });

      test('returns zero length for zero-length stitch', () {
        final stitch = Stitch(
          start: const math.Point(5.0, 5.0),
          end: const math.Point(5.0, 5.0),
          color: testColor,
        );

        expect(stitch.length, equals(0.0));
      });
    });

    group('angle calculation', () {
      test('calculates angle correctly for horizontal stitch (0 degrees)', () {
        final stitch = Stitch(
          start: const math.Point(0.0, 0.0),
          end: const math.Point(5.0, 0.0),
          color: testColor,
        );

        expect(stitch.angle, equals(0.0));
      });

      test('calculates angle correctly for vertical stitch (90 degrees)', () {
        final stitch = Stitch(
          start: const math.Point(0.0, 0.0),
          end: const math.Point(0.0, 5.0),
          color: testColor,
        );

        expect(stitch.angle, closeTo(math.pi / 2, 0.0001));
      });

      test('calculates angle correctly for 45-degree stitch', () {
        final stitch = Stitch(
          start: const math.Point(0.0, 0.0),
          end: const math.Point(5.0, 5.0),
          color: testColor,
        );

        expect(stitch.angle, closeTo(math.pi / 4, 0.0001));
      });

      test('calculates angle correctly for negative direction (-90 degrees)', () {
        final stitch = Stitch(
          start: const math.Point(0.0, 0.0),
          end: const math.Point(0.0, -5.0),
          color: testColor,
        );

        expect(stitch.angle, closeTo(-math.pi / 2, 0.0001));
      });

      test('calculates angle correctly for leftward stitch (180 degrees)', () {
        final stitch = Stitch(
          start: const math.Point(0.0, 0.0),
          end: const math.Point(-5.0, 0.0),
          color: testColor,
        );

        expect(stitch.angle.abs(), closeTo(math.pi, 0.0001));
      });
    });

    group('validation', () {
      test('validates stitch within length constraints', () {
        final stitch = Stitch(
          start: const math.Point(0.0, 0.0),
          end: const math.Point(5.0, 0.0),
          color: testColor,
        );

        expect(stitch.isValid(1.0, 10.0), isTrue);
        expect(stitch.isValid(4.0, 6.0), isTrue);
        expect(stitch.isValid(5.0, 5.0), isTrue);
      });

      test('invalidates stitch below minimum length', () {
        final stitch = Stitch(
          start: const math.Point(0.0, 0.0),
          end: const math.Point(2.0, 0.0),
          color: testColor,
        );

        expect(stitch.isValid(3.0, 10.0), isFalse);
      });

      test('invalidates stitch above maximum length', () {
        final stitch = Stitch(
          start: const math.Point(0.0, 0.0),
          end: const math.Point(15.0, 0.0),
          color: testColor,
        );

        expect(stitch.isValid(1.0, 12.0), isFalse);
      });

      test('validates zero-length stitch against zero minimum', () {
        final stitch = Stitch(
          start: const math.Point(0.0, 0.0),
          end: const math.Point(0.0, 0.0),
          color: testColor,
        );

        expect(stitch.isValid(0.0, 1.0), isTrue);
        expect(stitch.isValid(0.1, 1.0), isFalse);
      });
    });

    group('copyWith', () {
      test('creates copy with new start point', () {
        final original = Stitch(
          start: const math.Point(0.0, 0.0),
          end: const math.Point(5.0, 5.0),
          color: testColor,
        );

        final copy = original.copyWith(start: const math.Point(1.0, 1.0));

        expect(copy.start, equals(const math.Point(1.0, 1.0)));
        expect(copy.end, equals(original.end));
        expect(copy.color, equals(original.color));
      });

      test('creates copy with new end point', () {
        final original = Stitch(
          start: const math.Point(0.0, 0.0),
          end: const math.Point(5.0, 5.0),
          color: testColor,
        );

        final copy = original.copyWith(end: const math.Point(10.0, 10.0));

        expect(copy.start, equals(original.start));
        expect(copy.end, equals(const math.Point(10.0, 10.0)));
        expect(copy.color, equals(original.color));
      });

      test('creates copy with new color', () {
        final original = Stitch(
          start: const math.Point(0.0, 0.0),
          end: const math.Point(5.0, 5.0),
          color: testColor,
        );

        final newColor = const ThreadColor(
          name: 'Test Blue',
          code: 'B001',
          red: 0,
          green: 0,
          blue: 255,
          catalog: 'Test',
        );

        final copy = original.copyWith(color: newColor);

        expect(copy.start, equals(original.start));
        expect(copy.end, equals(original.end));
        expect(copy.color, equals(newColor));
      });
    });

    group('equality', () {
      test('equal stitches have same properties', () {
        final stitch1 = Stitch(
          start: const math.Point(0.0, 0.0),
          end: const math.Point(5.0, 5.0),
          color: testColor,
        );

        final stitch2 = Stitch(
          start: const math.Point(0.0, 0.0),
          end: const math.Point(5.0, 5.0),
          color: testColor,
        );

        expect(stitch1, equals(stitch2));
        expect(stitch1.hashCode, equals(stitch2.hashCode));
      });

      test('stitches with different start points are not equal', () {
        final stitch1 = Stitch(
          start: const math.Point(0.0, 0.0),
          end: const math.Point(5.0, 5.0),
          color: testColor,
        );

        final stitch2 = Stitch(
          start: const math.Point(1.0, 0.0),
          end: const math.Point(5.0, 5.0),
          color: testColor,
        );

        expect(stitch1, isNot(equals(stitch2)));
      });

      test('stitches with different colors are not equal', () {
        final stitch1 = Stitch(
          start: const math.Point(0.0, 0.0),
          end: const math.Point(5.0, 5.0),
          color: testColor,
        );

        final stitch2 = Stitch(
          start: const math.Point(0.0, 0.0),
          end: const math.Point(5.0, 5.0),
          color: const ThreadColor(
            name: 'Different',
            code: 'D001',
            red: 128,
            green: 128,
            blue: 128,
            catalog: 'Test',
          ),
        );

        expect(stitch1, isNot(equals(stitch2)));
      });
    });

  });
}
