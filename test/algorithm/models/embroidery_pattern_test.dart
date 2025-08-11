import 'dart:ui';
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:thread_digit/algorithm/models/embroidery_pattern.dart';
import 'package:thread_digit/algorithm/models/stitch.dart';
import 'package:thread_digit/algorithm/models/stitch_sequence.dart';
import 'package:thread_digit/colors/model/thread_color.dart';

void main() {
  group('EmbroideryPattern', () {
    late ThreadColor redColor;
    late ThreadColor blueColor;
    late List<StitchSequence> testSequences;
    late Map<String, ThreadColor> testThreads;

    setUp(() {
      redColor = const ThreadColor(
        name: 'Red',
        code: 'R001',
        red: 255,
        green: 0,
        blue: 0,
        catalog: 'Madeira',
      );

      blueColor = const ThreadColor(
        name: 'Blue',
        code: 'B001',
        red: 0,
        green: 0,
        blue: 255,
        catalog: 'Madeira',
      );

      testSequences = [
        StitchSequence(
          stitches: [
            Stitch(
              start: const math.Point(0.0, 0.0),
              end: const math.Point(3.0, 0.0),
              color: redColor,
            ),
            Stitch(
              start: const math.Point(3.0, 0.0),
              end: const math.Point(3.0, 4.0),
              color: redColor,
            ),
          ],
          color: redColor,
          threadId: 'R001',
        ),
        StitchSequence(
          stitches: [
            Stitch(
              start: const math.Point(5.0, 5.0),
              end: const math.Point(10.0, 5.0),
              color: blueColor,
            ),
          ],
          color: blueColor,
          threadId: 'B001',
        ),
      ];

      testThreads = {
        'R001': redColor,
        'B001': blueColor,
      };
    });

    group('totalStitches calculation', () {
      test('calculates total stitches across all sequences', () {
        final pattern = EmbroideryPattern(
          sequences: testSequences,
          dimensions: const Size(100.0, 100.0),
          threads: testThreads,
        );

        expect(pattern.totalStitches, equals(3)); // 2 + 1
      });

      test('returns zero for pattern with no sequences', () {
        final pattern = EmbroideryPattern(
          sequences: const [],
          dimensions: const Size(100.0, 100.0),
          threads: const {},
        );

        expect(pattern.totalStitches, equals(0));
      });

      test('returns zero for sequences with no stitches', () {
        final emptySequences = [
          StitchSequence(
            stitches: const [],
            color: redColor,
            threadId: 'R001',
          ),
          StitchSequence(
            stitches: const [],
            color: blueColor,
            threadId: 'B001',
          ),
        ];

        final pattern = EmbroideryPattern(
          sequences: emptySequences,
          dimensions: const Size(100.0, 100.0),
          threads: testThreads,
        );

        expect(pattern.totalStitches, equals(0));
      });

      test('handles large number of stitches', () {
        final largeSequence = StitchSequence(
          stitches: List.generate(
            1000,
            (i) => Stitch(
              start: math.Point(i.toDouble(), 0.0),
              end: math.Point(i + 1.0, 0.0),
              color: redColor,
            ),
          ),
          color: redColor,
          threadId: 'R001',
        );

        final pattern = EmbroideryPattern(
          sequences: [largeSequence],
          dimensions: const Size(100.0, 100.0),
          threads: {'R001': redColor},
        );

        expect(pattern.totalStitches, equals(1000));
      });
    });

    group('threadChanges calculation', () {
      test('calculates thread changes correctly for multiple threads', () {
        final pattern = EmbroideryPattern(
          sequences: testSequences,
          dimensions: const Size(100.0, 100.0),
          threads: testThreads,
        );

        expect(pattern.threadChanges, equals(1)); // 2 threads - 1 = 1 change
      });

      test('returns zero for single thread', () {
        final pattern = EmbroideryPattern(
          sequences: [testSequences.first],
          dimensions: const Size(100.0, 100.0),
          threads: {'R001': redColor},
        );

        expect(pattern.threadChanges, equals(0)); // 1 thread - 1 = 0 changes
      });

      test('returns zero for no threads', () {
        final pattern = EmbroideryPattern(
          sequences: const [],
          dimensions: const Size(100.0, 100.0),
          threads: const {},
        );

        expect(pattern.threadChanges, equals(0));
      });

      test('calculates correctly for many threads', () {
        final manyThreads = Map.fromEntries(
          List.generate(
            10,
            (i) => MapEntry(
              'T$i',
              ThreadColor(
                name: 'Color $i',
                code: 'C$i',
                red: i * 25,
                green: i * 20,
                blue: i * 15,
                catalog: 'Test',
              ),
            ),
          ),
        );

        final pattern = EmbroideryPattern(
          sequences: const [],
          dimensions: const Size(100.0, 100.0),
          threads: manyThreads,
        );

        expect(pattern.threadChanges, equals(9)); // 10 threads - 1 = 9 changes
      });
    });

    group('totalThreadLength calculation', () {
      test('calculates total thread length across all sequences', () {
        final pattern = EmbroideryPattern(
          sequences: testSequences,
          dimensions: const Size(100.0, 100.0),
          threads: testThreads,
        );

        // First sequence: 3 + 4 = 7mm, Second sequence: 5mm, Total: 12mm
        expect(pattern.totalThreadLength, equals(12.0));
      });

      test('returns zero for empty pattern', () {
        final pattern = EmbroideryPattern(
          sequences: const [],
          dimensions: const Size(100.0, 100.0),
          threads: const {},
        );

        expect(pattern.totalThreadLength, equals(0.0));
      });

      test('handles sequences with zero-length stitches', () {
        final sequenceWithZero = StitchSequence(
          stitches: [
            Stitch(
              start: const math.Point(0.0, 0.0),
              end: const math.Point(5.0, 0.0), // Length: 5
              color: redColor,
            ),
            Stitch(
              start: const math.Point(5.0, 0.0),
              end: const math.Point(5.0, 0.0), // Length: 0
              color: redColor,
            ),
          ],
          color: redColor,
          threadId: 'R001',
        );

        final pattern = EmbroideryPattern(
          sequences: [sequenceWithZero],
          dimensions: const Size(100.0, 100.0),
          threads: {'R001': redColor},
        );

        expect(pattern.totalThreadLength, equals(5.0));
      });
    });

    group('sequenceCount', () {
      test('returns correct count of sequences', () {
        final pattern = EmbroideryPattern(
          sequences: testSequences,
          dimensions: const Size(100.0, 100.0),
          threads: testThreads,
        );

        expect(pattern.sequenceCount, equals(2));
      });

      test('returns zero for empty pattern', () {
        final pattern = EmbroideryPattern(
          sequences: const [],
          dimensions: const Size(100.0, 100.0),
          threads: const {},
        );

        expect(pattern.sequenceCount, equals(0));
      });
    });

    group('copyWith', () {
      test('creates copy with new sequences', () {
        final original = EmbroideryPattern(
          sequences: testSequences,
          dimensions: const Size(100.0, 100.0),
          threads: testThreads,
        );

        final newSequences = [testSequences.first];
        final copy = original.copyWith(sequences: newSequences);

        expect(copy.sequences, equals(newSequences));
        expect(copy.dimensions, equals(original.dimensions));
        expect(copy.threads, equals(original.threads));
      });

      test('creates copy with new dimensions', () {
        final original = EmbroideryPattern(
          sequences: testSequences,
          dimensions: const Size(100.0, 100.0),
          threads: testThreads,
        );

        const newDimensions = Size(200.0, 150.0);
        final copy = original.copyWith(dimensions: newDimensions);

        expect(copy.sequences, equals(original.sequences));
        expect(copy.dimensions, equals(newDimensions));
        expect(copy.threads, equals(original.threads));
      });

      test('creates copy with new threads', () {
        final original = EmbroideryPattern(
          sequences: testSequences,
          dimensions: const Size(100.0, 100.0),
          threads: testThreads,
        );

        final newThreads = {'R001': redColor};
        final copy = original.copyWith(threads: newThreads);

        expect(copy.sequences, equals(original.sequences));
        expect(copy.dimensions, equals(original.dimensions));
        expect(copy.threads, equals(newThreads));
      });
    });

    group('equality', () {
      test('equal patterns have same properties', () {
        final pattern1 = EmbroideryPattern(
          sequences: testSequences,
          dimensions: const Size(100.0, 100.0),
          threads: testThreads,
        );

        final pattern2 = EmbroideryPattern(
          sequences: testSequences,
          dimensions: const Size(100.0, 100.0),
          threads: testThreads,
        );

        expect(pattern1, equals(pattern2));
        expect(pattern1.hashCode, equals(pattern2.hashCode));
      });

      test('patterns with different dimensions are not equal', () {
        final pattern1 = EmbroideryPattern(
          sequences: testSequences,
          dimensions: const Size(100.0, 100.0),
          threads: testThreads,
        );

        final pattern2 = EmbroideryPattern(
          sequences: testSequences,
          dimensions: const Size(200.0, 200.0),
          threads: testThreads,
        );

        expect(pattern1, isNot(equals(pattern2)));
      });

      test('patterns with different sequences are not equal', () {
        final pattern1 = EmbroideryPattern(
          sequences: testSequences,
          dimensions: const Size(100.0, 100.0),
          threads: testThreads,
        );

        final pattern2 = EmbroideryPattern(
          sequences: [testSequences.first],
          dimensions: const Size(100.0, 100.0),
          threads: testThreads,
        );

        expect(pattern1, isNot(equals(pattern2)));
      });
    });

  });
}
