import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui';

import 'package:image/image.dart' as img;
import 'package:thread_digit/algorithm/models/color_cluster.dart';
import 'package:thread_digit/algorithm/models/dithering_result.dart';
import 'package:thread_digit/algorithm/models/processing_result.dart';
import 'package:thread_digit/algorithm/models/quantization_result.dart';
import 'package:thread_digit/algorithm/processors/floyd_steinberg_ditherer.dart';
import 'package:thread_digit/algorithm/processors/kmeans_color_quantizer.dart';
import 'package:thread_digit/algorithm/utils/color_spaces.dart';
import 'package:thread_digit/colors/model/thread_color.dart';
import 'package:thread_digit/colors/service/color_matcher.dart';

/// Progress callback function type
typedef QuantizationProgressCallback = void Function(double progress, String stage);

/// Cancellation token for long-running operations
class CancelToken {
  bool _cancelled = false;

  /// Cancels the operation
  void cancel() => _cancelled = true;

  /// Checks if the operation was cancelled
  bool get isCancelled => _cancelled;
}

/// Color quantization orchestration service for embroidery pattern generation.
///
/// Coordinates K-means clustering, Floyd-Steinberg dithering, and thread matching
/// to produce optimal color quantization for photorealistic embroidery.
class ColorQuantizer {
  /// Default quantization parameters
  static const defaultParameters = QuantizationParameters();

  /// Performs complete color quantization pipeline with thread mapping.
  /// Returns quantized image with thread color assignments and quality metrics.
  static Future<ProcessingResult<QuantizationResult>> quantizeImage(
    img.Image sourceImage,
    List<List<ThreadColor>> threadCatalogs, {
    QuantizationParameters params = defaultParameters,
    QuantizationProgressCallback? progressCallback,
    CancelToken? cancelToken,
  }) async {
    if (!params.isValid) {
      return const ProcessingResult.failure(
        error: 'Invalid quantization parameters',
      );
    }

    if (threadCatalogs.isEmpty) {
      return const ProcessingResult.failure(
        error: 'Thread catalogs cannot be empty',
      );
    }

    try {
      final stopwatch = Stopwatch()..start();

      _reportProgress(progressCallback, 0.0, 'Starting color quantization...');
      _checkCancellation(cancelToken);

      // Step 1: Validate input image
      final validationResult = _validateImage(sourceImage);
      if (validationResult.isFailure) {
        return ProcessingResult.failure(error: validationResult.error!);
      }

      _reportProgress(progressCallback, 0.1, 'Performing K-means clustering...');
      _checkCancellation(cancelToken);

      // Step 2: Perform K-means clustering
      final clusteringResult = KMeansColorQuantizer.quantize(
        sourceImage,
        params.colorLimit,
      );

      if (clusteringResult.isFailure) {
        return ProcessingResult.failure(
          error: 'K-means clustering failed: ${clusteringResult.error}',
        );
      }

      _reportProgress(progressCallback, 0.4, 'Mapping colors to thread catalog...');
      _checkCancellation(cancelToken);

      // Step 3: Map quantized colors to thread colors
      final colorMapping = await _mapColorsToThreads(
        clusteringResult.data!.dominantColors,
        threadCatalogs,
        params.colorDistanceAlgorithm,
      );

      _reportProgress(progressCallback, 0.6, 'Applying Floyd-Steinberg dithering...');
      _checkCancellation(cancelToken);

      // Step 4: Apply dithering if enabled
      DitheringResult ditheringResult;
      if (params.enableDithering) {
        final ditheringParams = DitheringParameters(
          strength: params.ditheringStrength,
        );

        final dithering = FloydSteinbergDitherer.dither(
          sourceImage,
          colorMapping.keys.toList(),
          params: ditheringParams,
        );

        if (dithering.isFailure) {
          return ProcessingResult.failure(
            error: 'Dithering failed: ${dithering.error}',
          );
        }

        ditheringResult = dithering.data!;
      } else {
        // Create mock dithering result for disabled dithering
        ditheringResult = DitheringResult(
          ditheredImage: img.Image.from(sourceImage),
          errorMap: Float32List(sourceImage.width * sourceImage.height),
          originalColorCount: clusteringResult.data!.dominantColors.length,
          quantizedColorCount: params.colorLimit,
          processingTimeMs: 0,
          ditheringStrength: 0.0,
        );
      }

      _reportProgress(progressCallback, 0.8, 'Calculating thread usage statistics...');
      _checkCancellation(cancelToken);

      // Step 5: Calculate thread usage statistics
      final threadUsageStats = _calculateThreadUsage(
        ditheringResult.ditheredImage,
        colorMapping,
      );

      _reportProgress(progressCallback, 0.9, 'Assessing quality metrics...');
      _checkCancellation(cancelToken);

      // Step 6: Calculate quality metrics
      final qualityMetrics = _calculateQualityMetrics(
        sourceImage,
        ditheringResult,
        clusteringResult.data!,
        colorMapping,
      );

      stopwatch.stop();

      final result = QuantizationResult(
        quantizedImage: ditheringResult.ditheredImage,
        originalImage: sourceImage,
        colorMapping: colorMapping,
        clusteringResult: clusteringResult.data!,
        ditheringResult: ditheringResult,
        threadUsageStats: threadUsageStats,
        qualityMetrics: qualityMetrics,
        processingTimeMs: stopwatch.elapsedMilliseconds,
      );

      _reportProgress(progressCallback, 1.0, 'Color quantization complete');

      return ProcessingResult.success(data: result);
    } catch (e) {
      return ProcessingResult.failure(
        error: 'Color quantization failed: $e',
      );
    }
  }

  /// Validates input image meets requirements
  static ProcessingResult<void> _validateImage(img.Image image) {
    if (image.width < 32 || image.height < 32) {
      return const ProcessingResult.failure(
        error: 'Image too small (minimum 32x32 pixels)',
      );
    }

    if (image.width > 4096 || image.height > 4096) {
      return const ProcessingResult.failure(
        error: 'Image too large (maximum 4096x4096 pixels)',
      );
    }

    return const ProcessingResult.success(data: null);
  }

  /// Maps quantized colors to thread colors using specified algorithm
  static Future<Map<Color, ThreadColor>> _mapColorsToThreads(
    List<Color> quantizedColors,
    List<List<ThreadColor>> threadCatalogs,
    ColorDistanceAlgorithm algorithm,
  ) async {
    final mapping = <Color, ThreadColor>{};

    for (final color in quantizedColors) {
      final threadColor = ColorMatcherUtil.findOptimalMatch(
        color,
        threadCatalogs,
        algorithm: algorithm,
      );

      if (threadColor != null) {
        mapping[color] = threadColor;
      } else {
        // Fallback to nearest color if no match found
        final fallback = ColorMatcherUtil.findNearestColor(
          (color.r * 255.0).round() & 0xff,
          (color.g * 255.0).round() & 0xff,
          (color.b * 255.0).round() & 0xff,
          threadCatalogs,
        );
        if (fallback != null) {
          mapping[color] = fallback;
        }
      }
    }

    return mapping;
  }

  /// Calculates thread usage statistics and cost estimates
  static ThreadUsageStatistics _calculateThreadUsage(
    img.Image quantizedImage,
    Map<Color, ThreadColor> colorMapping,
  ) {
    final colorCounts = <Color, int>{};

    // Count pixels for each color
    for (int y = 0; y < quantizedImage.height; y++) {
      for (int x = 0; x < quantizedImage.width; x++) {
        final pixel = quantizedImage.getPixel(x, y);
        final color = Color.fromARGB(255, pixel.r.toInt(), pixel.g.toInt(), pixel.b.toInt());
        colorCounts[color] = (colorCounts[color] ?? 0) + 1;
      }
    }

    // Sort by usage frequency
    final sortedEntries = colorCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final threadColors = <ThreadColor>[];
    final pixelCounts = <int>[];
    final coveragePercentages = <double>[];
    final estimatedLengths = <double>[];

    final totalPixels = quantizedImage.width * quantizedImage.height;

    for (final entry in sortedEntries) {
      final threadColor = colorMapping[entry.key];
      if (threadColor != null) {
        threadColors.add(threadColor);
        pixelCounts.add(entry.value);

        final coverage = (entry.value / totalPixels) * 100;
        coveragePercentages.add(coverage);

        // Estimate thread length based on pixel coverage
        // Rough approximation: 1000 pixels ≈ 1 meter of thread
        final estimatedLength = entry.value.toDouble() / 1000.0;
        estimatedLengths.add(estimatedLength);
      }
    }

    // Estimate total cost (rough approximation: $0.50 per meter)
    final totalLength = estimatedLengths.fold(0.0, (sum, length) => sum + length);
    final estimatedCost = totalLength * 0.50;

    // Generate recommendations
    final recommendations = _generateThreadRecommendations(
      threadColors,
      coveragePercentages,
      estimatedLengths,
    );

    return ThreadUsageStatistics(
      threadColors: threadColors,
      pixelCounts: pixelCounts,
      coveragePercentages: coveragePercentages,
      estimatedLengths: estimatedLengths,
      estimatedCost: estimatedCost,
      recommendations: recommendations,
    );
  }

  /// Generates thread selection recommendations
  static List<String> _generateThreadRecommendations(
    List<ThreadColor> threads,
    List<double> coverages,
    List<double> lengths,
  ) {
    final recommendations = <String>[];

    if (threads.isEmpty) return recommendations;

    // Check for dominant color
    if (coverages[0] > 50) {
      recommendations.add('Primary thread (${threads[0].name}) covers ${coverages[0].toStringAsFixed(1)}% of design');
    }

    // Check for thread efficiency
    final minorThreads = threads.where((thread) {
      final index = threads.indexOf(thread);
      return index < coverages.length && coverages[index] < 5.0;
    }).length;

    if (minorThreads > threads.length / 2) {
      recommendations.add('Consider consolidating $minorThreads minor thread colors');
    }

    // Check total thread usage
    final totalLength = lengths.fold(0.0, (sum, length) => sum + length);
    if (totalLength > 100) {
      recommendations.add('High thread usage (${totalLength.toStringAsFixed(1)}m) - consider reducing colors');
    }

    // Check catalog diversity
    final catalogs = threads.map((t) => t.catalog).toSet();
    if (catalogs.length > 3) {
      recommendations.add('Using threads from ${catalogs.length} catalogs - may affect availability');
    }

    return recommendations;
  }

  /// Calculates comprehensive quality metrics
  static QuantizationQualityMetrics _calculateQualityMetrics(
    img.Image original,
    DitheringResult ditheringResult,
    ClusteringResult clusteringResult,
    Map<Color, ThreadColor> colorMapping,
  ) {
    // Color accuracy based on clustering variance
    final clusteringQuality = math.max(0, 100 - clusteringResult.totalVariance);

    // Dithering quality from dithering result
    final ditheringQuality = ditheringResult.qualityScore;

    // Thread matching accuracy based on color distance
    double threadMatchQuality = 0;
    if (colorMapping.isNotEmpty) {
      double totalSimilarity = 0;
      for (final entry in colorMapping.entries) {
        final similarity = ColorSpaces.calculateSimilarityPercentage(
          entry.key,
          entry.value.toColor(),
        );
        totalSimilarity += similarity;
      }
      threadMatchQuality = totalSimilarity / colorMapping.length;
    }

    // Visual similarity (simplified SSIM approximation)
    final visualSimilarity = _calculateVisualSimilarity(original, ditheringResult.ditheredImage);

    // Color accuracy combines multiple factors
    final colorAccuracy = (clusteringQuality + threadMatchQuality) / 2;

    // Overall score is weighted average
    final overallScore = (
      colorAccuracy * 0.3 +
      ditheringQuality * 0.25 +
      clusteringQuality * 0.2 +
      threadMatchQuality * 0.15 +
      visualSimilarity * 0.1
    );

    return QuantizationQualityMetrics(
      colorAccuracy: colorAccuracy,
      ditheringQuality: ditheringQuality,
      clusteringQuality: clusteringQuality.toDouble(),
      threadMatchQuality: threadMatchQuality,
      overallScore: overallScore,
      visualSimilarity: visualSimilarity,
    );
  }

  /// Calculates visual similarity between original and quantized images
  static double _calculateVisualSimilarity(img.Image original, img.Image quantized) {
    if (original.width != quantized.width || original.height != quantized.height) {
      return 0.0; // Cannot compare different sizes
    }

    double totalSimilarity = 0;
    int pixelCount = 0;

    final sampleRate = math.max(1, (original.width * original.height / 1000).ceil());

    for (int y = 0; y < original.height; y += sampleRate) {
      for (int x = 0; x < original.width; x += sampleRate) {
        final origPixel = original.getPixel(x, y);
        final quantPixel = quantized.getPixel(x, y);

        final origColor = Color.fromARGB(255, origPixel.r.toInt(), origPixel.g.toInt(), origPixel.b.toInt());
        final quantColor = Color.fromARGB(255, quantPixel.r.toInt(), quantPixel.g.toInt(), quantPixel.b.toInt());

        final similarity = ColorSpaces.calculateSimilarityPercentage(origColor, quantColor);
        totalSimilarity += similarity;
        pixelCount++;
      }
    }

    return pixelCount > 0 ? totalSimilarity / pixelCount : 0.0;
  }

  /// Reports progress to callback if provided
  static void _reportProgress(QuantizationProgressCallback? callback, double progress, String stage) {
    callback?.call(progress, stage);
  }

  /// Checks for cancellation and throws if cancelled
  static void _checkCancellation(CancelToken? cancelToken) {
    if (cancelToken?.isCancelled == true) {
      throw Exception('Color quantization was cancelled');
    }
  }

  /// Estimates processing time based on image size and parameters
  static Duration estimateProcessingTime(
    img.Image image,
    QuantizationParameters params,
  ) {
    final pixelCount = image.width * image.height;
    final baseTime = (pixelCount / 10000).ceil(); // Base processing time in seconds

    // Adjust for parameters
    var adjustedTime = baseTime;
    if (params.enableDithering) adjustedTime = (adjustedTime * 1.5).ceil();
    if (params.colorDistanceAlgorithm == ColorDistanceAlgorithm.ciede2000) {
      adjustedTime = (adjustedTime * 1.2).ceil();
    }

    return Duration(seconds: adjustedTime);
  }

  /// Gets optimal parameters based on image characteristics
  static QuantizationParameters getOptimalParameters(img.Image image) {
    final pixelCount = image.width * image.height;

    // Adjust color limit based on image complexity
    int colorLimit;
    if (pixelCount < 100000) {
      colorLimit = 8; // Small images need fewer colors
    } else if (pixelCount < 500000) {
      colorLimit = 16; // Medium images use default
    } else {
      colorLimit = 24; // Large images can handle more colors
    }

    return QuantizationParameters(
      colorLimit: colorLimit,
      enableDithering: true,
      ditheringStrength: 0.8,
      colorDistanceAlgorithm: ColorDistanceAlgorithm.ciede2000,
      qualityThreshold: 70.0,
    );
  }
}

