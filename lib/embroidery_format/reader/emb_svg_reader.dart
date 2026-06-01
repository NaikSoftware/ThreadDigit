import 'dart:io';
import 'dart:math';
import 'dart:ui';

import 'package:thread_digit/colors/model/thread_color.dart';
import 'package:thread_digit/embroidery_format/emb_svg_constants.dart';
import 'package:thread_digit/embroidery_format/model/elements/fill_element.dart';
import 'package:thread_digit/embroidery_format/model/elements/manual_stitch_element.dart';
import 'package:thread_digit/embroidery_format/model/elements/running_stitch_element.dart';
import 'package:thread_digit/embroidery_format/model/elements/satin_column_element.dart';
import 'package:thread_digit/embroidery_format/model/embroidery_document.dart';
import 'package:thread_digit/embroidery_format/model/embroidery_element.dart';
import 'package:thread_digit/embroidery_format/model/embroidery_metadata.dart';
import 'package:xml/xml.dart';

/// Parses the element-based `.emb.svg` format into an [EmbroideryDocument].
///
/// The document is an ordered list of embroidery elements (lines, manual
/// stitches, fills, satin columns) plus design dimensions and metadata. The
/// reader trusts the `emb:elementType` discriminator when present and falls
/// back to Ink/Stitch-style detection for externally authored files. All
/// elements and attributes are matched by local name so a different namespace
/// prefix still parses.
class EmbSvgReader {
  const EmbSvgReader();

  /// Parses a `.emb.svg` string into an [EmbroideryDocument].
  ///
  /// Throws [FormatException] if the document is not valid XML or is missing
  /// the root `<svg>` element.
  EmbroideryDocument read(String svg) {
    final XmlDocument document;
    try {
      document = XmlDocument.parse(svg);
    } on XmlException catch (e) {
      throw FormatException('Invalid .emb.svg: not well-formed XML ($e)');
    }

    final root = document.rootElement;
    if (root.localName != 'svg') {
      throw const FormatException('Invalid .emb.svg: missing root <svg> element');
    }

    final design = _firstByLocalName(root, EmbSvgConstants.elDesign);
    final palette = _parsePalette(design);
    final metadata = _parseMetadata(design, palette);
    final dimensions = _parseDimensions(root, design);
    final elements = _parseElements(root, palette.threadsById);

    return EmbroideryDocument(dimensions: dimensions, elements: elements, metadata: metadata);
  }

  /// Reads and parses the `.emb.svg` file at [path].
  Future<EmbroideryDocument> readFile(String path) async {
    final contents = await File(path).readAsString();
    return read(contents);
  }

  // --- Dimensions ---------------------------------------------------------

  /// Reads the `viewBox` ("0 0 W H") into a [Size]. Falls back to the
  /// `widthMm`/`heightMm` attributes on `<emb:design>` (stripping any `mm`).
  Size _parseDimensions(XmlElement root, XmlElement? design) {
    final viewBox = root.getAttribute('viewBox');
    if (viewBox != null && viewBox.trim().isNotEmpty) {
      final parts = viewBox.trim().split(RegExp(r'\s+'));
      if (parts.length == 4) {
        return Size(double.parse(parts[2]), double.parse(parts[3]));
      }
    }
    final width = _localAttr(design, EmbSvgConstants.attrWidthMm);
    final height = _localAttr(design, EmbSvgConstants.attrHeightMm);
    return Size(_parseMm(width), _parseMm(height));
  }

  // --- Metadata & palette -------------------------------------------------

  /// Builds the thread palette keyed by id, plus a needle-per-id map.
  _Palette _parsePalette(XmlElement? design) {
    final threadsById = <String, ThreadColor>{};
    final needleByThreadId = <String, int>{};
    if (design == null) {
      return _Palette(threadsById, needleByThreadId);
    }

    final paletteEl = _firstByLocalName(design, EmbSvgConstants.elPalette);
    if (paletteEl == null) {
      return _Palette(threadsById, needleByThreadId);
    }

    for (final thread in paletteEl.findElements(EmbSvgConstants.elThread, namespace: '*')) {
      final id = _localAttr(thread, EmbSvgConstants.attrThreadId);
      if (id == null) {
        continue;
      }
      final rgb = _localAttr(thread, EmbSvgConstants.attrRgb) ?? '#000000';
      final percentage = double.tryParse(_localAttr(thread, EmbSvgConstants.attrPercentage) ?? '') ?? 100.0;
      threadsById[id] = ThreadColor(
        name: _localAttr(thread, EmbSvgConstants.attrName) ?? '',
        code: _localAttr(thread, EmbSvgConstants.attrCode) ?? '',
        red: _hexComponent(rgb, 0),
        green: _hexComponent(rgb, 1),
        blue: _hexComponent(rgb, 2),
        catalog: _localAttr(thread, EmbSvgConstants.attrCatalog) ?? '',
        percentage: percentage,
      );

      final needle = int.tryParse(_localAttr(thread, EmbSvgConstants.attrNeedle) ?? '');
      if (needle != null) {
        needleByThreadId[id] = needle;
      }
    }
    return _Palette(threadsById, needleByThreadId);
  }

  EmbroideryMetadata _parseMetadata(XmlElement? design, _Palette palette) {
    if (design == null) {
      return EmbroideryMetadata(threads: palette.threadsById, needleByThreadId: palette.needleByThreadId);
    }
    final machine = _firstByLocalName(design, EmbSvgConstants.elMachine);
    final created = _localAttr(design, EmbSvgConstants.attrCreated);
    return EmbroideryMetadata(
      name: _localAttr(design, EmbSvgConstants.attrName),
      author: _localAttr(design, EmbSvgConstants.attrAuthor),
      notes: _localAttr(design, EmbSvgConstants.attrNotes),
      machineName: machine == null ? null : _localAttr(machine, EmbSvgConstants.attrMachineName),
      createdAt: created == null ? null : DateTime.tryParse(created),
      threads: palette.threadsById,
      needleByThreadId: palette.needleByThreadId,
    );
  }

  // --- Elements -----------------------------------------------------------

  /// Iterates the DIRECT children of `<svg>` in document order and builds an
  /// element for each `polyline`/`polygon`/`path`. Using direct children (not
  /// `findAllElements`) preserves stitching order and avoids descending into
  /// the `<metadata>` block.
  List<EmbroideryElement> _parseElements(XmlElement root, Map<String, ThreadColor> threadsById) {
    final elements = <EmbroideryElement>[];
    for (final child in root.childElements) {
      final shape = child.localName;
      if (shape != 'polyline' && shape != 'polygon' && shape != 'path') {
        continue;
      }
      final element = _buildElement(child, shape, threadsById);
      if (element != null) {
        elements.add(element);
      }
    }
    return elements;
  }

  EmbroideryElement? _buildElement(XmlElement el, String shape, Map<String, ThreadColor> threadsById) {
    final type = _resolveType(el, shape);
    final threadId = _embAttr(el, EmbSvgConstants.attrElementThreadId);
    final trimAfter = _inkAttr(el, EmbSvgConstants.paramTrimAfter) == EmbSvgConstants.valTrue;
    final stopAfter = _inkAttr(el, EmbSvgConstants.paramStopAfter) == EmbSvgConstants.valTrue;
    final customParams = _collectCustomParams(el);

    switch (type) {
      case EmbSvgConstants.typeLine:
        return RunningStitchElement(
          points: _parsePoints(el.getAttribute('points')),
          color: _resolveColor(el, threadId, threadsById, isFill: false),
          threadId: threadId,
          trimAfter: trimAfter,
          stopAfter: stopAfter,
          params: _collectParams(el, {EmbSvgConstants.paramStrokeMethod}),
          customParams: customParams,
        );
      case EmbSvgConstants.typeManualStitch:
        return ManualStitchElement(
          points: _parsePoints(el.getAttribute('points')),
          color: _resolveColor(el, threadId, threadsById, isFill: false),
          threadId: threadId,
          trimAfter: trimAfter,
          stopAfter: stopAfter,
          params: _collectParams(el, {EmbSvgConstants.paramStrokeMethod}),
          customParams: customParams,
        );
      case EmbSvgConstants.typeFill:
      case EmbSvgConstants.typePhotoStitch:
        final boundary = <Point<double>>[];
        final holes = <List<Point<double>>>[];
        if (shape == 'polygon') {
          boundary.addAll(_parsePoints(el.getAttribute('points')));
        } else {
          final subpaths = _parsePathD(el.getAttribute('d') ?? '');
          if (subpaths.isNotEmpty) {
            boundary.addAll(subpaths.first);
            holes.addAll(subpaths.skip(1));
          }
        }
        return FillElement(
          boundary: boundary,
          holes: holes,
          photoStitch: type == EmbSvgConstants.typePhotoStitch,
          color: _resolveColor(el, threadId, threadsById, isFill: true),
          threadId: threadId,
          trimAfter: trimAfter,
          stopAfter: stopAfter,
          params: _collectParams(el, const {}),
          customParams: customParams,
        );
      case EmbSvgConstants.typeSatinColumn:
        final subpaths = _parsePathD(el.getAttribute('d') ?? '');
        return SatinColumnElement(
          rail1: subpaths.isNotEmpty ? subpaths[0] : const [],
          rail2: subpaths.length > 1 ? subpaths[1] : const [],
          rungs: subpaths.length > 2 ? subpaths.sublist(2) : const [],
          color: _resolveColor(el, threadId, threadsById, isFill: false),
          threadId: threadId,
          trimAfter: trimAfter,
          stopAfter: stopAfter,
          params: _collectParams(el, {EmbSvgConstants.paramSatinColumn}),
          customParams: customParams,
        );
      default:
        return null;
    }
  }

  /// Resolves the element type. Trusts `emb:elementType` when present; otherwise
  /// applies best-effort Ink/Stitch-style detection from shape and attributes.
  String _resolveType(XmlElement el, String shape) {
    final declared = _embAttr(el, EmbSvgConstants.attrElementType);
    if (declared != null && declared.isNotEmpty) {
      return declared;
    }
    if (_inkAttr(el, EmbSvgConstants.paramSatinColumn) == EmbSvgConstants.valTrue) {
      return EmbSvgConstants.typeSatinColumn;
    }
    final fill = el.getAttribute('fill');
    final hasFill = shape == 'polygon' || (fill != null && fill != EmbSvgConstants.none && fill.isNotEmpty);
    if (hasFill) {
      return EmbSvgConstants.typeFill;
    }
    if (_inkAttr(el, EmbSvgConstants.paramStrokeMethod) == EmbSvgConstants.valManualStitch) {
      return EmbSvgConstants.typeManualStitch;
    }
    final stroke = el.getAttribute('stroke');
    if (stroke != null && stroke != EmbSvgConstants.none && stroke.isNotEmpty) {
      return EmbSvgConstants.typeLine;
    }
    return EmbSvgConstants.typeLine;
  }

  /// Picks the element color. A palette [threadId] is authoritative (full
  /// catalog data). Otherwise parses the SVG `fill`/`stroke` hex into a bare
  /// [ThreadColor]; falls back to a gray empty color when no color is present.
  ThreadColor _resolveColor(
    XmlElement el,
    String? threadId,
    Map<String, ThreadColor> threadsById, {
    required bool isFill,
  }) {
    if (threadId != null && threadsById.containsKey(threadId)) {
      return threadsById[threadId]!;
    }
    final raw = el.getAttribute(isFill ? 'fill' : 'stroke');
    if (raw == null || raw == EmbSvgConstants.none || !raw.startsWith('#')) {
      return const ThreadColor.empty(code: '');
    }
    return ThreadColor(
      name: '',
      code: '',
      red: _hexComponent(raw, 0),
      green: _hexComponent(raw, 1),
      blue: _hexComponent(raw, 2),
      catalog: '',
    );
  }

  // --- Attribute collection ----------------------------------------------
  //
  // Attributes are separated by namespace using the bound namespace URI of each
  // attribute (resolved via the writer's `inkstitch:`/`emb:` prefix bindings),
  // with a prefix-name fallback for unbound documents. Ink/Stitch parameters go
  // to `params`; `emb:` parameters go to `customParams`.

  /// Collects Ink/Stitch parameters by bare local name, excluding the structural
  /// keys in [structural] and the machine flags `trim_after`/`stop_after`.
  Map<String, String> _collectParams(XmlElement el, Set<String> structural) {
    final params = <String, String>{};
    for (final attr in el.attributes) {
      if (!_isInkstitch(attr)) {
        continue;
      }
      final name = attr.name.local;
      if (structural.contains(name) ||
          name == EmbSvgConstants.paramTrimAfter ||
          name == EmbSvgConstants.paramStopAfter) {
        continue;
      }
      params[name] = attr.value;
    }
    return params;
  }

  /// Collects `emb:` parameters by bare local name, excluding the structural
  /// `elementType` and `threadId` discriminators.
  Map<String, String> _collectCustomParams(XmlElement el) {
    final params = <String, String>{};
    for (final attr in el.attributes) {
      if (!_isEmb(attr)) {
        continue;
      }
      final name = attr.name.local;
      if (name == EmbSvgConstants.attrElementType || name == EmbSvgConstants.attrElementThreadId) {
        continue;
      }
      params[name] = attr.value;
    }
    return params;
  }

  bool _isInkstitch(XmlAttribute attr) =>
      attr.name.namespaceUri == EmbSvgConstants.inkstitchNamespace ||
      (attr.name.namespaceUri == null && attr.name.prefix == EmbSvgConstants.inkstitchPrefix);

  bool _isEmb(XmlAttribute attr) =>
      attr.name.namespaceUri == EmbSvgConstants.embNamespace ||
      (attr.name.namespaceUri == null && attr.name.prefix == EmbSvgConstants.embPrefix);

  /// Reads an `inkstitch:`-namespaced attribute value by local [name].
  String? _inkAttr(XmlElement el, String name) {
    for (final attr in el.attributes) {
      if (_isInkstitch(attr) && attr.name.local == name) {
        return attr.value;
      }
    }
    return null;
  }

  /// Reads an `emb:`-namespaced attribute value by local [name].
  String? _embAttr(XmlElement el, String name) {
    for (final attr in el.attributes) {
      if (_isEmb(attr) && attr.name.local == name) {
        return attr.value;
      }
    }
    return null;
  }

  // --- Geometry parsers ---------------------------------------------------

  /// Parses an SVG path `d` value into one point-list per subpath.
  ///
  /// Supports the absolute commands the writer emits: `M` (start a new subpath),
  /// `L` (add a point), `Z` (close — ignored for geometry, rings are implicitly
  /// closed in the model). Coordinates are "x,y" or "x y"; commas and whitespace
  /// are tolerated.
  List<List<Point<double>>> _parsePathD(String d) {
    final subpaths = <List<Point<double>>>[];
    List<Point<double>>? current;
    final tokens = d.replaceAll(',', ' ').trim().split(RegExp(r'\s+'));
    var i = 0;
    while (i < tokens.length) {
      final token = tokens[i];
      if (token.isEmpty) {
        i++;
        continue;
      }
      switch (token) {
        case 'M':
          current = <Point<double>>[];
          subpaths.add(current);
          if (i + 2 < tokens.length) {
            current.add(Point<double>(double.parse(tokens[i + 1]), double.parse(tokens[i + 2])));
          }
          i += 3;
        case 'L':
          if (current != null && i + 2 < tokens.length) {
            current.add(Point<double>(double.parse(tokens[i + 1]), double.parse(tokens[i + 2])));
          }
          i += 3;
        case 'Z':
        case 'z':
          i++;
        default:
          i++;
      }
    }
    return subpaths;
  }

  /// Parses a polyline/polygon `points` value ("x,y x,y ...") into points.
  List<Point<double>> _parsePoints(String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      return const [];
    }
    final points = <Point<double>>[];
    for (final token in raw.trim().split(RegExp(r'\s+'))) {
      final coords = token.split(',');
      if (coords.length != 2) {
        continue;
      }
      points.add(Point<double>(double.parse(coords[0]), double.parse(coords[1])));
    }
    return points;
  }

  // --- Small helpers ------------------------------------------------------

  /// Returns the first descendant element with the given local [name], or null.
  XmlElement? _firstByLocalName(XmlElement? parent, String name) =>
      parent?.findAllElements(name, namespace: '*').firstOrNull;

  /// Reads an attribute by local name, ignoring any namespace prefix.
  String? _localAttr(XmlElement? element, String name) => element?.getAttribute(name, namespace: '*');

  /// Parses a millimeter value, tolerating a trailing `mm` suffix.
  double _parseMm(String? value) {
    if (value == null) {
      return 0.0;
    }
    return double.parse(value.replaceAll(EmbSvgConstants.unitMillimeters, '').trim());
  }

  /// Extracts the [index]-th color component (0=R, 1=G, 2=B) from "#RRGGBB".
  int _hexComponent(String rgb, int index) {
    final hex = rgb.startsWith('#') ? rgb.substring(1) : rgb;
    if (hex.length < 6) {
      return 0;
    }
    return int.parse(hex.substring(index * 2, index * 2 + 2), radix: 16);
  }
}

/// Internal carrier for the parsed palette and its needle assignments.
class _Palette {
  const _Palette(this.threadsById, this.needleByThreadId);

  final Map<String, ThreadColor> threadsById;
  final Map<String, int> needleByThreadId;
}
