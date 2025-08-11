import 'package:equatable/equatable.dart';

/// Represents the result of an image processing operation.
///
/// Can contain either successful data of type [T] or error information.
/// Includes optional progress tracking for long-running operations.
class ProcessingResult<T> extends Equatable {
  /// Creates a successful processing result with data.
  const ProcessingResult.success({
    required this.data,
    this.progress = 1.0,
    this.message,
  })  : isSuccess = true,
        error = null;

  /// Creates a failed processing result with error information.
  const ProcessingResult.failure({
    required this.error,
    this.progress = 0.0,
    this.message,
  })  : isSuccess = false,
        data = null;

  /// Creates a progress update without final result.
  const ProcessingResult.progress({
    required this.progress,
    this.message,
  })  : isSuccess = false,
        data = null,
        error = null;

  /// Whether the processing operation was successful.
  final bool isSuccess;

  /// The resulting data if the operation was successful.
  final T? data;

  /// Error message if the operation failed.
  final String? error;

  /// Processing progress from 0.0 to 1.0.
  final double progress;

  /// Optional descriptive message about the operation.
  final String? message;

  /// Whether the operation failed.
  bool get isFailure => !isSuccess;

  /// Whether this is a progress update (not final result).
  bool get isProgress => !isSuccess && error == null;

  /// Whether the processing is complete (success or failure).
  bool get isComplete => isSuccess || error != null;

  /// Progress as a percentage (0-100).
  double get progressPercentage => progress * 100.0;

  /// Maps the data to a different type if successful.
  /// Returns a failure result if this result failed.
  ProcessingResult<R> map<R>(R Function(T data) mapper) {
    if (isSuccess && data != null) {
      try {
        return ProcessingResult.success(
          data: mapper(data as T),
          progress: progress,
          message: message,
        );
      } catch (e) {
        return ProcessingResult.failure(
          error: 'Mapping failed: $e',
          progress: progress,
        );
      }
    }
    return ProcessingResult.failure(
      error: error ?? 'No data available for mapping',
      progress: progress,
      message: message,
    );
  }

  /// Chains another processing operation if this one succeeded.
  /// Returns the original failure if this result failed.
  ProcessingResult<R> then<R>(ProcessingResult<R> Function(T data) next) {
    if (isSuccess && data != null) {
      return next(data as T);
    }
    return ProcessingResult.failure(
      error: error ?? 'No data available for chaining',
      progress: progress,
      message: message,
    );
  }

  @override
  List<Object?> get props => [isSuccess, data, error, progress, message];
}
