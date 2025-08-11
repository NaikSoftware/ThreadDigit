import 'dart:math' as math;
import 'dart:typed_data';


import 'package:image/image.dart' as img;
import 'package:thread_digit/algorithm/models/direction_field.dart';
import 'package:thread_digit/algorithm/models/processing_result.dart';
import 'package:thread_digit/algorithm/utils/artistic_math.dart';

/// Advanced thread flow analysis for photorealistic embroidery generation.
///
/// Analyzes image structure to determine optimal thread directions that follow
/// natural patterns like hair, fabric grain, and organic textures for silk
/// shading and artistic embroidery techniques.
class ThreadFlowAnalyzer {
  /// Default parameters optimized for photorealistic results
  static const _defaultSmoothing = 0.7;

  static const _defaultArtisticVariation = 0.15;

  /// Analyzes image and generates sophisticated thread flow directions.
  ///
  /// [image] - Source image for analysis
  /// [directionField] - Pre-computed structure tensor directions
  /// [smoothingFactor] - Controls flow field smoothing (0.0-1.0)
  /// [artisticVariation] - Amount of natural variation to add (0.0-1.0)
  static ProcessingResult<ThreadFlowField> analyzeThreadFlow(
    img.Image image,
    DirectionField directionField, {
    double smoothingFactor = _defaultSmoothing,
    double artisticVariation = _defaultArtisticVariation,
  }) {
    try {
      final width = image.width;
      final height = image.height;

      // Validate input dimensions match
      if (width != directionField.width || height != directionField.height) {
        return const ProcessingResult.failure(
          error: 'Image and direction field dimensions must match'
        );
      }

      final stopwatch = Stopwatch()..start();

      // Step 1: Analyze local texture characteristics
      final textureAnalysis = _analyzeTextureCharacteristics(image, directionField);

      // Step 2: Generate primary flow directions with artistic enhancement
      final primaryFlow = _generateArtisticFlowField(
        directionField,
        textureAnalysis,
        smoothingFactor,
        artisticVariation,
      );

      // Step 3: Create secondary flow for layered silk shading
      final secondaryFlow = _generateSecondaryFlow(primaryFlow, directionField);

      // Step 4: Calculate flow confidence and quality metrics
      final flowQuality = _calculateFlowQuality(primaryFlow, directionField);

      stopwatch.stop();

      final result = ThreadFlowField(
        width: width,
        height: height,
        primaryDirections: primaryFlow.directions,
        secondaryDirections: secondaryFlow.directions,
        flowCoherence: primaryFlow.coherence,
        textureComplexity: textureAnalysis.complexity,
        artisticIntensity: textureAnalysis.artisticIntensity,
        qualityScore: flowQuality.overallScore,
        processingTimeMs: stopwatch.elapsedMilliseconds,
      );

      return ProcessingResult.success(data: result);
    } catch (e) {
      return ProcessingResult.failure(
        error: 'Thread flow analysis failed: $e'
      );
    }
  }

  /// Analyzes texture characteristics for artistic treatment decisions.
  static _TextureAnalysis _analyzeTextureCharacteristics(
    img.Image image,
    DirectionField directionField,
  ) {
    final width = image.width;
    final height = image.height;

    final complexity = Float32List(width * height);
    final artisticIntensity = Float32List(width * height);

    // Analyze local neighborhoods for texture properties
    for (int y = 1; y < height - 1; y++) {
      for (int x = 1; x < width - 1; x++) {
        final index = y * width + x;

        // Calculate local gradient magnitude for complexity
        final gradientMag = _calculateLocalGradientMagnitude(image, x, y);

        // Calculate color variation in neighborhood
        final colorVariation = _calculateLocalColorVariation(image, x, y);

        // Get texture coherence from direction field
        final coherence = directionField.getCoherence(x, y);

        // Combine factors for texture complexity
        complexity[index] = (gradientMag * 0.4 + colorVariation * 0.3 +
                            (1.0 - coherence) * 0.3).clamp(0.0, 1.0);

        // Calculate artistic treatment intensity
        artisticIntensity[index] = ArtisticMath.calculateSilkShadingIntensity(
          gradientMag,
          coherence,
          colorVariation,
        );
      }
    }

    return _TextureAnalysis(
      complexity: complexity,
      artisticIntensity: artisticIntensity,
    );
  }

  /// Generates artistic flow field with natural variation.
  static _FlowFieldResult _generateArtisticFlowField(
    DirectionField directionField,
    _TextureAnalysis textureAnalysis,
    double smoothingFactor,
    double artisticVariation,
  ) {
    final width = directionField.width;
    final height = directionField.height;

    final directions = Float32List(width * height);
    final coherence = Float32List(width * height);
    final random = math.Random(42); // Deterministic for consistency

    // Generate flow directions with artistic enhancement
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final index = y * width + x;

        // Get base direction from structure tensor
        final baseDirection = directionField.getOrientation(x, y);
        final baseCoherence = directionField.getCoherence(x, y);

        // Apply artistic variation based on texture complexity
        final complexityFactor = textureAnalysis.complexity[index];
        final variationStrength = artisticVariation * (1.0 - complexityFactor);

        final artisticDirection = ArtisticMath.addArtisticVariation(
          baseDirection,
          variationStrength,
          random,
        );

        // Apply smoothing with neighboring directions
        final smoothedDirection = _applySmoothingFilter(
          directionField,
          x,
          y,
          artisticDirection,
          smoothingFactor,
        );

        directions[index] = smoothedDirection;
        coherence[index] = baseCoherence * (1.0 - variationStrength * 0.3);
      }
    }

    return _FlowFieldResult(
      directions: directions,
      coherence: coherence,
    );
  }

  /// Generates secondary flow for layered silk shading effects.
  static _FlowFieldResult _generateSecondaryFlow(
    _FlowFieldResult primaryFlow,
    DirectionField directionField,
  ) {
    final width = directionField.width;
    final height = directionField.height;

    final secondaryDirections = Float32List(width * height);
    final secondaryCoherence = Float32List(width * height);

    // Create perpendicular flow for cross-hatching effects
    for (int i = 0; i < width * height; i++) {
      // Secondary flow is perpendicular to primary (±90°)
      secondaryDirections[i] = primaryFlow.directions[i] + math.pi / 2;

      // Secondary flow has reduced coherence for subtle effect
      secondaryCoherence[i] = primaryFlow.coherence[i] * 0.6;
    }

    return _FlowFieldResult(
      directions: secondaryDirections,
      coherence: secondaryCoherence,
    );
  }

  /// Calculates flow quality metrics for validation.
  static _FlowQuality _calculateFlowQuality(
    _FlowFieldResult flow,
    DirectionField directionField,
  ) {
    final width = directionField.width;
    final height = directionField.height;

    double coherenceSum = 0;
    double directionConsistency = 0;
    int validSamples = 0;

    // Sample flow quality across the field
    for (int y = 1; y < height - 1; y += 2) {
      for (int x = 1; x < width - 1; x += 2) {
        final index = y * width + x;

        coherenceSum += flow.coherence[index];

        // Check direction consistency with neighbors
        final consistency = _calculateLocalDirectionConsistency(
          flow.directions,
          width,
          x,
          y,
        );
        directionConsistency += consistency;
        validSamples++;
      }
    }

    final avgCoherence = validSamples > 0 ? coherenceSum / validSamples : 0;
    final avgConsistency = validSamples > 0 ? directionConsistency / validSamples : 0;

    final overallScore = (avgCoherence * 0.6 + avgConsistency * 0.4) * 100;

    return _FlowQuality(
      averageCoherence: avgCoherence.toDouble(),
      directionConsistency: avgConsistency.toDouble(),
      overallScore: overallScore,
    );
  }

  /// Calculates local gradient magnitude for texture analysis.
  static double _calculateLocalGradientMagnitude(img.Image image, int x, int y) {
    final currentPixel = image.getPixel(x, y);
    final rightPixel = image.getPixel(x + 1, y);
    final bottomPixel = image.getPixel(x, y + 1);

    // Calculate gradient in both directions
    final dx = _getGrayValue(rightPixel) - _getGrayValue(currentPixel);
    final dy = _getGrayValue(bottomPixel) - _getGrayValue(currentPixel);

    return ArtisticMath.calculateGradientMagnitude(dx, dy) / 255.0;
  }

  /// Calculates local color variation for artistic analysis.
  static double _calculateLocalColorVariation(img.Image image, int x, int y) {
    final centerPixel = image.getPixel(x, y);
    double maxVariation = 0;

    // Check 3x3 neighborhood
    for (int dy = -1; dy <= 1; dy++) {
      for (int dx = -1; dx <= 1; dx++) {
        if (dx == 0 && dy == 0) continue;

        final nx = (x + dx).clamp(0, image.width - 1);
        final ny = (y + dy).clamp(0, image.height - 1);
        final neighborPixel = image.getPixel(nx, ny);

        // Calculate color distance
        final dr = centerPixel.r - neighborPixel.r;
        final dg = centerPixel.g - neighborPixel.g;
        final db = centerPixel.b - neighborPixel.b;
        final distance = math.sqrt(dr * dr + dg * dg + db * db);

        maxVariation = math.max(maxVariation, distance);
      }
    }

    return (maxVariation / 441.67).clamp(0.0, 1.0); // Normalize by max RGB distance
  }

  /// Applies smoothing filter to direction field.
  static double _applySmoothingFilter(
    DirectionField directionField,
    int x,
    int y,
    double centerDirection,
    double smoothingFactor,
  ) {
    if (smoothingFactor <= 0) return centerDirection;

    double sumX = 0, sumY = 0;
    double weightSum = 0;

    // Gaussian-like smoothing kernel
    final kernelSize = (smoothingFactor * 3).round().clamp(1, 3);

    for (int dy = -kernelSize; dy <= kernelSize; dy++) {
      for (int dx = -kernelSize; dx <= kernelSize; dx++) {
        final nx = (x + dx).clamp(0, directionField.width - 1);
        final ny = (y + dy).clamp(0, directionField.height - 1);

        final direction = (dx == 0 && dy == 0) ?
            centerDirection : directionField.getOrientation(nx, ny);
        final coherence = directionField.getCoherence(nx, ny);

        // Weight by coherence and distance
        final distance = math.sqrt(dx * dx + dy * dy);
        final weight = coherence * math.exp(-distance * distance / 2.0);

        sumX += math.cos(direction) * weight;
        sumY += math.sin(direction) * weight;
        weightSum += weight;
      }
    }

    if (weightSum > 0) {
      return math.atan2(sumY / weightSum, sumX / weightSum);
    }

    return centerDirection;
  }

  /// Calculates direction consistency in local neighborhood.
  static double _calculateLocalDirectionConsistency(
    Float32List directions,
    int width,
    int x,
    int y,
  ) {
    final centerIndex = y * width + x;
    final centerDirection = directions[centerIndex];

    double consistencySum = 0;
    int neighbors = 0;

    // Check 3x3 neighborhood
    for (int dy = -1; dy <= 1; dy++) {
      for (int dx = -1; dx <= 1; dx++) {
        if (dx == 0 && dy == 0) continue;

        final neighborIndex = (y + dy) * width + (x + dx);
        if (neighborIndex >= 0 && neighborIndex < directions.length) {
          final neighborDirection = directions[neighborIndex];

          // Calculate angular difference
          final angleDiff = _normalizeAngle(neighborDirection - centerDirection).abs();
          final consistency = 1.0 - (angleDiff / math.pi);

          consistencySum += consistency;
          neighbors++;
        }
      }
    }

    return neighbors > 0 ? consistencySum / neighbors : 0;
  }

  /// Converts pixel to grayscale value.
  static double _getGrayValue(img.Color pixel) {
    return pixel.r * 0.299 + pixel.g * 0.587 + pixel.b * 0.114;
  }

  /// Normalizes angle to [-π, π] range.
  static double _normalizeAngle(double angle) {
    double normalized = angle % (2 * math.pi);
    if (normalized > math.pi) {
      normalized -= 2 * math.pi;
    } else if (normalized < -math.pi) {
      normalized += 2 * math.pi;
    }
    return normalized;
  }
}

/// Result of thread flow analysis containing directional information for artistic embroidery.
class ThreadFlowField {
  const ThreadFlowField({
    required this.width,
    required this.height,
    required this.primaryDirections,
    required this.secondaryDirections,
    required this.flowCoherence,
    required this.textureComplexity,
    required this.artisticIntensity,
    required this.qualityScore,
    required this.processingTimeMs,
  });

  /// Width of the flow field
  final int width;

  /// Height of the flow field
  final int height;

  /// Primary thread directions for main silk shading strokes
  final Float32List primaryDirections;

  /// Secondary thread directions for layering and cross-hatching
  final Float32List secondaryDirections;

  /// Flow coherence strength at each point (0.0-1.0)
  final Float32List flowCoherence;

  /// Local texture complexity requiring artistic treatment (0.0-1.0)
  final Float32List textureComplexity;

  /// Recommended artistic intensity for silk shading (0.0-1.0)
  final Float32List artisticIntensity;

  /// Overall flow quality score (0-100)
  final double qualityScore;

  /// Processing time in milliseconds
  final int processingTimeMs;

  /// Total number of flow points
  int get pixelCount => width * height;

  /// Gets primary thread direction at specified coordinates
  double getPrimaryDirectionAt(int x, int y) {
    if (x < 0 || x >= width || y < 0 || y >= height) return 0.0;
    return primaryDirections[y * width + x];
  }

  /// Gets secondary thread direction at specified coordinates
  double getSecondaryDirectionAt(int x, int y) {
    if (x < 0 || x >= width || y < 0 || y >= height) return 0.0;
    return secondaryDirections[y * width + x];
  }

  /// Gets flow coherence at specified coordinates
  double getFlowCoherenceAt(int x, int y) {
    if (x < 0 || x >= width || y < 0 || y >= height) return 0.0;
    return flowCoherence[y * width + x];
  }

  /// Gets texture complexity at specified coordinates
  double getTextureComplexityAt(int x, int y) {
    if (x < 0 || x >= width || y < 0 || y >= height) return 0.0;
    return textureComplexity[y * width + x];
  }

  /// Gets artistic intensity recommendation at specified coordinates
  double getArtisticIntensityAt(int x, int y) {
    if (x < 0 || x >= width || y < 0 || y >= height) return 0.0;
    return artisticIntensity[y * width + x];
  }

  @override
  String toString() => 'ThreadFlowField($width x $height, quality: ${qualityScore.toStringAsFixed(1)})';
}

// Private helper classes
class _TextureAnalysis {
  const _TextureAnalysis({
    required this.complexity,
    required this.artisticIntensity,
  });

  final Float32List complexity;
  final Float32List artisticIntensity;
}

class _FlowFieldResult {
  const _FlowFieldResult({
    required this.directions,
    required this.coherence,
  });

  final Float32List directions;
  final Float32List coherence;
}

class _FlowQuality {
  const _FlowQuality({
    required this.averageCoherence,
    required this.directionConsistency,
    required this.overallScore,
  });

  final double averageCoherence;
  final double directionConsistency;
  final double overallScore;
}
