# Testing Strategy

## Test Categories

### Unit Tests
Test individual classes and methods in isolation.

**Location**: `test/algorithm/models/`, `test/algorithm/processors/`, etc.
**Coverage Target**: >90% line coverage
**Naming**: `{class_name}_test.dart`

```dart
// Example: test/algorithm/models/stitch_test.dart
void main() {
  group('Stitch', () {
    test('calculates length correctly', () {
      final stitch = Stitch(
        start: const Point(0, 0),
        end: const Point(3, 4),
        color: testThreadColor,
      );
      
      expect(stitch.length, equals(5.0));
    });
    
    test('validates against parameters', () {
      final params = EmbroideryParameters(
        minStitchLength: 2.0,
        maxStitchLength: 10.0,
        colorLimit: 16,
        density: 0.7,
      );
      
      final validStitch = Stitch(
        start: const Point(0, 0),
        end: const Point(5, 0),
        color: testThreadColor,
      );
      
      final invalidStitch = Stitch(
        start: const Point(0, 0),
        end: const Point(1, 0),
        color: testThreadColor,
      );
      
      expect(validStitch.isValid(params), isTrue);
      expect(invalidStitch.isValid(params), isFalse);
    });
  });
}
```

### Integration Tests  
Test component interactions and data flow.

**Location**: `test/algorithm/integration/`
**Focus**: Pipeline processing, component communication
**Data**: Use real test images and expected outputs

```dart
// Example: test/algorithm/integration/processing_pipeline_test.dart
void main() {
  group('Processing Pipeline Integration', () {
    late EmbroideryEngine engine;
    late TestImageData testImage;
    
    setUp(() async {
      engine = EmbroideryEngine();
      testImage = await loadTestImage('test_pattern_64x64.png');
    });
    
    test('processes simple pattern end-to-end', () async {
      final parameters = EmbroideryParameters(
        minStitchLength: 1.0,
        maxStitchLength: 12.0,
        colorLimit: 4,
        density: 0.5,
      );
      
      final result = await engine.processImage(testImage, parameters);
      
      expect(result.isSuccess, isTrue);
      expect(result.data!.sequences, isNotEmpty);
      expect(result.data!.totalStitches, greaterThan(0));
      expect(result.data!.threads.length, lessThanOrEqualTo(4));
      
      // Validate stitch continuity
      for (final sequence in result.data!.sequences) {
        expect(sequence.isValid, isTrue);
      }
    });
  });
}
```

### Performance Tests
Validate processing speed and memory usage.

**Location**: `test/algorithm/performance/`
**Metrics**: Processing time, memory usage, output quality
**Test Data**: Various image sizes and complexities

```dart
// Example: test/algorithm/performance/benchmark_test.dart
void main() {
  group('Performance Benchmarks', () {
    test('processes 512x512 image within time limit', () async {
      final testImage = await loadTestImage('benchmark_512x512.jpg');
      final engine = EmbroideryEngine();
      final parameters = standardParameters;
      
      final stopwatch = Stopwatch()..start();
      final result = await engine.processImage(testImage, parameters);
      stopwatch.stop();
      
      expect(result.isSuccess, isTrue);
      expect(stopwatch.elapsedMilliseconds, lessThan(30000)); // 30 seconds
    });
    
    test('memory usage stays within limits', () async {
      // Memory usage tracking test
      final memoryBefore = getCurrentMemoryUsage();
      
      final result = await processLargeImage();
      
      final memoryAfter = getCurrentMemoryUsage();
      final memoryUsed = memoryAfter - memoryBefore;
      
      expect(memoryUsed, lessThan(512 * 1024 * 1024)); // 512MB limit
    });
  });
}
```

### Visual Quality Tests
Compare generated patterns against reference outputs.

**Location**: `test/algorithm/visual/`
**Method**: Image comparison with tolerance thresholds
**Reference Data**: Hand-crafted reference patterns

```dart
// Example: test/algorithm/visual/quality_test.dart
void main() {
  group('Visual Quality Tests', () {
    test('generated pattern matches reference within tolerance', () async {
      final testImage = await loadTestImage('reference_pattern.png');
      final referencePattern = await loadReferencePattern('reference_pattern.pes');
      
      final result = await processImageWithStandardParams(testImage);
      final generatedPattern = result.data!;
      
      final similarity = comparePatterns(generatedPattern, referencePattern);
      expect(similarity, greaterThan(0.85)); // 85% similarity threshold
    });
  });
}
```

## Test Data Management

### Test Fixtures Structure
```
test/fixtures/
├── images/
│   ├── simple_patterns/     # Basic geometric patterns
│   ├── photos/             # Real photographs
│   ├── edge_cases/         # Challenging test cases
│   └── benchmarks/         # Performance test images
├── patterns/
│   ├── reference_outputs/  # Expected embroidery patterns
│   └── validation_data/    # Pattern validation datasets
└── parameters/
    ├── standard_params.dart # Common parameter sets
    └── edge_case_params.dart # Boundary condition parameters
```

### Test Utilities
```dart
// test/test_utils/test_helpers.dart
class TestHelpers {
  /// Loads test image from fixtures
  static Future<ImageData> loadTestImage(String filename) async {
    final path = 'test/fixtures/images/$filename';
    return ImageLoader.fromFile(path);
  }
  
  /// Creates standard test parameters
  static EmbroideryParameters get standardParameters => EmbroideryParameters(
    minStitchLength: 1.0,
    maxStitchLength: 12.0,
    colorLimit: 16,
    density: 0.7,
  );
  
  /// Compares two patterns for similarity
  static double comparePatterns(EmbroideryPattern a, EmbroideryPattern b) {
    // Implementation for pattern comparison
  }
}
```

## Mocking Strategy

### Service Mocks
```dart
// test/mocks/mock_services.dart
class MockColorMatcher extends Mock implements ColorMatcher {}
class MockImageProcessor extends Mock implements ImageProcessor {}
class MockProgressTracker extends Mock implements ProgressTracker {}
```

### Mock Usage Example
```dart
void main() {
  group('StitchGenerator with mocks', () {
    late MockColorMatcher mockColorMatcher;
    late StitchGenerator generator;
    
    setUp(() {
      mockColorMatcher = MockColorMatcher();
      generator = StitchGenerator(
        colorMatcher: mockColorMatcher,
        parameters: standardParameters,
      );
    });
    
    test('uses color matcher correctly', () {
      when(mockColorMatcher.findBestMatch(any))
          .thenReturn(testThreadColor);
      
      final stitches = generator.generateForRegion(testRegion);
      
      verify(mockColorMatcher.findBestMatch(testRegion.dominantColor));
      expect(stitches.first.color, equals(testThreadColor));
    });
  });
}
```

## Test Organization

### Test Groups
```dart
void main() {
  group('Algorithm Core', () {
    group('Data Models', () {
      // Model tests
    });
    
    group('Processors', () {
      group('Image Preprocessing', () {
        // Preprocessing tests
      });
      
      group('Texture Analysis', () {
        // Analysis tests
      });
    });
  });
  
  group('Integration', () {
    // Integration tests
  });
  
  group('Performance', () {
    // Performance tests
  }, skip: !shouldRunPerformanceTests);
}
```

### Test Configuration
```dart
// test/test_config.dart
class TestConfig {
  static const bool shouldRunPerformanceTests = bool.fromEnvironment('RUN_PERFORMANCE_TESTS');
  static const bool shouldRunVisualTests = bool.fromEnvironment('RUN_VISUAL_TESTS');
  static const String testDataPath = 'test/fixtures/';
}
```

## Continuous Integration

### Test Execution
```bash
# Unit tests (fast)
flutter test test/algorithm/models/
flutter test test/algorithm/processors/

# Integration tests (medium)  
flutter test test/algorithm/integration/

# Performance tests (slow, CI only)
flutter test test/algorithm/performance/ --dart-define=RUN_PERFORMANCE_TESTS=true

# All tests with coverage
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
```

### Coverage Requirements
- **Unit Tests**: >90% line coverage
- **Critical Paths**: 100% coverage for algorithm core
- **Integration Tests**: Cover all major workflows  
- **Edge Cases**: Cover all boundary conditions

### Quality Gates
1. All tests must pass
2. Coverage thresholds must be met
3. Performance benchmarks must pass
4. No new lint warnings
5. Visual quality tests pass (when applicable)

## Test Maintenance

### Test Data Updates
- **Regular Review**: Update test images and reference patterns
- **Version Control**: Track changes to expected outputs
- **Regression Detection**: Alert on unexpected output changes

### Test Performance
- **Fast Feedback**: Unit tests < 1 minute total
- **Parallel Execution**: Run independent test groups in parallel
- **Selective Testing**: Run only affected tests during development

### Test Documentation
- **Clear Naming**: Test names describe exact scenario
- **Comprehensive Setup**: Tests include all necessary context
- **Failure Diagnosis**: Tests provide clear failure messages