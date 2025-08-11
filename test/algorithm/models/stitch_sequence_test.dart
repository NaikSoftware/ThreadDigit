import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:thread_digit/algorithm/models/stitch.dart';
import 'package:thread_digit/algorithm/models/stitch_sequence.dart';
import 'package:thread_digit/colors/model/thread_color.dart';

void main() {
  group('StitchSequence', () {
    late ThreadColor testColor;

    setUp(() {
      testColor = const ThreadColor(
        name: 'Test Red',
        code: 'R001',
        red: 255,
        green: 0,
        blue: 0,
        catalog: 'Madeira',
      );
    });

    group('continuity validation', () {
      test('validates continuous sequence where each end equals next start', () {
        final stitches = [
          Stitch(
            start: const math.Point(0.0, 0.0),
            end: const math.Point(5.0, 0.0),
            color: testColor,
          ),
          Stitch(
            start: const math.Point(5.0, 0.0),
            end: const math.Point(5.0, 5.0),
            color: testColor,
          ),
          Stitch(
            start: const math.Point(5.0, 5.0),
            end: const math.Point(0.0, 5.0),
            color: testColor,
          ),
        ];

        final sequence = StitchSequence(
          stitches: stitches,
          color: testColor,
          threadId: 'T001',
        );

        expect(sequence.isValid, isTrue);
      });

      test('invalidates sequence with discontinuous stitches', () {
        final stitches = [
          Stitch(
            start: const math.Point(0.0, 0.0),
            end: const math.Point(5.0, 0.0),
            color: testColor,
          ),
          Stitch(
            start: const math.Point(6.0, 0.0), // Gap here - doesn't match previous end
            end: const math.Point(6.0, 5.0),
            color: testColor,
          ),
        ];

        final sequence = StitchSequence(
          stitches: stitches,
          color: testColor,
          threadId: 'T001',
        );

        expect(sequence.isValid, isFalse);
      });

      test('validates empty sequence as valid', () {
        final sequence = StitchSequence(
          stitches: const [],
          color: testColor,
          threadId: 'T001',
        );

        expect(sequence.isValid, isTrue);
      });

      test('validates single stitch sequence as valid', () {
        final sequence = StitchSequence(
          stitches: [
            Stitch(
              start: const math.Point(0.0, 0.0),
              end: const math.Point(5.0, 5.0),
              color: testColor,
            ),
          ],
          color: testColor,
          threadId: 'T001',
        );

        expect(sequence.isValid, isTrue);
      });

      test('detects break in middle of long sequence', () {
        final stitches = [
          Stitch(
            start: const math.Point(0.0, 0.0),
            end: const math.Point(1.0, 0.0),
            color: testColor,
          ),
          Stitch(
            start: const math.Point(1.0, 0.0),
            end: const math.Point(2.0, 0.0),
            color: testColor,
          ),
          Stitch(
            start: const math.Point(2.0, 0.0),
            end: const math.Point(3.0, 0.0),
            color: testColor,
          ),
          Stitch(
            start: const math.Point(3.5, 0.0), // Break here
            end: const math.Point(4.0, 0.0),
            color: testColor,
          ),
        ];

        final sequence = StitchSequence(
          stitches: stitches,
          color: testColor,
          threadId: 'T001',
        );

        expect(sequence.isValid, isFalse);
      });
    });

    group('totalLength calculation', () {
      test('calculates total length for multiple stitches', () {
        final stitches = [
          Stitch(
            start: const math.Point(0.0, 0.0),
            end: const math.Point(3.0, 0.0), // Length: 3
            color: testColor,
          ),
          Stitch(
            start: const math.Point(3.0, 0.0),
            end: const math.Point(3.0, 4.0), // Length: 4
            color: testColor,
          ),
          Stitch(
            start: const math.Point(3.0, 4.0),
            end: const math.Point(0.0, 4.0), // Length: 3
            color: testColor,
          ),
        ];

        final sequence = StitchSequence(
          stitches: stitches,
          color: testColor,
          threadId: 'T001',
        );

        expect(sequence.totalLength, equals(10.0));
      });

      test('returns zero for empty sequence', () {
        final sequence = StitchSequence(
          stitches: const [],
          color: testColor,
          threadId: 'T001',
        );

        expect(sequence.totalLength, equals(0.0));
      });

      test('calculates length for single stitch', () {
        final sequence = StitchSequence(
          stitches: [
            Stitch(
              start: const math.Point(0.0, 0.0),
              end: const math.Point(3.0, 4.0), // Length: 5
              color: testColor,
            ),
          ],
          color: testColor,
          threadId: 'T001',
        );

        expect(sequence.totalLength, equals(5.0));
      });

      test('handles sequences with zero-length stitches', () {
        final stitches = [
          Stitch(
            start: const math.Point(0.0, 0.0),
            end: const math.Point(5.0, 0.0), // Length: 5
            color: testColor,
          ),
          Stitch(
            start: const math.Point(5.0, 0.0),
            end: const math.Point(5.0, 0.0), // Length: 0
            color: testColor,
          ),
          Stitch(
            start: const math.Point(5.0, 0.0),
            end: const math.Point(5.0, 3.0), // Length: 3
            color: testColor,
          ),
        ];

        final sequence = StitchSequence(
          stitches: stitches,
          color: testColor,
          threadId: 'T001',
        );

        expect(sequence.totalLength, equals(8.0));
      });
    });

    group('stitchCount', () {
      test('returns correct count for multiple stitches', () {
        final stitches = List.generate(
          10,
          (i) => Stitch(
            start: math.Point(i.toDouble(), 0.0),
            end: math.Point(i + 1.0, 0.0),
            color: testColor,
          ),
        );

        final sequence = StitchSequence(
          stitches: stitches,
          color: testColor,
          threadId: 'T001',
        );

        expect(sequence.stitchCount, equals(10));
      });

      test('returns zero for empty sequence', () {
        final sequence = StitchSequence(
          stitches: const [],
          color: testColor,
          threadId: 'T001',
        );

        expect(sequence.stitchCount, equals(0));
      });
    });

    group('copyWith', () {
      test('creates copy with new stitches', () {
        final original = StitchSequence(
          stitches: [
            Stitch(
              start: const math.Point(0.0, 0.0),
              end: const math.Point(5.0, 0.0),
              color: testColor,
            ),
          ],
          color: testColor,
          threadId: 'T001',
        );

        final newStitches = [
          Stitch(
            start: const math.Point(1.0, 1.0),
            end: const math.Point(2.0, 2.0),
            color: testColor,
          ),
        ];

        final copy = original.copyWith(stitches: newStitches);

        expect(copy.stitches, equals(newStitches));
        expect(copy.color, equals(original.color));
        expect(copy.threadId, equals(original.threadId));
      });

      test('creates copy with new color', () {
        final original = StitchSequence(
          stitches: const [],
          color: testColor,
          threadId: 'T001',
        );

        final newColor = const ThreadColor(
          name: 'Blue',
          code: 'B001',
          red: 0,
          green: 0,
          blue: 255,
          catalog: 'Madeira',
        );

        final copy = original.copyWith(color: newColor);

        expect(copy.color, equals(newColor));
        expect(copy.threadId, equals(original.threadId));
      });

      test('creates copy with new threadId', () {
        final original = StitchSequence(
          stitches: const [],
          color: testColor,
          threadId: 'T001',
        );

        final copy = original.copyWith(threadId: 'T002');

        expect(copy.threadId, equals('T002'));
        expect(copy.color, equals(original.color));
      });
    });

    group('equality', () {
      test('equal sequences have same properties', () {
        final stitches = [
          Stitch(
            start: const math.Point(0.0, 0.0),
            end: const math.Point(5.0, 0.0),
            color: testColor,
          ),
        ];

        final seq1 = StitchSequence(
          stitches: stitches,
          color: testColor,
          threadId: 'T001',
        );

        final seq2 = StitchSequence(
          stitches: stitches,
          color: testColor,
          threadId: 'T001',
        );

        expect(seq1, equals(seq2));
        expect(seq1.hashCode, equals(seq2.hashCode));
      });

      test('sequences with different threadIds are not equal', () {
        final stitches = [
          Stitch(
            start: const math.Point(0.0, 0.0),
            end: const math.Point(5.0, 0.0),
            color: testColor,
          ),
        ];

        final seq1 = StitchSequence(
          stitches: stitches,
          color: testColor,
          threadId: 'T001',
        );

        final seq2 = StitchSequence(
          stitches: stitches,
          color: testColor,
          threadId: 'T002',
        );

        expect(seq1, isNot(equals(seq2)));
      });
    });

  });
}
