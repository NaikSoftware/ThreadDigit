# План підзадач для AI агентів - Алгоритм машинної вишивки

## Підзадача 1: Модуль обробки зображень

### Prompt для AI агента:
```
Create a Dart/Flutter image preprocessing module for embroidery generation with the following requirements:

1. Implement image loading and resizing functionality that:
   - Accepts various image formats (PNG, JPG, etc.)
   - Resizes images to a working resolution (max 800x800 pixels)
   - Maintains aspect ratio
   - Uses bicubic interpolation for quality

2. Implement noise reduction using:
   - Gaussian blur with adjustable sigma (0.5-2.0)
   - Bilateral filter for edge preservation
   - Parameters should be configurable

3. Create contrast enhancement features:
   - Histogram equalization
   - Adaptive contrast enhancement
   - Gamma correction with adjustable value

4. The module should expose a clean API:
   ```dart
   class ImagePreprocessor {
     Future<ProcessedImage> process(Uint8List imageData, PreprocessingConfig config);
   }
   ```

5. Include unit tests for all preprocessing functions.

Use existing Flutter packages where appropriate (image, image_editor_pro).
Follow SOLID principles and include proper error handling.
```

## Підзадача 2: Модуль аналізу текстур та градієнтів

### Prompt для AI агента:
```
Develop a texture and gradient analysis module in Dart for embroidery stitch direction determination:

1. Implement structure tensor analysis:
   - Calculate image gradients using Sobel operators
   - Compute structure tensor for each pixel
   - Extract dominant orientation angles
   - Return orientation map with angles in radians

2. Create edge detection functionality:
   - Implement Canny edge detector
   - Support adjustable thresholds
   - Return binary edge map and edge strength map

3. Implement texture classification:
   - Identify smooth regions (uniform fill areas)
   - Detect textured regions (requiring directional stitches)
   - Classify regions by complexity (simple/medium/complex)

4. Module API design:
   ```dart
   class TextureAnalyzer {
     Future<TextureAnalysis> analyze(ProcessedImage image);
   }
   
   class TextureAnalysis {
     final Matrix<double> orientationMap;
     final Matrix<bool> edgeMap;
     final Matrix<TextureType> textureClassification;
     final List<TextureRegion> regions;
   }
   ```

5. Optimize for performance using isolates for parallel processing.

Include comprehensive documentation and example usage.
```

## Підзадача 3: Модуль квантування кольорів

### Prompt для AI агента:
```
Create a color quantization module for embroidery thread mapping in Dart:

1. Implement K-means clustering in CIE Lab color space:
   - Convert RGB to Lab for perceptual accuracy
   - Support dynamic K value (2-20 colors)
   - Use K-means++ for initial centroid selection
   - Include convergence criteria

2. Implement Floyd-Steinberg dithering:
   - Apply error diffusion for smooth color transitions
   - Support multiple dithering patterns
   - Allow adjustable dithering strength (0-100%)

3. Thread color mapping:
   - Create thread color database structure
   - Implement nearest color matching in Lab space
   - Support multiple thread manufacturer catalogs
   - Use Delta E (CIE2000) for color distance

4. API design:
   ```dart
   class ColorQuantizer {
     Future<QuantizedImage> quantize(
       ProcessedImage image, 
       int colorLimit,
       ThreadCatalog catalog,
       DitheringOptions options
     );
   }
   ```

5. Include thread catalog data for major manufacturers (use existing catalog data from the project).

Ensure efficient memory usage and include progress callbacks for long operations.
```

## Підзадача 4: Модуль генерації стібків

### Prompt для AI агента:
```
Develop a stitch generation module that converts analyzed image data into embroidery stitches:

1. Implement adaptive mesh generation:
   - Create Delaunay triangulation based on image features
   - Adjust mesh density based on local detail level
   - Support density parameter (0.1-1.0)

2. Create stitch generation algorithms:
   - For uniform areas: parallel satin stitch fill
   - For textured areas: directional stitches following orientation map
   - For edges: running stitch or satin column
   - Support variable stitch length (minLength-maxLength)

3. Implement silk shading technique:
   - Gradual color transitions using overlapping stitches
   - Blend neighboring colors smoothly
   - Adjustable blending intensity

4. Implement sfumato technique:
   - Soft gradients without hard boundaries
   - Randomized stitch placement for organic look
   - Configurable randomness factor

5. Module API:
   ```dart
   class StitchGenerator {
     Future<List<Stitch>> generate(
       TextureAnalysis analysis,
       QuantizedImage colorData,
       StitchParameters params
     );
   }
   ```

6. Include collision detection for overlapping stitches and density control.

Focus on generating high-quality, realistic embroidery patterns.
```

## Підзадача 5: Модуль оптимізації послідовностей

### Prompt для AI агента:
```
Create a sequence optimization module for minimizing thread cuts in embroidery:

1. Implement stitch grouping:
   - Group stitches by color
   - Identify connectable sequences
   - Support jump stitch limits

2. Path optimization algorithms:
   - Implement nearest neighbor algorithm
   - Add 2-opt optimization
   - Consider Christofides algorithm for better results
   - Balance between optimization time and quality

3. Sequence connection logic:
   - Connect sequences with hidden travel stitches
   - Ensure travel stitches are covered by other stitches
   - Respect maximum jump distance

4. Color change optimization:
   - Minimize color changes
   - Group small same-color areas
   - Implement color sorting strategies

5. API design:
   ```dart
   class SequenceOptimizer {
     Future<List<StitchSequence>> optimize(
       List<Stitch> stitches,
       OptimizationParams params
     );
   }
   ```

6. Include performance metrics (thread cuts, total length, color changes).

Ensure the optimizer can handle large patterns (10,000+ stitches) efficiently.
```

## Підзадача 6: Модуль експорту та візуалізації

### Prompt для AI агента:
```
Develop export and visualization module for embroidery patterns:

1. Implement pattern visualization:
   - Real-time stitch rendering on canvas
   - Support zoom and pan
   - Show stitch direction and density
   - Color-coded sequence visualization

2. Create export functionality:
   - Export to PES format (use existing PES writer)
   - Export to DST format
   - Generate PDF documentation with thread list
   - Create PNG preview images

3. Statistics and reporting:
   - Total stitch count
   - Thread usage by color
   - Estimated sewing time
   - Pattern dimensions

4. Interactive preview features:
   - Step-through sequences
   - Highlight individual stitches
   - Show/hide layers by color
   - Density heatmap overlay

5. Module API:
   ```dart
   class PatternExporter {
     Future<void> exportPES(EmbroideryPattern pattern, String path);
     Future<void> exportDST(EmbroideryPattern pattern, String path);
     Future<Uint8List> generatePreview(EmbroideryPattern pattern, PreviewOptions options);
   }
   ```

Include proper error handling and validation for export formats.
```

## Підзадача 7: Інтеграційний модуль та UI

### Prompt для AI агента:
```
Create the main integration module and minimal UI for the embroidery generation system:

1. Main algorithm orchestrator:
   - Coordinate all modules in the correct sequence
   - Handle errors and provide fallbacks
   - Implement progress reporting
   - Support cancellation

2. Create minimal Flutter UI:
   - Image selection (gallery/camera)
   - Parameter controls (sliders/inputs)
   - Real-time preview
   - Export options
   - Progress indicators

3. State management:
   - Use BLoC pattern (as per project convention)
   - Handle async operations properly
   - Maintain UI responsiveness

4. Configuration management:
   - Save/load parameter presets
   - User preferences
   - Thread catalog selection

5. Main API:
   ```dart
   class EmbroideryGenerator {
     Stream<GenerationProgress> generateFromImage(
       Uint8List imageData,
       EmbroideryParameters params
     );
   }
   ```

6. Include comprehensive error messages and user guidance.

Follow Material Design guidelines and ensure smooth UX.
```

## Підзадача 8: Тестування та оптимізація

### Prompt для AI агента:
```
Create comprehensive testing suite and performance optimization for the embroidery algorithm:

1. Unit tests for each module:
   - Test edge cases and error conditions
   - Validate algorithm correctness
   - Mock dependencies appropriately

2. Integration tests:
   - End-to-end pattern generation
   - Various image types and sizes
   - Parameter boundary testing

3. Performance benchmarks:
   - Measure processing time for each stage
   - Memory usage profiling
   - Identify bottlenecks

4. Optimization tasks:
   - Implement caching where beneficial
   - Add parallel processing using isolates
   - Optimize memory-intensive operations
   - Consider SIMD operations for batch processing

5. Test data generation:
   - Create synthetic test images
   - Various complexity levels
   - Known expected outputs

6. Quality metrics:
   - Visual similarity scores
   - Stitch efficiency metrics
   - User study framework

Include performance regression tests and automated benchmark reporting.
```

## Порядок виконання

1. **Фаза 1**: Підзадачі 1-3 (базова обробка зображень)
2. **Фаза 2**: Підзадачі 4-5 (генерація стібків)
3. **Фаза 3**: Підзадачі 6-7 (візуалізація та інтеграція)
4. **Фаза 4**: Підзадача 8 (тестування та оптимізація)

## Додаткові рекомендації

- Кожна підзадача має бути автономною та тестованою
- Використовувати існуючі бібліотеки там, де це доцільно
- Дотримуватися стилю коду проекту
- Документувати всі публічні API
- Включати приклади використання