/// Image loading utilities extracted from existing ImagePicker code.
///
/// Provides reusable image loading functionality for algorithm processing
/// without UI dependencies.
library;

import 'dart:io';
import 'dart:typed_data';

import 'package:image/image.dart' as img;

/// Utility class for loading and converting images for algorithm processing.
class ImageLoader {
  /// Loads an image from a file path.
  /// Returns null if the file cannot be read or decoded.
  static Future<img.Image?> loadFromFile(String filePath) async {
    try {
      final File imageFile = File(filePath);
      final Uint8List imageBytes = await imageFile.readAsBytes();
      return img.decodeImage(imageBytes);
    } catch (e) {
      return null;
    }
  }

  /// Loads an image from raw bytes.
  /// Returns null if the bytes cannot be decoded.
  static img.Image? loadFromBytes(Uint8List bytes) {
    try {
      return img.decodeImage(bytes);
    } catch (e) {
      return null;
    }
  }

  /// Validates image dimensions and format.
  /// Returns true if image is suitable for processing.
  static bool validateImage(img.Image? image) {
    if (image == null) return false;

    // Check minimum dimensions
    if (image.width < 32 || image.height < 32) return false;

    // Check maximum dimensions to prevent memory issues
    if (image.width > 4096 || image.height > 4096) return false;

    return true;
  }

  /// Gets the pixel count of an image.
  static int getPixelCount(img.Image image) {
    return image.width * image.height;
  }

  /// Calculates memory usage estimate in bytes for an image.
  static int estimateMemoryUsage(img.Image image) {
    // Estimate: 4 bytes per pixel (RGBA) plus overhead
    return image.width * image.height * 4;
  }
}
