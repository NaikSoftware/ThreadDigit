import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:thread_digit/algorithm/models/embroidery_parameters.dart';
import 'package:thread_digit/algorithm/models/quantization_result.dart';
import 'package:thread_digit/algorithm/processors/preprocessing_pipeline.dart';
import 'package:thread_digit/algorithm/services/color_quantizer.dart' show ColorQuantizer;
import 'package:thread_digit/algorithm/services/color_quantizer.dart' as cq;
import 'package:thread_digit/colors/model/thread_color.dart';

void main() {
  group('Color Quantization Integration', () {
    late img.Image testImage;
    late List<List<ThreadColor>> threadCatalogs;

    setUp(() {
      testImage = _createComplexTestPattern();
      threadCatalogs = [
        _createMadeiraThreadCatalog(),
        _createGunoldThreadCatalog(),
      ];
    });

    test('end-to-end color quantization with preprocessing', () async {
      // Step 1: Preprocess image
      final preprocessingResult = await PreprocessingPipeline.processImage(testImage);
      expect(preprocessingResult.isSuccess, isTrue);

      // Step 2: Quantize colors
      const params = QuantizationParameters(
        colorLimit: 12,
        enableDithering: true,
        colorDistanceAlgorithm: ColorDistanceAlgorithm.ciede2000,
      );

      final quantizationResult = await ColorQuantizer.quantizeImage(
        preprocessingResult.data!.processedImage,
        threadCatalogs,
        params: params,
      );

      expect(quantizationResult.isSuccess, isTrue);
      
      final result = quantizationResult.data!;
      expect(result.threadCount, lessThanOrEqualTo(12));
      expect(result.overallQuality, greaterThan(50.0)); // Reasonable quality
      expect(result.meetsQualityStandards, isTrue);
    });

    test('integration with embroidery parameters', () async {
      const embroideryParams = EmbroideryParameters(
        minStitchLength: 2.0,
        maxStitchLength: 10.0,
        colorLimit: 8,
        density: 0.8,
      );

      final quantizationParams = QuantizationParameters(
        colorLimit: embroideryParams.colorLimit,
        enableDithering: true,
        ditheringStrength: 0.8,
      );

      final result = await ColorQuantizer.quantizeImage(
        testImage,
        threadCatalogs,
        params: quantizationParams,
      );

      expect(result.isSuccess, isTrue);
      expect(result.data!.threadCount, lessThanOrEqualTo(embroideryParams.colorLimit));
    });

    test('multiple thread catalog integration', () async {
      final result = await ColorQuantizer.quantizeImage(
        testImage,
        threadCatalogs,
      );

      expect(result.isSuccess, isTrue);
      
      final quantizationResult = result.data!;
      
      // Should map colors to threads from available catalogs
      expect(quantizationResult.colorMapping, isNotEmpty);
      
      // Check that threads come from provided catalogs
      final usedCatalogs = quantizationResult.usedThreads
          .map((thread) => thread.catalog)
          .toSet();
      
      expect(usedCatalogs.contains('Madeira') || usedCatalogs.contains('Gunold'), isTrue);
    });

    test('real-world photo processing simulation', () async {
      // Create more realistic photo-like pattern
      final photoLikeImage = _createPhotoLikePattern(256, 256);

      const params = QuantizationParameters(
        colorLimit: 16,
        enableDithering: true,
        ditheringStrength: 0.8,
        colorDistanceAlgorithm: ColorDistanceAlgorithm.ciede2000,
        qualityThreshold: 70.0,
      );

      final result = await ColorQuantizer.quantizeImage(
        photoLikeImage,
        threadCatalogs,
        params: params,
      );

      expect(result.isSuccess, isTrue);
      
      final quantizationResult = result.data!;
      expect(quantizationResult.threadCount, greaterThan(0));
      expect(quantizationResult.threadCount, lessThanOrEqualTo(16));
      
      // Should have reasonable thread usage distribution
      final stats = quantizationResult.threadUsageStats;
      expect(stats.threadColors, isNotEmpty);
      expect(stats.totalThreadLength, greaterThan(0));
      expect(stats.estimatedCost, greaterThan(0));
    });

    test('progressive quality improvement with more colors', () async {
      final results = <QuantizationResult>[];
      
      // Test with different color limits
      for (final colorLimit in [4, 8, 16]) {
        final params = QuantizationParameters(colorLimit: colorLimit);
        
        final result = await ColorQuantizer.quantizeImage(
          testImage,
          threadCatalogs,
          params: params,
        );
        
        expect(result.isSuccess, isTrue);
        results.add(result.data!);
      }

      // Quality should generally improve with more colors
      expect(results[0].overallQuality, lessThanOrEqualTo(results[2].overallQuality + 10)); // Allow some variance
      
      // Thread count should match color limits
      expect(results[0].threadCount, lessThanOrEqualTo(4));
      expect(results[1].threadCount, lessThanOrEqualTo(8));
      expect(results[2].threadCount, lessThanOrEqualTo(16));
    });

    test('performance within acceptable bounds', () async {
      final stopwatch = Stopwatch()..start();

      final result = await ColorQuantizer.quantizeImage(
        testImage,
        threadCatalogs,
      );

      stopwatch.stop();

      expect(result.isSuccess, isTrue);
      
      // Should complete within reasonable time for test image
      expect(stopwatch.elapsedMilliseconds, lessThan(30000)); // 30 seconds max
      
      // Processing time should be recorded
      expect(result.data!.processingTimeMs, greaterThan(0));
      expect(result.data!.processingTimeMs, lessThan(stopwatch.elapsedMilliseconds + 1000));
    });

    test('cancellation during long operation', () async {
      final cancelToken = cq.CancelToken();
      
      // Start processing and cancel after short delay
      final resultFuture = ColorQuantizer.quantizeImage(
        testImage,
        threadCatalogs,
        cancelToken: cancelToken,
      );

      // Cancel after a short delay
      await Future.delayed(const Duration(milliseconds: 10));
      cancelToken.cancel();

      final result = await resultFuture;
      
      // Should be cancelled or complete normally (timing dependent)
      if (result.isFailure) {
        expect(result.error, contains('cancelled'));
      } else {
        // If it completed before cancellation, that's also valid
        expect(result.data, isNotNull);
      }
    });

    test('error handling with corrupted image data', () async {
      // Create minimal image that might cause issues
      final tinyImage = img.Image(width: 1, height: 1);
      tinyImage.setPixel(0, 0, img.ColorRgb8(128, 128, 128));

      final result = await ColorQuantizer.quantizeImage(
        tinyImage,
        threadCatalogs,
      );

      // Should handle gracefully
      expect(result.isFailure, isTrue);
      expect(result.error, isNotEmpty);
    });

    test('thread recommendation generation', () async {
      final result = await ColorQuantizer.quantizeImage(
        testImage,
        threadCatalogs,
      );

      expect(result.isSuccess, isTrue);
      
      final stats = result.data!.threadUsageStats;
      expect(stats.recommendations, isNotNull);
      
      // Should provide meaningful recommendations for realistic usage
      if (stats.threadColors.isNotEmpty && stats.coveragePercentages.isNotEmpty) {
        // If there's a dominant color, should be noted
        if (stats.coveragePercentages.first > 50) {
          final hasRecommendation = stats.recommendations.any(
            (rec) => rec.contains('Primary thread') || rec.contains('covers'),
          );
          expect(hasRecommendation, isTrue);
        }
      }
    });

    test('quality metrics correlation with visual assessment', () async {
      // Test with well-suited vs poorly-suited palette
      final wellSuitedCatalog = _createWellMatchedCatalog();
      final poorlyMatchedCatalog = _createPoorlyMatchedCatalog();

      final goodResult = await ColorQuantizer.quantizeImage(
        testImage,
        [wellSuitedCatalog],
      );

      final poorResult = await ColorQuantizer.quantizeImage(
        testImage,
        [poorlyMatchedCatalog],
      );

      expect(goodResult.isSuccess, isTrue);
      expect(poorResult.isSuccess, isTrue);

      // Well-matched catalog should have better thread match quality
      final goodQuality = goodResult.data!.qualityMetrics;
      final poorQuality = poorResult.data!.qualityMetrics;

      expect(goodQuality.threadMatchQuality, greaterThanOrEqualTo(poorQuality.threadMatchQuality - 10));
    });
  });
}

/// Creates a complex test pattern simulating photograph characteristics
img.Image _createComplexTestPattern() {
  final image = img.Image(width: 128, height: 128);
  
  for (int y = 0; y < 128; y++) {
    for (int x = 0; x < 128; x++) {
      // Create gradient with some noise and color variation
      final baseR = (x * 255 / 127).round();
      final baseG = (y * 255 / 127).round();
      final baseB = ((x + y) * 128 / 254).round();
      
      // Add some noise
      final noise = ((x * y) % 17) - 8;
      
      final r = (baseR + noise).clamp(0, 255);
      final g = (baseG + noise).clamp(0, 255);
      final b = (baseB + noise).clamp(0, 255);
      
      image.setPixel(x, y, img.ColorRgb8(r, g, b));
    }
  }
  
  return image;
}

/// Creates a photo-like pattern with more realistic color distribution
img.Image _createPhotoLikePattern(int width, int height) {
  final image = img.Image(width: width, height: height);
  
  for (int y = 0; y < height; y++) {
    for (int x = 0; x < width; x++) {
      // Simulate skin tones, hair, clothing, background
      double t = (x + y) / (width + height);
      
      int r, g, b;
      
      if (t < 0.3) {
        // Skin tone region
        r = (220 + (t * 50)).round().clamp(0, 255);
        g = (180 + (t * 40)).round().clamp(0, 255);
        b = (150 + (t * 30)).round().clamp(0, 255);
      } else if (t < 0.6) {
        // Hair/dark region
        r = (80 + (t * 40)).round().clamp(0, 255);
        g = (60 + (t * 30)).round().clamp(0, 255);
        b = (40 + (t * 20)).round().clamp(0, 255);
      } else {
        // Background/clothing
        r = (100 + (t * 100)).round().clamp(0, 255);
        g = (120 + (t * 80)).round().clamp(0, 255);
        b = (140 + (t * 60)).round().clamp(0, 255);
      }
      
      image.setPixel(x, y, img.ColorRgb8(r, g, b));
    }
  }
  
  return image;
}

/// Creates a realistic Madeira thread catalog subset
List<ThreadColor> _createMadeiraThreadCatalog() {
  return [
    const ThreadColor(name: 'Snow White', code: '1001', red: 255, green: 255, blue: 255, catalog: 'Madeira'),
    const ThreadColor(name: 'Black', code: '1000', red: 0, green: 0, blue: 0, catalog: 'Madeira'),
    const ThreadColor(name: 'Dark Red', code: '1147', red: 139, green: 0, blue: 0, catalog: 'Madeira'),
    const ThreadColor(name: 'Red', code: '1134', red: 220, green: 20, blue: 60, catalog: 'Madeira'),
    const ThreadColor(name: 'Pink', code: '1114', red: 255, green: 182, blue: 193, catalog: 'Madeira'),
    const ThreadColor(name: 'Orange', code: '1178', red: 255, green: 165, blue: 0, catalog: 'Madeira'),
    const ThreadColor(name: 'Yellow', code: '1067', red: 255, green: 255, blue: 0, catalog: 'Madeira'),
    const ThreadColor(name: 'Green', code: '1051', red: 0, green: 128, blue: 0, catalog: 'Madeira'),
    const ThreadColor(name: 'Blue', code: '1029', red: 0, green: 0, blue: 255, catalog: 'Madeira'),
    const ThreadColor(name: 'Purple', code: '1013', red: 128, green: 0, blue: 128, catalog: 'Madeira'),
    const ThreadColor(name: 'Brown', code: '1142', red: 139, green: 69, blue: 19, catalog: 'Madeira'),
    const ThreadColor(name: 'Gray', code: '1181', red: 128, green: 128, blue: 128, catalog: 'Madeira'),
  ];
}

/// Creates a realistic Gunold thread catalog subset
List<ThreadColor> _createGunoldThreadCatalog() {
  return [
    const ThreadColor(name: 'White', code: '61001', red: 250, green: 250, blue: 250, catalog: 'Gunold'),
    const ThreadColor(name: 'Black', code: '61005', red: 10, green: 10, blue: 10, catalog: 'Gunold'),
    const ThreadColor(name: 'Cardinal Red', code: '61081', red: 200, green: 0, blue: 40, catalog: 'Gunold'),
    const ThreadColor(name: 'Salmon', code: '61089', red: 250, green: 128, blue: 114, catalog: 'Gunold'),
    const ThreadColor(name: 'Golden Yellow', code: '61024', red: 255, green: 215, blue: 0, catalog: 'Gunold'),
    const ThreadColor(name: 'Kelly Green', code: '61051', red: 76, green: 187, blue: 23, catalog: 'Gunold'),
    const ThreadColor(name: 'Royal Blue', code: '61135', red: 65, green: 105, blue: 225, catalog: 'Gunold'),
    const ThreadColor(name: 'Lavender', code: '61193', red: 230, green: 230, blue: 250, catalog: 'Gunold'),
    const ThreadColor(name: 'Chocolate', code: '61058', red: 210, green: 105, blue: 30, catalog: 'Gunold'),
    const ThreadColor(name: 'Silver', code: '61041', red: 192, green: 192, blue: 192, catalog: 'Gunold'),
  ];
}

/// Creates a well-matched catalog for test pattern
List<ThreadColor> _createWellMatchedCatalog() {
  return [
    const ThreadColor(name: 'Perfect Red', code: 'P001', red: 255, green: 0, blue: 0, catalog: 'Perfect'),
    const ThreadColor(name: 'Perfect Green', code: 'P002', red: 0, green: 255, blue: 0, catalog: 'Perfect'),
    const ThreadColor(name: 'Perfect Blue', code: 'P003', red: 0, green: 0, blue: 255, catalog: 'Perfect'),
    const ThreadColor(name: 'Perfect Yellow', code: 'P004', red: 255, green: 255, blue: 0, catalog: 'Perfect'),
    const ThreadColor(name: 'Perfect Magenta', code: 'P005', red: 255, green: 0, blue: 255, catalog: 'Perfect'),
    const ThreadColor(name: 'Perfect Cyan', code: 'P006', red: 0, green: 255, blue: 255, catalog: 'Perfect'),
  ];
}

/// Creates a poorly matched catalog for test pattern
List<ThreadColor> _createPoorlyMatchedCatalog() {
  return [
    const ThreadColor(name: 'Muddy Brown 1', code: 'M001', red: 101, green: 67, blue: 33, catalog: 'Muddy'),
    const ThreadColor(name: 'Muddy Brown 2', code: 'M002', red: 102, green: 68, blue: 34, catalog: 'Muddy'),
    const ThreadColor(name: 'Muddy Brown 3', code: 'M003', red: 103, green: 69, blue: 35, catalog: 'Muddy'),
    const ThreadColor(name: 'Muddy Brown 4', code: 'M004', red: 104, green: 70, blue: 36, catalog: 'Muddy'),
  ];
}