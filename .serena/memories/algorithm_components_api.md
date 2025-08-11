# Algorithm Components API Reference

## PreprocessingPipeline
**Static Method**: `PreprocessingPipeline.processImage(img.Image input, {PipelineParameters params, ProgressCallback? progressCallback, CancelToken? cancelToken})`
- Returns: `Future<ProcessingResult<PreprocessingResult>>`
- Input: Uses `image` package Image type, not `ui.Image`
- Output contains processed image, edge map, gradients, direction field

## KMeansColorQuantizer  
**Static Method**: `KMeansColorQuantizer.quantize(img.Image image, int clusterCount, {KMeansParameters params})`
- Returns: `ProcessingResult<ClusteringResult>`
- NOT `quantizeColors()` - method name is `quantize()`
- Takes cluster count as second parameter

## FloydSteinbergDitherer
**Static Method**: `FloydSteinbergDitherer.dither(img.Image sourceImage, List<Color> palette, {DitheringParameters params})`
- Returns: `ProcessingResult<DitheringResult>`
- NOT `ditherImage()` - method name is `dither()`
- Takes List<Color> palette, not individual colors

## ThreadFlowAnalyzer
**Static Method**: `ThreadFlowAnalyzer.analyzeThreadFlow(img.Image image, DirectionField directionField, {double smoothingFactor, double artisticVariation})`
- Returns: `ProcessingResult<ThreadFlowField>`
- Requires DirectionField from preprocessing pipeline
- NO maxStitchLength parameter - this was wrong in current service

## ColorMatcher
**Instance methods** - NOT static:
- Constructor: `ColorMatcher()`  
- Method: `findClosestMatch(Color color)` - returns ThreadColor
- NO static methods like in current service
## SfumatoEngine
**Static Method**: `SfumatoEngine.generateSfumato(img.Image image, ThreadFlowField threadFlow, OpacityMap opacityMap, ThreadColor baseThreadColor, ThreadColor highlightThreadColor, List<bool> colorMask, EmbroideryParameters parameters, {int layerCount})`
- Returns: `ProcessingResult<SfumatoResult>`
- Implements Leonardo da Vinci's layered transparency technique
- Takes colorMask (List<bool>) to define regions for sfumato application
- Takes EmbroideryParameters, not individual stitch length/density parameters

## SilkShadingEngine
**Static Method**: `SilkShadingEngine.generateSilkShading(img.Image image, ThreadFlowField threadFlow, OpacityMap opacityMap, ThreadColor threadColor, List<bool> colorMask, EmbroideryParameters parameters)`
- Returns: `ProcessingResult<SilkShadingResult>`
- Implements photorealistic silk shading (thread painting) technique
- Takes colorMask (List<bool>) to define regions for this specific color
- NO individual density/stitch length parameters - uses EmbroideryParameters

## AdaptiveOpacityController
**Static Method**: `AdaptiveOpacityController.generateOpacityMap(img.Image image, ThreadFlowField threadFlow, {double baseDensity, double contrastEnhancement, double atmosphericDepth})`
- Returns: `ProcessingResult<OpacityMap>`
- Controls thread density variation for photorealistic shading
- Takes ThreadFlowField, not individual direction field
- Returns OpacityMap, not individual opacity values

## ColorMatcherUtil
**Static Methods** - All are static utility functions:
- `findOptimalMatch(Color imageColor, List<List<ThreadColor>> threadCatalogs, {ColorDistanceAlgorithm algorithm, bool allowNearby})`
- `findNearestColor(int red, int green, int blue, List<List<ThreadColor>> threadCatalogs)`
- Takes List<List<ThreadColor>> - list of catalogs, not individual colors
- NO instance methods - current service creates ColorMatcher() instance incorrectly
