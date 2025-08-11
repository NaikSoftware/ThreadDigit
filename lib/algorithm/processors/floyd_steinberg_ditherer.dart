import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui';

import 'package:image/image.dart' as img;
import 'package:thread_digit/algorithm/models/dithering_result.dart';
import 'package:thread_digit/algorithm/models/processing_result.dart';

/// Floyd-Steinberg error diffusion dithering for smooth color transitions.
///
/// Implements the classic Floyd-Steinberg dithering algorithm with configurable
/// parameters for optimal embroidery color quantization.
class FloydSteinbergDitherer {
  /// Default dithering parameters optimized for embroidery
  static const defaultParameters = DitheringParameters();

  /// Applies Floyd-Steinberg dithering to quantize image colors.
  /// Returns dithered image with smooth color transitions and error analysis.
  static ProcessingResult<DitheringResult> dither(
    img.Image sourceImage,
    List<Color> palette, {
    DitheringParameters params = defaultParameters,
  }) {
    if (!params.isValid) {
      return const ProcessingResult.failure(
        error: 'Invalid dithering parameters',
      );
    }

    if (palette.isEmpty) {
      return const ProcessingResult.failure(
        error: 'Color palette cannot be empty',
      );
    }

    try {
      final stopwatch = Stopwatch()..start();

      // Count original colors (approximation)
      final originalColorCount = _estimateColorCount(sourceImage);

      // Create output image for dithering results
      final outputImage = img.Image(width: sourceImage.width, height: sourceImage.height);

      // Initialize error tracking
      final errorMap = Float32List(sourceImage.width * sourceImage.height);

      // Apply Floyd-Steinberg dithering
      _applyFloydSteinbergDithering(
        sourceImage,
        outputImage,
        palette,
        params,
        errorMap,
      );

      stopwatch.stop();

      final result = DitheringResult(
        ditheredImage: outputImage,
        errorMap: errorMap,
        originalColorCount: originalColorCount,
        quantizedColorCount: palette.length,
        processingTimeMs: stopwatch.elapsedMilliseconds,
        ditheringStrength: params.strength,
      );

      return ProcessingResult.success(data: result);
    } catch (e) {
      return ProcessingResult.failure(
        error: 'Floyd-Steinberg dithering failed: $e',
      );
    }
  }

  /// Applies Floyd-Steinberg error diffusion algorithm
  static void _applyFloydSteinbergDithering(
    img.Image sourceImage,
    img.Image outputImage,
    List<Color> palette,
    DitheringParameters params,
    Float32List errorMap,
  ) {
    final width = sourceImage.width;
    final height = sourceImage.height;

    // Error buffers for RGB channels
    final redError = Float32List((width + 2) * 2); // Two rows with padding
    final greenError = Float32List((width + 2) * 2);
    final blueError = Float32List((width + 2) * 2);

    for (int y = 0; y < height; y++) {
      final currentRow = y % 2;
      final nextRow = 1 - currentRow;

      // Clear next row errors
      for (int i = 0; i < width + 2; i++) {
        final nextIndex = nextRow * (width + 2) + i;
        redError[nextIndex] = 0;
        greenError[nextIndex] = 0;
        blueError[nextIndex] = 0;
      }

      // Process row (serpentine scanning if enabled)
      final startX = (params.serpentine && y % 2 == 1) ? width - 1 : 0;
      final endX = (params.serpentine && y % 2 == 1) ? -1 : width;
      final stepX = (params.serpentine && y % 2 == 1) ? -1 : 1;

      for (int x = startX; x != endX; x += stepX) {
        final currentIndex = currentRow * (width + 2) + (x + 1);

        // Get current pixel with accumulated error
        final pixel = sourceImage.getPixel(x, y);
        final currentRed = (pixel.r.toDouble() + redError[currentIndex]).clamp(0, 255);
        final currentGreen = (pixel.g.toDouble() + greenError[currentIndex]).clamp(0, 255);
        final currentBlue = (pixel.b.toDouble() + blueError[currentIndex]).clamp(0, 255);

        final currentColor = Color.fromARGB(255, currentRed.toInt(), currentGreen.toInt(), currentBlue.toInt());

        // Find closest color in palette
        final closestColor = _findClosestColor(currentColor, palette);

        // Set quantized pixel to output image
        outputImage.setPixel(x, y, img.ColorRgb8((closestColor.r * 255.0).round() & 0xff, (closestColor.g * 255.0).round() & 0xff, (closestColor.b * 255.0).round() & 0xff));

        // Calculate quantization error
        final errorRed = currentRed - ((closestColor.r * 255.0).round() & 0xff).toDouble();
        final errorGreen = currentGreen - ((closestColor.g * 255.0).round() & 0xff).toDouble();
        final errorBlue = currentBlue - ((closestColor.b * 255.0).round() & 0xff).toDouble();

        // Store total error for quality assessment (normalized to 0-1 range)
        final totalError = math.sqrt(errorRed * errorRed + errorGreen * errorGreen + errorBlue * errorBlue);
        const maxRgbDistance = 441.6729559300637; // sqrt(255^2 + 255^2 + 255^2)
        errorMap[y * width + x] = totalError / maxRgbDistance;

        // Distribute error using Floyd-Steinberg weights
        if (params.strength > 0) {
          _distributeError(
            x, y, width, height,
            errorRed, errorGreen, errorBlue,
            redError, greenError, blueError,
            params,
            stepX,
          );
        }
      }
    }
  }

  /// Distributes quantization error to neighboring pixels
  static void _distributeError(
    int x, int y, int width, int height,
    double errorRed, double errorGreen, double errorBlue,
    Float32List redError, Float32List greenError, Float32List blueError,
    DitheringParameters params,
    int stepX,
  ) {
    final currentRow = y % 2;
    final nextRow = 1 - currentRow;
    final strength = params.strength;

    // Floyd-Steinberg error distribution pattern:
    //       X   7/16
    // 3/16 5/16  1/16

    final weights = [
      (stepX, 0, 7.0 / 16.0),      // Right (or left in reverse)
      (-stepX, 1, 3.0 / 16.0),     // Bottom-left (or bottom-right in reverse)
      (0, 1, 5.0 / 16.0),          // Bottom
      (stepX, 1, 1.0 / 16.0),      // Bottom-right (or bottom-left in reverse)
    ];

    for (final (dx, dy, weight) in weights) {
      final nx = x + dx;
      final ny = y + dy;

      // Check bounds
      if (nx >= 0 && nx < width && ny >= 0 && ny < height) {
        final targetRow = (dy == 0) ? currentRow : nextRow;
        final targetIndex = targetRow * (width + 2) + (nx + 1);

        final weightedStrength = weight * strength;

        final distributedRed = errorRed * weightedStrength;
        final distributedGreen = errorGreen * weightedStrength;
        final distributedBlue = errorBlue * weightedStrength;

        if (params.errorClamp) {
          redError[targetIndex] = (redError[targetIndex] + distributedRed).clamp(-128, 127);
          greenError[targetIndex] = (greenError[targetIndex] + distributedGreen).clamp(-128, 127);
          blueError[targetIndex] = (blueError[targetIndex] + distributedBlue).clamp(-128, 127);
        } else {
          redError[targetIndex] += distributedRed;
          greenError[targetIndex] += distributedGreen;
          blueError[targetIndex] += distributedBlue;
        }
      }
    }
  }

  /// Finds the closest color in palette using Euclidean distance
  static Color _findClosestColor(Color targetColor, List<Color> palette) {
    if (palette.length == 1) return palette[0];

    double minDistance = double.infinity;
    Color closestColor = palette[0];

    for (final color in palette) {
      final distance = _colorDistance(targetColor, color);
      if (distance < minDistance) {
        minDistance = distance;
        closestColor = color;
      }
    }

    return closestColor;
  }

  /// Calculates weighted RGB color distance
  static double _colorDistance(Color color1, Color color2) {
    const double redWeight = 0.299;
    const double greenWeight = 0.587;
    const double blueWeight = 0.114;

    final dr = (color1.r * 255.0).round() & 0xff - (color2.r * 255.0).round() & 0xff;
    final dg = (color1.g * 255.0).round() & 0xff - (color2.g * 255.0).round() & 0xff;
    final db = (color1.b * 255.0).round() & 0xff - (color2.b * 255.0).round() & 0xff;

    return math.sqrt(
      redWeight * dr * dr +
      greenWeight * dg * dg +
      blueWeight * db * db
    );
  }

  /// Estimates number of unique colors in image (sampling-based)
  static int _estimateColorCount(img.Image image) {
    final colorSet = <int>{};
    final sampleRate = math.max(1, (image.width * image.height / 5000).ceil());

    for (int y = 0; y < image.height; y += sampleRate) {
      for (int x = 0; x < image.width; x += sampleRate) {
        final pixel = image.getPixel(x, y);
        final colorValue = (pixel.r.toInt() << 16) | (pixel.g.toInt() << 8) | pixel.b.toInt();
        colorSet.add(colorValue);

        // Limit sampling to prevent excessive memory usage
        if (colorSet.length > 10000) break;
      }
      if (colorSet.length > 10000) break;
    }

    return colorSet.length;
  }

  /// Validates that palette contains distinct colors
  static bool isValidPalette(List<Color> palette) {
    if (palette.isEmpty) return false;

    final uniqueColors = <int>{};
    for (final color in palette) {
      final colorValue = (((color.r * 255.0).round() & 0xff) << 16) | (((color.g * 255.0).round() & 0xff) << 8) | ((color.b * 255.0).round() & 0xff);
      uniqueColors.add(colorValue);
    }

    return uniqueColors.length == palette.length;
  }

  /// Creates a grayscale test pattern for dithering validation
  static img.Image createGradientTestPattern(int width, int height) {
    final image = img.Image(width: width, height: height);

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        // Horizontal gradient from black to white
        final intensity = (x * 255 / (width - 1)).round().clamp(0, 255);
        image.setPixel(x, y, img.ColorRgb8(intensity, intensity, intensity));
      }
    }

    return image;
  }

  /// Analyzes dithering quality by detecting banding artifacts
  static double analyzeBanding(DitheringResult result) {
    final image = result.ditheredImage;
    final width = image.width;
    final height = image.height;

    double bandingScore = 0;
    int sampleCount = 0;

    // Sample horizontal gradients to detect banding
    for (int y = height ~/ 4; y < 3 * height ~/ 4; y += 4) {
      for (int x = 1; x < width - 1; x++) {
        final leftPixel = image.getPixel(x - 1, y);
        final currentPixel = image.getPixel(x, y);
        final rightPixel = image.getPixel(x + 1, y);

        // Calculate local gradient variation
        final leftIntensity = (leftPixel.r + leftPixel.g + leftPixel.b) / 3;
        final currentIntensity = (currentPixel.r + currentPixel.g + currentPixel.b) / 3;
        final rightIntensity = (rightPixel.r + rightPixel.g + rightPixel.b) / 3;

        final gradient1 = (currentIntensity - leftIntensity).abs();
        final gradient2 = (rightIntensity - currentIntensity).abs();
        final gradientDiff = (gradient1 - gradient2).abs();

        bandingScore += gradientDiff;
        sampleCount++;
      }
    }

    return sampleCount > 0 ? bandingScore / sampleCount : 0;
  }
}
