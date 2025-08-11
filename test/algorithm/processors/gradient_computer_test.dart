import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:thread_digit/algorithm/processors/gradient_computer.dart';


void main() {
  group('GradientComputer', () {
    late img.Image testImage;
    late img.Image gradientImage;

    setUp(() {
      // Create test patterns
      testImage = _createTestPattern();
      gradientImage = _createGradientPattern();
    });

    test('gradient parameters validation works correctly', () {
      const validParams = GradientParameters();
      expect(validParams.isValid, isTrue);

      const invalidKernel = GradientParameters(sobelKernelSize: 7);
      expect(invalidKernel.isValid, isFalse);

      const invalidSigma = GradientParameters(smoothingSigma: -1.0);
      expect(invalidSigma.isValid, isFalse);
    });

    test('computes gradients successfully with valid parameters', () {
      const params = GradientParameters(
        sobelKernelSize: 3,
        smoothingSigma: 2.0,
        normalizeGradients: true,
      );

      final result = GradientComputer.computeGradients(testImage, params);

      expect(result.isSuccess, isTrue);
      expect(result.data, isNotNull);

      final gradients = result.data!;
      expect(gradients.width, equals(testImage.width));
      expect(gradients.height, equals(testImage.height));
      expect(gradients.magnitudes.length, equals(testImage.width * testImage.height));
      expect(gradients.directions.length, equals(testImage.width * testImage.height));
    });

    test('fails with invalid parameters', () {
      const invalidParams = GradientParameters(smoothingSigma: -1.0);

      final result = GradientComputer.computeGradients(testImage, invalidParams);

      expect(result.isFailure, isTrue);
      expect(result.error, contains('Invalid gradient parameters'));
    });

    test('horizontal gradient produces primarily horizontal gradients', () {
      const params = GradientParameters(normalizeGradients: true);

      final result = GradientComputer.computeGradients(gradientImage, params);

      expect(result.isSuccess, isTrue);
      final gradients = result.data!;

      // Sample gradients in middle area where they should be strongest
      final centerY = gradients.height ~/ 2;
      final centerX = gradients.width ~/ 2;
      
      final magnitude = gradients.getMagnitude(centerX, centerY);
      final direction = gradients.getDirection(centerX, centerY);

      // Should have some gradient magnitude
      expect(magnitude, greaterThan(0.05));
      
      // Direction should be close to 0 or π (horizontal)
      expect(direction.abs() < 0.5 || (direction.abs() - 3.14159).abs() < 0.5, isTrue);
    });

    test('normalized gradients are in valid range', () {
      const params = GradientParameters(normalizeGradients: true);

      final result = GradientComputer.computeGradients(testImage, params);

      expect(result.isSuccess, isTrue);
      final gradients = result.data!;

      // Check that all magnitudes are in [0, 1] range
      for (final magnitude in gradients.magnitudes) {
        expect(magnitude, greaterThanOrEqualTo(0.0));
        expect(magnitude, lessThanOrEqualTo(1.0));
      }

      // Check that all directions are in [-π, π] range
      for (final direction in gradients.directions) {
        expect(direction, greaterThanOrEqualTo(-3.15));
        expect(direction, lessThanOrEqualTo(3.15));
      }
    });

    test('calculates average magnitude correctly', () {
      const params = GradientParameters();

      final result = GradientComputer.computeGradients(testImage, params);

      expect(result.isSuccess, isTrue);
      final gradients = result.data!;

      final averageMagnitude = gradients.averageMagnitude;
      expect(averageMagnitude, greaterThanOrEqualTo(0.0));

      // Average should be reasonable (not all zeros, not too high)
      expect(averageMagnitude, lessThan(gradients.maxMagnitude));
    });

    test('different smoothing parameters produce different results', () {
      const lowSmoothing = GradientParameters(smoothingSigma: 1.0);
      const highSmoothing = GradientParameters(smoothingSigma: 4.0);

      final lowResult = GradientComputer.computeGradients(testImage, lowSmoothing);
      final highResult = GradientComputer.computeGradients(testImage, highSmoothing);

      expect(lowResult.isSuccess, isTrue);
      expect(highResult.isSuccess, isTrue);

      final lowAvg = lowResult.data!.averageMagnitude;
      final highAvg = highResult.data!.averageMagnitude;

      // Results should be different (usually high smoothing reduces gradients)
      expect(lowAvg, isNot(closeTo(highAvg, 0.01)));
    });

    test('gets gradient vector correctly', () {
      const params = GradientParameters(normalizeGradients: true);

      final result = GradientComputer.computeGradients(testImage, params);

      expect(result.isSuccess, isTrue);
      final gradients = result.data!;

      final centerX = gradients.width ~/ 2;
      final centerY = gradients.height ~/ 2;
      
      final vector = gradients.getGradientVector(centerX, centerY);

      // Vector components should be in valid range
      expect(vector.x.abs(), lessThanOrEqualTo(1.0));
      expect(vector.y.abs(), lessThanOrEqualTo(1.0));
    });

    test('visualization methods create valid images', () {
      const params = GradientParameters();

      final result = GradientComputer.computeGradients(testImage, params);

      expect(result.isSuccess, isTrue);
      final gradients = result.data!;

      final magnitudeViz = GradientComputer.visualizeMagnitudes(gradients);
      final directionViz = GradientComputer.visualizeDirections(gradients);

      expect(magnitudeViz.width, equals(gradients.width));
      expect(magnitudeViz.height, equals(gradients.height));
      expect(directionViz.width, equals(gradients.width));
      expect(directionViz.height, equals(gradients.height));
    });
  });
}

/// Creates a test pattern with clear gradients
img.Image _createTestPattern() {
  final image = img.Image(width: 64, height: 64);
  
  // Create a pattern with diagonal features
  for (int y = 0; y < 64; y++) {
    for (int x = 0; x < 64; x++) {
      final intensity = ((x + y) % 32) * 8;
      image.setPixel(x, y, img.ColorRgb8(intensity, intensity, intensity));
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