import 'dart:io';
import 'dart:math';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:thread_digit/algorithm/models/embroidery_pattern.dart';
import 'package:thread_digit/algorithm/models/stitch.dart';
import 'package:thread_digit/algorithm/models/stitch_sequence.dart';
import 'package:thread_digit/colors/model/thread_color.dart';
import 'package:thread_digit/embroidery_format/model/elements/fill_element.dart';
import 'package:thread_digit/embroidery_format/model/elements/manual_stitch_element.dart';
import 'package:thread_digit/embroidery_format/model/elements/running_stitch_element.dart';
import 'package:thread_digit/embroidery_format/model/elements/satin_column_element.dart';
import 'package:thread_digit/embroidery_format/model/embroidery_document.dart';
import 'package:thread_digit/embroidery_format/model/embroidery_element.dart';
import 'package:thread_digit/embroidery_format/model/embroidery_metadata.dart';
import 'package:thread_digit/embroidery_format/reader/emb_svg_reader.dart';
import 'package:thread_digit/embroidery_format/writer/emb_svg_writer.dart';

const _red = ThreadColor(name: 'Red', code: 'R001', red: 255, green: 0, blue: 0, catalog: 'Madeira');
const _blue = ThreadColor(name: 'Blue', code: 'B002', red: 0, green: 0, blue: 255, catalog: 'Madeira');
const _green = ThreadColor(name: 'Green', code: 'G003', red: 0, green: 170, blue: 0, catalog: 'Madeira');

const _palette = {'t0': _red, 't1': _blue, 't2': _green};

EmbroideryDocument _document(List<EmbroideryElement> elements) {
  return EmbroideryDocument(
    dimensions: const Size(100, 80),
    elements: elements,
    metadata: const EmbroideryMetadata(
      name: 'Test',
      author: 'thread_digit',
      threads: _palette,
    ),
  );
}

void main() {
  const writer = EmbSvgWriter();
  const reader = EmbSvgReader();

  EmbroideryDocument roundTrip(EmbroideryDocument doc) => reader.read(writer.write(doc));

  group('round-trip by element type', () {
    test('running-stitch line', () {
      final doc = _document([
        RunningStitchElement(
          points: const [Point(5, 5), Point(20, 5), Point(35, 8)],
          color: _red,
          threadId: 't0',
          trimAfter: true,
          params: const {'running_stitch_length_mm': '2.5'},
        ),
      ]);

      expect(roundTrip(doc), doc);
    });

    test('manual stitches', () {
      final doc = _document([
        ManualStitchElement(
          points: const [Point(35, 8), Point(38, 10), Point(41, 12)],
          color: _red,
          threadId: 't0',
          trimAfter: true,
        ),
      ]);

      expect(roundTrip(doc), doc);
    });

    test('fill', () {
      final doc = _document([
        FillElement(
          boundary: const [Point(50, 20), Point(80, 20), Point(80, 50), Point(50, 50)],
          color: _blue,
          threadId: 't1',
          params: const {'fill_method': 'auto_fill', 'angle': '45', 'row_spacing_mm': '0.25'},
        ),
      ]);

      expect(roundTrip(doc), doc);
    });

    test('fill with holes uses a path and round-trips', () {
      final doc = _document([
        FillElement(
          boundary: const [Point(0, 0), Point(40, 0), Point(40, 40), Point(0, 40)],
          holes: const [
            [Point(10, 10), Point(20, 10), Point(20, 20), Point(10, 20)],
          ],
          color: _blue,
          threadId: 't1',
        ),
      ]);

      expect(writer.write(doc), contains('<path'));
      expect(roundTrip(doc), doc);
    });

    test('photo-stitch fill', () {
      final doc = _document([
        FillElement(
          boundary: const [Point(10, 55), Point(40, 55), Point(40, 75), Point(10, 75)],
          color: _green,
          threadId: 't2',
          photoStitch: true,
        ),
      ]);

      final restored = roundTrip(doc);
      expect(restored, doc);
      expect((restored.elements.single as FillElement).photoStitch, isTrue);
    });

    test('satin column with rungs', () {
      final doc = _document([
        SatinColumnElement(
          rail1: const [Point(55, 55), Point(60, 70)],
          rail2: const [Point(60, 55), Point(65, 70)],
          rungs: const [
            [Point(55, 55), Point(60, 55)],
          ],
          color: _green,
          threadId: 't2',
          trimAfter: true,
          params: const {'zigzag_spacing_mm': '0.4', 'pull_compensation_mm': '0.2'},
        ),
      ]);

      expect(roundTrip(doc), doc);
    });
  });

  group('document-level round-trip', () {
    test('preserves a mixed document and its element order', () {
      final doc = _document([
        RunningStitchElement(points: const [Point(0, 0), Point(10, 0)], color: _red, threadId: 't0'),
        FillElement(boundary: const [Point(0, 0), Point(5, 0), Point(5, 5)], color: _blue, threadId: 't1'),
        ManualStitchElement(points: const [Point(5, 5), Point(6, 6)], color: _green, threadId: 't2'),
      ]);

      final restored = roundTrip(doc);

      expect(restored, doc);
      expect(restored.elements.map((e) => e.elementType).toList(), ['line', 'fill', 'manual_stitch']);
      expect(restored.metadata.threads, _palette);
    });

    test('preserves unknown inkstitch params and custom emb params', () {
      final doc = _document([
        RunningStitchElement(
          points: const [Point(0, 0), Point(1, 1)],
          color: _red,
          threadId: 't0',
          params: const {'future_inkstitch_param': '7'},
          customParams: const {'photo_density': 'high'},
        ),
      ]);

      final restored = roundTrip(doc).elements.single;

      expect(restored.params['future_inkstitch_param'], '7');
      expect(restored.customParams['photo_density'], 'high');
    });

    test('builds manual elements from an EmbroideryPattern and round-trips', () {
      final sequence = StitchSequence(
        stitches: const [
          Stitch(start: Point(0, 0), end: Point(5, 2.5), color: _red),
          Stitch(start: Point(5, 2.5), end: Point(10, 4), color: _red),
        ],
        color: _red,
        threadId: 't0',
      );
      final pattern = EmbroideryPattern(
        sequences: [sequence],
        dimensions: const Size(40, 40),
        threads: const {'t0': _red},
      );

      final doc = EmbroideryDocument.fromPattern(pattern);
      final restored = roundTrip(doc);

      expect(restored, doc);
      final element = restored.elements.single as ManualStitchElement;
      expect(element.points, const [Point(0, 0), Point(5, 2.5), Point(10, 4)]);
      expect(element.toSequence().stitches, sequence.stitches);
    });

    test('resolves bare colors for elements without a thread id', () {
      final doc = EmbroideryDocument(
        dimensions: const Size(10, 10),
        elements: [
          const RunningStitchElement(
            points: [Point(0, 0), Point(1, 1)],
            color: ThreadColor(name: '', code: '', red: 18, green: 52, blue: 86, catalog: ''),
          ),
        ],
      );

      final restored = roundTrip(doc).elements.single;
      expect(restored.color.red, 18);
      expect(restored.color.green, 52);
      expect(restored.color.blue, 86);
      expect(restored.threadId, isNull);
    });
  });

  group('Ink/Stitch compatibility and viewer rendering', () {
    test('stroke elements set fill:none and fill elements set stroke:none', () {
      final svg = writer.write(
        _document([
          RunningStitchElement(points: const [Point(0, 0), Point(1, 1)], color: _red, threadId: 't0'),
          FillElement(boundary: const [Point(0, 0), Point(2, 0), Point(2, 2)], color: _blue, threadId: 't1'),
        ]),
      );

      expect(svg, contains('fill="none"'));
      expect(svg, contains('stroke="none"'));
    });

    test('uses Ink/Stitch namespace, parameter names and markers', () {
      final svg = writer.write(
        _document([
          ManualStitchElement(points: const [Point(0, 0), Point(1, 1)], color: _red, threadId: 't0'),
          SatinColumnElement(
            rail1: const [Point(0, 0), Point(0, 5)],
            rail2: const [Point(2, 0), Point(2, 5)],
            color: _green,
            threadId: 't2',
          ),
        ]),
      );

      expect(svg, contains('xmlns:inkstitch="http://inkstitch.org/namespace"'));
      expect(svg, contains('inkstitch:stroke_method="manual_stitch"'));
      expect(svg, contains('inkstitch:satin_column="true"'));
    });

    test('emits valid standard SVG any viewer can render', () {
      final svg = writer.write(
        _document([
          RunningStitchElement(points: const [Point(0, 0), Point(10, 10)], color: _red, threadId: 't0'),
        ]),
      );

      expect(svg, contains('<svg'));
      expect(svg, contains('xmlns="http://www.w3.org/2000/svg"'));
      expect(svg, contains('viewBox="0 0 100 80"'));
      expect(svg, contains('<polyline'));
    });
  });

  group('reading the contract fixture', () {
    test('parses every element type from the on-disk fixture', () {
      final svg = File('test/embroidery_format/fixtures/contract_sample.emb.svg').readAsStringSync();

      final doc = reader.read(svg);

      expect(doc.dimensions, const Size(100, 80));
      expect(doc.elements.map((e) => e.elementType).toList(), [
        'line',
        'manual_stitch',
        'fill',
        'photo_stitch',
        'satin_column',
      ]);
      expect(doc.metadata.threads.length, 3);
      expect(doc.metadata.name, 'Contract Sample');
    });
  });

  group('reader errors', () {
    test('throws FormatException on non-XML input', () {
      expect(() => reader.read('not xml'), throwsFormatException);
    });

    test('throws FormatException when the root is not <svg>', () {
      expect(() => reader.read('<html></html>'), throwsFormatException);
    });
  });
}
