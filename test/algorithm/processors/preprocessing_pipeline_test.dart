import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:thread_digit/algorithm/processors/preprocessing_pipeline.dart';
import 'package:thread_digit/algorithm/processors/image_preprocessor.dart';

void main() {
  group('PreprocessingPipeline', () {
    late img.Image testImage;

    setUp(() {
      // Create a simple test image with some patterns
      testImage = img.Image(width: 64, height: 64);
      
      // Add some pattern for better processing results
      for (int y = 0; y < 64; y++) {
        for (int x = 0; x < 64; x++) {
          final intensity = ((x + y) % 32) * 8; // Creates diagonal stripes
          testImage.setPixel(x, y, img.ColorRgb8(intensity, intensity, intensity));
        }
      }
    });

    test('validates input image correctly', () {
      // Valid image
      final validResult = PreprocessingPipeline.validateInput(testImage);
      expect(validResult.isSuccess, isTrue);

      // Too small image
      final tooSmall = img.Image(width: 16, height: 16);
      final smallResult = PreprocessingPipeline.validateInput(tooSmall);
      expect(smallResult.isFailure, isTrue);
      expect(smallResult.error, contains('too small'));

      // Too large image (simulated)
      final tooLarge = img.Image(width: 5000, height: 5000);
      final largeResult = PreprocessingPipeline.validateInput(tooLarge);
      expect(largeResult.isFailure, isTrue);
      expect(largeResult.error, contains('too large'));
    });

    test('processes complete pipeline successfully', () async {
      final result = await PreprocessingPipeline.processImage(testImage);

      expect(result.isSuccess, isTrue);
      expect(result.data, isNotNull);

      final data = result.data!;
      expect(data.isValid, isTrue);
      expect(data.processedImage.width, equals(testImage.width));
      expect(data.processedImage.height, equals(testImage.height));
      expect(data.edgeMap.width, equals(testImage.width));
      expect(data.gradients.width, equals(testImage.width));
      expect(data.directionField.width, equals(testImage.width));
      expect(data.processingTimeMs, greaterThan(0));
    });

    test('tracks progress correctly', () async {
      final progressUpdates = <double>[];
      final stageMessages = <String>[];

      await PreprocessingPipeline.processImage(
        testImage,
        progressCallback: (progress, stage) {
          progressUpdates.add(progress);
          stageMessages.add(stage);
        },
      );

      expect(progressUpdates, isNotEmpty);
      expect(progressUpdates.first, equals(0.0));
      expect(progressUpdates.last, equals(1.0));
      expect(stageMessages, contains('Preprocessing image...'));
      expect(stageMessages, contains('Preprocessing pipeline complete'));
    });

    test('fails with invalid pipeline parameters', () async {
      const invalidPreprocessingParams = PreprocessingParameters(spatialSigma: -1.0);
      final invalidParams = PipelineParameters(
        preprocessingParams: invalidPreprocessingParams,
      );

      final result = await PreprocessingPipeline.processImage(
        testImage,
        params: invalidParams,
      );

      expect(result.isFailure, isTrue);
      expect(result.error, contains('Invalid pipeline parameters'));
    });

    test('estimates processing time and memory usage', () {
      final time = PreprocessingPipeline.estimateProcessingTime(64, 64);
      final memory = PreprocessingPipeline.estimateMemoryUsage(64, 64);

      expect(time, greaterThan(0));
      expect(memory, greaterThan(0));
      
      // Larger images should take more time and memory
      final largeTime = PreprocessingPipeline.estimateProcessingTime(512, 512);
      final largeMemory = PreprocessingPipeline.estimateMemoryUsage(512, 512);
      
      expect(largeTime, greaterThan(time));
      expect(largeMemory, greaterThan(memory));
    });

    test('generates optimal parameters for different image sizes', () {
      // Small image
      final smallImage = img.Image(width: 50, height: 50);
      final smallParams = PreprocessingPipeline.getOptimalParameters(smallImage);
      expect(smallParams.isValid, isTrue);

      // Large image
      final largeImage = img.Image(width: 1500, height: 1500);
      final largeParams = PreprocessingPipeline.getOptimalParameters(largeImage);
      expect(largeParams.isValid, isTrue);
      
      // Parameters should be different for different sized images
      expect(smallParams.gradientParams.smoothingSigma, 
             isNot(equals(largeParams.gradientParams.smoothingSigma)));
    });

    test('cancellation works correctly', () async {
      final cancelToken = CancelToken();
      
      // Cancel immediately
      cancelToken.cancel();
      expect(cancelToken.isCancelled, isTrue);

      final result = await PreprocessingPipeline.processImage(
        testImage,
        cancelToken: cancelToken,
      );

      expect(result.isFailure, isTrue);
      expect(result.error, contains('cancelled'));
    });
  });
}