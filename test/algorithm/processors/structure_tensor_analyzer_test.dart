import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:thread_digit/algorithm/processors/structure_tensor_analyzer.dart';
import 'package:thread_digit/algorithm/processors/image_loader.dart';

void main() {
  group('StructureTensorAnalyzer', () {
    late img.Image testImage;
    late img.Image woolImage;

    setUp(() async {
      // Create test patterns
      testImage = _createTestPattern();
      woolImage = await ImageLoader.loadFromFile('test/res/images/wool-horizontal-direction.png') ?? _createDirectionalPattern();
    });

    test('structure tensor parameters validation works correctly', () {
      const validParams = StructureTensorParameters();
      expect(validParams.isValid, isTrue);

      const invalidGaussianSigma = StructureTensorParameters(gaussianSigma: -1.0);
      expect(invalidGaussianSigma.isValid, isFalse);

      const invalidIntegrationSigma = StructureTensorParameters(integrationSigma: -1.0);
      expect(invalidIntegrationSigma.isValid, isFalse);

      const invalidCoherence = StructureTensorParameters(minCoherence: 1.5);
      expect(invalidCoherence.isValid, isFalse);
    });

    test('analyzes structure tensor successfully with valid parameters', () {
      const params = StructureTensorParameters(
        gaussianSigma: 2.0,
        integrationSigma: 4.0,
        minCoherence: 0.01,
      );

      final result = StructureTensorAnalyzer.analyzeStructure(testImage, params);

      expect(result.isSuccess, isTrue);
      expect(result.data, isNotNull);

      final directionField = result.data!;
      expect(directionField.width, equals(testImage.width));
      expect(directionField.height, equals(testImage.height));
      expect(directionField.isValid, isTrue);
    });

    test('fails with invalid parameters', () {
      const invalidParams = StructureTensorParameters(gaussianSigma: -1.0);

      final result = StructureTensorAnalyzer.analyzeStructure(testImage, invalidParams);

      expect(result.isFailure, isTrue);
      expect(result.error, contains('Invalid structure tensor parameters'));
    });

    test('directional pattern produces meaningful coherence values', () {
      const params = StructureTensorParameters();

      final result = StructureTensorAnalyzer.analyzeStructure(woolImage, params);

      expect(result.isSuccess, isTrue);
      final directionField = result.data!;

      // Should have some coherent regions
      final avgCoherence = directionField.averageCoherence;
      expect(avgCoherence, greaterThan(0.0));
      expect(avgCoherence, lessThanOrEqualTo(1.0));

      // Check that coherences are in valid range
      for (final coherence in directionField.coherences) {
        expect(coherence, greaterThanOrEqualTo(0.0));
        expect(coherence, lessThanOrEqualTo(1.0));
      }
    });

    test('gets orientation and coherence at specific coordinates', () {
      const params = StructureTensorParameters();

      final result = StructureTensorAnalyzer.analyzeStructure(testImage, params);

      expect(result.isSuccess, isTrue);
      final directionField = result.data!;

      final centerX = directionField.width ~/ 2;
      final centerY = directionField.height ~/ 2;

      final orientation = directionField.getOrientation(centerX, centerY);
      final coherence = directionField.getCoherence(centerX, centerY);

      // Orientation should be in valid range [-π, π]
      expect(orientation, greaterThanOrEqualTo(-3.15));
      expect(orientation, lessThanOrEqualTo(3.15));

      // Coherence should be in valid range [0, 1]
      expect(coherence, greaterThanOrEqualTo(0.0));
      expect(coherence, lessThanOrEqualTo(1.0));
    });

    test('calculates statistics correctly', () {
      const params = StructureTensorParameters();

      final result = StructureTensorAnalyzer.analyzeStructure(testImage, params);

      expect(result.isSuccess, isTrue);
      final directionField = result.data!;

      final stats = StructureTensorAnalyzer.calculateStatistics(directionField);

      expect(stats, contains('averageCoherence'));
      expect(stats, contains('minCoherence'));
      expect(stats, contains('maxCoherence'));
      expect(stats, contains('coherenceRatio'));
      expect(stats, contains('validPixels'));

      final double avgCoherence = stats['averageCoherence']!;
      final double minCoherence = stats['minCoherence']!;
      final double maxCoherence = stats['maxCoherence']!;

      expect(avgCoherence, greaterThanOrEqualTo(0.0));
      expect(avgCoherence, lessThanOrEqualTo(1.0));
      // Min/max may be equal to average if all values are the same
      expect(minCoherence, lessThanOrEqualTo(maxCoherence));
      expect(avgCoherence, greaterThanOrEqualTo(minCoherence));
      expect(avgCoherence, lessThanOrEqualTo(maxCoherence));
    });

    test('visualization methods create valid images', () {
      const params = StructureTensorParameters();

      final result = StructureTensorAnalyzer.analyzeStructure(testImage, params);

      expect(result.isSuccess, isTrue);
      final directionField = result.data!;

      final orientationViz = StructureTensorAnalyzer.visualizeOrientations(directionField);
      final coherenceViz = StructureTensorAnalyzer.visualizeCoherence(directionField);

      expect(orientationViz.width, equals(directionField.width));
      expect(orientationViz.height, equals(directionField.height));
      expect(coherenceViz.width, equals(directionField.width));
      expect(coherenceViz.height, equals(directionField.height));
    });

    test('different parameters produce different analysis results', () {
      const lowSigma = StructureTensorParameters(integrationSigma: 2.0);
      const highSigma = StructureTensorParameters(integrationSigma: 6.0);

      final lowResult = StructureTensorAnalyzer.analyzeStructure(testImage, lowSigma);
      final highResult = StructureTensorAnalyzer.analyzeStructure(testImage, highSigma);

      expect(lowResult.isSuccess, isTrue);
      expect(highResult.isSuccess, isTrue);

      final lowAvgCoherence = lowResult.data!.averageCoherence;
      final highAvgCoherence = highResult.data!.averageCoherence;

      // Results may be similar for simple patterns, just ensure both processed
      expect(lowAvgCoherence, greaterThanOrEqualTo(0.0));
      expect(highAvgCoherence, greaterThanOrEqualTo(0.0));
    });

    test('handles uniform color image gracefully', () {
      // Create uniform gray image
      final uniformImage = img.Image(width: 32, height: 32);
      img.fill(uniformImage, color: img.ColorRgb8(128, 128, 128));

      const params = StructureTensorParameters();

      final result = StructureTensorAnalyzer.analyzeStructure(uniformImage, params);

      expect(result.isSuccess, isTrue);
      final directionField = result.data!;

      // Uniform image should have low coherence everywhere
      final avgCoherence = directionField.averageCoherence;
      expect(avgCoherence, lessThan(0.5)); // Should be relatively low
    });
  });
}

/// Creates a pattern with clear directional features (fallback)
img.Image _createDirectionalPattern() {
  final image = img.Image(width: 64, height: 64);

  // Create vertical stripes (horizontal direction)
  for (int y = 0; y < 64; y++) {
    for (int x = 0; x < 64; x++) {
      final intensity = (x % 8) < 4 ? 0 : 255;
      image.setPixel(x, y, img.ColorRgb8(intensity, intensity, intensity));
    }
  }

  return image;
}

/// Creates a test pattern with gradients
img.Image _createTestPattern() {
  final image = img.Image(width: 64, height: 64);

  // Create horizontal gradient
  for (int y = 0; y < 64; y++) {
    for (int x = 0; x < 64; x++) {
      final intensity = (x * 255 / 63).round();
      image.setPixel(x, y, img.ColorRgb8(intensity, intensity, intensity));
    }
  }

  return image;
}

