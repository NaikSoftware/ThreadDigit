import 'package:equatable/equatable.dart';
import 'package:thread_digit/algorithm/models/stitch.dart';
import 'package:thread_digit/colors/model/thread_color.dart';

class StitchSequence extends Equatable {
  const StitchSequence({
    required this.stitches,
    required this.color,
    required this.threadId,
  });

  final List<Stitch> stitches;
  final ThreadColor color;
  final String threadId;

  /// Validates sequence continuity - each stitch end must equal next stitch start
  bool get isValid {
    if (stitches.isEmpty) return true;

    for (int i = 0; i < stitches.length - 1; i++) {
      if (stitches[i].end != stitches[i + 1].start) {
        return false;
      }
    }
    return true;
  }

  /// Total sequence length in millimeters
  double get totalLength {
    if (stitches.isEmpty) return 0.0;
    return stitches.fold(0.0, (sum, stitch) => sum + stitch.length);
  }

  /// Number of stitches in the sequence
  int get stitchCount => stitches.length;

  /// Creates a copy with optional parameter overrides
  StitchSequence copyWith({
    List<Stitch>? stitches,
    ThreadColor? color,
    String? threadId,
  }) {
    return StitchSequence(
      stitches: stitches ?? this.stitches,
      color: color ?? this.color,
      threadId: threadId ?? this.threadId,
    );
  }

  @override
  List<Object?> get props => [stitches, color, threadId];

  @override
  String toString() => 'StitchSequence(threadId: $threadId, color: ${color.catalog}-${color.code}, '
      'stitches: $stitchCount, totalLength: ${totalLength.toStringAsFixed(2)}mm, '
      'valid: $isValid)';
}
