# Data Models

## Core Algorithm Data Models

### Stitch
Represents a single embroidery stitch with start and end coordinates.

```dart
class Stitch extends Equatable {
  const Stitch({
    required this.start,
    required this.end,
    required this.color,
    this.thickness = 1.0,
  });

  final Point<double> start;
  final Point<double> end;
  final ThreadColor color;
  final double thickness;

  /// Calculated stitch length in millimeters
  double get length => start.distanceTo(end);
  
  /// Stitch direction angle in radians
  double get angle => atan2(end.y - start.y, end.x - start.x);
  
  /// Validates stitch against parameters
  bool isValid(EmbroideryParameters params) {
    return length >= params.minStitchLength && 
           length <= params.maxStitchLength;
  }

  @override
  List<Object?> get props => [start, end, color, thickness];
}
```

### StitchSequence  
Represents a continuous sequence of stitches that can be embroidered without thread cuts.

```dart
class StitchSequence extends Equatable {
  const StitchSequence({
    required this.stitches,
    required this.color,
    required this.threadId,
  });

  final List<Stitch> stitches;
  final ThreadColor color;
  final String threadId;

  /// Validates sequence continuity
  bool get isValid {
    for (int i = 0; i < stitches.length - 1; i++) {
      if (stitches[i].end != stitches[i + 1].start) {
        return false;
      }
    }
    return true;
  }

  /// Total sequence length
  double get totalLength => stitches.fold(0.0, (sum, stitch) => sum + stitch.length);

  /// Estimated embroidery time in seconds
  double get estimatedTime => stitches.length * 0.1; // 100ms per stitch

  @override
  List<Object?> get props => [stitches, color, threadId];
}
```

### EmbroideryPattern
Complete embroidery pattern with all sequences and metadata.

```dart
class EmbroideryPattern extends Equatable {
  const EmbroideryPattern({
    required this.sequences,
    required this.dimensions,
    required this.threads,
    required this.metadata,
  });

  final List<StitchSequence> sequences;
  final Size dimensions;
  final Map<String, ThreadColor> threads;
  final PatternMetadata metadata;

  /// Total stitch count across all sequences
  int get totalStitches => sequences.fold(0, (sum, seq) => sum + seq.stitches.length);
  
  /// Number of thread changes required
  int get threadChanges => threads.length - 1;
  
  /// Estimated total embroidery time
  Duration get estimatedTime {
    final stitchTime = totalStitches * 0.1; // 100ms per stitch
    final changeTime = threadChanges * 30.0; // 30s per thread change
    return Duration(seconds: (stitchTime + changeTime).round());
  }

  @override
  List<Object?> get props => [sequences, dimensions, threads, metadata];
}
```

### EmbroideryParameters
Configuration parameters for the embroidery algorithm.

```dart
class EmbroideryParameters extends Equatable {
  const EmbroideryParameters({
    required this.minStitchLength,
    required this.maxStitchLength,
    required this.colorLimit,
    required this.density,
    this.smoothing = 0.5,
    this.enableSilkShading = false,
    this.enableSfumato = false,
    this.overlapThreshold = 0.1,
  });

  final double minStitchLength;     // mm
  final double maxStitchLength;     // mm  
  final int colorLimit;            // max colors
  final double density;            // 0.1 - 1.0
  final double smoothing;          // 0.0 - 1.0
  final bool enableSilkShading;
  final bool enableSfumato;
  final double overlapThreshold;   // 0.0 - 1.0

  /// Validates all parameters are within acceptable ranges
  ValidationResult validate() {
    final errors = <String>[];
    
    if (minStitchLength <= 0) errors.add('minStitchLength must be positive');
    if (maxStitchLength <= minStitchLength) errors.add('maxStitchLength must be > minStitchLength');
    if (colorLimit < 1) errors.add('colorLimit must be >= 1');
    if (density < 0.1 || density > 1.0) errors.add('density must be 0.1-1.0');
    
    return ValidationResult(isValid: errors.isEmpty, errors: errors);
  }

  @override
  List<Object?> get props => [
    minStitchLength, maxStitchLength, colorLimit, density,
    smoothing, enableSilkShading, enableSfumato, overlapThreshold
  ];
}
```

## Analysis Data Models

### DirectionField
Represents texture direction analysis results.

```dart
class DirectionField extends Equatable {
  const DirectionField({
    required this.width,
    required this.height,
    required this.angles,
    required this.strengths,
  });

  final int width;
  final int height;
  final List<double> angles;    // direction angles in radians
  final List<double> strengths; // coherence strength 0.0-1.0

  /// Gets direction angle at pixel coordinates
  double angleAt(int x, int y) {
    if (x < 0 || x >= width || y < 0 || y >= height) return 0.0;
    return angles[y * width + x];
  }

  /// Gets coherence strength at pixel coordinates  
  double strengthAt(int x, int y) {
    if (x < 0 || x >= width || y < 0 || y >= height) return 0.0;
    return strengths[y * width + x];
  }

  @override
  List<Object?> get props => [width, height, angles, strengths];
}
```

### ImageRegion
Represents a segmented region of the image with uniform properties.

```dart  
class ImageRegion extends Equatable {
  const ImageRegion({
    required this.bounds,
    required this.dominantColor,
    required this.averageDirection,
    required this.isUniform,
    required this.pixels,
  });

  final Rectangle<int> bounds;
  final Color dominantColor;
  final double averageDirection;
  final bool isUniform;
  final List<Point<int>> pixels;

  /// Region area in pixels
  int get area => pixels.length;
  
  /// Aspect ratio of bounding rectangle
  double get aspectRatio => bounds.width / bounds.height;
  
  /// Determines appropriate fill strategy
  FillStrategy get recommendedFillStrategy {
    if (isUniform && area > 1000) return FillStrategy.parallel;
    if (aspectRatio > 3.0) return FillStrategy.linear;
    return FillStrategy.adaptive;
  }

  @override
  List<Object?> get props => [bounds, dominantColor, averageDirection, isUniform, pixels];
}
```

## Processing Result Models

### ProcessingResult
Generic result wrapper for processing operations.

```dart
class ProcessingResult<T> extends Equatable {
  const ProcessingResult._({
    required this.isSuccess,
    this.data,
    this.error,
    this.warnings = const [],
  });

  factory ProcessingResult.success(T data, {List<String> warnings = const []}) {
    return ProcessingResult._(isSuccess: true, data: data, warnings: warnings);
  }

  factory ProcessingResult.failure(String error) {
    return ProcessingResult._(isSuccess: false, error: error);
  }

  final bool isSuccess;
  final T? data;
  final String? error;
  final List<String> warnings;

  @override
  List<Object?> get props => [isSuccess, data, error, warnings];
}
```

### ValidationResult
Result of parameter or data validation.

```dart
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
}
```

## Integration with Existing Models

### Enhanced ThreadColor Usage
The existing ThreadColor model integrates seamlessly:

```dart  
// Existing ThreadColor model works directly with new Stitch model
final stitch = Stitch(
  start: Point(0, 0),
  end: Point(10, 5),
  color: ThreadColor(
    name: 'Red',
    code: 'R001',
    red: 255, green: 0, blue: 0,
    catalog: 'Madeira',
  ),
);
```

### Enhanced ColorMatcher Integration
Existing ColorMatcher enhanced for algorithm needs:

```dart
extension ColorMatcherAlgorithm on ColorMatcherUtil {
  /// Find optimal thread match using CIEDE2000
  static ThreadColor findOptimalMatch(
    Color imageColor,
    List<ThreadColor> catalog,
    ColorSpace colorSpace = ColorSpace.cieLab,
  ) {
    // Enhanced implementation using CIEDE2000
  }
}
```

## Enums and Constants

### FillStrategy
```dart
enum FillStrategy {
  parallel,    // Parallel lines for uniform areas
  adaptive,    // Adaptive to texture direction
  linear,      // Linear for thin regions
  radial,      // Radial from center point
}
```

### ColorSpace
```dart
enum ColorSpace {
  rgb,         // RGB color space
  cieLab,      // CIE LAB color space
  hsv,         // HSV color space
}
```

### Algorithm Constants
```dart
class AlgorithmConstants {
  static const double defaultMinStitchLength = 1.0;   // mm
  static const double defaultMaxStitchLength = 12.0;  // mm
  static const int defaultColorLimit = 16;
  static const double defaultDensity = 0.7;
  
  // Performance limits
  static const int maxImageWidth = 2048;
  static const int maxImageHeight = 2048;
  static const int maxStitchCount = 50000;
}