/// Structure tensor analysis for local orientation detection.
///
/// Analyzes local image structure using structure tensors to determine
/// dominant texture orientations and coherence for embroidery stitch generation.
library;

import 'dart:math' as math;

import 'package:image/image.dart' as img;
import 'package:thread_digit/algorithm/models/direction_field.dart';
import 'package:thread_digit/algorithm/models/processing_result.dart';
import 'package:thread_digit/algorithm/processors/gradient_computer.dart';

/// Parameters for structure tensor analysis.
class StructureTensorParameters {
  /// Creates structure tensor parameters with specified values.
  const StructureTensorParameters({
    this.gaussianSigma = 2.0,
    this.integrationSigma = 4.0,
    this.minCoherence = 0.01,
    this.gradientThreshold = 0.1,
  });

  /// Gaussian sigma for gradient computation.
  final double gaussianSigma;

  /// Gaussian sigma for structure tensor integration.
  final double integrationSigma;

  /// Minimum coherence threshold for valid orientations.
  final double minCoherence;

  /// Minimum gradient magnitude threshold.
  final double gradientThreshold;

  /// Validates parameters are within acceptable ranges.
  bool get isValid {
    return gaussianSigma > 0 &&
        integrationSigma > 0 &&
        minCoherence >= 0 &&
        minCoherence <= 1 &&
        gradientThreshold >= 0;
  }
}

/// Data from structure tensor eigenvalue analysis.
class StructureTensorData {
  /// Creates structure tensor data.
  const StructureTensorData({
    required this.width,
    required this.height,
    required this.orientations,
    required this.coherences,
    required this.eigenvalue1,
    required this.eigenvalue2,
  });

  /// Width of the tensor field.
  final int width;

  /// Height of the tensor field.
  final int height;

  /// Primary orientation angles in radians.
  final List<double> orientations;

  /// Coherence values (0.0-1.0).
  final List<double> coherences;

  /// Larger eigenvalues.
  final List<double> eigenvalue1;

  /// Smaller eigenvalues.
  final List<double> eigenvalue2;

  /// Gets orientation at specified coordinates.
  double getOrientation(int x, int y) {
    if (x < 0 || x >= width || y < 0 || y >= height) return 0.0;
    return orientations[y * width + x];
  }

  /// Gets coherence at specified coordinates.
  double getCoherence(int x, int y) {
    if (x < 0 || x >= width || y < 0 || y >= height) return 0.0;
    return coherences[y * width + x];
  }
}

/// Analyzes local image structure using structure tensors.
class StructureTensorAnalyzer {
  /// Default structure tensor parameters.
  static const defaultParameters = StructureTensorParameters();

  /// Analyzes structure tensor for the input image.
  /// Returns a ProcessingResult containing DirectionField or error.
  static ProcessingResult<DirectionField> analyzeStructure(
    img.Image input,
    StructureTensorParameters params,
  ) {
    if (!params.isValid) {
      return const ProcessingResult.failure(
        error: 'Invalid structure tensor parameters',
      );
    }

    try {
      // Step 1: Compute gradients
      final gradientParams = GradientParameters(
        sobelKernelSize: 3,
        smoothingSigma: params.gaussianSigma,
        normalizeGradients: true,
      );

      final gradientResult = GradientComputer.computeGradients(input, gradientParams);
      if (gradientResult.isFailure) {
        return ProcessingResult.failure(error: gradientResult.error!);
      }

      final gradients = gradientResult.data!;

      // Step 2: Compute structure tensor components
      final tensorData = _computeStructureTensor(gradients, params);

      // Step 3: Perform eigenvalue analysis
      final analyzed = _performEigenAnalysis(tensorData, params);

      // Step 4: Create DirectionField
      final directionField = DirectionField(
        width: analyzed.width,
        height: analyzed.height,
        orientations: analyzed.orientations,
        coherences: analyzed.coherences,
      );

      return ProcessingResult.success(data: directionField);
    } catch (e) {
      return ProcessingResult.failure(
        error: 'Structure tensor analysis failed: $e',
      );
    }
  }

  /// Computes structure tensor components from gradients.
  static StructureTensorData _computeStructureTensor(
    GradientResult gradients,
    StructureTensorParameters params,
  ) {
    final width = gradients.width;
    final height = gradients.height;
    final pixelCount = width * height;

    // Structure tensor components: Jxx, Jxy, Jyy
    final jxx = List<double>.filled(pixelCount, 0.0);
    final jxy = List<double>.filled(pixelCount, 0.0);
    final jyy = List<double>.filled(pixelCount, 0.0);

    // Compute structure tensor components
    for (int i = 0; i < pixelCount; i++) {
      final magnitude = gradients.magnitudes[i];
      final direction = gradients.directions[i];

      if (magnitude > params.gradientThreshold) {
        final ix = magnitude * math.cos(direction);
        final iy = magnitude * math.sin(direction);

        jxx[i] = ix * ix;
        jxy[i] = ix * iy;
        jyy[i] = iy * iy;
      }
    }

    // Apply Gaussian integration
    final kernelSize = (params.integrationSigma * 6).round() | 1;
    final kernel = _generateGaussianKernel(kernelSize, params.integrationSigma);

    final smoothedJxx = _applyGaussianToField(jxx, width, height, kernel, kernelSize);
    final smoothedJxy = _applyGaussianToField(jxy, width, height, kernel, kernelSize);
    final smoothedJyy = _applyGaussianToField(jyy, width, height, kernel, kernelSize);

    return _performEigenAnalysisRaw(width, height, smoothedJxx, smoothedJxy, smoothedJyy);
  }

  /// Performs eigenvalue analysis on structure tensor data.
  static StructureTensorData _performEigenAnalysis(
    StructureTensorData tensorData,
    StructureTensorParameters params,
  ) {
    return tensorData; // Already performed in _performEigenAnalysisRaw
  }

  /// Performs eigenvalue analysis on raw tensor components.
  static StructureTensorData _performEigenAnalysisRaw(
    int width,
    int height,
    List<double> jxx,
    List<double> jxy,
    List<double> jyy,
  ) {
    final pixelCount = width * height;
    final orientations = List<double>.filled(pixelCount, 0.0);
    final coherences = List<double>.filled(pixelCount, 0.0);
    final eigenvalue1 = List<double>.filled(pixelCount, 0.0);
    final eigenvalue2 = List<double>.filled(pixelCount, 0.0);

    for (int i = 0; i < pixelCount; i++) {
      final a = jxx[i];
      final b = jxy[i];
      final c = jyy[i];

      // Compute eigenvalues of 2x2 matrix [a b; b c]
      final trace = a + c;
      final det = a * c - b * b;
      final discriminant = trace * trace - 4 * det;

      if (discriminant >= 0) {
        final sqrtDisc = math.sqrt(discriminant);
        final lambda1 = (trace + sqrtDisc) / 2;
        final lambda2 = (trace - sqrtDisc) / 2;

        eigenvalue1[i] = lambda1;
        eigenvalue2[i] = lambda2;

        // Compute coherence: (λ1 - λ2) / (λ1 + λ2)
        final sum = lambda1 + lambda2;
        final coherence = sum > 0 ? (lambda1 - lambda2) / sum : 0.0;
        coherences[i] = coherence.clamp(0.0, 1.0);

        // Compute dominant orientation
        // Eigenvector corresponding to λ1: solve (A - λ1*I)v = 0
        double orientation = 0.0;
        if (b.abs() > 1e-10) {
          // Use first row: (a - λ1)*vx + b*vy = 0
          // So vy/vx = -(a - λ1)/b
          orientation = math.atan2(-(a - lambda1), b);
        } else if ((a - lambda1).abs() > 1e-10) {
          // b ≈ 0, so eigenvector is [0, 1] if a != λ1
          orientation = math.pi / 2;
        }
        // If both are ≈ 0, orientation stays 0

        orientations[i] = orientation;
      }
    }

    return StructureTensorData(
      width: width,
      height: height,
      orientations: orientations,
      coherences: coherences,
      eigenvalue1: eigenvalue1,
      eigenvalue2: eigenvalue2,
    );
  }

  /// Generates Gaussian kernel for integration.
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

  /// Creates a visualization of orientation field.
  static img.Image visualizeOrientations(DirectionField field) {
    final output = img.Image(width: field.width, height: field.height);

    for (int y = 0; y < field.height; y++) {
      for (int x = 0; x < field.width; x++) {
        final orientation = field.getOrientation(x, y);
        final coherence = field.getCoherence(x, y);

        if (coherence > 0.1) {
          // Color-code orientation with intensity based on coherence
          final normalizedAngle = (orientation + math.pi) / (2 * math.pi);
          final hue = (normalizedAngle * 360).round() % 360;

          final rgb = _hsvToRgb(hue, 1.0, coherence);
          output.setPixel(x, y, img.ColorRgb8(rgb[0], rgb[1], rgb[2]));
        } else {
          output.setPixel(x, y, img.ColorRgb8(0, 0, 0));
        }
      }
    }

    return output;
  }

  /// Creates a visualization of coherence field.
  static img.Image visualizeCoherence(DirectionField field) {
    final output = img.Image(width: field.width, height: field.height);

    for (int y = 0; y < field.height; y++) {
      for (int x = 0; x < field.width; x++) {
        final coherence = field.getCoherence(x, y);
        final intensity = (coherence * 255).round().clamp(0, 255);
        output.setPixel(x, y, img.ColorRgb8(intensity, intensity, intensity));
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

  /// Calculates statistics for a direction field.
  static Map<String, double> calculateStatistics(DirectionField field) {
    double totalCoherence = 0.0;
    int validPixels = 0;
    double minCoherence = 1.0;
    double maxCoherence = 0.0;

    for (int i = 0; i < field.coherences.length; i++) {
      final coherence = field.coherences[i];
      if (coherence > 0) {
        totalCoherence += coherence;
        validPixels++;
        minCoherence = math.min(minCoherence, coherence);
        maxCoherence = math.max(maxCoherence, coherence);
      }
    }

    final averageCoherence = validPixels > 0 ? totalCoherence / validPixels : 0.0;
    final coherenceRatio = validPixels / field.coherences.length;

    return {
      'averageCoherence': averageCoherence,
      'minCoherence': minCoherence,
      'maxCoherence': maxCoherence,
      'coherenceRatio': coherenceRatio,
      'validPixels': validPixels.toDouble(),
    };
  }
}
