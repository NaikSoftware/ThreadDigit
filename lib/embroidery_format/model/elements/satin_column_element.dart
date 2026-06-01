import 'dart:math';

import 'package:thread_digit/embroidery_format/emb_svg_constants.dart';
import 'package:thread_digit/embroidery_format/model/embroidery_element.dart';

/// A satin column: dense zig-zag stitches between two rails.
///
/// Stored as a `<path>` with two subpaths (the rails) stroked with [color] and
/// tagged with Ink/Stitch's `satin_column="true"`. Optional [rungs] mark where
/// the column direction is sampled.
class SatinColumnElement extends EmbroideryElement {
  const SatinColumnElement({
    required this.rail1,
    required this.rail2,
    required super.color,
    this.rungs = const [],
    super.threadId,
    super.trimAfter,
    super.stopAfter,
    super.params,
    super.customParams,
  });

  /// First rail in millimeters.
  final List<Point<double>> rail1;

  /// Second rail in millimeters.
  final List<Point<double>> rail2;

  /// Optional rungs (direction lines), each a list of points in millimeters.
  final List<List<Point<double>>> rungs;

  @override
  String get elementType => EmbSvgConstants.typeSatinColumn;

  /// Spacing between zig-zag points in millimeters.
  double get zigzagSpacingMm =>
      doubleParam(EmbSvgConstants.paramZigzagSpacingMm, EmbSvgConstants.defaultZigzagSpacingMm);

  /// Pull compensation added to each side in millimeters.
  double get pullCompensationMm =>
      doubleParam(EmbSvgConstants.paramPullCompensationMm, EmbSvgConstants.defaultPullCompensationMm);

  @override
  List<Object?> get props => [rail1, rail2, rungs, color, threadId, trimAfter, stopAfter, params, customParams];
}
