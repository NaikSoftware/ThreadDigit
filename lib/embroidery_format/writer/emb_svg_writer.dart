import 'dart:io';
import 'dart:math';

import 'package:xml/xml.dart';
import 'package:thread_digit/colors/model/thread_color.dart';
import 'package:thread_digit/embroidery_format/emb_svg_constants.dart';
import 'package:thread_digit/embroidery_format/model/elements/fill_element.dart';
import 'package:thread_digit/embroidery_format/model/elements/manual_stitch_element.dart';
import 'package:thread_digit/embroidery_format/model/elements/running_stitch_element.dart';
import 'package:thread_digit/embroidery_format/model/elements/satin_column_element.dart';
import 'package:thread_digit/embroidery_format/model/embroidery_document.dart';
import 'package:thread_digit/embroidery_format/model/embroidery_element.dart';
import 'package:thread_digit/embroidery_format/model/embroidery_metadata.dart';

/// Serializes an [EmbroideryDocument] into the `.emb.svg` wire format.
///
/// The output is valid SVG (renderable by generic viewers) and readable by
/// Ink/Stitch: parameters Ink/Stitch understands live in its own namespace,
/// while thread-catalog data and the element-type discriminator live in the
/// [EmbSvgConstants.embNamespace] namespace. Each document element becomes one
/// SVG shape, emitted in document (stitching) order.
class EmbSvgWriter {
  const EmbSvgWriter();

  /// Serializes [document] to a pretty-printed `.emb.svg` string.
  String write(EmbroideryDocument document) {
    final builder = XmlBuilder();
    final width = document.dimensions.width;
    final height = document.dimensions.height;

    builder.declaration(encoding: 'UTF-8');
    builder.element(
      'svg',
      nest: () {
        builder.namespace(EmbSvgConstants.svgNamespace);
        builder.namespace(EmbSvgConstants.inkstitchNamespace, EmbSvgConstants.inkstitchPrefix);
        builder.namespace(EmbSvgConstants.embNamespace, EmbSvgConstants.embPrefix);
        builder.attribute('width', '${_num(width)}${EmbSvgConstants.unitMillimeters}');
        builder.attribute('height', '${_num(height)}${EmbSvgConstants.unitMillimeters}');
        builder.attribute('viewBox', '0 0 ${_num(width)} ${_num(height)}');
        _embAttribute(builder, EmbSvgConstants.attrVersion, EmbSvgConstants.formatVersion);
        _embAttribute(builder, EmbSvgConstants.attrUnits, EmbSvgConstants.unitMillimeters);

        _buildMetadata(builder, document);
        for (final element in document.elements) {
          _buildElement(builder, element);
        }
      },
    );

    return builder.buildDocument().toXmlString(pretty: true);
  }

  /// Writes [document] to [path] (should end with `.emb.svg`). Returns the file.
  Future<File> writeToFile(EmbroideryDocument document, String path) {
    final file = File(path);
    return file.writeAsString(write(document));
  }

  void _buildMetadata(XmlBuilder builder, EmbroideryDocument document) {
    final metadata = document.metadata;
    builder.element(
      'metadata',
      nest: () {
        builder.element(
          EmbSvgConstants.elDesign,
          namespace: EmbSvgConstants.embNamespace,
          nest: () {
            _optionalAttribute(builder, EmbSvgConstants.attrName, metadata.name);
            _optionalAttribute(builder, EmbSvgConstants.attrAuthor, metadata.author);
            _optionalAttribute(builder, EmbSvgConstants.attrNotes, metadata.notes);
            _optionalAttribute(builder, EmbSvgConstants.attrCreated, metadata.createdAt?.toIso8601String());
            builder.attribute(EmbSvgConstants.attrElementCount, '${document.elements.length}');
            builder.attribute(EmbSvgConstants.attrWidthMm, _num(document.dimensions.width));
            builder.attribute(EmbSvgConstants.attrHeightMm, _num(document.dimensions.height));

            _buildPalette(builder, metadata);
          },
        );
      },
    );
  }

  void _buildPalette(XmlBuilder builder, EmbroideryMetadata metadata) {
    builder.element(
      EmbSvgConstants.elPalette,
      namespace: EmbSvgConstants.embNamespace,
      nest: () {
        metadata.threads.forEach((id, color) {
          builder.element(
            EmbSvgConstants.elThread,
            namespace: EmbSvgConstants.embNamespace,
            nest: () {
              builder.attribute(EmbSvgConstants.attrThreadId, id);
              builder.attribute(EmbSvgConstants.attrCatalog, color.catalog);
              builder.attribute(EmbSvgConstants.attrCode, color.code);
              builder.attribute(EmbSvgConstants.attrName, color.name);
              builder.attribute(EmbSvgConstants.attrRgb, _rgb(color));
              builder.attribute(EmbSvgConstants.attrPercentage, color.percentage.toString());
            },
          );
        });
      },
    );
  }

  /// Dispatches to the per-type serializer based on the element's runtime type.
  void _buildElement(XmlBuilder builder, EmbroideryElement element) {
    switch (element) {
      case RunningStitchElement():
        _buildPolyline(builder, element, element.points, EmbSvgConstants.valRunningStitch);
      case ManualStitchElement():
        _buildPolyline(builder, element, element.points, EmbSvgConstants.valManualStitch);
      case FillElement():
        _buildFill(builder, element);
      case SatinColumnElement():
        _buildSatinColumn(builder, element);
      default:
        throw ArgumentError('Unsupported embroidery element: ${element.runtimeType}');
    }
  }

  /// Running-stitch and manual-stitch lines: an open `<polyline>` carrying the
  /// type-derived `inkstitch:stroke_method` marker and stroke presentation.
  void _buildPolyline(XmlBuilder builder, EmbroideryElement element, List<Point<double>> points, String strokeMethod) {
    builder.element(
      'polyline',
      nest: () {
        _commonAttributes(builder, element, skipParams: {EmbSvgConstants.paramStrokeMethod});
        _inkAttribute(builder, EmbSvgConstants.paramStrokeMethod, strokeMethod);
        builder.attribute('points', _points(points));
        _strokeStyle(builder, element.color);
      },
    );
  }

  /// Fill (and photo-stitch) areas: a `<polygon>` when solid, or a `<path>`
  /// with `fill-rule="evenodd"` when the element has holes.
  void _buildFill(XmlBuilder builder, FillElement element) {
    if (element.holes.isEmpty) {
      builder.element(
        'polygon',
        nest: () {
          _commonAttributes(builder, element);
          builder.attribute('points', _points(element.boundary));
          _fillStyle(builder, element.color);
        },
      );
    } else {
      builder.element(
        'path',
        nest: () {
          _commonAttributes(builder, element);
          builder.attribute('d', _pathD([element.boundary, ...element.holes], close: true));
          builder.attribute('fill-rule', 'evenodd');
          _fillStyle(builder, element.color);
        },
      );
    }
  }

  /// Satin column: a `<path>` of open subpaths (rail1, rail2, then rungs)
  /// carrying the type-derived `inkstitch:satin_column` marker.
  void _buildSatinColumn(XmlBuilder builder, SatinColumnElement element) {
    builder.element(
      'path',
      nest: () {
        _commonAttributes(builder, element, skipParams: {EmbSvgConstants.paramSatinColumn});
        _inkAttribute(builder, EmbSvgConstants.paramSatinColumn, EmbSvgConstants.valTrue);
        builder.attribute('d', _pathD([element.rail1, element.rail2, ...element.rungs], close: false));
        _strokeStyle(builder, element.color);
      },
    );
  }

  /// Writes attributes common to every element: the type discriminator, the
  /// optional thread reference, all [EmbroideryElement.params] (Ink/Stitch
  /// namespace) and [EmbroideryElement.customParams] (emb namespace), and the
  /// trim/stop machine flags. Keys in [skipParams] are omitted from the params
  /// loop because a structural marker for them is written by the caller.
  void _commonAttributes(XmlBuilder builder, EmbroideryElement element, {Set<String> skipParams = const {}}) {
    _embAttribute(builder, EmbSvgConstants.attrElementType, element.elementType);
    if (element.threadId != null) {
      _embAttribute(builder, EmbSvgConstants.attrElementThreadId, element.threadId!);
    }
    element.params.forEach((key, value) {
      if (!skipParams.contains(key)) {
        _inkAttribute(builder, key, value);
      }
    });
    element.customParams.forEach((key, value) {
      _embAttribute(builder, key, value);
    });
    if (element.trimAfter) {
      _inkAttribute(builder, EmbSvgConstants.paramTrimAfter, EmbSvgConstants.valTrue);
    }
    if (element.stopAfter) {
      _inkAttribute(builder, EmbSvgConstants.paramStopAfter, EmbSvgConstants.valTrue);
    }
  }

  /// Stroke presentation for line-like shapes. `fill="none"` keeps Ink/Stitch
  /// from treating the shape as a fill.
  void _strokeStyle(XmlBuilder builder, ThreadColor color) {
    builder.attribute('fill', EmbSvgConstants.none);
    builder.attribute('stroke', _rgb(color));
    builder.attribute('stroke-width', _num(EmbSvgConstants.defaultStrokeWidthMm));
    builder.attribute('stroke-linecap', EmbSvgConstants.strokeLineCap);
    builder.attribute('stroke-linejoin', EmbSvgConstants.strokeLineJoin);
  }

  /// Fill presentation for area shapes. `stroke="none"` keeps Ink/Stitch from
  /// adding a running stitch around the outline.
  void _fillStyle(XmlBuilder builder, ThreadColor color) {
    builder.attribute('stroke', EmbSvgConstants.none);
    builder.attribute('fill', _rgb(color));
  }

  /// Formats a point list as an SVG `points` chain: `"x,y x,y ..."`.
  String _points(List<Point<double>> points) {
    return points.map((p) => '${_num(p.x)},${_num(p.y)}').join(' ');
  }

  /// Formats subpaths as an SVG path `d`: each subpath is `M x,y L x,y ...`,
  /// suffixed with `Z` when [close] is true, and subpaths joined by spaces.
  String _pathD(List<List<Point<double>>> subpaths, {required bool close}) {
    final parts = <String>[];
    for (final subpath in subpaths) {
      if (subpath.isEmpty) continue;
      final buffer = StringBuffer('M ${_num(subpath.first.x)},${_num(subpath.first.y)}');
      for (var i = 1; i < subpath.length; i++) {
        buffer.write(' L ${_num(subpath[i].x)},${_num(subpath[i].y)}');
      }
      if (close) buffer.write(' Z');
      parts.add(buffer.toString());
    }
    return parts.join(' ');
  }

  /// Formats a color as an uppercase `#RRGGBB` string.
  String _rgb(ThreadColor color) {
    String hex(int value) => value.toRadixString(16).padLeft(2, '0').toUpperCase();
    return '#${hex(color.red)}${hex(color.green)}${hex(color.blue)}';
  }

  /// Formats a double so whole numbers omit the decimal part (`5.0` -> `5`)
  /// while fractional values keep Dart's shortest round-trippable form.
  String _num(double value) {
    if (value == value.truncateToDouble() && value.isFinite) {
      return value.toInt().toString();
    }
    return value.toString();
  }

  void _embAttribute(XmlBuilder builder, String name, String value) {
    builder.attribute(name, value, namespace: EmbSvgConstants.embNamespace);
  }

  void _inkAttribute(XmlBuilder builder, String name, String value) {
    builder.attribute(name, value, namespace: EmbSvgConstants.inkstitchNamespace);
  }

  void _optionalAttribute(XmlBuilder builder, String name, String? value) {
    if (value != null) {
      builder.attribute(name, value);
    }
  }
}
