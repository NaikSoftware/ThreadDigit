import 'package:flutter_test/flutter_test.dart';
import 'dart:math' as math;
import 'dart:ui';

import 'package:thread_digit/algorithm/utils/artistic_math.dart';

void main() {
  group('ArtisticMath', () {
    test('color temperature adjustment works correctly', () {
      const baseColor = Color.fromARGB(255, 128, 128, 128);
      
      // Warm temperature should enhance reds
      final warmColor = ArtisticMath.applyColorTemperature(baseColor, 3000.0);
      expect((warmColor.r * 255.0).round() & 0xff, greaterThan((baseColor.r * 255.0).round() & 0xff));
      
      // Cool temperature should enhance blues
      final coolColor = ArtisticMath.applyColorTemperature(baseColor, 10000.0);
      expect((coolColor.b * 255.0).round() & 0xff, greaterThan((baseColor.b * 255.0).round() & 0xff));
      
      // Neutral temperature should remain similar
      final neutralColor = ArtisticMath.applyColorTemperature(baseColor, 6500.0);
      expect((((neutralColor.r * 255.0).round() & 0xff) - ((baseColor.r * 255.0).round() & 0xff)).abs(), lessThan(10));
    });

    test('gradient magnitude calculation works correctly', () {
      expect(ArtisticMath.calculateGradientMagnitude(3.0, 4.0), closeTo(5.0, 0.001));
      expect(ArtisticMath.calculateGradientMagnitude(0.0, 0.0), equals(0.0));
      expect(ArtisticMath.calculateGradientMagnitude(-3.0, 4.0), closeTo(5.0, 0.001));
    });

    test('sfumato smoothing calculation produces valid values', () {
      final smoothing = ArtisticMath.calculateSfumatoSmoothing(10.0, 20.0, 0.8);
      expect(smoothing, greaterThanOrEqualTo(0.0));
      expect(smoothing, lessThanOrEqualTo(1.0));
      
      // Higher gradients should get more smoothing (the algorithm inverts this relationship)
      final highGradientSmoothing = ArtisticMath.calculateSfumatoSmoothing(18.0, 20.0, 0.8);
      final lowGradientSmoothing = ArtisticMath.calculateSfumatoSmoothing(2.0, 20.0, 0.8);
      expect(lowGradientSmoothing, greaterThan(highGradientSmoothing));
    });

    test('thread opacity calculation handles edge cases', () {
      expect(ArtisticMath.calculateThreadOpacity(0.5, 0.3, 0.2), 
             greaterThanOrEqualTo(0.1));
      expect(ArtisticMath.calculateThreadOpacity(0.5, 0.3, 0.2), 
             lessThanOrEqualTo(1.0));
      
      // Extreme values should be clamped
      expect(ArtisticMath.calculateThreadOpacity(2.0, 1.0, 1.0), equals(1.0));
      expect(ArtisticMath.calculateThreadOpacity(-1.0, 0.0, 0.0), equals(0.1));
    });

    test('artistic variation adds controlled randomness', () {
      final random = math.Random(42);
      const baseAngle = math.pi / 4; // 45 degrees
      
      final variations = <double>[];
      for (int i = 0; i < 10; i++) {
        variations.add(ArtisticMath.addArtisticVariation(baseAngle, 0.5, random));
      }
      
      // All variations should be within reasonable bounds
      for (final variation in variations) {
        final diff = (variation - baseAngle).abs();
        expect(diff, lessThan(math.pi / 8)); // Less than 22.5 degrees
      }
      
      // Should produce different values
      expect(variations.toSet().length, greaterThan(5));
    });

    test('atmospheric factor decreases with depth', () {
      final nearFactor = ArtisticMath.calculateAtmosphericFactor(0.1, 1.0);
      final farFactor = ArtisticMath.calculateAtmosphericFactor(0.9, 1.0);
      
      expect(nearFactor, greaterThan(farFactor));
      expect(nearFactor, lessThanOrEqualTo(1.0));
      expect(farFactor, greaterThanOrEqualTo(0.0));
    });

    test('thread color blending works correctly', () {
      const color1 = Color.fromARGB(255, 255, 0, 0); // Red
      const color2 = Color.fromARGB(255, 0, 0, 255); // Blue
      
      final blended50 = ArtisticMath.blendThreadColors(color1, color2, 0.5);
      expect((blended50.r * 255.0).round() & 0xff, closeTo(127, 1));
      expect((blended50.b * 255.0).round() & 0xff, closeTo(127, 1));
      expect((blended50.g * 255.0).round() & 0xff, equals(0));
      
      final blended0 = ArtisticMath.blendThreadColors(color1, color2, 0.0);
      expect(blended0, equals(color1));
      
      final blended100 = ArtisticMath.blendThreadColors(color1, color2, 1.0);
      expect(blended100, equals(color2));
    });

    test('artistic stitch length adapts to complexity', () {
      const baseLength = 6.0;
      const minLength = 2.0;
      const maxLength = 12.0;
      
      // High complexity should produce shorter stitches
      final highComplexityLength = ArtisticMath.calculateArtisticStitchLength(
        baseLength, minLength, maxLength, 0.9, 0.5);
      
      // Low complexity should produce longer stitches
      final lowComplexityLength = ArtisticMath.calculateArtisticStitchLength(
        baseLength, minLength, maxLength, 0.1, 0.5);
      
      expect(highComplexityLength, lessThan(lowComplexityLength));
      expect(highComplexityLength, greaterThanOrEqualTo(minLength));
      expect(lowComplexityLength, lessThanOrEqualTo(maxLength));
    });

    test('silk shading intensity calculation combines factors correctly', () {
      final intensity = ArtisticMath.calculateSilkShadingIntensity(0.8, 0.7, 0.6);
      expect(intensity, greaterThanOrEqualTo(0.0));
      expect(intensity, lessThanOrEqualTo(1.0));
      
      // Higher input values should generally produce higher intensity
      final lowIntensity = ArtisticMath.calculateSilkShadingIntensity(0.1, 0.1, 0.1);
      expect(intensity, greaterThan(lowIntensity));
    });

    test('golden ratio spacing produces natural proportions', () {
      const baseSpacing = 10.0;
      final goldenSpacing = ArtisticMath.applyGoldenRatioSpacing(baseSpacing);
      
      expect(goldenSpacing, isNot(equals(baseSpacing)));
      expect(goldenSpacing, greaterThan(baseSpacing * 0.8));
      expect(goldenSpacing, lessThan(baseSpacing * 1.2));
      
      // Should be deterministic
      final goldenSpacing2 = ArtisticMath.applyGoldenRatioSpacing(baseSpacing);
      expect(goldenSpacing, equals(goldenSpacing2));
    });

    test('thread tension simulation creates realistic displacement', () {
      const startPoint = Offset(0, 0);
      const endPoint = Offset(10, 0);
      
      // No tension should return original endpoint
      final noTension = ArtisticMath.applyThreadTension(startPoint, endPoint, 0.0);
      expect(noTension, equals(endPoint));
      
      // With tension should create displacement
      final withTension = ArtisticMath.applyThreadTension(startPoint, endPoint, 0.5);
      expect(withTension, isNot(equals(endPoint)));
      
      // Displacement should be reasonable (within 5% of stitch length)
      final displacement = (withTension - endPoint).distance;
      expect(displacement, lessThan(0.5)); // 5% of 10-unit stitch
    });
  });
}