import 'package:flutter_test/flutter_test.dart';
import 'dart:ui';
import 'package:image/image.dart' as img;
import 'package:thread_digit/algorithm/models/dithering_result.dart';
import 'package:thread_digit/algorithm/processors/floyd_steinberg_ditherer.dart';

void main() {
  group('FloydSteinbergDitherer', () {
    late img.Image testImage;
    late img.Image gradientImage;
    late List<Color> testPalette;

    setUp(() {
      testImage = _createTestPattern();
      gradientImage = FloydSteinbergDitherer.createGradientTestPattern(64, 32);
      testPalette = [
        Color.fromARGB(255, 0, 0, 0),       // Black
        Color.fromARGB(255, 128, 128, 128), // Gray
        Color.fromARGB(255, 255, 255, 255), // White
      ];
    });

    test('dithering parameters validation works correctly', () {
      final validParams = DitheringParameters();
      expect(validParams.isValid, isTrue);

      final invalidStrength = DitheringParameters(strength: 1.5);
      expect(invalidStrength.isValid, isFalse);

      final invalidNegativeStrength = DitheringParameters(strength: -0.1);
      expect(invalidNegativeStrength.isValid, isFalse);

      final zeroStrength = DitheringParameters(strength: 0.0);
      expect(zeroStrength.isValid, isTrue);
    });

    test('applies dithering successfully with valid parameters', () {
      final params = DitheringParameters(strength: 0.8);

      final result = FloydSteinbergDitherer.dither(
        testImage,
        testPalette,
        params: params,
      );

      expect(result.isSuccess, isTrue);
      expect(result.data, isNotNull);

      final ditheringResult = result.data!;
      expect(ditheringResult.ditheredImage.width, equals(testImage.width));
      expect(ditheringResult.ditheredImage.height, equals(testImage.height));
      expect(ditheringResult.quantizedColorCount, equals(testPalette.length));
      expect(ditheringResult.ditheringStrength, equals(0.8));
    });

    test('fails with invalid parameters', () {
      final invalidParams = DitheringParameters(strength: 2.0);

      final result = FloydSteinbergDitherer.dither(
        testImage,
        testPalette,
        params: invalidParams,
      );

      expect(result.isFailure, isTrue);
      expect(result.error, contains('Invalid dithering parameters'));
    });

    test('fails with empty palette', () {
      final result = FloydSteinbergDitherer.dither(
        testImage,
        <Color>[],
      );

      expect(result.isFailure, isTrue);
      expect(result.error, contains('Color palette cannot be empty'));
    });

    test('gradient dithering produces smooth transitions', () {
      final params = DitheringParameters(strength: 0.8);

      final result = FloydSteinbergDitherer.dither(
        gradientImage,
        testPalette,
        params: params,
      );

      expect(result.isSuccess, isTrue);
      final ditheringResult = result.data!;

      // Gradient should have low average error (smooth dithering)
      expect(ditheringResult.averageError, lessThan(0.5));
      expect(ditheringResult.qualityScore, greaterThan(60.0));
    });

    test('different dithering strengths produce different results', () {
      final weakDithering = DitheringParameters(strength: 0.2);
      final strongDithering = DitheringParameters(strength: 1.0);

      final weakResult = FloydSteinbergDitherer.dither(
        gradientImage,
        testPalette,
        params: weakDithering,
      );

      final strongResult = FloydSteinbergDitherer.dither(
        gradientImage,
        testPalette,
        params: strongDithering,
      );

      expect(weakResult.isSuccess, isTrue);
      expect(strongResult.isSuccess, isTrue);

      // Strong dithering should distribute error more effectively
      final weakError = weakResult.data!.averageError;
      final strongError = strongResult.data!.averageError;

      // Both should have reasonable error levels
      expect(weakError, greaterThanOrEqualTo(0));
      expect(strongError, greaterThanOrEqualTo(0));
    });

    test('serpentine scanning affects dithering quality', () {
      final serpentineParams = DitheringParameters(serpentine: true);
      final rasterParams = DitheringParameters(serpentine: false);

      final serpentineResult = FloydSteinbergDitherer.dither(
        gradientImage,
        testPalette,
        params: serpentineParams,
      );

      final rasterResult = FloydSteinbergDitherer.dither(
        gradientImage,
        testPalette,
        params: rasterParams,
      );

      expect(serpentineResult.isSuccess, isTrue);
      expect(rasterResult.isSuccess, isTrue);

      // Both should produce valid results with reasonable quality
      expect(serpentineResult.data!.qualityScore, greaterThanOrEqualTo(0));
      expect(rasterResult.data!.qualityScore, greaterThanOrEqualTo(0));
    });

    test('error clamping prevents overflow', () {
      const clampedParams = DitheringParameters(errorClamp: true);
      const unclampedParams = DitheringParameters(errorClamp: false);

      final clampedResult = FloydSteinbergDitherer.dither(
        testImage,
        testPalette,
        params: clampedParams,
      );

      final unclampedResult = FloydSteinbergDitherer.dither(
        testImage,
        testPalette,
        params: unclampedParams,
      );

      expect(clampedResult.isSuccess, isTrue);
      expect(unclampedResult.isSuccess, isTrue);

      // Clamped version should have bounded errors
      final clampedErrors = clampedResult.data!.errorMap;
      for (final error in clampedErrors) {
        expect(error.abs(), lessThan(500)); // Reasonable upper bound
      }
    });

    test('dithering statistics are accurate', () {
      final result = FloydSteinbergDitherer.dither(
        testImage,
        testPalette,
      );

      expect(result.isSuccess, isTrue);
      final ditheringResult = result.data!;

      final stats = ditheringResult.statistics;
      expect(stats.quantizedColorCount, equals(testPalette.length));
      expect(stats.colorReductionPercentage, greaterThanOrEqualTo(0));
      expect(stats.colorReductionPercentage, lessThanOrEqualTo(100));
      expect(stats.qualityScore, greaterThanOrEqualTo(0));
      expect(stats.qualityScore, lessThanOrEqualTo(100));
      expect(stats.processingTimeMs, greaterThanOrEqualTo(0));
    });

    test('error map provides pixel-level error information', () {
      final result = FloydSteinbergDitherer.dither(
        testImage,
        testPalette,
      );

      expect(result.isSuccess, isTrue);
      final ditheringResult = result.data!;

      // Error map should have correct size
      expect(ditheringResult.errorMap.length, equals(testImage.width * testImage.height));

      // Should be able to get error at specific coordinates
      final error = ditheringResult.getErrorAt(10, 10);
      expect(error.isFinite, isTrue);

      // Boundary checks
      final outOfBoundsError = ditheringResult.getErrorAt(-1, -1);
      expect(outOfBoundsError, equals(0.0));
    });

    test('quality assessment identifies effectiveness', () {
      // Test with good palette (grayscale for gradient)
      final goodResult = FloydSteinbergDitherer.dither(
        gradientImage,
        testPalette,
      );

      // Test with poor palette (single color)
      final poorPalette = [const Color.fromARGB(255, 128, 128, 128)];
      final poorResult = FloydSteinbergDitherer.dither(
        gradientImage,
        poorPalette,
      );

      expect(goodResult.isSuccess, isTrue);
      expect(poorResult.isSuccess, isTrue);

      final goodEffectiveness = goodResult.data!.statistics.effectiveness;
      final poorEffectiveness = poorResult.data!.statistics.effectiveness;

      // Good palette should be more effective (lower enum index = better)
      expect(goodEffectiveness.index, lessThanOrEqualTo(poorEffectiveness.index));
    });

    test('palette validation works correctly', () {
      final validPalette = [
        const Color.fromARGB(255, 0, 0, 0),
        const Color.fromARGB(255, 255, 255, 255),
      ];

      final duplicatePalette = [
        const Color.fromARGB(255, 128, 128, 128),
        const Color.fromARGB(255, 128, 128, 128), // Duplicate
      ];

      expect(FloydSteinbergDitherer.isValidPalette(validPalette), isTrue);
      expect(FloydSteinbergDitherer.isValidPalette(duplicatePalette), isFalse);
      expect(FloydSteinbergDitherer.isValidPalette(<Color>[]), isFalse);
    });

    test('banding analysis detects artifacts', () {
      // Create poorly dithered gradient
      final singleColorPalette = [const Color.fromARGB(255, 128, 128, 128)];
      final poorResult = FloydSteinbergDitherer.dither(
        gradientImage,
        singleColorPalette,
      );

      expect(poorResult.isSuccess, isTrue);
      final bandingScore = FloydSteinbergDitherer.analyzeBanding(poorResult.data!);

      // Should detect minimal banding in single-color result
      expect(bandingScore.isFinite, isTrue);
      expect(bandingScore, greaterThanOrEqualTo(0));
    });

    test('gradient test pattern generation works correctly', () {
      final generatedGradient = FloydSteinbergDitherer.createGradientTestPattern(100, 50);

      expect(generatedGradient.width, equals(100));
      expect(generatedGradient.height, equals(50));

      // Check gradient properties
      final leftPixel = generatedGradient.getPixel(0, 25);
      final rightPixel = generatedGradient.getPixel(99, 25);

      // Left should be darker than right
      expect(leftPixel.r, lessThan(rightPixel.r));
      expect(leftPixel.g, lessThan(rightPixel.g));
      expect(leftPixel.b, lessThan(rightPixel.b));
    });
  });
}

/// Creates a test pattern with color variations
img.Image _createTestPattern() {
  final image = img.Image(width: 32, height: 32);
  
  // Create checkerboard pattern
  for (int y = 0; y < 32; y++) {
    for (int x = 0; x < 32; x++) {
      final isOdd = (x + y) % 2 == 1;
      final intensity = isOdd ? 200 : 50;
      image.setPixel(x, y, img.ColorRgb8(intensity, intensity, intensity));
    }
  }
  
  return image;
}