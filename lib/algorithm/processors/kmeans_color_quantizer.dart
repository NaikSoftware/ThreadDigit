/// K-means color quantization in LAB color space for optimal perceptual accuracy.
///
/// Implements K-means clustering with k-means++ initialization for
/// embroidery color palette generation from photographic input.
library;

import 'dart:math' as math;
import 'dart:ui';

import 'package:image/image.dart' as img;
import 'package:thread_digit/algorithm/models/color_cluster.dart';
import 'package:thread_digit/algorithm/models/processing_result.dart';
import 'package:thread_digit/algorithm/utils/color_conversion_utils.dart';

/// K-means clustering parameters for color quantization
class KMeansParameters {
  const KMeansParameters({
    this.maxIterations = 100,
    this.convergenceThreshold = 0.001,
    this.initializationMethod = ClusterInitialization.kMeansPlusPlus,
    this.minClusterSize = 5,
  });

  /// Maximum number of iterations before termination
  final int maxIterations;

  /// Convergence threshold for center movement
  final double convergenceThreshold;

  /// Method for initializing cluster centers
  final ClusterInitialization initializationMethod;

  /// Minimum number of pixels required per cluster
  final int minClusterSize;

  /// Validates parameters are within acceptable ranges
  bool get isValid {
    return maxIterations > 0 &&
           maxIterations <= 1000 &&
           convergenceThreshold > 0 &&
           convergenceThreshold < 1.0 &&
           minClusterSize >= 1;
  }
}

/// Methods for initializing K-means cluster centers
enum ClusterInitialization {
  /// Random initialization
  random,
  
  /// K-means++ initialization for better convergence
  kMeansPlusPlus,
}

/// K-means color quantization processor using LAB color space
class KMeansColorQuantizer {
  /// Default parameters optimized for embroidery
  static const defaultParameters = KMeansParameters();

  /// Quantizes image colors using K-means clustering in LAB color space.
  /// Returns dominant color palette with specified number of clusters.
  static ProcessingResult<ClusteringResult> quantize(
    img.Image image,
    int clusterCount, {
    KMeansParameters params = defaultParameters,
  }) {
    if (!params.isValid) {
      return const ProcessingResult.failure(
        error: 'Invalid K-means parameters',
      );
    }

    if (clusterCount < 1 || clusterCount > 64) {
      return const ProcessingResult.failure(
        error: 'Cluster count must be between 1 and 64',
      );
    }

    try {
      final stopwatch = Stopwatch()..start();

      // Step 1: Extract LAB colors from image
      final labColors = _extractLabColors(image);
      
      if (labColors.length < clusterCount) {
        return ProcessingResult.failure(
          error: 'Image has fewer unique colors (${labColors.length}) than requested clusters ($clusterCount)',
        );
      }

      // Step 2: Initialize cluster centers
      final initialCenters = _initializeCenters(
        labColors.map((e) => e.lab).toList(),
        clusterCount,
        params.initializationMethod,
      );

      // Step 3: Perform K-means clustering
      final result = _performKMeans(
        labColors,
        initialCenters,
        params,
      );

      stopwatch.stop();

      return ProcessingResult.success(
        data: ClusteringResult(
          clusters: result.clusters,
          iterations: result.iterations,
          converged: result.converged,
          totalVariance: result.totalVariance,
          processingTimeMs: stopwatch.elapsedMilliseconds,
        ),
      );
    } catch (e) {
      return ProcessingResult.failure(
        error: 'K-means quantization failed: $e',
      );
    }
  }

  /// Extracts LAB colors with their RGB counterparts from image
  static List<_LabColorPixel> _extractLabColors(img.Image image) {
    final colors = <_LabColorPixel>[];
    
    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final pixel = image.getPixel(x, y);
        final rgbColor = Color.fromARGB(255, pixel.r.toInt(), pixel.g.toInt(), pixel.b.toInt());
        final labColor = ColorConversionUtils.rgbToLab(pixel.r.toInt(), pixel.g.toInt(), pixel.b.toInt());
        
        colors.add(_LabColorPixel(rgbColor, labColor));
      }
    }
    
    return colors;
  }

  /// Initializes cluster centers using specified method
  static List<LabColor> _initializeCenters(
    List<LabColor> colors,
    int clusterCount,
    ClusterInitialization method,
  ) {
    switch (method) {
      case ClusterInitialization.random:
        return _randomInitialization(colors, clusterCount);
      case ClusterInitialization.kMeansPlusPlus:
        return _kMeansPlusPlusInitialization(colors, clusterCount);
    }
  }

  /// Random cluster center initialization
  static List<LabColor> _randomInitialization(List<LabColor> colors, int clusterCount) {
    final random = math.Random();
    final centers = <LabColor>[];
    final usedIndices = <int>{};

    while (centers.length < clusterCount && usedIndices.length < colors.length) {
      final index = random.nextInt(colors.length);
      if (!usedIndices.contains(index)) {
        centers.add(colors[index]);
        usedIndices.add(index);
      }
    }

    return centers;
  }

  /// K-means++ initialization for better convergence
  static List<LabColor> _kMeansPlusPlusInitialization(List<LabColor> colors, int clusterCount) {
    final random = math.Random();
    final centers = <LabColor>[];

    // Choose first center randomly
    centers.add(colors[random.nextInt(colors.length)]);

    // Choose remaining centers with probability proportional to squared distance
    for (int i = 1; i < clusterCount; i++) {
      final distances = <double>[];
      double totalDistance = 0;

      // Calculate minimum distance to existing centers for each point
      for (final color in colors) {
        double minDistance = double.infinity;
        for (final center in centers) {
          final distance = ColorConversionUtils.labDistance(color, center);
          minDistance = math.min(minDistance, distance);
        }
        final squaredDistance = minDistance * minDistance;
        distances.add(squaredDistance);
        totalDistance += squaredDistance;
      }

      // Choose next center with probability proportional to squared distance
      if (totalDistance > 0) {
        final threshold = random.nextDouble() * totalDistance;
        double cumulativeDistance = 0;

        for (int j = 0; j < colors.length; j++) {
          cumulativeDistance += distances[j];
          if (cumulativeDistance >= threshold) {
            centers.add(colors[j]);
            break;
          }
        }
      } else {
        // Fallback to random if all distances are zero
        centers.add(colors[random.nextInt(colors.length)]);
      }
    }

    return centers;
  }

  /// Performs K-means clustering algorithm
  static ClusteringResult _performKMeans(
    List<_LabColorPixel> pixels,
    List<LabColor> initialCenters,
    KMeansParameters params,
  ) {
    var centers = List<LabColor>.from(initialCenters);
    var assignments = List.filled(pixels.length, 0);
    var converged = false;
    var iterations = 0;

    for (iterations = 0; iterations < params.maxIterations && !converged; iterations++) {
      // Step 1: Assign pixels to nearest centers
      for (int i = 0; i < pixels.length; i++) {
        double minDistance = double.infinity;
        int bestCluster = 0;

        for (int j = 0; j < centers.length; j++) {
          final distance = ColorConversionUtils.labDistance(pixels[i].lab, centers[j]);
          if (distance < minDistance) {
            minDistance = distance;
            bestCluster = j;
          }
        }

        assignments[i] = bestCluster;
      }

      // Step 2: Update cluster centers
      final newCenters = <LabColor>[];
      var maxCenterMovement = 0.0;

      for (int j = 0; j < centers.length; j++) {
        final clusterPixels = <LabColor>[];
        
        for (int i = 0; i < pixels.length; i++) {
          if (assignments[i] == j) {
            clusterPixels.add(pixels[i].lab);
          }
        }

        if (clusterPixels.isNotEmpty) {
          final newCenter = _calculateCentroid(clusterPixels);
          final movement = ColorConversionUtils.labDistance(centers[j], newCenter);
          maxCenterMovement = math.max(maxCenterMovement, movement);
          newCenters.add(newCenter);
        } else {
          // Keep empty cluster center unchanged
          newCenters.add(centers[j]);
        }
      }

      // Check for convergence
      converged = maxCenterMovement < params.convergenceThreshold;
      centers = newCenters;
    }

    // Build final clusters
    final clusters = _buildClusters(pixels, centers, assignments);
    final totalVariance = _calculateTotalVariance(clusters);

    return ClusteringResult(
      clusters: clusters,
      iterations: iterations,
      converged: converged,
      totalVariance: totalVariance,
      processingTimeMs: 0, // Will be set by caller
    );
  }

  /// Calculates centroid of LAB colors
  static LabColor _calculateCentroid(List<LabColor> colors) {
    if (colors.isEmpty) {
      return const LabColor(50, 0, 0); // Neutral gray
    }

    double lSum = 0, aSum = 0, bSum = 0;
    for (final color in colors) {
      lSum += color.l;
      aSum += color.a;
      bSum += color.b;
    }

    final count = colors.length;
    return LabColor(lSum / count, aSum / count, bSum / count);
  }

  /// Builds final cluster objects with statistics
  static List<ColorCluster> _buildClusters(
    List<_LabColorPixel> pixels,
    List<LabColor> centers,
    List<int> assignments,
  ) {
    final clusters = <ColorCluster>[];

    for (int i = 0; i < centers.length; i++) {
      final members = <Color>[];
      final labMembers = <LabColor>[];

      for (int j = 0; j < pixels.length; j++) {
        if (assignments[j] == i) {
          members.add(pixels[j].rgb);
          labMembers.add(pixels[j].lab);
        }
      }

      final variance = _calculateClusterVariance(centers[i], labMembers);
      
      clusters.add(ColorCluster(
        center: centers[i],
        members: members,
        memberCount: members.length,
        variance: variance,
      ));
    }

    return clusters;
  }

  /// Calculates variance within a cluster
  static double _calculateClusterVariance(LabColor center, List<LabColor> members) {
    if (members.isEmpty) return 0.0;

    double sumSquaredDistances = 0;
    for (final member in members) {
      final distance = ColorConversionUtils.labDistance(center, member);
      sumSquaredDistances += distance * distance;
    }

    return sumSquaredDistances / members.length;
  }

  /// Calculates total variance across all clusters
  static double _calculateTotalVariance(List<ColorCluster> clusters) {
    double totalVariance = 0;
    int totalMembers = 0;

    for (final cluster in clusters) {
      totalVariance += cluster.variance * cluster.memberCount;
      totalMembers += cluster.memberCount;
    }

    return totalMembers > 0 ? totalVariance / totalMembers : 0.0;
  }

  /// Estimates optimal number of clusters for given image
  static int estimateOptimalClusters(img.Image image, {int maxClusters = 16}) {
    // Use elbow method approximation based on image characteristics
    final uniqueColors = _countUniqueColors(image);
    
    // Heuristic: optimal clusters is roughly square root of unique colors, clamped
    final estimated = math.sqrt(uniqueColors).round();
    return estimated.clamp(2, maxClusters);
  }

  /// Counts approximate unique colors in image (sampled)
  static int _countUniqueColors(img.Image image) {
    final colorSet = <int>{};
    final sampleRate = math.max(1, (image.width * image.height / 10000).ceil());
    
    for (int y = 0; y < image.height; y += sampleRate) {
      for (int x = 0; x < image.width; x += sampleRate) {
        final pixel = image.getPixel(x, y);
        final colorValue = (pixel.r.toInt() << 16) | (pixel.g.toInt() << 8) | pixel.b.toInt();
        colorSet.add(colorValue);
      }
    }
    
    return colorSet.length;
  }
}

/// Helper class to associate RGB and LAB representations
class _LabColorPixel {
  const _LabColorPixel(this.rgb, this.lab);

  final Color rgb;
  final LabColor lab;
}