import 'dart:ui';
import 'dart:math' as math;

import 'package:equatable/equatable.dart';
import 'package:thread_digit/algorithm/utils/color_conversion_utils.dart';

/// Color cluster representation for K-means quantization algorithm.
///
/// Represents a cluster of similar colors with statistical information
/// for embroidery color quantization and thread mapping.
class ColorCluster extends Equatable {
  const ColorCluster({
    required this.center,
    required this.members,
    required this.memberCount,
    required this.variance,
  });

  /// Center of the cluster in LAB color space
  final LabColor center;

  /// List of member colors (pixels) belonging to this cluster
  final List<Color> members;

  /// Number of pixels assigned to this cluster
  final int memberCount;

  /// Statistical variance of the cluster (measure of spread)
  final double variance;

  /// Creates an empty cluster with given center
  ColorCluster.empty(this.center)
      : members = <Color>[],
        memberCount = 0,
        variance = 0.0;

  /// Creates a cluster with updated center and members
  ColorCluster copyWith({
    LabColor? center,
    List<Color>? members,
    int? memberCount,
    double? variance,
  }) {
    return ColorCluster(
      center: center ?? this.center,
      members: members ?? this.members,
      memberCount: memberCount ?? this.memberCount,
      variance: variance ?? this.variance,
    );
  }

  /// Calculates the RGB color representation of the cluster center
  Color get centerColor => ColorConversionUtils.labToRgb(center);

  /// Checks if the cluster has any members
  bool get isEmpty => memberCount == 0;

  /// Checks if the cluster is not empty
  bool get isNotEmpty => memberCount > 0;

  /// Calculates the relative weight of this cluster (0-1)
  double getWeight(int totalPixels) {
    if (totalPixels == 0) return 0.0;
    return memberCount / totalPixels;
  }

  /// Determines if this cluster is well-formed (low variance)
  bool get isWellFormed => variance < 100.0; // Threshold for good clustering

  /// Gets the dominant color statistics for this cluster
  ClusterStatistics get statistics => ClusterStatistics(
        memberCount: memberCount,
        variance: variance,
        centerColor: centerColor,
        weight: memberCount.toDouble(),
      );

  @override
  List<Object?> get props => [center, memberCount, variance];

  @override
  String toString() => 'ColorCluster(center: $center, members: $memberCount, variance: ${variance.toStringAsFixed(2)})';
}

/// Statistical information about a color cluster
class ClusterStatistics extends Equatable {
  const ClusterStatistics({
    required this.memberCount,
    required this.variance,
    required this.centerColor,
    required this.weight,
  });

  /// Number of pixels in this cluster
  final int memberCount;

  /// Statistical variance of the cluster
  final double variance;

  /// RGB color of the cluster center
  final Color centerColor;

  /// Relative weight of this cluster
  final double weight;

  /// Quality score of the cluster (0-100)
  double get qualityScore {
    // Lower variance and higher member count indicate better quality
    final varianceScore = (100.0 - variance).clamp(0, 100);
    final memberScore = math.min(100.0, memberCount / 10.0 * 100);
    return (varianceScore + memberScore) / 2;
  }

  @override
  List<Object?> get props => [memberCount, variance, centerColor, weight];

  @override
  String toString() => 'ClusterStats(members: $memberCount, variance: ${variance.toStringAsFixed(2)}, quality: ${qualityScore.toStringAsFixed(1)})';
}

/// Result of K-means clustering operation
class ClusteringResult extends Equatable {
  const ClusteringResult({
    required this.clusters,
    required this.iterations,
    required this.converged,
    required this.totalVariance,
    required this.processingTimeMs,
  });

  /// List of computed clusters
  final List<ColorCluster> clusters;

  /// Number of iterations performed
  final int iterations;

  /// Whether the algorithm converged
  final bool converged;

  /// Total variance across all clusters
  final double totalVariance;

  /// Processing time in milliseconds
  final int processingTimeMs;

  /// Number of clusters
  int get clusterCount => clusters.length;

  /// Total number of pixels processed
  int get totalPixels => clusters.fold(0, (sum, cluster) => sum + cluster.memberCount);

  /// Average cluster quality
  double get averageQuality => clusters.isEmpty
      ? 0.0
      : clusters.map((c) => c.statistics.qualityScore).reduce((a, b) => a + b) / clusters.length;

  /// Gets the dominant colors from clustering
  List<Color> get dominantColors => clusters.map((cluster) => cluster.centerColor).toList();

  /// Checks if the clustering result is valid
  bool get isValid => converged && clusters.isNotEmpty && totalVariance.isFinite;

  @override
  List<Object?> get props => [clusters, iterations, converged, totalVariance, processingTimeMs];

  @override
  String toString() => 'ClusteringResult(clusters: $clusterCount, iterations: $iterations, '
      'converged: $converged, variance: ${totalVariance.toStringAsFixed(2)}, '
      'time: ${processingTimeMs}ms, quality: ${averageQuality.toStringAsFixed(1)})';
}
