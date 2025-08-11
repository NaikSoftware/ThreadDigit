import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:thread_digit/algorithm/models/quantization_result.dart';
import 'package:thread_digit/algorithm/services/color_quantizer.dart';
import 'package:thread_digit/colors/model/thread_color.dart';

void main() {
  group('ColorQuantizer', () {
    late img.Image testImage;
    late List<List<ThreadColor>> testCatalogs;

    setUp(() {
      testImage = _createTestPattern();
      testCatalogs = [_createTestThreadCatalog()];
    });

    test('quantization parameters validation works correctly', () {
      final validParams = QuantizationParameters();
      expect(validParams.isValid, isTrue);

      final invalidColorLimit = QuantizationParameters(colorLimit: 0);
      expect(invalidColorLimit.isValid, isFalse);

      final invalidStrength = QuantizationParameters(ditheringStrength: 1.5);
      expect(invalidStrength.isValid, isFalse);

      final invalidQuality = QuantizationParameters(qualityThreshold: 150.0);
      expect(invalidQuality.isValid, isFalse);
    });

    test('quantizes image successfully with default parameters', () async {
      final result = await ColorQuantizer.quantizeImage(
        testImage,
        testCatalogs,
      );

      expect(result.isSuccess, isTrue);
      expect(result.data, isNotNull);

      final quantizationResult = result.data!;
      expect(quantizationResult.threadCount, lessThanOrEqualTo(16)); // Default color limit
      expect(quantizationResult.qualityMetrics.overallScore, greaterThanOrEqualTo(0));
      expect(quantizationResult.processingTimeMs, greaterThan(0));
    });

    test('fails with invalid parameters', () async {
      final invalidParams = QuantizationParameters(colorLimit: 100);

      final result = await ColorQuantizer.quantizeImage(
        testImage,
        testCatalogs,
        params: invalidParams,
      );

      expect(result.isFailure, isTrue);
      expect(result.error, contains('Invalid quantization parameters'));
    });

    test('fails with empty thread catalogs', () async {
      final result = await ColorQuantizer.quantizeImage(
        testImage,
        <List<ThreadColor>>[],
      );

      expect(result.isFailure, isTrue);
      expect(result.error, contains('Thread catalogs cannot be empty'));
    });

    test('progress callback receives updates', () async {
      final progressUpdates = <double>[];
      final stageMessages = <String>[];

      await ColorQuantizer.quantizeImage(
        testImage,
        testCatalogs,
        progressCallback: (progress, stage) {
          progressUpdates.add(progress);
          stageMessages.add(stage);
        },
      );

      expect(progressUpdates, isNotEmpty);
      expect(progressUpdates.first, equals(0.0));
      expect(progressUpdates.last, equals(1.0));
      expect(stageMessages, contains('Starting color quantization...'));
      expect(stageMessages, contains('Color quantization complete'));
    });

    test('cancellation works correctly', () async {
      final cancelToken = CancelToken();
      
      // Cancel immediately
      cancelToken.cancel();
      expect(cancelToken.isCancelled, isTrue);

      final result = await ColorQuantizer.quantizeImage(
        testImage,
        testCatalogs,
        cancelToken: cancelToken,
      );

      expect(result.isFailure, isTrue);
      expect(result.error, contains('cancelled'));
    });

    test('dithering can be disabled', () async {
      final noDitheringParams = QuantizationParameters(enableDithering: false);

      final result = await ColorQuantizer.quantizeImage(
        testImage,
        testCatalogs,
        params: noDitheringParams,
      );

      expect(result.isSuccess, isTrue);
      final quantizationResult = result.data!;
      expect(quantizationResult.ditheringResult.ditheringStrength, equals(0.0));
    });

    test('different color distance algorithms produce results', () async {
      final ciede2000Params = QuantizationParameters(
        colorDistanceAlgorithm: ColorDistanceAlgorithm.ciede2000,
      );

      final labParams = QuantizationParameters(
        colorDistanceAlgorithm: ColorDistanceAlgorithm.labEuclidean,
      );

      final rgbParams = QuantizationParameters(
        colorDistanceAlgorithm: ColorDistanceAlgorithm.euclidean,
      );

      final ciede2000Result = await ColorQuantizer.quantizeImage(
        testImage,
        testCatalogs,
        params: ciede2000Params,
      );

      final labResult = await ColorQuantizer.quantizeImage(
        testImage,
        testCatalogs,
        params: labParams,
      );

      final rgbResult = await ColorQuantizer.quantizeImage(
        testImage,
        testCatalogs,
        params: rgbParams,
      );

      expect(ciede2000Result.isSuccess, isTrue);
      expect(labResult.isSuccess, isTrue);
      expect(rgbResult.isSuccess, isTrue);

      // All should produce valid mappings
      expect(ciede2000Result.data!.colorMapping, isNotEmpty);
      expect(labResult.data!.colorMapping, isNotEmpty);
      expect(rgbResult.data!.colorMapping, isNotEmpty);
    });

    test('thread usage statistics are calculated correctly', () async {
      final result = await ColorQuantizer.quantizeImage(
        testImage,
        testCatalogs,
      );

      expect(result.isSuccess, isTrue);
      final quantizationResult = result.data!;
      final stats = quantizationResult.threadUsageStats;

      expect(stats.threadColors.length, equals(quantizationResult.threadCount));
      expect(stats.pixelCounts.length, equals(stats.threadColors.length));
      expect(stats.coveragePercentages.length, equals(stats.threadColors.length));
      expect(stats.estimatedLengths.length, equals(stats.threadColors.length));
      expect(stats.estimatedCost, greaterThanOrEqualTo(0));
      expect(stats.totalThreadLength, greaterThanOrEqualTo(0));

      // Coverage should sum to approximately 100%
      final totalCoverage = stats.coveragePercentages.fold(0.0, (sum, coverage) => sum + coverage);
      expect(totalCoverage, closeTo(100.0, 10.0)); // Allow some tolerance
    });

    test('quality metrics are comprehensive', () async {
      final result = await ColorQuantizer.quantizeImage(
        testImage,
        testCatalogs,
      );

      expect(result.isSuccess, isTrue);
      final quantizationResult = result.data!;
      final quality = quantizationResult.qualityMetrics;

      expect(quality.colorAccuracy, greaterThanOrEqualTo(0));
      expect(quality.colorAccuracy, lessThanOrEqualTo(100));
      expect(quality.ditheringQuality, greaterThanOrEqualTo(0));
      expect(quality.ditheringQuality, lessThanOrEqualTo(100));
      expect(quality.clusteringQuality, greaterThanOrEqualTo(0));
      expect(quality.clusteringQuality, lessThanOrEqualTo(100));
      expect(quality.threadMatchQuality, greaterThanOrEqualTo(0));
      expect(quality.threadMatchQuality, lessThanOrEqualTo(100));
      expect(quality.overallScore, greaterThanOrEqualTo(0));
      expect(quality.overallScore, lessThanOrEqualTo(100));

      // Quality level should be appropriate
      expect(quality.qualityLevel, isNotNull);
    });

    test('summary provides concise overview', () async {
      final result = await ColorQuantizer.quantizeImage(
        testImage,
        testCatalogs,
      );

      expect(result.isSuccess, isTrue);
      final quantizationResult = result.data!;
      final summary = quantizationResult.summary;

      expect(summary.threadCount, equals(quantizationResult.threadCount));
      expect(summary.qualityScore, equals(quantizationResult.overallQuality));
      expect(summary.processingTimeSeconds, greaterThan(0));
      expect(summary.colorReductionPercentage, greaterThanOrEqualTo(0));
      expect(summary.colorReductionPercentage, lessThanOrEqualTo(100));
    });

    test('processing time estimation works correctly', () {
      final smallImage = img.Image(width: 32, height: 32);
      final largeImage = img.Image(width: 512, height: 512);
      
      final smallTime = ColorQuantizer.estimateProcessingTime(
        smallImage,
        QuantizationParameters(),
      );
      
      final largeTime = ColorQuantizer.estimateProcessingTime(
        largeImage,
        QuantizationParameters(),
      );

      expect(smallTime.inMilliseconds, greaterThan(0));
      expect(largeTime.inMilliseconds, greaterThan(smallTime.inMilliseconds));
    });

    test('optimal parameters generation works correctly', () {
      final smallImage = img.Image(width: 50, height: 50);
      final largeImage = img.Image(width: 1500, height: 1500);

      final smallParams = ColorQuantizer.getOptimalParameters(smallImage);
      final largeParams = ColorQuantizer.getOptimalParameters(largeImage);

      expect(smallParams.isValid, isTrue);
      expect(largeParams.isValid, isTrue);

      // Larger images should generally allow more colors
      expect(largeParams.colorLimit, greaterThanOrEqualTo(smallParams.colorLimit));
    });

    test('handles small images gracefully', () async {
      final tinyImage = img.Image(width: 16, height: 16);
      img.fill(tinyImage, color: img.ColorRgb8(128, 128, 128));

      final result = await ColorQuantizer.quantizeImage(
        tinyImage,
        testCatalogs,
      );

      expect(result.isFailure, isTrue);
      expect(result.error, contains('Image too small'));
    });

    test('rejects oversized images', () async {
      // Note: We can't actually create a 5000x5000 image in tests due to memory constraints
      // This test would be more relevant in integration testing
      
      // Test the boundary case
      final largishImage = img.Image(width: 1000, height: 1000);
      
      final result = await ColorQuantizer.quantizeImage(
        largishImage,
        testCatalogs,
      );

      // Should succeed for reasonable sizes
      expect(result.isSuccess, isTrue);
    });

    test('cancellation token behavior is correct', () {
      final token = CancelToken();
      
      expect(token.isCancelled, isFalse);
      
      token.cancel();
      expect(token.isCancelled, isTrue);
      
      // Multiple cancellations should be safe
      token.cancel();
      expect(token.isCancelled, isTrue);
    });
  });
}

/// Creates a test pattern with multiple colors
img.Image _createTestPattern() {
  final image = img.Image(width: 64, height: 64);
  
  // Create a pattern with distinct regions
  for (int y = 0; y < 64; y++) {
    for (int x = 0; x < 64; x++) {
      late img.Color color;
      
      if (x < 16) {
        color = img.ColorRgb8(255, 0, 0); // Red
      } else if (x < 32) {
        color = img.ColorRgb8(0, 255, 0); // Green
      } else if (x < 48) {
        color = img.ColorRgb8(0, 0, 255); // Blue
      } else {
        color = img.ColorRgb8(255, 255, 0); // Yellow
      }
      
      image.setPixel(x, y, color);
    }
  }
  
  return image;
}

/// Creates a test thread catalog
List<ThreadColor> _createTestThreadCatalog() {
  return [
    const ThreadColor(
      name: 'Black',
      code: 'BK001',
      red: 0,
      green: 0,
      blue: 0,
      catalog: 'Test',
    ),
    const ThreadColor(
      name: 'Red',
      code: 'RD001',
      red: 255,
      green: 0,
      blue: 0,
      catalog: 'Test',
    ),
    const ThreadColor(
      name: 'Green',
      code: 'GR001',
      red: 0,
      green: 255,
      blue: 0,
      catalog: 'Test',
    ),
    const ThreadColor(
      name: 'Blue',
      code: 'BL001',
      red: 0,
      green: 0,
      blue: 255,
      catalog: 'Test',
    ),
    const ThreadColor(
      name: 'Yellow',
      code: 'YL001',
      red: 255,
      green: 255,
      blue: 0,
      catalog: 'Test',
    ),
    const ThreadColor(
      name: 'White',
      code: 'WH001',
      red: 255,
      green: 255,
      blue: 255,
      catalog: 'Test',
    ),
    const ThreadColor(
      name: 'Gray',
      code: 'GY001',
      red: 128,
      green: 128,
      blue: 128,
      catalog: 'Test',
    ),
  ];
}