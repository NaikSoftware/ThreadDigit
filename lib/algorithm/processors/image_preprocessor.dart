/// Image preprocessing for embroidery algorithm optimization.
///
/// Handles resizing, noise filtering, and contrast enhancement to prepare
/// images for optimal texture analysis and stitch generation.
library;

import 'dart:math' as math;

import 'package:image/image.dart' as img;
import 'package:thread_digit/algorithm/models/processing_result.dart';

/// Parameters for image preprocessing operations.
class PreprocessingParameters {
  /// Creates preprocessing parameters with specified values.
  const PreprocessingParameters({
    this.maxDimension = 1024,
    this.spatialSigma = 5.0,
    this.rangeSigma = 0.1,
    this.contrastFactor = 1.2,
    this.preserveAspectRatio = true,
  });

  /// Maximum dimension (width or height) for resized image.
  final int maxDimension;

  /// Spatial sigma for bilateral filtering (edge preservation).
  final double spatialSigma;

  /// Range sigma for bilateral filtering (intensity similarity).
  final double rangeSigma;

  /// Contrast enhancement factor (1.0 = no change).
  final double contrastFactor;

  /// Whether to maintain original aspect ratio during resize.
  final bool preserveAspectRatio;

  /// Validates parameters are within acceptable ranges.
  bool get isValid {
    return maxDimension > 32 && maxDimension <= 4096 && spatialSigma > 0 && rangeSigma > 0 && contrastFactor > 0;
  }
}

/// Preprocesses images for optimal embroidery algorithm performance.
class ImagePreprocessor {
  /// Default preprocessing parameters optimized for embroidery.
  static const defaultParameters = PreprocessingParameters();

  /// Preprocesses an image with the specified parameters.
  /// Returns a ProcessingResult containing the processed image or error.
  static ProcessingResult<img.Image> process(
    img.Image input,
    PreprocessingParameters params,
  ) {
    if (!params.isValid) {
      return const ProcessingResult.failure(
        error: 'Invalid preprocessing parameters',
      );
    }

    try {
      // Step 1: Resize image maintaining aspect ratio
      final resized = _resizeImage(input, params);

      // Step 2: Apply bilateral filtering for noise reduction
      final filtered = _applyBilateralFilter(resized, params);

      // Step 3: Enhance contrast while preserving details
      final enhanced = _enhanceContrast(filtered, params);

      return ProcessingResult.success(data: enhanced);
    } catch (e) {
      return ProcessingResult.failure(
        error: 'Preprocessing failed: $e',
      );
    }
  }

  /// Resizes image maintaining aspect ratio within maximum dimension.
  static img.Image _resizeImage(
    img.Image input,
    PreprocessingParameters params,
  ) {
    final maxDim = params.maxDimension;

    // Calculate new dimensions
    int newWidth, newHeight;
    if (input.width > input.height) {
      newWidth = math.min(input.width, maxDim);
      newHeight = params.preserveAspectRatio ? (input.height * newWidth / input.width).round() : maxDim;
    } else {
      newHeight = math.min(input.height, maxDim);
      newWidth = params.preserveAspectRatio ? (input.width * newHeight / input.height).round() : maxDim;
    }

    // Only resize if dimensions changed
    if (newWidth != input.width || newHeight != input.height) {
      return img.copyResize(input, width: newWidth, height: newHeight);
    }

    return input;
  }

  /// Applies bilateral filtering for noise reduction while preserving edges.
  static img.Image _applyBilateralFilter(
    img.Image input,
    PreprocessingParameters params,
  ) {
    // Create output image
    final output = img.Image.from(input);

    final spatialSigma = params.spatialSigma;
    final rangeSigma = params.rangeSigma;
    final kernelRadius = (spatialSigma * 3).round();

    // Apply bilateral filter
    for (int y = 0; y < input.height; y++) {
      for (int x = 0; x < input.width; x++) {
        final filtered = _bilateralFilterPixel(
          input,
          x,
          y,
          kernelRadius,
          spatialSigma,
          rangeSigma,
        );
        output.setPixel(x, y, filtered);
      }
    }

    return output;
  }

  /// Applies bilateral filter to a single pixel.
  static img.Color _bilateralFilterPixel(
    img.Image input,
    int centerX,
    int centerY,
    int radius,
    double spatialSigma,
    double rangeSigma,
  ) {
    final centerPixel = input.getPixel(centerX, centerY);
    final centerR = centerPixel.r;
    final centerG = centerPixel.g;
    final centerB = centerPixel.b;

    double weightSum = 0;
    double rSum = 0, gSum = 0, bSum = 0;

    final spatialFactor = -0.5 / (spatialSigma * spatialSigma);
    final rangeFactor = -0.5 / (rangeSigma * rangeSigma);

    for (int dy = -radius; dy <= radius; dy++) {
      for (int dx = -radius; dx <= radius; dx++) {
        final x = centerX + dx;
        final y = centerY + dy;

        if (x >= 0 && x < input.width && y >= 0 && y < input.height) {
          final pixel = input.getPixel(x, y);
          final r = pixel.r;
          final g = pixel.g;
          final b = pixel.b;

          // Spatial weight based on distance
          final spatialDist = dx * dx + dy * dy;
          final spatialWeight = math.exp(spatialDist * spatialFactor);

          // Range weight based on intensity difference
          final intensityDiff = math.pow(r - centerR, 2) + math.pow(g - centerG, 2) + math.pow(b - centerB, 2);
          final rangeWeight = math.exp(intensityDiff * rangeFactor);

          final weight = spatialWeight * rangeWeight;
          weightSum += weight;

          rSum += r * weight;
          gSum += g * weight;
          bSum += b * weight;
        }
      }
    }

    if (weightSum > 0) {
      return img.ColorRgb8(
        (rSum / weightSum).round().clamp(0, 255),
        (gSum / weightSum).round().clamp(0, 255),
        (bSum / weightSum).round().clamp(0, 255),
      );
    }

    return centerPixel;
  }

  /// Enhances contrast while preserving detail information.
  static img.Image _enhanceContrast(
    img.Image input,
    PreprocessingParameters params,
  ) {
    if (params.contrastFactor == 1.0) return input;

    final output = img.Image.from(input);
    final factor = params.contrastFactor;

    for (int y = 0; y < input.height; y++) {
      for (int x = 0; x < input.width; x++) {
        final pixel = input.getPixel(x, y);
        final r = pixel.r;
        final g = pixel.g;
        final b = pixel.b;

        // Apply contrast enhancement: newValue = (oldValue - 128) * factor + 128
        final newR = ((r - 128) * factor + 128).round().clamp(0, 255);
        final newG = ((g - 128) * factor + 128).round().clamp(0, 255);
        final newB = ((b - 128) * factor + 128).round().clamp(0, 255);

        output.setPixel(x, y, img.ColorRgb8(newR, newG, newB));
      }
    }

    return output;
  }

  /// Estimates processing time based on image dimensions.
  /// Returns estimated seconds for mobile processing.
  static double estimateProcessingTime(img.Image image) {
    final pixelCount = image.width * image.height;
    // Rough estimate: 0.1 microseconds per pixel on mobile
    return pixelCount * 0.0000001;
  }

  /// Calculates appropriate parameters based on image characteristics.
  static PreprocessingParameters getOptimalParameters(img.Image image) {
    // Adjust parameters based on image size and characteristics
    final pixelCount = image.width * image.height;

    // Reduce spatial sigma for smaller images
    final spatialSigma = pixelCount < 100000 ? 3.0 : 5.0;

    // Adjust max dimension based on available processing power
    final maxDimension = pixelCount > 2000000 ? 1024 : 1536;

    return PreprocessingParameters(
      maxDimension: maxDimension,
      spatialSigma: spatialSigma,
      rangeSigma: 0.1,
      contrastFactor: 1.2,
      preserveAspectRatio: true,
    );
  }
}
