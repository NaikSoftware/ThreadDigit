/// Edge detection algorithms for embroidery texture analysis.
///
/// Implements Canny edge detection with Sobel operators to identify
/// texture boundaries and structural features for stitch generation.
library;

import 'dart:math' as math;

import 'package:image/image.dart' as img;
import 'package:thread_digit/algorithm/models/processing_result.dart';

/// Parameters for edge detection operations.
class EdgeDetectionParameters {
  /// Creates edge detection parameters with specified values.
  const EdgeDetectionParameters({
    this.lowThreshold = 50,
    this.highThreshold = 150,
    this.gaussianSigma = 1.0,
    this.sobelKernelSize = 3,
  });

  /// Low threshold for Canny hysteresis.
  final int lowThreshold;

  /// High threshold for Canny hysteresis.
  final int highThreshold;

  /// Gaussian blur sigma for noise reduction.
  final double gaussianSigma;

  /// Size of Sobel kernels (3 or 5).
  final int sobelKernelSize;

  /// Validates parameters are within acceptable ranges.
  bool get isValid {
    return lowThreshold > 0 &&
        highThreshold > lowThreshold &&
        gaussianSigma > 0 &&
        (sobelKernelSize == 3 || sobelKernelSize == 5);
  }
}

/// Result of gradient computation containing magnitude and direction.
class GradientData {
  /// Creates gradient data with magnitude and direction arrays.
  const GradientData({
    required this.width,
    required this.height,
    required this.magnitudes,
    required this.directions,
  });

  /// Width of the gradient field.
  final int width;

  /// Height of the gradient field.
  final int height;

  /// Gradient magnitudes for each pixel.
  final List<double> magnitudes;

  /// Gradient directions in radians for each pixel.
  final List<double> directions;

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
}

/// Detects edges in images using Canny edge detection algorithm.
class EdgeDetector {
  /// Default edge detection parameters optimized for embroidery.
  static const defaultParameters = EdgeDetectionParameters();

  /// Detects edges in the input image using Canny edge detection.
  /// Returns a ProcessingResult containing binary edge map or error.
  static ProcessingResult<img.Image> detectEdges(
    img.Image input,
    EdgeDetectionParameters params,
  ) {
    if (!params.isValid) {
      return const ProcessingResult.failure(
        error: 'Invalid edge detection parameters',
      );
    }

    try {
      // Step 1: Convert to grayscale
      final grayscale = img.grayscale(input);

      // Step 2: Apply Gaussian blur for noise reduction
      final blurred = _applyGaussianBlur(grayscale, params.gaussianSigma);

      // Step 3: Compute gradients using Sobel operators
      final gradients = _computeGradients(blurred, params.sobelKernelSize);

      // Step 4: Apply non-maximum suppression
      final suppressed = _nonMaximumSuppression(gradients);

      // Step 5: Apply double threshold and hysteresis
      final edges = _applyHysteresis(suppressed, gradients, params);

      return ProcessingResult.success(data: edges);
    } catch (e) {
      return ProcessingResult.failure(
        error: 'Edge detection failed: $e',
      );
    }
  }

  /// Computes gradients using Sobel operators.
  /// Returns gradient magnitude and direction data.
  static GradientData _computeGradients(img.Image input, int kernelSize) {
    final width = input.width;
    final height = input.height;
    final magnitudes = List<double>.filled(width * height, 0.0);
    final directions = List<double>.filled(width * height, 0.0);

    // Sobel 3x3 kernels
    final sobelX = kernelSize == 3
        ? [-1, 0, 1, -2, 0, 2, -1, 0, 1]
        : [-1, -2, 0, 2, 1, -4, -6, 0, 6, 4, -6, -12, 0, 12, 6, -4, -6, 0, 6, 4, -1, -2, 0, 2, 1];

    final sobelY = kernelSize == 3
        ? [-1, -2, -1, 0, 0, 0, 1, 2, 1]
        : [-1, -4, -6, -4, -1, -2, -6, -12, -6, -2, 0, 0, 0, 0, 0, 2, 6, 12, 6, 2, 1, 4, 6, 4, 1];

    final offset = kernelSize ~/ 2;

    for (int y = offset; y < height - offset; y++) {
      for (int x = offset; x < width - offset; x++) {
        double gx = 0.0, gy = 0.0;

        // Apply Sobel kernels
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

        final index = y * width + x;
        magnitudes[index] = magnitude;
        directions[index] = direction;
      }
    }

    return GradientData(
      width: width,
      height: height,
      magnitudes: magnitudes,
      directions: directions,
    );
  }

  /// Applies Gaussian blur for noise reduction.
  static img.Image _applyGaussianBlur(img.Image input, double sigma) {
    final kernelSize = (sigma * 6).round() | 1; // Ensure odd size
    final kernel = _generateGaussianKernel(kernelSize, sigma);
    return _applyConvolution(input, kernel, kernelSize);
  }

  /// Generates Gaussian kernel for blur operation.
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

  /// Applies convolution with the specified kernel.
  static img.Image _applyConvolution(img.Image input, List<double> kernel, int kernelSize) {
    final output = img.Image.from(input);
    final offset = kernelSize ~/ 2;

    for (int y = offset; y < input.height - offset; y++) {
      for (int x = offset; x < input.width - offset; x++) {
        double sum = 0.0;

        for (int ky = 0; ky < kernelSize; ky++) {
          for (int kx = 0; kx < kernelSize; kx++) {
            final px = x + kx - offset;
            final py = y + ky - offset;
            final intensity = img.getLuminance(input.getPixel(px, py));
            sum += intensity * kernel[ky * kernelSize + kx];
          }
        }

        final value = sum.round().clamp(0, 255);
        output.setPixel(x, y, img.ColorRgb8(value, value, value));
      }
    }

    return output;
  }

  /// Applies non-maximum suppression along gradient direction.
  static img.Image _nonMaximumSuppression(GradientData gradients) {
    final width = gradients.width;
    final height = gradients.height;
    final output = img.Image(width: width, height: height);

    for (int y = 1; y < height - 1; y++) {
      for (int x = 1; x < width - 1; x++) {
        final magnitude = gradients.getMagnitude(x, y);
        final direction = gradients.getDirection(x, y);

        // Quantize direction to nearest 45 degrees
        final angle = direction * 180 / math.pi;
        final quantizedAngle = ((angle + 22.5) / 45).floor() * 45;

        // Check neighbors along gradient direction
        double neighbor1 = 0, neighbor2 = 0;

        switch (quantizedAngle % 180) {
          case 0: // Horizontal
            neighbor1 = gradients.getMagnitude(x - 1, y);
            neighbor2 = gradients.getMagnitude(x + 1, y);
            break;
          case 45: // Diagonal /
            neighbor1 = gradients.getMagnitude(x - 1, y + 1);
            neighbor2 = gradients.getMagnitude(x + 1, y - 1);
            break;
          case 90: // Vertical
            neighbor1 = gradients.getMagnitude(x, y - 1);
            neighbor2 = gradients.getMagnitude(x, y + 1);
            break;
          case 135: // Diagonal \
            neighbor1 = gradients.getMagnitude(x - 1, y - 1);
            neighbor2 = gradients.getMagnitude(x + 1, y + 1);
            break;
        }

        // Suppress if not local maximum
        final isMaximum = magnitude >= neighbor1 && magnitude >= neighbor2;
        final value = isMaximum ? magnitude.round().clamp(0, 255) : 0;
        output.setPixel(x, y, img.ColorRgb8(value, value, value));
      }
    }

    return output;
  }

  /// Applies double threshold and hysteresis edge tracking.
  static img.Image _applyHysteresis(
    img.Image suppressed,
    GradientData gradients,
    EdgeDetectionParameters params,
  ) {
    final width = suppressed.width;
    final height = suppressed.height;
    final output = img.Image(width: width, height: height);

    // Create edge strength map
    final edges = List<int>.filled(width * height, 0);

    // Apply thresholds
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final intensity = img.getLuminance(suppressed.getPixel(x, y));
        final index = y * width + x;

        if (intensity >= params.highThreshold) {
          edges[index] = 2; // Strong edge
        } else if (intensity >= params.lowThreshold) {
          edges[index] = 1; // Weak edge
        }
      }
    }

    // Hysteresis: connect weak edges to strong edges
    final visited = List<bool>.filled(width * height, false);

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final index = y * width + x;
        if (edges[index] == 2 && !visited[index]) {
          _traceEdges(x, y, width, height, edges, visited);
        }
      }
    }

    // Create final edge image
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final index = y * width + x;
        final value = visited[index] ? 255 : 0;
        output.setPixel(x, y, img.ColorRgb8(value, value, value));
      }
    }

    return output;
  }

  /// Traces connected edges using depth-first search.
  static void _traceEdges(int x, int y, int width, int height, List<int> edges, List<bool> visited) {
    final stack = <math.Point<int>>[math.Point(x, y)];

    while (stack.isNotEmpty) {
      final point = stack.removeLast();
      final px = point.x;
      final py = point.y;

      if (px < 0 || px >= width || py < 0 || py >= height) continue;

      final index = py * width + px;
      if (visited[index]) continue;

      visited[index] = true;

      // Check 8-connected neighbors
      for (int dy = -1; dy <= 1; dy++) {
        for (int dx = -1; dx <= 1; dx++) {
          if (dx == 0 && dy == 0) continue;

          final nx = px + dx;
          final ny = py + dy;

          if (nx >= 0 && nx < width && ny >= 0 && ny < height) {
            final nIndex = ny * width + nx;
            if (edges[nIndex] >= 1 && !visited[nIndex]) {
              stack.add(math.Point(nx, ny));
            }
          }
        }
      }
    }
  }
}
