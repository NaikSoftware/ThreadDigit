import 'dart:math';
import 'package:thread_digit/colors/thread_color.dart';

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
}
