import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:thread_digit/algorithm/processors/image_preprocessor.dart';

void main() {
  group('ImagePreprocessor', () {
    late img.Image testImage;

    setUp(() {
      // Create a 100x100 test image
      testImage = img.Image(width: 100, height: 100);
      img.fill(testImage, color: img.ColorRgb8(128, 128, 128));
    });

    test('preprocessing parameters validation works correctly', () {
      const validParams = PreprocessingParameters();
      expect(validParams.isValid, isTrue);

      const invalidMaxDim = PreprocessingParameters(maxDimension: 16); // Too small
      expect(invalidMaxDim.isValid, isFalse);

      const invalidSpatialSigma = PreprocessingParameters(spatialSigma: -1.0);
      expect(invalidSpatialSigma.isValid, isFalse);
    });

    test('processes image successfully with valid parameters', () {
      const params = PreprocessingParameters(
        maxDimension: 200,
        spatialSigma: 3.0,
        rangeSigma: 0.1,
        contrastFactor: 1.1,
      );

      final result = ImagePreprocessor.process(testImage, params);

      expect(result.isSuccess, isTrue);
      expect(result.data, isNotNull);
      expect(result.data!.width, lessThanOrEqualTo(200));
      expect(result.data!.height, lessThanOrEqualTo(200));
    });

    test('fails with invalid parameters', () {
      const invalidParams = PreprocessingParameters(spatialSigma: -1.0);

      final result = ImagePreprocessor.process(testImage, invalidParams);

      expect(result.isFailure, isTrue);
      expect(result.error, contains('Invalid preprocessing parameters'));
    });

    test('resizes large images correctly', () {
      // Create large test image
      final largeImage = img.Image(width: 2000, height: 1000);
      const params = PreprocessingParameters(maxDimension: 500);

      final result = ImagePreprocessor.process(largeImage, params);

      expect(result.isSuccess, isTrue);
      expect(result.data!.width, equals(500));
      expect(result.data!.height, equals(250)); // Maintains aspect ratio
    });

    test('estimates processing time reasonably', () {
      final time = ImagePreprocessor.estimateProcessingTime(testImage);
      expect(time, greaterThan(0));
      expect(time, lessThan(1.0)); // Should be very fast for small image
    });

    test('generates optimal parameters based on image size', () {
      // Small image
      final smallImage = img.Image(width: 100, height: 100);
      final smallParams = ImagePreprocessor.getOptimalParameters(smallImage);
      expect(smallParams.spatialSigma, equals(3.0)); // Reduced for small images

      // Large image  
      final largeImage = img.Image(width: 2000, height: 2000);
      final largeParams = ImagePreprocessor.getOptimalParameters(largeImage);
      expect(largeParams.maxDimension, equals(1024)); // Reduced for large images
    });
  });
}