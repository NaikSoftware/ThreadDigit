/// Complete preprocessing pipeline orchestration for embroidery algorithm.
///
/// Coordinates all preprocessing steps with progress tracking, error handling,
/// and validation between stages for optimal embroidery stitch generation.
library;

import 'dart:async';

import 'package:image/image.dart' as img;
import 'package:thread_digit/algorithm/models/direction_field.dart';
import 'package:thread_digit/algorithm/models/processing_result.dart';
import 'package:thread_digit/algorithm/processors/edge_detector.dart';
import 'package:thread_digit/algorithm/processors/gradient_computer.dart';
import 'package:thread_digit/algorithm/processors/image_preprocessor.dart';
import 'package:thread_digit/algorithm/processors/structure_tensor_analyzer.dart';

/// Complete result of preprocessing pipeline containing all processed data.
class PreprocessingResult {
  /// Creates preprocessing result with all processed data.
  const PreprocessingResult({
    required this.processedImage,
    required this.edgeMap,
    required this.gradients,
    required this.directionField,
    required this.processingTimeMs,
  });

  /// The preprocessed and enhanced input image.
  final img.Image processedImage;

  /// Binary edge map from Canny edge detection.
  final img.Image edgeMap;

  /// Gradient magnitude and direction data.
  final GradientResult gradients;

  /// Direction field from structure tensor analysis.
  final DirectionField directionField;

  /// Total processing time in milliseconds.
  final int processingTimeMs;

  /// Validates that all results are consistent and valid.
  bool get isValid {
    return processedImage.width == edgeMap.width &&
        processedImage.width == gradients.width &&
        processedImage.width == directionField.width &&
        processedImage.height == edgeMap.height &&
        processedImage.height == gradients.height &&
        processedImage.height == directionField.height &&
        directionField.isValid;
  }

  /// Gets processing statistics summary.
  Map<String, dynamic> get statistics {
    return {
      'imageWidth': processedImage.width,
      'imageHeight': processedImage.height,
      'totalPixels': processedImage.width * processedImage.height,
      'averageGradientMagnitude': gradients.averageMagnitude,
      'averageCoherence': directionField.averageCoherence,
      'processingTimeMs': processingTimeMs,
      'processingTimePerPixel': processingTimeMs / (processedImage.width * processedImage.height),
    };
  }
}

/// Parameters controlling the entire preprocessing pipeline.
class PipelineParameters {
  /// Creates pipeline parameters with specified values.
  const PipelineParameters({
    this.preprocessingParams = const PreprocessingParameters(),
    this.edgeParams = const EdgeDetectionParameters(),
    this.gradientParams = const GradientParameters(),
    this.structureTensorParams = const StructureTensorParameters(),
    this.enableProgressTracking = true,
  });

  /// Parameters for image preprocessing stage.
  final PreprocessingParameters preprocessingParams;

  /// Parameters for edge detection stage.
  final EdgeDetectionParameters edgeParams;

  /// Parameters for gradient computation stage.
  final GradientParameters gradientParams;

  /// Parameters for structure tensor analysis stage.
  final StructureTensorParameters structureTensorParams;

  /// Whether to enable progress tracking callbacks.
  final bool enableProgressTracking;

  /// Validates all parameter sets.
  bool get isValid {
    return preprocessingParams.isValid && edgeParams.isValid && gradientParams.isValid && structureTensorParams.isValid;
  }
}

/// Progress callback function type.
typedef ProgressCallback = void Function(double progress, String stage);

/// Complete preprocessing pipeline for embroidery algorithm.
class PreprocessingPipeline {
  /// Default pipeline parameters optimized for embroidery.
  static const defaultParameters = PipelineParameters();

  /// Total number of processing stages.
  static const int totalStages = 5;

  /// Processes an image through the complete preprocessing pipeline.
  ///
  /// [input] - Input image to process
  /// [params] - Pipeline parameters (uses defaults if not provided)
  /// [progressCallback] - Optional callback for progress updates
  /// [cancelToken] - Optional cancellation token for long operations
  ///
  /// Returns ProcessingResult containing complete preprocessing data or error.
  static Future<ProcessingResult<PreprocessingResult>> processImage(
    img.Image input, {
    PipelineParameters params = defaultParameters,
    ProgressCallback? progressCallback,
    CancelToken? cancelToken,
  }) async {
    if (!params.isValid) {
      return const ProcessingResult.failure(
        error: 'Invalid pipeline parameters',
      );
    }

    final stopwatch = Stopwatch()..start();

    try {
      // Stage 1: Image preprocessing (20% progress)
      _updateProgress(progressCallback, 0.0, 'Preprocessing image...');
      _checkCancellation(cancelToken);

      final preprocessingResult = ImagePreprocessor.process(input, params.preprocessingParams);
      if (preprocessingResult.isFailure) {
        return ProcessingResult.failure(error: preprocessingResult.error!);
      }
      final processedImage = preprocessingResult.data!;

      _updateProgress(progressCallback, 0.2, 'Image preprocessing complete');

      // Stage 2: Edge detection (40% progress)
      _updateProgress(progressCallback, 0.2, 'Detecting edges...');
      _checkCancellation(cancelToken);

      final edgeResult = EdgeDetector.detectEdges(processedImage, params.edgeParams);
      if (edgeResult.isFailure) {
        return ProcessingResult.failure(error: edgeResult.error!);
      }
      final edgeMap = edgeResult.data!;

      _updateProgress(progressCallback, 0.4, 'Edge detection complete');

      // Stage 3: Gradient computation (60% progress)
      _updateProgress(progressCallback, 0.4, 'Computing gradients...');
      _checkCancellation(cancelToken);

      final gradientResult = GradientComputer.computeGradients(processedImage, params.gradientParams);
      if (gradientResult.isFailure) {
        return ProcessingResult.failure(error: gradientResult.error!);
      }
      final gradients = gradientResult.data!;

      _updateProgress(progressCallback, 0.6, 'Gradient computation complete');

      // Stage 4: Structure tensor analysis (80% progress)
      _updateProgress(progressCallback, 0.6, 'Analyzing structure tensor...');
      _checkCancellation(cancelToken);

      final structureResult = StructureTensorAnalyzer.analyzeStructure(
        processedImage,
        params.structureTensorParams,
      );
      if (structureResult.isFailure) {
        return ProcessingResult.failure(error: structureResult.error!);
      }
      final directionField = structureResult.data!;

      _updateProgress(progressCallback, 0.8, 'Structure tensor analysis complete');

      // Stage 5: Final validation and result assembly (100% progress)
      _updateProgress(progressCallback, 0.8, 'Finalizing results...');
      _checkCancellation(cancelToken);

      stopwatch.stop();
      final processingTimeMs = stopwatch.elapsedMilliseconds;

      final result = PreprocessingResult(
        processedImage: processedImage,
        edgeMap: edgeMap,
        gradients: gradients,
        directionField: directionField,
        processingTimeMs: processingTimeMs,
      );

      // Validate final result
      if (!result.isValid) {
        return const ProcessingResult.failure(
          error: 'Final preprocessing result validation failed',
        );
      }

      _updateProgress(progressCallback, 1.0, 'Preprocessing pipeline complete');

      return ProcessingResult.success(data: result);
    } catch (e) {
      stopwatch.stop();
      return ProcessingResult.failure(
        error: 'Pipeline processing failed: $e',
      );
    }
  }

  /// Estimates total processing time for given image dimensions.
  /// Returns estimated time in milliseconds.
  static int estimateProcessingTime(int width, int height) {
    final pixelCount = width * height;

    // Rough estimates based on processing complexity:
    final preprocessingTime = pixelCount * 0.001; // 1ms per 1000 pixels
    final edgeDetectionTime = pixelCount * 0.002; // 2ms per 1000 pixels
    final gradientTime = pixelCount * 0.0015; // 1.5ms per 1000 pixels
    final structureTensorTime = pixelCount * 0.003; // 3ms per 1000 pixels
    final overhead = 100; // 100ms overhead

    return (preprocessingTime + edgeDetectionTime + gradientTime + structureTensorTime + overhead).round();
  }

  /// Estimates memory usage for given image dimensions.
  /// Returns estimated memory in bytes.
  static int estimateMemoryUsage(int width, int height) {
    final pixelCount = width * height;

    // Memory estimates:
    final originalImage = pixelCount * 4; // RGBA
    final processedImage = pixelCount * 4; // RGBA
    final edgeMap = pixelCount * 1; // Grayscale
    final gradients = pixelCount * 8; // 2 doubles per pixel
    final directionField = pixelCount * 8; // 2 doubles per pixel
    final temporaryBuffers = pixelCount * 12; // Various intermediate results

    return originalImage + processedImage + edgeMap + gradients + directionField + temporaryBuffers;
  }

  /// Validates input image meets processing requirements.
  static ProcessingResult<void> validateInput(img.Image input) {
    // Check minimum dimensions
    if (input.width < 32 || input.height < 32) {
      return const ProcessingResult.failure(
        error: 'Image too small: minimum 32x32 pixels required',
      );
    }

    // Check maximum dimensions
    if (input.width > 4096 || input.height > 4096) {
      return const ProcessingResult.failure(
        error: 'Image too large: maximum 4096x4096 pixels supported',
      );
    }

    // Check memory requirements
    final estimatedMemory = estimateMemoryUsage(input.width, input.height);
    const maxMemoryMb = 512;
    if (estimatedMemory > maxMemoryMb * 1024 * 1024) {
      return ProcessingResult.failure(
        error: 'Image requires too much memory: ${(estimatedMemory / 1024 / 1024).round()}MB > ${maxMemoryMb}MB',
      );
    }

    return const ProcessingResult.success(data: null);
  }

  /// Creates optimal parameters based on image characteristics.
  static PipelineParameters getOptimalParameters(img.Image input) {
    final pixelCount = input.width * input.height;

    // Adjust parameters based on image size
    final preprocessingParams = ImagePreprocessor.getOptimalParameters(input);

    // Adjust edge detection sensitivity for larger images
    final edgeParams = pixelCount > 1000000
        ? const EdgeDetectionParameters(lowThreshold: 60, highThreshold: 180)
        : const EdgeDetectionParameters();

    // Adjust gradient smoothing for image size
    final gradientParams =
        pixelCount < 100000 ? const GradientParameters(smoothingSigma: 1.5) : const GradientParameters();

    // Adjust structure tensor integration for detail level
    final structureTensorParams = pixelCount > 500000
        ? const StructureTensorParameters(integrationSigma: 3.0)
        : const StructureTensorParameters();

    return PipelineParameters(
      preprocessingParams: preprocessingParams,
      edgeParams: edgeParams,
      gradientParams: gradientParams,
      structureTensorParams: structureTensorParams,
      enableProgressTracking: true,
    );
  }

  /// Updates progress callback if provided.
  static void _updateProgress(ProgressCallback? callback, double progress, String stage) {
    callback?.call(progress, stage);
  }

  /// Checks for cancellation and throws if cancelled.
  static void _checkCancellation(CancelToken? token) {
    if (token?.isCancelled == true) {
      throw ProcessingCancelledException();
    }
  }
}

/// Token for cancelling long-running processing operations.
class CancelToken {
  bool _isCancelled = false;

  /// Whether the operation has been cancelled.
  bool get isCancelled => _isCancelled;

  /// Cancels the operation.
  void cancel() {
    _isCancelled = true;
  }
}

/// Exception thrown when processing is cancelled.
class ProcessingCancelledException implements Exception {
  /// Creates a processing cancelled exception.
  const ProcessingCancelledException([this.message = 'Processing was cancelled']);

  /// Error message.
  final String message;

  @override
  String toString() => 'ProcessingCancelledException: $message';
}
