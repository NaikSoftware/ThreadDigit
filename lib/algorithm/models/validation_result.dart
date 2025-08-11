import 'package:equatable/equatable.dart';

class ValidationResult extends Equatable {
  const ValidationResult({
    required this.isValid,
    this.errors = const [],
    this.warnings = const [],
  });

  final bool isValid;
  final List<String> errors;
  final List<String> warnings;

  @override
  List<Object?> get props => [isValid, errors, warnings];

  @override
  String toString() => 'ValidationResult(isValid: $isValid, errors: $errors, warnings: $warnings)';
}
