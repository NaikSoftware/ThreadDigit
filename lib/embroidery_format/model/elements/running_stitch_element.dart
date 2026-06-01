import 'dart:math';

import 'package:thread_digit/embroidery_format/emb_svg_constants.dart';
import 'package:thread_digit/embroidery_format/model/embroidery_element.dart';

/// A running-stitch line: stitches follow a path at a fixed spacing.
///
/// Stored as an open `<polyline>` stroked with [color]. The vertices describe
/// the path geometry, not individual needle points; a converter lays stitches
/// along it using [stitchLengthMm].
class RunningStitchElement extends EmbroideryElement {
  const RunningStitchElement({
    required this.points,
    required super.color,
    super.threadId,
    super.trimAfter,
    super.stopAfter,
    super.params,
    super.customParams,
  });

  /// Path vertices in millimeters.
  final List<Point<double>> points;

  @override
  String get elementType => EmbSvgConstants.typeLine;

  /// Stitch spacing along the path in millimeters.
  double get stitchLengthMm =>
      doubleParam(EmbSvgConstants.paramRunningStitchLengthMm, EmbSvgConstants.defaultRunningStitchLengthMm);

  /// Number of times the path is repeated.
  int get repeats => intParam(EmbSvgConstants.paramRepeats, EmbSvgConstants.defaultRepeats);

  @override
  List<Object?> get props => [points, color, threadId, trimAfter, stopAfter, params, customParams];
}
