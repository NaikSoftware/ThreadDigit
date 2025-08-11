import 'package:flutter_test/flutter_test.dart';
import 'package:thread_digit/algorithm/models/validation_result.dart';

void main() {
  group('ValidationResult', () {
    test('validation result with errors should be invalid', () {
      const result = ValidationResult(
        isValid: false,
        errors: ['Error 1', 'Error 2'],
      );

      expect(result.isValid, isFalse);
      expect(result.errors, hasLength(2));
    });

    test('validation result with warnings should remain valid', () {
      const result = ValidationResult(
        isValid: true,
        warnings: ['Warning 1', 'Warning 2'],
      );

      expect(result.isValid, isTrue);
      expect(result.warnings, hasLength(2));
    });

    group('equality', () {
      test('equal results have same properties', () {
        const result1 = ValidationResult(
          isValid: true,
          errors: ['Error 1'],
          warnings: ['Warning 1'],
        );

        const result2 = ValidationResult(
          isValid: true,
          errors: ['Error 1'],
          warnings: ['Warning 1'],
        );

        expect(result1, equals(result2));
        expect(result1.hashCode, equals(result2.hashCode));
      });

      test('results with different validity are not equal', () {
        const result1 = ValidationResult(isValid: true);
        const result2 = ValidationResult(isValid: false);

        expect(result1, isNot(equals(result2)));
      });

      test('results with different errors are not equal', () {
        const result1 = ValidationResult(
          isValid: false,
          errors: ['Error 1'],
        );

        const result2 = ValidationResult(
          isValid: false,
          errors: ['Error 2'],
        );

        expect(result1, isNot(equals(result2)));
      });

      test('results with different warnings are not equal', () {
        const result1 = ValidationResult(
          isValid: true,
          warnings: ['Warning 1'],
        );

        const result2 = ValidationResult(
          isValid: true,
          warnings: ['Warning 2'],
        );

        expect(result1, isNot(equals(result2)));
      });
    });

  });
}
