import 'dart:ui';

import 'package:equatable/equatable.dart';
import 'package:image/image.dart' as img;
import 'package:thread_digit/algorithm/models/color_cluster.dart';
import 'package:thread_digit/algorithm/models/dithering_result.dart';
import 'package:thread_digit/colors/model/thread_color.dart';

/// Result model for complete color quantization operations.
///
/// Contains quantized image, thread mappings, and quality metrics for
/// embroidery pattern generation integration.
class QuantizationResult extends Equatable {
  const QuantizationResult({
    required this.quantizedImage,
    required this.originalImage,
    required this.colorMapping,
    required this.clusteringResult,
    required this.ditheringResult,
    required this.threadUsageStats,
    required this.qualityMetrics,
    required this.processingTimeMs,
  });

  /// Final quantized and dithered image
  final img.Image quantizedImage;

  /// Original input image for comparison
  final img.Image originalImage;

  /// Mapping from quantized colors to thread colors
  final Map<Color, ThreadColor> colorMapping;

  /// K-means clustering analysis results
  final ClusteringResult clusteringResult;

  /// Floyd-Steinberg dithering results
  final DitheringResult ditheringResult;

  /// Thread usage statistics and recommendations
  final ThreadUsageStatistics threadUsageStats;

  /// Quality assessment metrics
  final QuantizationQualityMetrics qualityMetrics;

  /// Total processing time in milliseconds
  final int processingTimeMs;

  /// List of thread colors used in final result
  List<ThreadColor> get usedThreads => colorMapping.values.toList();

  /// Number of thread colors used
  int get threadCount => colorMapping.length;

  /// Image dimensions
  int get width => quantizedImage.width;
  int get height => quantizedImage.height;
  int get pixelCount => width * height;

  /// Overall quality score (0-100)
  double get overallQuality => qualityMetrics.overallScore;

  /// Checks if quantization meets quality thresholds
  bool get meetsQualityStandards => overallQuality >= 70.0;

  /// Generates summary statistics
  QuantizationSummary get summary => QuantizationSummary(
        threadCount: threadCount,
        colorReductionRatio: ditheringResult.colorReductionRatio,
        processingTimeMs: processingTimeMs,
        qualityScore: overallQuality,
        ditheringEffectiveness: ditheringResult.statistics.effectiveness,
        threadCostEstimate: threadUsageStats.estimatedCost,
      );

  @override
  List<Object?> get props => [
        quantizedImage,
        colorMapping,
        clusteringResult,
        ditheringResult,
        processingTimeMs,
      ];

  @override
  String toString() => 'QuantizationResult('
      'threads: $threadCount, '
      'quality: ${overallQuality.toStringAsFixed(1)}, '
      'time: ${processingTimeMs}ms)';
}

/// Statistics about thread usage and costs
class ThreadUsageStatistics extends Equatable {
  const ThreadUsageStatistics({
    required this.threadColors,
    required this.pixelCounts,
    required this.coveragePercentages,
    required this.estimatedLengths,
    required this.estimatedCost,
    required this.recommendations,
  });

  /// List of thread colors in usage order
  final List<ThreadColor> threadColors;

  /// Pixel count for each thread color
  final List<int> pixelCounts;

  /// Coverage percentage for each thread
  final List<double> coveragePercentages;

  /// Estimated thread length needed (in meters)
  final List<double> estimatedLengths;

  /// Estimated total cost for all threads
  final double estimatedCost;

  /// Recommendations for thread selection optimization
  final List<String> recommendations;

  /// Most used thread color
  ThreadColor? get primaryThread => threadColors.isNotEmpty ? threadColors[0] : null;

  /// Total estimated thread length
  double get totalThreadLength => estimatedLengths.fold(0, (sum, length) => sum + length);

  /// Number of threads used
  int get threadCount => threadColors.length;

  @override
  List<Object?> get props => [
        threadColors,
        pixelCounts,
        coveragePercentages,
        estimatedLengths,
        estimatedCost,
      ];

  @override
  String toString() => 'ThreadUsage(threads: $threadCount, '
      'length: ${totalThreadLength.toStringAsFixed(1)}m, '
      'cost: \$${estimatedCost.toStringAsFixed(2)})';
}

/// Quality metrics for quantization assessment
class QuantizationQualityMetrics extends Equatable {
  const QuantizationQualityMetrics({
    required this.colorAccuracy,
    required this.ditheringQuality,
    required this.clusteringQuality,
    required this.threadMatchQuality,
    required this.overallScore,
    required this.visualSimilarity,
  });

  /// Color accuracy compared to original (0-100)
  final double colorAccuracy;

  /// Dithering quality assessment (0-100)
  final double ditheringQuality;

  /// K-means clustering quality (0-100)
  final double clusteringQuality;

  /// Thread color matching accuracy (0-100)
  final double threadMatchQuality;

  /// Overall quality score (0-100)
  final double overallScore;

  /// Visual similarity to original image (0-100)
  final double visualSimilarity;

  /// Quality assessment level
  QualityLevel get qualityLevel {
    if (overallScore >= 90) return QualityLevel.excellent;
    if (overallScore >= 80) return QualityLevel.good;
    if (overallScore >= 60) return QualityLevel.acceptable;
    return QualityLevel.poor;
  }

  /// Identifies areas needing improvement
  List<String> get improvementAreas {
    final areas = <String>[];

    if (colorAccuracy < 80) areas.add('Color accuracy needs improvement');
    if (ditheringQuality < 70) areas.add('Dithering quality could be enhanced');
    if (clusteringQuality < 75) areas.add('Color clustering needs refinement');
    if (threadMatchQuality < 80) areas.add('Thread color matching accuracy');
    if (visualSimilarity < 75) areas.add('Visual similarity to original');

    return areas;
  }

  @override
  List<Object?> get props => [
        colorAccuracy,
        ditheringQuality,
        clusteringQuality,
        threadMatchQuality,
        overallScore,
        visualSimilarity,
      ];

  @override
  String toString() => 'QualityMetrics('
      'overall: ${overallScore.toStringAsFixed(1)}, '
      'level: $qualityLevel, '
      'similarity: ${visualSimilarity.toStringAsFixed(1)}%)';
}

/// Summary of quantization operation
class QuantizationSummary extends Equatable {
  const QuantizationSummary({
    required this.threadCount,
    required this.colorReductionRatio,
    required this.processingTimeMs,
    required this.qualityScore,
    required this.ditheringEffectiveness,
    required this.threadCostEstimate,
  });

  /// Number of thread colors used
  final int threadCount;

  /// Color reduction ratio (0.0-1.0)
  final double colorReductionRatio;

  /// Processing time in milliseconds
  final int processingTimeMs;

  /// Overall quality score (0-100)
  final double qualityScore;

  /// Dithering effectiveness assessment
  final DitheringEffectiveness ditheringEffectiveness;

  /// Estimated thread cost
  final double threadCostEstimate;

  /// Color reduction percentage
  double get colorReductionPercentage => colorReductionRatio * 100;

  /// Processing time in seconds
  double get processingTimeSeconds => processingTimeMs / 1000.0;

  @override
  List<Object?> get props => [
        threadCount,
        colorReductionRatio,
        processingTimeMs,
        qualityScore,
        ditheringEffectiveness,
        threadCostEstimate,
      ];

  @override
  String toString() => 'QuantizationSummary('
      'threads: $threadCount, '
      'reduction: ${colorReductionPercentage.toStringAsFixed(1)}%, '
      'quality: ${qualityScore.toStringAsFixed(1)}, '
      'time: ${processingTimeSeconds.toStringAsFixed(1)}s)';
}

/// Quality level enumeration
enum QualityLevel {
  /// Excellent quality (90-100)
  excellent,

  /// Good quality (80-89)
  good,

  /// Acceptable quality (60-79)
  acceptable,

  /// Poor quality (<60)
  poor,
}

/// Color distance calculation algorithms for thread matching
enum ColorDistanceAlgorithm {
  /// Euclidean distance in RGB space (fast but less perceptual)
  euclidean,

  /// CIEDE2000 perceptual color difference (slow but highly accurate)
  ciede2000,

  /// LAB color space Euclidean distance (balanced speed/accuracy)
  labEuclidean,
}

/// Parameters for color quantization pipeline
class QuantizationParameters extends Equatable {
  const QuantizationParameters({
    this.colorLimit = 16,
    this.enableDithering = true,
    this.ditheringStrength = 0.8,
    this.colorDistanceAlgorithm = ColorDistanceAlgorithm.ciede2000,
    this.qualityThreshold = 70.0,
  });

  /// Maximum number of colors to quantize to
  final int colorLimit;

  /// Enable Floyd-Steinberg dithering
  final bool enableDithering;

  /// Dithering strength (0.0-1.0)
  final double ditheringStrength;

  /// Color distance algorithm for thread matching
  final ColorDistanceAlgorithm colorDistanceAlgorithm;

  /// Minimum quality threshold for acceptance
  final double qualityThreshold;

  /// Default parameters for embroidery quantization
  static const defaultParameters = QuantizationParameters();

  /// Validates parameters are within acceptable ranges
  bool get isValid {
    return colorLimit >= 2 &&
           colorLimit <= 64 &&
           ditheringStrength >= 0.0 &&
           ditheringStrength <= 1.0 &&
           qualityThreshold >= 0.0 &&
           qualityThreshold <= 100.0;
  }

  @override
  List<Object?> get props => [
        colorLimit,
        enableDithering,
        ditheringStrength,
        colorDistanceAlgorithm,
        qualityThreshold,
      ];

  @override
  String toString() => 'QuantizationParams('
      'colors: $colorLimit, '
      'dithering: $enableDithering($ditheringStrength), '
      'algorithm: $colorDistanceAlgorithm)';
}
