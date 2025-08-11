import 'dart:math';
import 'dart:ui';

import 'package:thread_digit/algorithm/models/quantization_result.dart';
import 'package:thread_digit/algorithm/utils/color_conversion_utils.dart';
import 'package:thread_digit/algorithm/utils/color_spaces.dart';
import 'package:thread_digit/colors/model/thread_color.dart';

class ColorMatcherUtil {
  // Find exact matching color from all catalogs
  static ThreadColor? findColor(
    int red,
    int green,
    int blue,
    List<List<ThreadColor>> threadCatalogs, {
    bool allowNearby = false,
  }) {
    if (threadCatalogs.isEmpty) {
      throw ArgumentError('Thread catalogs cannot be empty');
    }
    for (final List<ThreadColor> threadCatalog in threadCatalogs) {
      final ThreadColor? color = threadCatalog.cast<ThreadColor?>().firstWhere(
            (color) => color?.red == red && color?.green == green && color?.blue == blue,
            orElse: () => null,
          );
      if (color != null) {
        return color;
      }
    }
    if (allowNearby) {
      // If exact match not found and nearby colors are allowed, find the closest match
      return findNearestColor(red, green, blue, threadCatalogs);
    } else {
      return null;
    }
  }

  // Find exact matching colors from each catalog
  static List<ThreadColor> findAllExactColors(
    int red,
    int green,
    int blue,
    List<List<ThreadColor>> threadCatalogs,
  ) {
    final List<ThreadColor> result = [];
    for (final threadCatalog in threadCatalogs) {
      final ThreadColor? color = findColor(red, green, blue, [threadCatalog]);
      if (color != null) {
        result.add(color);
      }
    }
    return result;
  }

  // Find nearest color using weighted Euclidean distance in RGB space
  static ThreadColor? findNearestColor(
    int red,
    int green,
    int blue,
    List<List<ThreadColor>> threadCatalogs,
  ) {
    double minDistance = double.infinity;
    ThreadColor? nearestColor;

    // Weights for RGB components based on human perception
    const double redWeight = 0.299;
    const double greenWeight = 0.587;
    const double blueWeight = 0.114;

    for (final catalog in threadCatalogs) {
      for (final color in catalog) {
        final double distance = sqrt(redWeight * pow(color.red - red, 2) +
            greenWeight * pow(color.green - green, 2) +
            blueWeight * pow(color.blue - blue, 2));

        if (distance < minDistance) {
          minDistance = distance;
          nearestColor = color;
        }
      }
    }

    if (nearestColor == null) {
      return null;
    }

    // Maximum possible weighted distance in RGB space.
    final double maxDistance = sqrt(redWeight * pow(255, 2) + greenWeight * pow(255, 2) + blueWeight * pow(255, 2));
    final double matchingPercentage = 100 * (1 - minDistance / maxDistance);
    return nearestColor.withPercentage(matchingPercentage);
  }

  // Find K nearest colors from all catalogs
  static List<ThreadColor> findKNearestColors(
    int red,
    int green,
    int blue,
    List<List<ThreadColor>> threadCatalogs,
    int k,
  ) {
    if (k <= 0) {
      throw ArgumentError('k must be positive');
    }

    // Create a list of tuples (color, distance)
    final List<({ThreadColor color, double distance})> colorDistances = [];

    const double redWeight = 0.299;
    const double greenWeight = 0.587;
    const double blueWeight = 0.114;

    for (final catalog in threadCatalogs) {
      for (final color in catalog) {
        final double distance = sqrt(redWeight * pow(color.red - red, 2) +
            greenWeight * pow(color.green - green, 2) +
            blueWeight * pow(color.blue - blue, 2));

        colorDistances.add((color: color, distance: distance));
      }
    }

    // Sort by distance
    colorDistances.sort((a, b) => a.distance.compareTo(b.distance));

    // Return k nearest colors
    return colorDistances.take(k).map((e) => e.color).toList();
  }

  // Calculate color difference percentage
  static double calculateColorDifference(
    ThreadColor color, {
    required int red,
    required int green,
    required int blue,
  }) {
    const double redWeight = 0.299;
    const double greenWeight = 0.587;
    const double blueWeight = 0.114;

    final double distance = sqrt(redWeight * pow(color.red - red, 2) +
        greenWeight * pow(color.green - green, 2) +
        blueWeight * pow(color.blue - blue, 2));

    // Convert to percentage (0-100)
    // Maximum possible distance in RGB space with weights
    final double maxDistance = sqrt(redWeight * pow(255, 2) + greenWeight * pow(255, 2) + blueWeight * pow(255, 2));

    return (1 - distance / maxDistance) * 100;
  }

  static ThreadColor findByCodeAndCatalog(
    String code,
    String catalog,
    Map<String, List<ThreadColor>> threadCatalogs,
  ) {
    final List<ThreadColor>? threadCatalog = threadCatalogs[catalog];
    if (threadCatalog == null) {
      return ThreadColor(name: 'Unknown', code: code, red: 127, green: 127, blue: 127, catalog: catalog);
    }
    final ThreadColor color = threadCatalog.firstWhere(
      (color) => color.code == code,
      orElse: () => ThreadColor(name: 'Unknown', code: code, red: 127, green: 127, blue: 127, catalog: catalog),
    );
    return color;
  }

  /// Enhanced color matching using CIEDE2000 algorithm for optimal perceptual accuracy
  static ThreadColor? findOptimalMatch(
    Color imageColor,
    List<List<ThreadColor>> threadCatalogs, {
    ColorDistanceAlgorithm algorithm = ColorDistanceAlgorithm.ciede2000,
    bool allowNearby = true,
  }) {
    if (threadCatalogs.isEmpty) {
      throw ArgumentError('Thread catalogs cannot be empty');
    }

    // First try exact match
    final exactMatch = findColor(
      (imageColor.r * 255.0).round() & 0xff,
      (imageColor.g * 255.0).round() & 0xff,
      (imageColor.b * 255.0).round() & 0xff,
      threadCatalogs,
      allowNearby: false,
    );
    
    if (exactMatch != null) {
      return exactMatch;
    }

    if (!allowNearby) {
      return null;
    }

    // Find best match using specified algorithm
    switch (algorithm) {
      case ColorDistanceAlgorithm.ciede2000:
        return _findBestMatchCiede2000(imageColor, threadCatalogs);
      case ColorDistanceAlgorithm.labEuclidean:
        return _findBestMatchLab(imageColor, threadCatalogs);
      case ColorDistanceAlgorithm.euclidean:
        return findNearestColor((imageColor.r * 255.0).round() & 0xff, (imageColor.g * 255.0).round() & 0xff, (imageColor.b * 255.0).round() & 0xff, threadCatalogs);
    }
  }

  /// Finds best color match using CIEDE2000 distance
  static ThreadColor? _findBestMatchCiede2000(
    Color targetColor,
    List<List<ThreadColor>> threadCatalogs,
  ) {
    double minDistance = double.infinity;
    ThreadColor? bestMatch;

    for (final catalog in threadCatalogs) {
      for (final threadColor in catalog) {
        final distance = ColorSpaces.ciede2000Distance(
          targetColor,
          threadColor.toColor(),
        );

        if (distance < minDistance) {
          minDistance = distance;
          bestMatch = threadColor;
        }
      }
    }

    if (bestMatch != null) {
      // Convert CIEDE2000 distance to percentage (ΔE < 3.0 is considered excellent)
      final maxPerceptualDistance = 100.0;
      final similarity = max(0, 1 - (minDistance / maxPerceptualDistance)) * 100;
      return bestMatch.withPercentage(similarity.clamp(0, 100).toDouble());
    }

    return null;
  }

  /// Finds best color match using LAB distance
  static ThreadColor? _findBestMatchLab(
    Color targetColor,
    List<List<ThreadColor>> threadCatalogs,
  ) {
    double minDistance = double.infinity;
    ThreadColor? bestMatch;

    for (final catalog in threadCatalogs) {
      for (final threadColor in catalog) {
        final distance = ColorSpaces.labDistance(
          ColorConversionUtils.rgbToLab((targetColor.r * 255.0).round() & 0xff, (targetColor.g * 255.0).round() & 0xff, (targetColor.b * 255.0).round() & 0xff),
          ColorConversionUtils.rgbToLab(threadColor.red, threadColor.green, threadColor.blue),
        );

        if (distance < minDistance) {
          minDistance = distance;
          bestMatch = threadColor;
        }
      }
    }

    if (bestMatch != null) {
      // Convert LAB distance to percentage (max LAB distance ~373)
      const maxLabDistance = 373.0;
      final similarity = max(0, 1 - (minDistance / maxLabDistance)) * 100;
      return bestMatch.withPercentage(similarity.clamp(0, 100).toDouble());
    }

    return null;
  }

  /// Finds multiple best matches using CIEDE2000 for comparison
  static List<ThreadColor> findTopMatches(
    Color imageColor,
    List<List<ThreadColor>> threadCatalogs,
    int count, {
    ColorDistanceAlgorithm algorithm = ColorDistanceAlgorithm.ciede2000,
  }) {
    if (count <= 0) {
      throw ArgumentError('Count must be positive');
    }

    final List<({ThreadColor color, double distance})> colorDistances = [];

    for (final catalog in threadCatalogs) {
      for (final threadColor in catalog) {
        double distance = 0.0;
        
        switch (algorithm) {
          case ColorDistanceAlgorithm.ciede2000:
            distance = ColorSpaces.ciede2000Distance(imageColor, threadColor.toColor());
            break;
          case ColorDistanceAlgorithm.labEuclidean:
            distance = ColorSpaces.labDistance(
              ColorConversionUtils.rgbToLab((imageColor.r * 255.0).round() & 0xff, (imageColor.g * 255.0).round() & 0xff, (imageColor.b * 255.0).round() & 0xff),
              ColorConversionUtils.rgbToLab(threadColor.red, threadColor.green, threadColor.blue),
            );
            break;
          case ColorDistanceAlgorithm.euclidean:
            distance = ColorSpaces.weightedRgbDistance(imageColor, threadColor.toColor());
            break;
        }

        colorDistances.add((color: threadColor, distance: distance));
      }
    }

    // Sort by distance and take top matches
    colorDistances.sort((a, b) => a.distance.compareTo(b.distance));
    
    final topMatches = colorDistances.take(count).map((match) {
      // Calculate similarity percentage based on algorithm
      double similarity = 0.0;
      switch (algorithm) {
        case ColorDistanceAlgorithm.ciede2000:
          similarity = ColorSpaces.calculateSimilarityPercentage(imageColor, match.color.toColor());
          break;
        case ColorDistanceAlgorithm.labEuclidean:
          const maxLabDistance = 373.0;
          similarity = max(0, 1 - (match.distance / maxLabDistance)) * 100;
          break;
        case ColorDistanceAlgorithm.euclidean:
          final maxDistance = sqrt(0.299 * pow(255, 2) + 0.587 * pow(255, 2) + 0.114 * pow(255, 2));
          similarity = max(0, 1 - (match.distance / maxDistance)) * 100;
          break;
      }
      
      return match.color.withPercentage(similarity.clamp(0, 100).toDouble());
    }).toList();

    return topMatches;
  }

  /// Batch color matching for efficient processing of multiple colors
  static Map<Color, ThreadColor> batchColorMatch(
    List<Color> colors,
    List<List<ThreadColor>> threadCatalogs, {
    ColorDistanceAlgorithm algorithm = ColorDistanceAlgorithm.ciede2000,
  }) {
    final Map<Color, ThreadColor> results = {};
    
    for (final color in colors) {
      final match = findOptimalMatch(
        color,
        threadCatalogs,
        algorithm: algorithm,
      );
      
      if (match != null) {
        results[color] = match;
      }
    }
    
    return results;
  }
}
