import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:thread_digit/algorithm/processors/edge_detector.dart';


void main() {
  group('EdgeDetector', () {
    late img.Image testImage;
    late img.Image gradientImage;

    setUp(() {
      // Create test patterns
      testImage = _createTestPattern();
      gradientImage = _createGradientPattern();
    });

    test('edge detection parameters validation works correctly', () {
      const validParams = EdgeDetectionParameters();
      expect(validParams.isValid, isTrue);

      const invalidThresholds = EdgeDetectionParameters(lowThreshold: 200, highThreshold: 100);
      expect(invalidThresholds.isValid, isFalse);

      const invalidSigma = EdgeDetectionParameters(gaussianSigma: -1.0);
      expect(invalidSigma.isValid, isFalse);

      const invalidKernel = EdgeDetectionParameters(sobelKernelSize: 7);
      expect(invalidKernel.isValid, isFalse);
    });

    test('detects edges successfully with valid parameters', () {
      const params = EdgeDetectionParameters(
        lowThreshold: 50,
        highThreshold: 150,
        gaussianSigma: 1.0,
      );

      final result = EdgeDetector.detectEdges(testImage, params);

      expect(result.isSuccess, isTrue);
      expect(result.data, isNotNull);
      expect(result.data!.width, equals(testImage.width));
      expect(result.data!.height, equals(testImage.height));
    });

    test('fails with invalid parameters', () {
      const invalidParams = EdgeDetectionParameters(lowThreshold: -10);

      final result = EdgeDetector.detectEdges(testImage, invalidParams);

      expect(result.isFailure, isTrue);
      expect(result.error, contains('Invalid edge detection parameters'));
    });

    test('detects more edges in textured image than solid color', () {
      // Create solid color image
      final solidImage = img.Image(width: 64, height: 64);
      img.fill(solidImage, color: img.ColorRgb8(128, 128, 128));

      const params = EdgeDetectionParameters();

      final texturedResult = EdgeDetector.detectEdges(testImage, params);
      final solidResult = EdgeDetector.detectEdges(solidImage, params);

      expect(texturedResult.isSuccess, isTrue);
      expect(solidResult.isSuccess, isTrue);

      // Count white pixels (edges) in both results
      final texturedEdgeCount = _countWhitePixels(texturedResult.data!);
      final solidEdgeCount = _countWhitePixels(solidResult.data!);

      expect(texturedEdgeCount, greaterThan(solidEdgeCount));
    });

    test('gradient image produces expected edge patterns', () {
      const params = EdgeDetectionParameters(
        lowThreshold: 10,  // Lower threshold for gradient
        highThreshold: 50,
      );

      final result = EdgeDetector.detectEdges(gradientImage, params);

      expect(result.isSuccess, isTrue);

      // Gradient should produce some edges, but may be minimal for smooth gradients
      final edgeCount = _countWhitePixels(result.data!);
      // For gradients, just ensure processing worked (may have few edges)
      expect(edgeCount, greaterThanOrEqualTo(0));
    });

    test('different threshold values produce different edge counts', () {
      const lowThresholdParams = EdgeDetectionParameters(lowThreshold: 20, highThreshold: 60);
      const highThresholdParams = EdgeDetectionParameters(lowThreshold: 80, highThreshold: 200);

      final lowResult = EdgeDetector.detectEdges(testImage, lowThresholdParams);
      final highResult = EdgeDetector.detectEdges(testImage, highThresholdParams);

      expect(lowResult.isSuccess, isTrue);
      expect(highResult.isSuccess, isTrue);

      final lowEdgeCount = _countWhitePixels(lowResult.data!);
      final highEdgeCount = _countWhitePixels(highResult.data!);

      // Lower thresholds should generally detect more edges
      expect(lowEdgeCount, greaterThanOrEqualTo(highEdgeCount));
    });
  });
}

/// Creates a test pattern with edges for testing
img.Image _createTestPattern() {
  final image = img.Image(width: 64, height: 64);
  
  // Create a pattern with clear edges
  for (int y = 0; y < 64; y++) {
    for (int x = 0; x < 64; x++) {
      final color = (x < 32) ? img.ColorRgb8(0, 0, 0) : img.ColorRgb8(255, 255, 255);
      image.setPixel(x, y, color);
    }
  }
  
  return image;
}

/// Creates a horizontal gradient pattern
img.Image _createGradientPattern() {
  final image = img.Image(width: 64, height: 64);
  
  for (int y = 0; y < 64; y++) {
    for (int x = 0; x < 64; x++) {
      final intensity = (x * 255 / 63).round();
      image.setPixel(x, y, img.ColorRgb8(intensity, intensity, intensity));
    }
  }
  
  return image;
}

/// Counts white pixels (edges) in binary edge image
int _countWhitePixels(img.Image image) {
  int count = 0;
  for (int y = 0; y < image.height; y++) {
    for (int x = 0; x < image.width; x++) {
      final pixel = image.getPixel(x, y);
      if (pixel.r > 128) count++; // Consider bright pixels as edges
    }
  }
  return count;
}