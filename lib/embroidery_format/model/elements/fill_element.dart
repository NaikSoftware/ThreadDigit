import 'dart:math';

import 'package:thread_digit/embroidery_format/emb_svg_constants.dart';
import 'package:thread_digit/embroidery_format/model/embroidery_element.dart';

/// A filled area stitched with parallel rows.
///
/// Stored as a `<polygon>` (or `<path>` when it has holes) filled with [color]
/// and `stroke="none"`. Photo embroidery is the same shape with [photoStitch]
/// set, so it carries an `emb:elementType="photo_stitch"` discriminator and can
/// gain photo-specific parameters later without a format change.
class FillElement extends EmbroideryElement {
  const FillElement({
    required this.boundary,
    required super.color,
    this.holes = const [],
    this.photoStitch = false,
    super.threadId,
    super.trimAfter,
    super.stopAfter,
    super.params,
    super.customParams,
  });

  /// Outer boundary ring in millimeters (implicitly closed).
  final List<Point<double>> boundary;

  /// Inner rings to subtract from the fill, each implicitly closed.
  final List<List<Point<double>>> holes;

  /// Whether this fill is a photo-embroidery region.
  final bool photoStitch;

  @override
  String get elementType => photoStitch ? EmbSvgConstants.typePhotoStitch : EmbSvgConstants.typeFill;

  /// Row angle in degrees.
  double get angleDeg => doubleParam(EmbSvgConstants.paramAngle, EmbSvgConstants.defaultFillAngle);

  /// Spacing between rows in millimeters.
  double get rowSpacingMm => doubleParam(EmbSvgConstants.paramRowSpacingMm, EmbSvgConstants.defaultRowSpacingMm);

  /// Maximum stitch length in millimeters.
  double get maxStitchLengthMm =>
      doubleParam(EmbSvgConstants.paramMaxStitchLengthMm, EmbSvgConstants.defaultMaxStitchLengthMm);

  /// Number of staggered rows before the pattern repeats.
  int get staggers => intParam(EmbSvgConstants.paramStaggers, EmbSvgConstants.defaultStaggers);

  @override
  List<Object?> get props => [
    boundary,
    holes,
    photoStitch,
    color,
    threadId,
    trimAfter,
    stopAfter,
    params,
    customParams,
  ];
}
