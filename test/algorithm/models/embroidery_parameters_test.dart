import 'package:flutter_test/flutter_test.dart';
import 'package:thread_digit/algorithm/models/embroidery_parameters.dart';

void main() {
  group('EmbroideryParameters', () {
    group('validation', () {
      test('validates correct parameters', () {
        const params = EmbroideryParameters(
          minStitchLength: 1.0,
          maxStitchLength: 12.0,
          colorLimit: 16,
          density: 0.7,
        );

        final result = params.validate();

        expect(result.isValid, isTrue);
        expect(result.errors, isEmpty);
        expect(result.warnings, isEmpty);
      });

      test('detects negative minStitchLength', () {
        const params = EmbroideryParameters(
          minStitchLength: -1.0,
          maxStitchLength: 12.0,
          colorLimit: 16,
          density: 0.7,
        );

        final result = params.validate();

        expect(result.isValid, isFalse);
        expect(result.errors, contains('minStitchLength must be positive (got: -1.0)'));
      });

      test('detects zero minStitchLength', () {
        const params = EmbroideryParameters(
          minStitchLength: 0.0,
          maxStitchLength: 12.0,
          colorLimit: 16,
          density: 0.7,
        );

        final result = params.validate();

        expect(result.isValid, isFalse);
        expect(result.errors, contains('minStitchLength must be positive (got: 0.0)'));
      });

      test('detects maxStitchLength less than minStitchLength', () {
        const params = EmbroideryParameters(
          minStitchLength: 10.0,
          maxStitchLength: 5.0,
          colorLimit: 16,
          density: 0.7,
        );

        final result = params.validate();

        expect(result.isValid, isFalse);
        expect(
          result.errors,
          contains('maxStitchLength must be greater than minStitchLength (got: max=5.0, min=10.0)'),
        );
      });

      test('detects maxStitchLength equal to minStitchLength', () {
        const params = EmbroideryParameters(
          minStitchLength: 5.0,
          maxStitchLength: 5.0,
          colorLimit: 16,
          density: 0.7,
        );

        final result = params.validate();

        expect(result.isValid, isFalse);
        expect(
          result.errors,
          contains('maxStitchLength must be greater than minStitchLength (got: max=5.0, min=5.0)'),
        );
      });

      test('warns about very small minStitchLength', () {
        const params = EmbroideryParameters(
          minStitchLength: 0.3,
          maxStitchLength: 12.0,
          colorLimit: 16,
          density: 0.7,
        );

        final result = params.validate();

        expect(result.isValid, isTrue);
        expect(result.errors, isEmpty);
        expect(result.warnings, contains('minStitchLength below 0.5mm may cause thread breakage'));
      });

      test('warns about very large maxStitchLength', () {
        const params = EmbroideryParameters(
          minStitchLength: 1.0,
          maxStitchLength: 20.0,
          colorLimit: 16,
          density: 0.7,
        );

        final result = params.validate();

        expect(result.isValid, isTrue);
        expect(result.errors, isEmpty);
        expect(result.warnings, contains('maxStitchLength above 15mm may cause loose stitches'));
      });

      test('detects invalid colorLimit (zero)', () {
        const params = EmbroideryParameters(
          minStitchLength: 1.0,
          maxStitchLength: 12.0,
          colorLimit: 0,
          density: 0.7,
        );

        final result = params.validate();

        expect(result.isValid, isFalse);
        expect(result.errors, contains('colorLimit must be at least 1 (got: 0)'));
      });

      test('detects invalid colorLimit (negative)', () {
        const params = EmbroideryParameters(
          minStitchLength: 1.0,
          maxStitchLength: 12.0,
          colorLimit: -5,
          density: 0.7,
        );

        final result = params.validate();

        expect(result.isValid, isFalse);
        expect(result.errors, contains('colorLimit must be at least 1 (got: -5)'));
      });

      test('warns about excessive colorLimit', () {
        const params = EmbroideryParameters(
          minStitchLength: 1.0,
          maxStitchLength: 12.0,
          colorLimit: 100,
          density: 0.7,
        );

        final result = params.validate();

        expect(result.isValid, isTrue);
        expect(result.warnings, contains('colorLimit above 64 may be impractical for production'));
      });

      test('detects density below range', () {
        const params = EmbroideryParameters(
          minStitchLength: 1.0,
          maxStitchLength: 12.0,
          colorLimit: 16,
          density: 0.05,
        );

        final result = params.validate();

        expect(result.isValid, isFalse);
        expect(result.errors, contains('density must be between 0.1 and 1.0 (got: 0.05)'));
      });

      test('detects density above range', () {
        const params = EmbroideryParameters(
          minStitchLength: 1.0,
          maxStitchLength: 12.0,
          colorLimit: 16,
          density: 1.5,
        );

        final result = params.validate();

        expect(result.isValid, isFalse);
        expect(result.errors, contains('density must be between 0.1 and 1.0 (got: 1.5)'));
      });

      test('validates density at boundaries', () {
        const paramsLow = EmbroideryParameters(
          minStitchLength: 1.0,
          maxStitchLength: 12.0,
          colorLimit: 16,
          density: 0.1,
        );

        const paramsHigh = EmbroideryParameters(
          minStitchLength: 1.0,
          maxStitchLength: 12.0,
          colorLimit: 16,
          density: 1.0,
        );

        expect(paramsLow.validate().isValid, isTrue);
        expect(paramsHigh.validate().isValid, isTrue);
      });

      test('detects invalid smoothing', () {
        const paramsNegative = EmbroideryParameters(
          minStitchLength: 1.0,
          maxStitchLength: 12.0,
          colorLimit: 16,
          density: 0.7,
          smoothing: -0.1,
        );

        const paramsAbove = EmbroideryParameters(
          minStitchLength: 1.0,
          maxStitchLength: 12.0,
          colorLimit: 16,
          density: 0.7,
          smoothing: 1.1,
        );

        expect(paramsNegative.validate().errors, contains('smoothing must be between 0.0 and 1.0 (got: -0.1)'));
        expect(paramsAbove.validate().errors, contains('smoothing must be between 0.0 and 1.0 (got: 1.1)'));
      });

      test('detects invalid overlapThreshold', () {
        const paramsNegative = EmbroideryParameters(
          minStitchLength: 1.0,
          maxStitchLength: 12.0,
          colorLimit: 16,
          density: 0.7,
          overlapThreshold: -0.1,
        );

        const paramsAbove = EmbroideryParameters(
          minStitchLength: 1.0,
          maxStitchLength: 12.0,
          colorLimit: 16,
          density: 0.7,
          overlapThreshold: 1.5,
        );

        expect(paramsNegative.validate().errors, contains('overlapThreshold must be between 0.0 and 1.0 (got: -0.1)'));
        expect(paramsAbove.validate().errors, contains('overlapThreshold must be between 0.0 and 1.0 (got: 1.5)'));
      });

      test('detects multiple validation errors', () {
        const params = EmbroideryParameters(
          minStitchLength: -1.0,
          maxStitchLength: -2.0,
          colorLimit: 0,
          density: 2.0,
        );

        final result = params.validate();

        expect(result.isValid, isFalse);
        expect(result.errors.length, greaterThanOrEqualTo(3));
      });
    });

    group('default parameters', () {
      test('default parameters are valid', () {
        const params = EmbroideryParameters.defaultParameters;

        final result = params.validate();

        expect(result.isValid, isTrue);
        expect(result.errors, isEmpty);
      });

      test('default parameters have expected values', () {
        const params = EmbroideryParameters.defaultParameters;

        expect(params.minStitchLength, equals(1.0));
        expect(params.maxStitchLength, equals(12.0));
        expect(params.colorLimit, equals(16));
        expect(params.density, equals(0.7));
        expect(params.smoothing, equals(0.5));
        expect(params.enableSilkShading, isTrue);
        expect(params.enableSfumato, isTrue);
        expect(params.overlapThreshold, equals(0.1));
      });
    });

    group('techniques enabled by default', () {
      test('silk shading is enabled by default', () {
        const params = EmbroideryParameters(
          minStitchLength: 1.0,
          maxStitchLength: 12.0,
          colorLimit: 16,
          density: 0.7,
        );

        expect(params.enableSilkShading, isTrue);
      });

      test('sfumato is enabled by default', () {
        const params = EmbroideryParameters(
          minStitchLength: 1.0,
          maxStitchLength: 12.0,
          colorLimit: 16,
          density: 0.7,
        );

        expect(params.enableSfumato, isTrue);
      });
    });

    group('copyWith', () {
      test('creates copy with updated minStitchLength', () {
        const original = EmbroideryParameters(
          minStitchLength: 1.0,
          maxStitchLength: 12.0,
          colorLimit: 16,
          density: 0.7,
        );

        final copy = original.copyWith(minStitchLength: 2.0);

        expect(copy.minStitchLength, equals(2.0));
        expect(copy.maxStitchLength, equals(original.maxStitchLength));
        expect(copy.colorLimit, equals(original.colorLimit));
      });

      test('creates copy with disabled techniques', () {
        const original = EmbroideryParameters(
          minStitchLength: 1.0,
          maxStitchLength: 12.0,
          colorLimit: 16,
          density: 0.7,
        );

        final copy = original.copyWith(
          enableSilkShading: false,
          enableSfumato: false,
        );

        expect(copy.enableSilkShading, isFalse);
        expect(copy.enableSfumato, isFalse);
      });

      test('preserves all unchanged values', () {
        const original = EmbroideryParameters(
          minStitchLength: 1.5,
          maxStitchLength: 10.0,
          colorLimit: 32,
          density: 0.8,
          smoothing: 0.3,
          enableSilkShading: false,
          enableSfumato: false,
          overlapThreshold: 0.2,
        );

        final copy = original.copyWith(density: 0.9);

        expect(copy.minStitchLength, equals(original.minStitchLength));
        expect(copy.maxStitchLength, equals(original.maxStitchLength));
        expect(copy.colorLimit, equals(original.colorLimit));
        expect(copy.density, equals(0.9));
        expect(copy.smoothing, equals(original.smoothing));
        expect(copy.enableSilkShading, equals(original.enableSilkShading));
        expect(copy.enableSfumato, equals(original.enableSfumato));
        expect(copy.overlapThreshold, equals(original.overlapThreshold));
      });
    });

    group('equality', () {
      test('equal parameters have same properties', () {
        const params1 = EmbroideryParameters(
          minStitchLength: 1.0,
          maxStitchLength: 12.0,
          colorLimit: 16,
          density: 0.7,
        );

        const params2 = EmbroideryParameters(
          minStitchLength: 1.0,
          maxStitchLength: 12.0,
          colorLimit: 16,
          density: 0.7,
        );

        expect(params1, equals(params2));
        expect(params1.hashCode, equals(params2.hashCode));
      });

      test('parameters with different values are not equal', () {
        const params1 = EmbroideryParameters(
          minStitchLength: 1.0,
          maxStitchLength: 12.0,
          colorLimit: 16,
          density: 0.7,
        );

        const params2 = EmbroideryParameters(
          minStitchLength: 1.0,
          maxStitchLength: 12.0,
          colorLimit: 16,
          density: 0.8,
        );

        expect(params1, isNot(equals(params2)));
      });
    });

  });
}
