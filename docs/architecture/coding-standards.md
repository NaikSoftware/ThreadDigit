# Coding Standards

## General Dart Standards

### Code Style
- **Line Length**: 120 characters maximum
- **Formatting**: Use `dart format --line-length=120`  
- **Linting**: Follow `flutter_lints` rules
- **Documentation**: Minimal but essential docs only

### Naming Conventions
- **Classes**: PascalCase (`StitchGenerator`, `EmbroideryParameters`)
- **Variables/Methods**: camelCase (`stitchLength`, `generatePattern()`)  
- **Constants**: camelCase (`maxStitchLength`)
- **Files**: snake_case (`stitch_generator.dart`)
- **Private Members**: Leading underscore (`_internalMethod`)

## Data Model Standards

### Immutability
```dart
class Stitch extends Equatable {
  const Stitch({
    required this.start,
    required this.end,
    required this.color,
  });
  
  final Point<double> start;
  final Point<double> end;
  final ThreadColor color;
  
  // Functional updates only
  Stitch copyWith({Point<double>? start, Point<double>? end}) {
    return Stitch(
      start: start ?? this.start,
      end: end ?? this.end,  
      color: color,
    );
  }
}
```

### Equality Implementation
- **Always use Equatable** for value objects
- **Include all significant fields** in props
- **Override toString()** for debugging

```dart
@override
List<Object?> get props => [start, end, color];

@override  
String toString() => 'Stitch(${start.x},${start.y} → ${end.x},${end.y})';
```

## Algorithm Implementation Standards

### Performance Guidelines
- **Prefer final variables** where possible
- **Use const constructors** for immutable objects
- **Minimize object creation** in tight loops
- **Use typed collections** (`List<Stitch>` not `List<dynamic>`)

### Error Handling
```dart
// Input validation with clear error messages
void validateStitchLength(double length) {
  if (length < minStitchLength) {
    throw ArgumentError('Stitch length $length below minimum $minStitchLength');
  }
  if (length > maxStitchLength) {
    throw ArgumentError('Stitch length $length exceeds maximum $maxStitchLength');
  }
}

// Null safety with proper checks
ThreadColor? findNearestColor(int r, int g, int b) {
  // Return null if no match found, don't throw
  return colorCatalog.findNearest(r, g, b);
}
```

### Algorithm Structure
```dart
abstract class ImageProcessor {
  /// Process image with given parameters
  ProcessingResult process(ImageData input, ProcessingParameters params);
}

class TextureAnalyzer implements ImageProcessor {
  @override
  ProcessingResult process(ImageData input, ProcessingParameters params) {
    _validateInput(input);
    _validateParameters(params);
    
    try {
      final result = _performAnalysis(input, params);
      return ProcessingResult.success(result);
    } catch (e) {
      return ProcessingResult.failure('Analysis failed: $e');
    }
  }
}
```

## Testing Standards

### Test Structure
```dart
void main() {
  group('StitchGenerator', () {
    late StitchGenerator generator;
    late EmbroideryParameters parameters;
    
    setUp(() {
      parameters = const EmbroideryParameters(
        minStitchLength: 1.0,
        maxStitchLength: 12.0,
      );
      generator = StitchGenerator(parameters);
    });

    test('generates valid stitch lengths', () {
      final stitches = generator.generateForRegion(testRegion);
      
      for (final stitch in stitches) {
        expect(stitch.length, greaterThanOrEqualTo(parameters.minStitchLength));
        expect(stitch.length, lessThanOrEqualTo(parameters.maxStitchLength));
      }
    });
  });
}
```

### Test Coverage Requirements
- **Unit Tests**: >90% line coverage for algorithm components
- **Integration Tests**: Complete pipeline validation
- **Edge Cases**: Test boundary conditions and error states
- **Performance Tests**: Validate timing constraints

## Documentation Standards

### Class Documentation
```dart
/// Generates embroidery stitches from image analysis results.
/// 
/// Uses texture direction fields and color quantization to create
/// optimal stitch patterns that preserve image fidelity.
class StitchGenerator {
  /// Creates generator with specified parameters.
  const StitchGenerator(this.parameters);
  
  /// Generates stitches for the given image region.
  /// 
  /// Returns empty list if region is invalid or too small.
  List<Stitch> generateForRegion(ImageRegion region) {
    // Implementation
  }
}
```

### Method Documentation
- **Brief description** of what method does
- **Parameter explanation** if not obvious
- **Return value description** if not obvious  
- **Special cases or exceptions** if applicable

## Performance Standards

### Memory Management
- **Avoid memory leaks** in long-running processes
- **Dispose resources** properly (streams, controllers)
- **Use object pooling** for frequently created objects
- **Monitor memory usage** during processing

### Computational Efficiency  
- **O(n) or O(n log n)** algorithms preferred
- **Avoid O(n²)** unless unavoidable
- **Use appropriate data structures** (Maps for lookups, Lists for iteration)
- **Profile critical paths** with Flutter's profiling tools

### Mobile Optimization
- **Limit memory usage** to <512MB for processing
- **Use isolates** for CPU-intensive work
- **Provide progress feedback** for long operations
- **Support cancellation** of long-running tasks

## Architecture Principles

### Separation of Concerns
- **Models**: Pure data with no business logic
- **Processors**: Single responsibility processing units  
- **Services**: Orchestrate processors and manage state
- **Utils**: Pure functions with no side effects

### Dependency Management
- **Dependency injection** through constructors
- **Interface segregation** - small, focused interfaces
- **Inversion of control** - depend on abstractions

### Error Handling Strategy
- **Fail fast** with clear error messages
- **Graceful degradation** where possible
- **Comprehensive logging** for debugging
- **User-friendly error presentation**
