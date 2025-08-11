import 'package:flutter_test/flutter_test.dart';
import 'package:thread_digit/algorithm/utils/color_conversion_utils.dart';

void main() {
  group('ColorConversionUtils', () {
    test('RGB to LAB conversion works correctly', () {
      // Test black color
      final blackLab = ColorConversionUtils.rgbToLab(0, 0, 0);
      expect(blackLab.l, closeTo(0, 1));
      expect(blackLab.a, closeTo(0, 5));
      expect(blackLab.b, closeTo(0, 5));

      // Test white color
      final whiteLab = ColorConversionUtils.rgbToLab(255, 255, 255);
      expect(whiteLab.l, closeTo(100, 1));
      expect(whiteLab.a, closeTo(0, 5));
      expect(whiteLab.b, closeTo(0, 5));

      // Test red color
      final redLab = ColorConversionUtils.rgbToLab(255, 0, 0);
      expect(redLab.l, greaterThan(40));
      expect(redLab.a, greaterThan(50));
      expect(redLab.b, greaterThan(20));
    });

    test('LAB to RGB conversion works correctly', () {
      // Test neutral gray
      final grayRgb = ColorConversionUtils.labToRgb(const LabColor(50, 0, 0));
      expect((grayRgb.r * 255.0).round() & 0xff, closeTo(119, 10));
      expect((grayRgb.g * 255.0).round() & 0xff, closeTo(119, 10));
      expect((grayRgb.b * 255.0).round() & 0xff, closeTo(119, 10));
    });

    test('RGB to LAB to RGB round trip preserves values', () {
      final testColors = [
        (128, 128, 128), // Gray
        (255, 0, 0),     // Red
        (0, 255, 0),     // Green
        (0, 0, 255),     // Blue
        (255, 255, 0),   // Yellow
        (255, 0, 255),   // Magenta
        (0, 255, 255),   // Cyan
      ];

      for (final (r, g, b) in testColors) {
        final lab = ColorConversionUtils.rgbToLab(r, g, b);
        final backToRgb = ColorConversionUtils.labToRgb(lab);

        // Allow small tolerance due to floating point precision
        expect((backToRgb.r * 255.0).round() & 0xff, closeTo(r, 3), reason: 'Red channel for ($r, $g, $b)');
        expect((backToRgb.g * 255.0).round() & 0xff, closeTo(g, 3), reason: 'Green channel for ($r, $g, $b)');
        expect((backToRgb.b * 255.0).round() & 0xff, closeTo(b, 3), reason: 'Blue channel for ($r, $g, $b)');
      }
    });

    test('LAB color validation works correctly', () {
      expect(ColorConversionUtils.isValidLab(const LabColor(50, 0, 0)), isTrue);
      expect(ColorConversionUtils.isValidLab(const LabColor(0, -128, -128)), isTrue);
      expect(ColorConversionUtils.isValidLab(const LabColor(100, 127, 127)), isTrue);
      
      // Invalid LAB values
      expect(ColorConversionUtils.isValidLab(const LabColor(-10, 0, 0)), isFalse);
      expect(ColorConversionUtils.isValidLab(const LabColor(110, 0, 0)), isFalse);
      expect(ColorConversionUtils.isValidLab(const LabColor(50, 200, 0)), isFalse);
      expect(ColorConversionUtils.isValidLab(const LabColor(50, 0, 200)), isFalse);
    });

    test('RGB color validation works correctly', () {
      expect(ColorConversionUtils.isValidRgb(0, 0, 0), isTrue);
      expect(ColorConversionUtils.isValidRgb(255, 255, 255), isTrue);
      expect(ColorConversionUtils.isValidRgb(128, 64, 192), isTrue);
      
      // Invalid RGB values
      expect(ColorConversionUtils.isValidRgb(-1, 0, 0), isFalse);
      expect(ColorConversionUtils.isValidRgb(256, 0, 0), isFalse);
      expect(ColorConversionUtils.isValidRgb(0, -1, 0), isFalse);
      expect(ColorConversionUtils.isValidRgb(0, 0, 256), isFalse);
    });

    test('LAB distance calculation works correctly', () {
      final lab1 = const LabColor(50, 0, 0);
      final lab2 = const LabColor(60, 10, 5);
      
      final distance = ColorConversionUtils.labDistance(lab1, lab2);
      expect(distance, greaterThan(0));
      
      // Distance from color to itself should be zero
      final sameDistance = ColorConversionUtils.labDistance(lab1, lab1);
      expect(sameDistance, closeTo(0, 0.001));
      
      // Distance should be symmetric
      final reverseDistance = ColorConversionUtils.labDistance(lab2, lab1);
      expect(distance, closeTo(reverseDistance, 0.001));
    });

    test('LAB color equality works correctly', () {
      const lab1 = LabColor(50, 10, -5);
      const lab2 = LabColor(50, 10, -5);
      const lab3 = LabColor(51, 10, -5);
      
      expect(lab1 == lab2, isTrue);
      expect(lab1 == lab3, isFalse);
      expect(lab1.hashCode == lab2.hashCode, isTrue);
    });

    test('XYZ color works correctly', () {
      const xyz1 = XyzColor(50, 50, 50);
      const xyz2 = XyzColor(50, 50, 50);
      const xyz3 = XyzColor(60, 50, 50);
      
      expect(xyz1.toString(), contains('XYZ'));
      expect(xyz1.x, equals(50));
      expect(xyz1.y, equals(50));
      expect(xyz1.z, equals(50));
      
      // Test equality and different values
      expect(xyz1 == xyz2, isTrue);
      expect(xyz1 == xyz3, isFalse);
    });

    test('LAB color toString works correctly', () {
      const lab = LabColor(50.5, 10.2, -5.8);
      final str = lab.toString();
      expect(str, contains('LAB'));
      expect(str, contains('50.5'));
      expect(str, contains('10.2'));
      expect(str, contains('-5.8'));
    });

    test('conversion handles edge cases correctly', () {
      // Test near-black
      final nearBlackLab = ColorConversionUtils.rgbToLab(1, 1, 1);
      expect(nearBlackLab.l, greaterThan(0));
      expect(nearBlackLab.l, lessThan(5));
      
      // Test near-white
      final nearWhiteLab = ColorConversionUtils.rgbToLab(254, 254, 254);
      expect(nearWhiteLab.l, greaterThan(95));
      expect(nearWhiteLab.l, lessThan(100));
    });
  });
}