/// Gradient computation for directional analysis in embroidery algorithm.
///
/// Computes gradient magnitude and direction maps using Sobel operators
/// with smoothing filters for coherent gradient fields.
library;

import 'dart:math' as math;

import 'package:image/image.dart' as img;
import 'package:thread_digit/algorithm/models/processing_result.dart';

/// Parameters for gradient computation operations.
class GradientParameters {
  /// Creates gradient parameters with specified values.
  const GradientParameters({
    this.sobelKernelSize = 3,
    this.smoothingSigma = 2.0,
    this.normalizeGradients = true,
  });

  /// Size of Sobel kernels (3 or 5).
  final int sobelKernelSize;

  /// Gaussian sigma for gradient smoothing.
  final double smoothingSigma;

  /// Whether to normalize gradient magnitudes to 0-1 range.
  final bool normalizeGradients;

  /// Validates parameters are within acceptable ranges.
  bool get isValid {
    return (sobelKernelSize == 3 || sobelKernelSize == 5) && smoothingSigma > 0;
  }
}

/// Result of gradient computation containing magnitude and direction data.
class GradientResult {
  /// Creates gradient result with magnitude and direction maps.
  const GradientResult({
    required this.width,
    required this.height,
    required this.magnitudes,
    required this.directions,
    required this.maxMagnitude,
  });

  /// Width of the gradient field.
  final int width;

  /// Height of the gradient field.
  final int height;

  /// Gradient magnitudes for each pixel (0.0-1.0 if normalized).
  final List<double> magnitudes;

  /// Gradient directions in radians for each pixel (-π to π).
  final List<double> directions;

  /// Maximum gradient magnitude before normalization.
  final double maxMagnitude;

  /// Gets gradient magnitude at specified coordinates.
  double getMagnitude(int x, int y) {
    if (x < 0 || x >= width || y < 0 || y >= height) return 0.0;
    return magnitudes[y * width + x];
  }

  /// Gets gradient direction at specified coordinates.
  double getDirection(int x, int y) {
    if (x < 0 || x >= width || y < 0 || y >= height) return 0.0;
    return directions[y * width + x];
  }

  /// Gets gradient vector at specified coordinates.
  math.Point<double> getGradientVector(int x, int y) {
    final magnitude = getMagnitude(x, y);
    final direction = getDirection(x, y);
    return math.Point(
      magnitude * math.cos(direction),
      magnitude * math.sin(direction),
    );
  }

  /// Calculates average gradient magnitude across the field.
  double get averageMagnitude {
    if (magnitudes.isEmpty) return 0.0;
    return magnitudes.reduce((a, b) => a + b) / magnitudes.length;
  }
}

/// Computes image gradients for directional analysis.
class GradientComputer {
  /// Default gradient computation parameters.
  static const defaultParameters = GradientParameters();

  /// Computes gradients for the input image.
  /// Returns a ProcessingResult containing gradient data or error.
  static ProcessingResult<GradientResult> computeGradients(
    img.Image input,
    GradientParameters params,
  ) {
    if (!params.isValid) {
      return const ProcessingResult.failure(
        error: 'Invalid gradient parameters',
      );
    }

    try {
      // Step 1: Convert to grayscale if needed
      final grayscale = input.numChannels > 1 ? img.grayscale(input) : input;

      // Step 2: Compute raw gradients using Sobel operators
      final rawGradients = _computeRawGradients(grayscale, params.sobelKernelSize);

      // Step 3: Apply smoothing to create coherent gradient fields
      final smoothed = _applySmoothingFilter(rawGradients, params.smoothingSigma);

      // Step 4: Normalize if requested
      final result = params.normalizeGradients ? _normalizeGradients(smoothed) : smoothed;

      return ProcessingResult.success(data: result);
    } catch (e) {
      return ProcessingResult.failure(
        error: 'Gradient computation failed: $e',
      );
    }
  }

  /// Computes raw gradients using Sobel operators.
  static GradientResult _computeRawGradients(img.Image input, int kernelSize) {
    final width = input.width;
    final height = input.height;
    final magnitudes = List<double>.filled(width * height, 0.0);
    final directions = List<double>.filled(width * height, 0.0);

    // Sobel kernels
    List<int> sobelX, sobelY;

    if (kernelSize == 3) {
      sobelX = [-1, 0, 1, -2, 0, 2, -1, 0, 1];
      sobelY = [-1, -2, -1, 0, 0, 0, 1, 2, 1];
    } else {
      // 5x5 Sobel kernels
      sobelX = [-1, -2, 0, 2, 1, -4, -6, 0, 6, 4, -6, -12, 0, 12, 6, -4, -6, 0, 6, 4, -1, -2, 0, 2, 1];
      sobelY = [-1, -4, -6, -4, -1, -2, -6, -12, -6, -2, 0, 0, 0, 0, 0, 2, 6, 12, 6, 2, 1, 4, 6, 4, 1];
    }

    final offset = kernelSize ~/ 2;
    double maxMagnitude = 0.0;

    // Apply Sobel operators
    for (int y = offset; y < height - offset; y++) {
      for (int x = offset; x < width - offset; x++) {
        double gx = 0.0, gy = 0.0;

        // Convolve with Sobel kernels
        for (int ky = 0; ky < kernelSize; ky++) {
          for (int kx = 0; kx < kernelSize; kx++) {
            final px = x + kx - offset;
            final py = y + ky - offset;
            final intensity = img.getLuminance(input.getPixel(px, py));

            final kernelIndex = ky * kernelSize + kx;
            gx += intensity * sobelX[kernelIndex];
            gy += intensity * sobelY[kernelIndex];
          }
        }

        final magnitude = math.sqrt(gx * gx + gy * gy);
        final direction = math.atan2(gy, gx);

        if (magnitude > maxMagnitude) {
          maxMagnitude = magnitude;
        }

        final index = y * width + x;
        magnitudes[index] = magnitude;
        directions[index] = direction;
      }
    }

    return GradientResult(
      width: width,
      height: height,
      magnitudes: magnitudes,
      directions: directions,
      maxMagnitude: maxMagnitude,
    );
  }

  /// Applies Gaussian smoothing to gradient fields for coherence.
  static GradientResult _applySmoothingFilter(GradientResult input, double sigma) {
    final kernelSize = (sigma * 6).round() | 1; // Ensure odd size
    final kernel = _generateGaussianKernel(kernelSize, sigma);

    final smoothedMagnitudes = _applyGaussianToField(
      input.magnitudes,
      input.width,
      input.height,
      kernel,
      kernelSize,
    );

    // Smooth directions using complex exponentials to handle wraparound
    final complexReal = List<double>.generate(
      input.directions.length,
      (i) => math.cos(input.directions[i]),
    );
    final complexImag = List<double>.generate(
      input.directions.length,
      (i) => math.sin(input.directions[i]),
    );

    final smoothedReal = _applyGaussianToField(
      complexReal,
      input.width,
      input.height,
      kernel,
      kernelSize,
    );
    final smoothedImag = _applyGaussianToField(
      complexImag,
      input.width,
      input.height,
      kernel,
      kernelSize,
    );

    final smoothedDirections = List<double>.generate(
      smoothedReal.length,
      (i) => math.atan2(smoothedImag[i], smoothedReal[i]),
    );

    return GradientResult(
      width: input.width,
      height: input.height,
      magnitudes: smoothedMagnitudes,
      directions: smoothedDirections,
      maxMagnitude: input.maxMagnitude,
    );
  }

  /// Generates Gaussian kernel for smoothing operations.
  static List<double> _generateGaussianKernel(int size, double sigma) {
    final kernel = List<double>.filled(size * size, 0.0);
    final center = size ~/ 2;
    double sum = 0.0;

    for (int y = 0; y < size; y++) {
      for (int x = 0; x < size; x++) {
        final dx = x - center;
        final dy = y - center;
        final value = math.exp(-(dx * dx + dy * dy) / (2 * sigma * sigma));
        kernel[y * size + x] = value;
        sum += value;
      }
    }

    // Normalize kernel
    for (int i = 0; i < kernel.length; i++) {
      kernel[i] /= sum;
    }

    return kernel;
  }

  /// Applies Gaussian filter to a 2D field.
  static List<double> _applyGaussianToField(
    List<double> field,
    int width,
    int height,
    List<double> kernel,
    int kernelSize,
  ) {
    final output = List<double>.filled(field.length, 0.0);
    final offset = kernelSize ~/ 2;

    for (int y = offset; y < height - offset; y++) {
      for (int x = offset; x < width - offset; x++) {
        double sum = 0.0;

        for (int ky = 0; ky < kernelSize; ky++) {
          for (int kx = 0; kx < kernelSize; kx++) {
            final px = x + kx - offset;
            final py = y + ky - offset;
            final fieldValue = field[py * width + px];
            final kernelValue = kernel[ky * kernelSize + kx];
            sum += fieldValue * kernelValue;
          }
        }

        output[y * width + x] = sum;
      }
    }

    return output;
  }

  /// Normalizes gradient magnitudes to 0-1 range.
  static GradientResult _normalizeGradients(GradientResult input) {
    if (input.maxMagnitude == 0.0) return input;

    final normalizedMagnitudes = input.magnitudes.map((magnitude) => magnitude / input.maxMagnitude).toList();

    return GradientResult(
      width: input.width,
      height: input.height,
      magnitudes: normalizedMagnitudes,
      directions: input.directions,
      maxMagnitude: input.maxMagnitude,
    );
  }

  /// Creates a visualization image of gradient magnitudes.
  static img.Image visualizeMagnitudes(GradientResult gradients) {
    final output = img.Image(width: gradients.width, height: gradients.height);

    for (int y = 0; y < gradients.height; y++) {
      for (int x = 0; x < gradients.width; x++) {
        final magnitude = gradients.getMagnitude(x, y);
        final intensity = (magnitude * 255).round().clamp(0, 255);
        output.setPixel(x, y, img.ColorRgb8(intensity, intensity, intensity));
      }
    }

    return output;
  }

  /// Creates a visualization image of gradient directions.
  static img.Image visualizeDirections(GradientResult gradients) {
    final output = img.Image(width: gradients.width, height: gradients.height);

    for (int y = 0; y < gradients.height; y++) {
      for (int x = 0; x < gradients.width; x++) {
        final direction = gradients.getDirection(x, y);
        final magnitude = gradients.getMagnitude(x, y);

        if (magnitude > 0.1) {
          // Color-code direction: red=0°, green=90°, blue=180°
          final normalizedAngle = (direction + math.pi) / (2 * math.pi);
          final hue = (normalizedAngle * 360).round() % 360;

          // Convert HSV to RGB for direction visualization
          final rgb = _hsvToRgb(hue, 1.0, magnitude);
          output.setPixel(x, y, img.ColorRgb8(rgb[0], rgb[1], rgb[2]));
        } else {
          output.setPixel(x, y, img.ColorRgb8(0, 0, 0));
        }
      }
    }

    return output;
  }

  /// Converts HSV color to RGB.
  static List<int> _hsvToRgb(int h, double s, double v) {
    final c = v * s;
    final x = c * (1 - ((h / 60) % 2 - 1).abs());
    final m = v - c;

    double r, g, b;
    if (h < 60) {
      r = c;
      g = x;
      b = 0;
    } else if (h < 120) {
      r = x;
      g = c;
      b = 0;
    } else if (h < 180) {
      r = 0;
      g = c;
      b = x;
    } else if (h < 240) {
      r = 0;
      g = x;
      b = c;
    } else if (h < 300) {
      r = x;
      g = 0;
      b = c;
    } else {
      r = c;
      g = 0;
      b = x;
    }

    return [
      ((r + m) * 255).round().clamp(0, 255),
      ((g + m) * 255).round().clamp(0, 255),
      ((b + m) * 255).round().clamp(0, 255),
    ];
  }
}
