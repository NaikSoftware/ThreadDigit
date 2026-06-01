import 'package:equatable/equatable.dart';
import 'package:thread_digit/colors/model/thread_color.dart';

/// Base class for every embroidery element in an [EmbroideryDocument].
///
/// An element is one SVG shape with an embroidery meaning: a running-stitch
/// line, a sequence of manual stitches, a fill area, or a satin column. Each
/// element carries its display [color], an optional [threadId] referencing the
/// document palette, machine [trimAfter]/[stopAfter] flags, and two free-form
/// parameter maps.
///
/// [params] holds Ink/Stitch parameters by their bare name (without the
/// `inkstitch:` prefix), for example `running_stitch_length_mm` -> `2.5`.
/// [customParams] holds extra `emb:`-namespaced parameters. Both round-trip
/// untouched, so a parameter the model does not type still survives a
/// read/write cycle. Subclasses expose typed accessors over [params].
abstract class EmbroideryElement extends Equatable {
  const EmbroideryElement({
    required this.color,
    this.threadId,
    this.trimAfter = false,
    this.stopAfter = false,
    this.params = const {},
    this.customParams = const {},
  });

  /// Display color, written to the SVG `stroke` or `fill` of the shape.
  final ThreadColor color;

  /// Palette entry this element uses, or null when the element is standalone.
  final String? threadId;

  /// Whether the machine trims the thread after stitching this element.
  final bool trimAfter;

  /// Whether the machine stops after stitching this element.
  final bool stopAfter;

  /// Ink/Stitch parameters by bare name (no `inkstitch:` prefix).
  final Map<String, String> params;

  /// Extra `emb:`-namespaced parameters by bare name.
  final Map<String, String> customParams;

  /// The `emb:elementType` discriminator value for this element.
  String get elementType;

  /// Reads a typed double from [params], falling back to [fallback].
  double doubleParam(String name, double fallback) => double.tryParse(params[name] ?? '') ?? fallback;

  /// Reads a typed int from [params], falling back to [fallback].
  int intParam(String name, int fallback) => int.tryParse(params[name] ?? '') ?? fallback;
}
