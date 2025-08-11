import 'dart:math' as math;

import 'package:equatable/equatable.dart';

/// Represents a direction field containing orientation and coherence data
/// from structure tensor analysis for embroidery stitch generation.
class DirectionField extends Equatable {
  /// Creates a direction field with the specified dimensions and data.
  ///
  /// [width] and [height] define the field dimensions.
  /// [orientations] contains angle values in radians for each pixel.
  /// [coherences] contains coherence strength values (0.0-1.0) for each pixel.
  const DirectionField({
    required this.width,
    required this.height,
    required this.orientations,
    required this.coherences,
  });

  /// Width of the direction field in pixels.
  final int width;

  /// Height of the direction field in pixels.
  final int height;

  /// Orientation angles in radians for each pixel.
  /// Length must equal width * height.
  final List<double> orientations;

  /// Coherence strength values (0.0-1.0) for each pixel.
  /// Length must equal width * height.
  /// Higher values indicate stronger directional consistency.
  final List<double> coherences;

  /// Total number of pixels in the direction field.
  int get pixelCount => width * height;

  /// Gets the orientation angle at the specified pixel coordinates.
  /// Returns the angle in radians, or 0.0 if coordinates are out of bounds.
  double getOrientation(int x, int y) {
    if (x < 0 || x >= width || y < 0 || y >= height) return 0.0;
    return orientations[y * width + x];
  }

  /// Gets the coherence strength at the specified pixel coordinates.
  /// Returns the coherence value (0.0-1.0), or 0.0 if coordinates are out of bounds.
  double getCoherence(int x, int y) {
    if (x < 0 || x >= width || y < 0 || y >= height) return 0.0;
    return coherences[y * width + x];
  }

  /// Gets the direction vector at the specified pixel coordinates.
  /// Returns a normalized Point representing the dominant direction.
  math.Point<double> getDirectionVector(int x, int y) {
    final angle = getOrientation(x, y);
    return math.Point(math.cos(angle), math.sin(angle));
  }

  /// Calculates the average coherence across the entire field.
  /// Higher values indicate more consistent directional patterns.
  double get averageCoherence {
    if (coherences.isEmpty) return 0.0;
    return coherences.reduce((a, b) => a + b) / coherences.length;
  }

  /// Validates the direction field data integrity.
  /// Returns true if orientations and coherences match expected dimensions.
  bool get isValid {
    return orientations.length == pixelCount &&
        coherences.length == pixelCount &&
        width > 0 &&
        height > 0 &&
        coherences.every((c) => c >= 0.0 && c <= 1.0);
  }

  /// Creates a copy of this direction field with updated values.
  DirectionField copyWith({
    int? width,
    int? height,
    List<double>? orientations,
    List<double>? coherences,
  }) {
    return DirectionField(
      width: width ?? this.width,
      height: height ?? this.height,
      orientations: orientations ?? this.orientations,
      coherences: coherences ?? this.coherences,
    );
  }

  @override
  List<Object?> get props => [width, height, orientations, coherences];
}
