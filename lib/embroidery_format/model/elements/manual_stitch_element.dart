import 'dart:math';

import 'package:thread_digit/algorithm/models/stitch.dart';
import 'package:thread_digit/algorithm/models/stitch_sequence.dart';
import 'package:thread_digit/embroidery_format/emb_svg_constants.dart';
import 'package:thread_digit/embroidery_format/model/embroidery_element.dart';

/// A sequence of explicit stitches: every vertex is a needle penetration.
///
/// Stored as an open `<polyline>` stroked with [color] and tagged with
/// Ink/Stitch's `stroke_method="manual_stitch"`, so Ink/Stitch treats the
/// vertices as exact stitches rather than re-digitizing the path. This is the
/// element produced from algorithm output.
class ManualStitchElement extends EmbroideryElement {
  const ManualStitchElement({
    required this.points,
    required super.color,
    super.threadId,
    super.trimAfter,
    super.stopAfter,
    super.params,
    super.customParams,
  });

  /// Builds a manual-stitch element from a continuous [StitchSequence].
  ///
  /// The point chain is the start of the first stitch followed by every stitch
  /// end (N+1 points for N stitches).
  factory ManualStitchElement.fromSequence(StitchSequence sequence, {bool trimAfter = true, bool stopAfter = false}) {
    final points = <Point<double>>[];
    if (sequence.stitches.isNotEmpty) {
      points.add(sequence.stitches.first.start);
      for (final stitch in sequence.stitches) {
        points.add(stitch.end);
      }
    }
    return ManualStitchElement(
      points: points,
      color: sequence.color,
      threadId: sequence.threadId,
      trimAfter: trimAfter,
      stopAfter: stopAfter,
    );
  }

  /// Exact needle points in millimeters.
  final List<Point<double>> points;

  @override
  String get elementType => EmbSvgConstants.typeManualStitch;

  /// Reconstructs a [StitchSequence] by pairing consecutive points.
  StitchSequence toSequence() {
    final stitches = <Stitch>[];
    for (var i = 0; i + 1 < points.length; i++) {
      stitches.add(Stitch(start: points[i], end: points[i + 1], color: color));
    }
    return StitchSequence(stitches: stitches, color: color, threadId: threadId ?? '');
  }

  @override
  List<Object?> get props => [points, color, threadId, trimAfter, stopAfter, params, customParams];
}
