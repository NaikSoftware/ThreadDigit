import 'dart:math' as math;
import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:thread_digit/algorithm/models/processing_result.dart';
import 'package:thread_digit/algorithm/techniques/thread_flow_analyzer.dart';
import 'package:thread_digit/algorithm/utils/artistic_math.dart';

/// Advanced opacity control system for photorealistic embroidery shading.
///
/// Implements sophisticated thread density variation to simulate traditional
/// silk shading and painting techniques, creating natural-looking shadows,
/// highlights, and depth through strategic thread placement and opacity.
class AdaptiveOpacityController {
  /// Default atmospheric strength for depth effects
  static const _defaultAtmosphericStrength = 0.6;

  /// Generates sophisticated opacity map for photorealistic thread density control.
  ///
  /// [image] - Source image for luminance analysis
  /// [threadFlow] - Thread flow field for directional opacity variations
  /// [baseDensity] - Base thread density (0.1-1.0)
  /// [contrastEnhancement] - Amount of contrast enhancement (0.0-2.0)
  /// [atmosphericDepth] - Strength of atmospheric perspective (0.0-1.0)
  static ProcessingResult<OpacityMap> generateOpacityMap(
    img.Image image,
    ThreadFlowField threadFlow, {
    double baseDensity = 0.7,
    double contrastEnhancement = 1.3,
    double atmosphericDepth = _defaultAtmosphericStrength,
  }) {
    try {
      if (image.width != threadFlow.width || image.height != threadFlow.height) {
        return const ProcessingResult.failure(
          error: 'Image and thread flow dimensions must match'
        );
      }

      final stopwatch = Stopwatch()..start();

      final width = image.width;
      final height = image.height;

      // Step 1: Extract luminance information for shading analysis
      final luminanceData = _extractLuminanceData(image);

      // Step 2: Calculate depth map for atmospheric perspective
      final depthMap = _calculateDepthMap(image, threadFlow);

      // Step 3: Generate base opacity from luminance and artistic requirements
      final baseOpacity = _generateBaseOpacity(
        luminanceData,
        threadFlow,
        baseDensity,
      );

      // Step 4: Apply contrast enhancement for dramatic effect
      final contrastEnhanced = _applyContrastEnhancement(
        baseOpacity,
        contrastEnhancement,
        luminanceData,
      );

      // Step 5: Apply atmospheric perspective for depth
      final atmosphericAdjusted = _applyAtmosphericPerspective(
        contrastEnhanced,
        depthMap,
        atmosphericDepth,
      );

      // Step 6: Add artistic variation to prevent mechanical appearance
      final artisticOpacity = _addArtisticVariation(
        atmosphericAdjusted,
        threadFlow,
        luminanceData,
      );

      // Step 7: Calculate quality metrics
      final qualityMetrics = _calculateOpacityQuality(
        artisticOpacity,
        luminanceData,
        threadFlow,
      );

      stopwatch.stop();

      final result = OpacityMap(
        width: width,
        height: height,
        opacityValues: artisticOpacity,
        luminanceData: luminanceData.values,
        depthMap: depthMap,
        contrastRatio: qualityMetrics.contrastRatio.toDouble(),
        dynamicRange: qualityMetrics.dynamicRange,
        artisticScore: qualityMetrics.artisticScore.toDouble(),
        processingTimeMs: stopwatch.elapsedMilliseconds,
      );

      return ProcessingResult.success(data: result);
    } catch (e) {
      return ProcessingResult.failure(
        error: 'Opacity map generation failed: $e'
      );
    }
  }

  /// Extracts luminance data with perceptual weighting for artistic analysis.
  static _LuminanceData _extractLuminanceData(img.Image image) {
    final width = image.width;
    final height = image.height;
    final luminance = Float32List(width * height);

    double minLum = 1.0, maxLum = 0.0, sumLum = 0.0;

    // Extract perceptually weighted luminance
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final pixel = image.getPixel(x, y);
        final index = y * width + x;

        // Use perceptual luminance formula (Rec. 709)
        final lum = (pixel.r * 0.2126 + pixel.g * 0.7152 + pixel.b * 0.0722) / 255.0;

        luminance[index] = lum;
        minLum = math.min(minLum, lum);
        maxLum = math.max(maxLum, lum);
        sumLum += lum;
      }
    }

    final avgLum = sumLum / (width * height);
    final dynamicRange = maxLum - minLum;

    return _LuminanceData(
      values: luminance,
      minLuminance: minLum,
      maxLuminance: maxLum,
      averageLuminance: avgLum,
      dynamicRange: dynamicRange,
    );
  }

  /// Calculates depth map for atmospheric perspective effects.
  static Float32List _calculateDepthMap(img.Image image, ThreadFlowField threadFlow) {
    final width = image.width;
    final height = image.height;
    final depthMap = Float32List(width * height);

    // Use multiple depth cues for sophisticated depth estimation
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final index = y * width + x;

        // Depth cue 1: Distance from camera (y-coordinate based)
        final perspectiveDepth = y / height;

        // Depth cue 2: Texture coherence (high coherence = closer)
        final textureDepth = 1.0 - threadFlow.getFlowCoherenceAt(x, y);

        // Depth cue 3: Color saturation (saturated = closer)
        final saturationDepth = _calculateSaturationBasedDepth(image, x, y);

        // Combine depth cues with weighted average
        final combinedDepth = (perspectiveDepth * 0.4 +
                              textureDepth * 0.3 +
                              saturationDepth * 0.3).clamp(0.0, 1.0);

        depthMap[index] = combinedDepth;
      }
    }

    return depthMap;
  }

  /// Generates base opacity from luminance and artistic requirements.
  static Float32List _generateBaseOpacity(
    _LuminanceData luminanceData,
    ThreadFlowField threadFlow,
    double baseDensity,
  ) {
    final width = threadFlow.width;
    final height = threadFlow.height;
    final baseOpacity = Float32List(width * height);

    for (int i = 0; i < width * height; i++) {
      final luminance = luminanceData.values[i];
      final artisticIntensity = threadFlow.artisticIntensity[i];
      final textureComplexity = threadFlow.textureComplexity[i];

      // Convert luminance to thread opacity (darker areas = more threads)
      final luminanceOpacity = 1.0 - luminance;

      // Apply artistic intensity modulation
      final artisticModulation = 0.8 + (artisticIntensity * 0.4);

      // Apply texture complexity (complex areas need more threads)
      final complexityModulation = 0.9 + (textureComplexity * 0.2);

      // Combine all factors
      final finalOpacity = luminanceOpacity * baseDensity *
                          artisticModulation * complexityModulation;

      baseOpacity[i] = finalOpacity.clamp(0.0, 1.0);
    }

    return baseOpacity;
  }

  /// Applies contrast enhancement for dramatic artistic effect.
  static Float32List _applyContrastEnhancement(
    Float32List baseOpacity,
    double contrastFactor,
    _LuminanceData luminanceData,
  ) {
    if (contrastFactor <= 1.0) return baseOpacity;

    final enhanced = Float32List(baseOpacity.length);
    final midPoint = 0.5;

    for (int i = 0; i < baseOpacity.length; i++) {
      final opacity = baseOpacity[i];
      final luminance = luminanceData.values[i];

      // Apply S-curve contrast enhancement
      final contrast = math.pow((opacity - midPoint) * contrastFactor + midPoint, 1.0);

      // Modulate by local luminance characteristics
      final luminanceFactor = 1.0 + (luminance - luminanceData.averageLuminance) * 0.3;

      enhanced[i] = (contrast * luminanceFactor).clamp(0.0, 1.0).toDouble();
    }

    return enhanced;
  }

  /// Applies atmospheric perspective for realistic depth perception.
  static Float32List _applyAtmosphericPerspective(
    Float32List opacity,
    Float32List depthMap,
    double atmosphericStrength,
  ) {
    final atmospheric = Float32List(opacity.length);

    for (int i = 0; i < opacity.length; i++) {
      final baseOpacity = opacity[i];
      final depth = depthMap[i];

      // Calculate atmospheric factor (distant objects are lighter)
      final atmosphericFactor = ArtisticMath.calculateAtmosphericFactor(depth, 1.0);

      // Apply atmospheric perspective
      final perspectiveAdjustment = 1.0 - (atmosphericStrength * (1.0 - atmosphericFactor));

      atmospheric[i] = (baseOpacity * perspectiveAdjustment).clamp(0.0, 1.0);
    }

    return atmospheric;
  }

  /// Adds artistic variation to prevent mechanical appearance.
  static Float32List _addArtisticVariation(
    Float32List opacity,
    ThreadFlowField threadFlow,
    _LuminanceData luminanceData,
  ) {
    final artistic = Float32List(opacity.length);
    final random = math.Random(123); // Deterministic seed

    for (int i = 0; i < opacity.length; i++) {
      final baseOpacity = opacity[i];
      final artisticIntensity = threadFlow.artisticIntensity[i];
      final coherence = threadFlow.flowCoherence[i];

      // Calculate variation strength based on artistic needs
      final variationStrength = artisticIntensity * (1.0 - coherence) * 0.15;

      // Generate artistic noise (more variation in artistic areas)
      final variation = (random.nextDouble() - 0.5) * 2 * variationStrength;

      // Apply golden ratio based micro-adjustments for natural rhythm
      final goldenRatioAdjustment = math.sin(i * 2.618) * 0.02 * artisticIntensity;

      final finalOpacity = baseOpacity + variation + goldenRatioAdjustment;
      artistic[i] = finalOpacity.clamp(0.0, 1.0);
    }

    return artistic;
  }

  /// Calculates saturation-based depth estimation.
  static double _calculateSaturationBasedDepth(img.Image image, int x, int y) {
    final pixel = image.getPixel(x, y);
    final r = pixel.r / 255.0;
    final g = pixel.g / 255.0;
    final b = pixel.b / 255.0;

    final maxVal = math.max(r, math.max(g, b));
    final minVal = math.min(r, math.min(g, b));

    final saturation = maxVal > 0 ? (maxVal - minVal) / maxVal : 0;

    // Higher saturation indicates closer objects
    return 1.0 - saturation;
  }

  /// Calculates opacity quality metrics for validation.
  static _OpacityQuality _calculateOpacityQuality(
    Float32List opacity,
    _LuminanceData luminanceData,
    ThreadFlowField threadFlow,
  ) {
    double minOp = 1.0, maxOp = 0.0;
    double contrastSum = 0.0;
    double artisticAlignmentSum = 0.0;
    int sampleCount = 0;

    // Sample opacity characteristics
    for (int i = 0; i < opacity.length; i++) {
      final op = opacity[i];
      minOp = math.min(minOp, op);
      maxOp = math.max(maxOp, op);

      // Calculate local contrast
      if (i > 0) {
        contrastSum += (op - opacity[i - 1]).abs();
      }

      // Calculate artistic alignment (opacity should follow artistic intensity)
      final artisticIntensity = threadFlow.artisticIntensity[i];
      final alignment = 1.0 - (op - artisticIntensity).abs();
      artisticAlignmentSum += alignment;
      sampleCount++;
    }

    final dynamicRange = maxOp - minOp;
    final contrastRatio = sampleCount > 1 ? contrastSum / (sampleCount - 1) : 0;
    final artisticScore = sampleCount > 0 ? (artisticAlignmentSum / sampleCount) * 100 : 0;

    return _OpacityQuality(
      contrastRatio: contrastRatio.toDouble(),
      dynamicRange: dynamicRange,
      artisticScore: artisticScore.toDouble(),
    );
  }
}

/// Result of adaptive opacity analysis containing thread density information.
class OpacityMap {
  const OpacityMap({
    required this.width,
    required this.height,
    required this.opacityValues,
    required this.luminanceData,
    required this.depthMap,
    required this.contrastRatio,
    required this.dynamicRange,
    required this.artisticScore,
    required this.processingTimeMs,
  });

  /// Width of the opacity map
  final int width;

  /// Height of the opacity map
  final int height;

  /// Thread opacity values (0.0 = transparent, 1.0 = full density)
  final Float32List opacityValues;

  /// Source luminance data for reference
  final Float32List luminanceData;

  /// Calculated depth map for atmospheric effects
  final Float32List depthMap;

  /// Local contrast ratio measurement
  final double contrastRatio;

  /// Dynamic range of opacity values (0.0-1.0)
  final double dynamicRange;

  /// Artistic quality score (0-100)
  final double artisticScore;

  /// Processing time in milliseconds
  final int processingTimeMs;

  /// Total number of opacity points
  int get pixelCount => width * height;

  /// Gets thread opacity at specified coordinates
  double getOpacityAt(int x, int y) {
    if (x < 0 || x >= width || y < 0 || y >= height) return 0.0;
    return opacityValues[y * width + x];
  }

  /// Gets luminance value at specified coordinates
  double getLuminanceAt(int x, int y) {
    if (x < 0 || x >= width || y < 0 || y >= height) return 0.0;
    return luminanceData[y * width + x];
  }

  /// Gets depth value at specified coordinates
  double getDepthAt(int x, int y) {
    if (x < 0 || x >= width || y < 0 || y >= height) return 0.0;
    return depthMap[y * width + x];
  }

  /// Calculates average opacity for quality assessment
  double get averageOpacity {
    double sum = 0;
    for (final opacity in opacityValues) {
      sum += opacity;
    }
    return sum / opacityValues.length;
  }

  @override
  String toString() => 'OpacityMap($width x $height, artistic: ${artisticScore.toStringAsFixed(1)})';
}

// Private helper classes
class _LuminanceData {
  const _LuminanceData({
    required this.values,
    required this.minLuminance,
    required this.maxLuminance,
    required this.averageLuminance,
    required this.dynamicRange,
  });

  final Float32List values;
  final double minLuminance;
  final double maxLuminance;
  final double averageLuminance;
  final double dynamicRange;
}

class _OpacityQuality {
  const _OpacityQuality({
    required this.contrastRatio,
    required this.dynamicRange,
    required this.artisticScore,
  });

  final double contrastRatio;
  final double dynamicRange;
  final double artisticScore;
}
