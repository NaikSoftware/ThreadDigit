import 'package:equatable/equatable.dart';
import 'package:thread_digit/algorithm/models/validation_result.dart';

class EmbroideryParameters extends Equatable {
  const EmbroideryParameters({
    required this.minStitchLength,
    required this.maxStitchLength,
    required this.colorLimit,
    required this.density,
    this.smoothing = 0.5,
    this.enableSilkShading = true,
    this.enableSfumato = true,
    this.overlapThreshold = 0.1,
  });

  /// Minimum stitch length in millimeters
  final double minStitchLength;

  /// Maximum stitch length in millimeters
  final double maxStitchLength;

  /// Maximum number of thread colors
  final int colorLimit;

  /// Stitch density (0.1 to 1.0, where 1.0 is maximum density)
  final double density;

  /// Smoothing level (0.0 to 1.0)
  final double smoothing;

  /// Enable silk shading technique for gradients
  final bool enableSilkShading;

  /// Enable sfumato technique for soft edges
  final bool enableSfumato;

  /// Threshold for stitch overlap (0.0 to 1.0)
  final double overlapThreshold;

  /// Default parameters for typical embroidery with all techniques enabled
  static const EmbroideryParameters defaultParameters = EmbroideryParameters(
    minStitchLength: 1.0,
    maxStitchLength: 12.0,
    colorLimit: 16,
    density: 0.7,
    smoothing: 0.5,
    enableSilkShading: true,
    enableSfumato: true,
    overlapThreshold: 0.1,
  );

  /// Validates all parameters are within acceptable ranges
  ValidationResult validate() {
    final errors = <String>[];
    final warnings = <String>[];

    // Stitch length validation
    if (minStitchLength <= 0) {
      errors.add('minStitchLength must be positive (got: $minStitchLength)');
    }
    if (maxStitchLength <= minStitchLength) {
      errors.add('maxStitchLength must be greater than minStitchLength '
          '(got: max=$maxStitchLength, min=$minStitchLength)');
    }
    if (minStitchLength < 0.5) {
      warnings.add('minStitchLength below 0.5mm may cause thread breakage');
    }
    if (maxStitchLength > 15.0) {
      warnings.add('maxStitchLength above 15mm may cause loose stitches');
    }

    // Color limit validation
    if (colorLimit < 1) {
      errors.add('colorLimit must be at least 1 (got: $colorLimit)');
    }
    if (colorLimit > 64) {
      warnings.add('colorLimit above 64 may be impractical for production');
    }

    // Density validation
    if (density < 0.1 || density > 1.0) {
      errors.add('density must be between 0.1 and 1.0 (got: $density)');
    }

    // Smoothing validation
    if (smoothing < 0.0 || smoothing > 1.0) {
      errors.add('smoothing must be between 0.0 and 1.0 (got: $smoothing)');
    }

    // Overlap threshold validation
    if (overlapThreshold < 0.0 || overlapThreshold > 1.0) {
      errors.add('overlapThreshold must be between 0.0 and 1.0 (got: $overlapThreshold)');
    }

    return ValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
      warnings: warnings,
    );
  }

  /// Creates a copy with optional parameter overrides
  EmbroideryParameters copyWith({
    double? minStitchLength,
    double? maxStitchLength,
    int? colorLimit,
    double? density,
    double? smoothing,
    bool? enableSilkShading,
    bool? enableSfumato,
    double? overlapThreshold,
  }) {
    return EmbroideryParameters(
      minStitchLength: minStitchLength ?? this.minStitchLength,
      maxStitchLength: maxStitchLength ?? this.maxStitchLength,
      colorLimit: colorLimit ?? this.colorLimit,
      density: density ?? this.density,
      smoothing: smoothing ?? this.smoothing,
      enableSilkShading: enableSilkShading ?? this.enableSilkShading,
      enableSfumato: enableSfumato ?? this.enableSfumato,
      overlapThreshold: overlapThreshold ?? this.overlapThreshold,
    );
  }

  @override
  List<Object?> get props => [
        minStitchLength,
        maxStitchLength,
        colorLimit,
        density,
        smoothing,
        enableSilkShading,
        enableSfumato,
        overlapThreshold,
      ];

  @override
  String toString() => 'EmbroideryParameters('
      'stitchLength: $minStitchLength-${maxStitchLength}mm, '
      'colors: $colorLimit, '
      'density: $density, '
      'smoothing: $smoothing, '
      'silkShading: $enableSilkShading, '
      'sfumato: $enableSfumato, '
      'overlap: $overlapThreshold)';
}
