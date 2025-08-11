import 'dart:math' as math;

import 'package:equatable/equatable.dart';
import 'package:thread_digit/colors/model/thread_color.dart';

class Stitch extends Equatable {
  const Stitch({
    required this.start,
    required this.end,
    required this.color,
  });

  final math.Point<double> start;
  final math.Point<double> end;
  final ThreadColor color;

  /// Calculated stitch length in millimeters
  double get length {
    final dx = end.x - start.x;
    final dy = end.y - start.y;
    return math.sqrt(dx * dx + dy * dy);
  }

  /// Stitch direction angle in radians
  double get angle => math.atan2(end.y - start.y, end.x - start.x);

  /// Validates stitch against parameters
  bool isValid(double minStitchLength, double maxStitchLength) {
    final stitchLength = length;
    return stitchLength >= minStitchLength && stitchLength <= maxStitchLength;
  }

  /// Creates a copy with optional parameter overrides
  Stitch copyWith({
    math.Point<double>? start,
    math.Point<double>? end,
    ThreadColor? color,
  }) {
    return Stitch(
      start: start ?? this.start,
      end: end ?? this.end,
      color: color ?? this.color,
    );
  }

  @override
  List<Object?> get props => [start, end, color];

  @override
  String toString() => 'Stitch(${start.x.toStringAsFixed(2)},${start.y.toStringAsFixed(2)} → '
      '${end.x.toStringAsFixed(2)},${end.y.toStringAsFixed(2)}, '
      'length: ${length.toStringAsFixed(2)}mm, angle: ${(angle * 180 / math.pi).toStringAsFixed(1)}°)';
}
