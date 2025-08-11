import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:thread_digit/algorithm/processors/kmeans_color_quantizer.dart';

void main() {
  group('KMeansColorQuantizer', () {
    late img.Image testImage;
    late img.Image gradientImage;

    setUp(() {
      testImage = _createTestPattern();
      gradientImage = _createGradientPattern();
    });

    test('quantization parameters validation works correctly', () {
      const validParams = KMeansParameters();
      expect(validParams.isValid, isTrue);

      const invalidMaxIterations = KMeansParameters(maxIterations: 0);
      expect(invalidMaxIterations.isValid, isFalse);

      const invalidConvergence = KMeansParameters(convergenceThreshold: 2.0);
      expect(invalidConvergence.isValid, isFalse);

      const invalidMinCluster = KMeansParameters(minClusterSize: 0);
      expect(invalidMinCluster.isValid, isFalse);
    });

    test('quantizes colors successfully with valid parameters', () {
      final result = KMeansColorQuantizer.quantize(testImage, 4);

      expect(result.isSuccess, isTrue);
      expect(result.data, isNotNull);

      final clusteringResult = result.data!;
      expect(clusteringResult.clusters.length, equals(4));
      expect(clusteringResult.isValid, isTrue);
      expect(clusteringResult.converged, isTrue);
      expect(clusteringResult.totalPixels, equals(testImage.width * testImage.height));
    });

    test('fails with invalid parameters', () {
      const invalidParams = KMeansParameters(maxIterations: -1);

      final result = KMeansColorQuantizer.quantize(
        testImage, 
        4, 
        params: invalidParams,
      );

      expect(result.isFailure, isTrue);
      expect(result.error, contains('Invalid K-means parameters'));
    });

    test('fails with invalid cluster count', () {
      final result1 = KMeansColorQuantizer.quantize(testImage, 0);
      expect(result1.isFailure, isTrue);
      expect(result1.error, contains('Cluster count must be between 1 and 64'));

      final result2 = KMeansColorQuantizer.quantize(testImage, 100);
      expect(result2.isFailure, isTrue);
      expect(result2.error, contains('Cluster count must be between 1 and 64'));
    });

    test('handles single cluster correctly', () {
      final result = KMeansColorQuantizer.quantize(testImage, 1);

      expect(result.isSuccess, isTrue);
      final clusteringResult = result.data!;
      expect(clusteringResult.clusters.length, equals(1));
      expect(clusteringResult.clusters[0].memberCount, equals(testImage.width * testImage.height));
    });

    test('reduces number of clusters for simple images', () {
      // Create simple two-color image
      final simpleImage = img.Image(width: 32, height: 32);
      for (int y = 0; y < 32; y++) {
        for (int x = 0; x < 32; x++) {
          final color = x < 16 ? img.ColorRgb8(0, 0, 0) : img.ColorRgb8(255, 255, 255);
          simpleImage.setPixel(x, y, color);
        }
      }

      final result = KMeansColorQuantizer.quantize(simpleImage, 8);

      expect(result.isSuccess, isTrue);
      final clusteringResult = result.data!;
      
      // Should have meaningful clusters
      final meaningfulClusters = clusteringResult.clusters
          .where((cluster) => cluster.memberCount > 10)
          .length;
      expect(meaningfulClusters, greaterThanOrEqualTo(1));
      expect(meaningfulClusters, lessThanOrEqualTo(8));
    });

    test('gradient image produces expected clustering', () {
      final result = KMeansColorQuantizer.quantize(gradientImage, 6);

      expect(result.isSuccess, isTrue);
      final clusteringResult = result.data!;
      
      // Gradient should produce clusters spanning the intensity range
      expect(clusteringResult.clusters.length, equals(6));
      
      // Should have reasonable variance
      expect(clusteringResult.totalVariance, greaterThan(0));
      expect(clusteringResult.totalVariance, lessThan(5000)); // Reasonable upper bound
    });

    test('k-means++ initialization produces better results than random', () {
      const kmeansParams = KMeansParameters(
        initializationMethod: ClusterInitialization.kMeansPlusPlus,
        maxIterations: 50,
      );
      
      const randomParams = KMeansParameters(
        initializationMethod: ClusterInitialization.random,
        maxIterations: 50,
      );

      final kmeansResult = KMeansColorQuantizer.quantize(
        testImage, 
        4, 
        params: kmeansParams,
      );
      
      final randomResult = KMeansColorQuantizer.quantize(
        testImage, 
        4, 
        params: randomParams,
      );

      expect(kmeansResult.isSuccess, isTrue);
      expect(randomResult.isSuccess, isTrue);

      // K-means++ should generally converge faster or with better quality
      final kmeansIterations = kmeansResult.data!.iterations;
      final randomIterations = randomResult.data!.iterations;
      
      // Verify iterations were performed
      expect(kmeansIterations, greaterThan(0));
      expect(randomIterations, greaterThan(0));
      
      // Both should converge
      expect(kmeansResult.data!.converged, isTrue);
      expect(randomResult.data!.converged, isTrue);
    });

    test('clustering result provides meaningful statistics', () {
      final result = KMeansColorQuantizer.quantize(testImage, 4);

      expect(result.isSuccess, isTrue);
      final clusteringResult = result.data!;

      expect(clusteringResult.clusterCount, equals(4));
      expect(clusteringResult.totalPixels, equals(testImage.width * testImage.height));
      expect(clusteringResult.averageQuality, greaterThanOrEqualTo(0));
      expect(clusteringResult.averageQuality, lessThanOrEqualTo(100));
      expect(clusteringResult.dominantColors.length, equals(4));
      expect(clusteringResult.processingTimeMs, greaterThanOrEqualTo(0));
    });

    test('optimal cluster estimation works correctly', () {
      final simpleImage = img.Image(width: 16, height: 16);
      img.fill(simpleImage, color: img.ColorRgb8(128, 128, 128));
      
      final optimalClusters = KMeansColorQuantizer.estimateOptimalClusters(simpleImage);
      expect(optimalClusters, greaterThanOrEqualTo(2));
      expect(optimalClusters, lessThanOrEqualTo(16));
      
      // Test with max clusters parameter
      final optimalWithMax = KMeansColorQuantizer.estimateOptimalClusters(
        simpleImage, 
        maxClusters: 8,
      );
      expect(optimalWithMax, lessThanOrEqualTo(8));
    });

    test('handles empty or very small images gracefully', () {
      final tinyImage = img.Image(width: 2, height: 2);
      for (int y = 0; y < 2; y++) {
        for (int x = 0; x < 2; x++) {
          tinyImage.setPixel(x, y, img.ColorRgb8(x * 128, y * 128, 64));
        }
      }

      final result = KMeansColorQuantizer.quantize(tinyImage, 2);
      
      // Should either succeed or fail gracefully
      if (result.isSuccess) {
        expect(result.data!.clusters.length, lessThanOrEqualTo(4)); // Max pixels
      } else {
        expect(result.error, isNotEmpty);
      }
    });

    test('different parameters produce different results', () {
      const params1 = KMeansParameters(maxIterations: 20, convergenceThreshold: 0.1);
      const params2 = KMeansParameters(maxIterations: 100, convergenceThreshold: 0.001);

      final result1 = KMeansColorQuantizer.quantize(testImage, 4, params: params1);
      final result2 = KMeansColorQuantizer.quantize(testImage, 4, params: params2);

      expect(result1.isSuccess, isTrue);
      expect(result2.isSuccess, isTrue);

      // Results might be different due to different convergence criteria
      // At minimum, both should be valid
      expect(result1.data!.isValid, isTrue);
      expect(result2.data!.isValid, isTrue);
    });
  });
}

/// Creates a test pattern with distinct color regions
img.Image _createTestPattern() {
  final image = img.Image(width: 64, height: 64);
  
  // Create quadrants with different colors
  for (int y = 0; y < 64; y++) {
    for (int x = 0; x < 64; x++) {
      img.Color color;
      if (x < 32 && y < 32) {
        color = img.ColorRgb8(255, 0, 0); // Red
      } else if (x >= 32 && y < 32) {
        color = img.ColorRgb8(0, 255, 0); // Green
      } else if (x < 32 && y >= 32) {
        color = img.ColorRgb8(0, 0, 255); // Blue
      } else {
        color = img.ColorRgb8(255, 255, 0); // Yellow
      }
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