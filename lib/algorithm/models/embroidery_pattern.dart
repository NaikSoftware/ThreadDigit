import 'dart:ui';

import 'package:equatable/equatable.dart';
import 'package:thread_digit/algorithm/models/stitch_sequence.dart';
import 'package:thread_digit/colors/model/thread_color.dart';

class EmbroideryPattern extends Equatable {
  const EmbroideryPattern({
    required this.sequences,
    required this.dimensions,
    required this.threads,
  });

  final List<StitchSequence> sequences;
  final Size dimensions;
  final Map<String, ThreadColor> threads;

  /// Total stitch count across all sequences
  int get totalStitches {
    return sequences.fold(0, (sum, seq) => sum + seq.stitchCount);
  }

  /// Number of thread changes required (number of unique colors - 1)
  int get threadChanges {
    if (threads.isEmpty) return 0;
    return threads.length - 1;
  }

  /// Total thread length used in millimeters
  double get totalThreadLength {
    return sequences.fold(0.0, (sum, seq) => sum + seq.totalLength);
  }

  /// Number of sequences in the pattern
  int get sequenceCount => sequences.length;

  /// Creates a copy with optional parameter overrides
  EmbroideryPattern copyWith({
    List<StitchSequence>? sequences,
    Size? dimensions,
    Map<String, ThreadColor>? threads,
  }) {
    return EmbroideryPattern(
      sequences: sequences ?? this.sequences,
      dimensions: dimensions ?? this.dimensions,
      threads: threads ?? this.threads,
    );
  }

  @override
  List<Object?> get props => [sequences, dimensions, threads];

  @override
  String toString() => 'EmbroideryPattern('
      'dimensions: ${dimensions.width.toStringAsFixed(1)}x${dimensions.height.toStringAsFixed(1)}mm, '
      'stitches: $totalStitches, '
      'sequences: $sequenceCount, '
      'threads: ${threads.length}, '
      'changes: $threadChanges, '
      'totalLength: ${totalThreadLength.toStringAsFixed(2)}mm)';
}
