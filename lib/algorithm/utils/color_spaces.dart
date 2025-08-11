/// CIEDE2000 color difference calculation for perceptually accurate color matching.
///
/// Implements the complete CIEDE2000 formula with corrections for hue rotation,
/// lightness, and chroma differences for optimal thread color matching.
library;

import 'dart:math' as math;
import 'dart:ui';

import 'package:thread_digit/algorithm/utils/color_conversion_utils.dart';

/// Advanced color space utilities with CIEDE2000 implementation
class ColorSpaces {
  /// Calculates CIEDE2000 color difference between two colors.
  /// Returns ΔE00 value where smaller values indicate more similar colors.
  /// Values < 1.0 are considered identical, < 3.0 are perceptually similar.
  static double ciede2000Distance(Color color1, Color color2) {
    final lab1 = ColorConversionUtils.rgbToLab((color1.r * 255.0).round() & 0xff, (color1.g * 255.0).round() & 0xff, (color1.b * 255.0).round() & 0xff);
    final lab2 = ColorConversionUtils.rgbToLab((color2.r * 255.0).round() & 0xff, (color2.g * 255.0).round() & 0xff, (color2.b * 255.0).round() & 0xff);
    
    return ciede2000DistanceLab(lab1, lab2);
  }

  /// Calculates CIEDE2000 color difference between two LAB colors.
  /// Implements the complete CIEDE2000 formula with all correction terms.
  static double ciede2000DistanceLab(LabColor lab1, LabColor lab2) {
    // Step 1: Calculate Chroma and Hue values
    final c1 = math.sqrt(lab1.a * lab1.a + lab1.b * lab1.b);
    final c2 = math.sqrt(lab2.a * lab2.a + lab2.b * lab2.b);
    final cMean = (c1 + c2) / 2.0;

    // Step 2: Calculate G factor for chroma weighting
    final g = 0.5 * (1 - math.sqrt(math.pow(cMean, 7) / (math.pow(cMean, 7) + math.pow(25, 7))));

    // Step 3: Calculate adjusted a* values
    final aPrime1 = lab1.a * (1 + g);
    final aPrime2 = lab2.a * (1 + g);

    // Step 4: Calculate adjusted chroma and hue values
    final cPrime1 = math.sqrt(aPrime1 * aPrime1 + lab1.b * lab1.b);
    final cPrime2 = math.sqrt(aPrime2 * aPrime2 + lab2.b * lab2.b);

    final hPrime1 = _calculateHue(aPrime1, lab1.b);
    final hPrime2 = _calculateHue(aPrime2, lab2.b);

    // Step 5: Calculate differences
    final deltaL = lab2.l - lab1.l;
    final deltaC = cPrime2 - cPrime1;
    final deltaH = _calculateHueDifference(hPrime1, hPrime2, cPrime1, cPrime2);
    final deltaHPrime = 2 * math.sqrt(cPrime1 * cPrime2) * math.sin(_degreesToRadians(deltaH) / 2);

    // Step 6: Calculate mean values
    final lMean = (lab1.l + lab2.l) / 2.0;
    final cPrimeMean = (cPrime1 + cPrime2) / 2.0;
    final hPrimeMean = _calculateMeanHue(hPrime1, hPrime2, cPrime1, cPrime2);

    // Step 7: Calculate weighting functions
    final t = 1 - 0.17 * math.cos(_degreesToRadians(hPrimeMean - 30)) +
              0.24 * math.cos(_degreesToRadians(2 * hPrimeMean)) +
              0.32 * math.cos(_degreesToRadians(3 * hPrimeMean + 6)) -
              0.20 * math.cos(_degreesToRadians(4 * hPrimeMean - 63));

    final deltaTheta = 30 * math.exp(-math.pow((hPrimeMean - 275) / 25, 2));
    final rc = 2 * math.sqrt(math.pow(cPrimeMean, 7) / (math.pow(cPrimeMean, 7) + math.pow(25, 7)));
    final rt = -math.sin(_degreesToRadians(2 * deltaTheta)) * rc;

    // Step 8: Calculate SL, SC, SH weighting functions
    final sl = 1 + (0.015 * math.pow(lMean - 50, 2)) / math.sqrt(20 + math.pow(lMean - 50, 2));
    final sc = 1 + 0.045 * cPrimeMean;
    final sh = 1 + 0.015 * cPrimeMean * t;

    // Step 9: Calculate final CIEDE2000 difference with standard weighting factors
    const kl = 1.0; // Lightness weighting factor
    const kc = 1.0; // Chroma weighting factor  
    const kh = 1.0; // Hue weighting factor

    final deltaE00 = math.sqrt(
      math.pow(deltaL / (kl * sl), 2) +
      math.pow(deltaC / (kc * sc), 2) +
      math.pow(deltaHPrime / (kh * sh), 2) +
      rt * (deltaC / (kc * sc)) * (deltaHPrime / (kh * sh))
    );

    return deltaE00;
  }

  /// Calculates hue angle in degrees from a* and b* components
  static double _calculateHue(double aPrime, double b) {
    if (aPrime == 0 && b == 0) return 0;
    
    final hue = _radiansToDegrees(math.atan2(b, aPrime));
    return hue < 0 ? hue + 360 : hue;
  }

  /// Calculates hue difference with proper handling of circular hue space
  static double _calculateHueDifference(double h1, double h2, double c1, double c2) {
    if (c1 == 0 || c2 == 0) return 0;
    
    final diff = (h2 - h1).abs();
    if (diff <= 180) {
      return h2 - h1;
    } else if (h2 > h1) {
      return h2 - h1 - 360;
    } else {
      return h2 - h1 + 360;
    }
  }

  /// Calculates mean hue with proper circular averaging
  static double _calculateMeanHue(double h1, double h2, double c1, double c2) {
    if (c1 == 0 || c2 == 0) return h1 + h2;
    
    final diff = (h1 - h2).abs();
    if (diff <= 180) {
      return (h1 + h2) / 2;
    } else if (h1 + h2 < 360) {
      return (h1 + h2 + 360) / 2;
    } else {
      return (h1 + h2 - 360) / 2;
    }
  }

  /// Converts degrees to radians
  static double _degreesToRadians(double degrees) => degrees * math.pi / 180;

  /// Converts radians to degrees
  static double _radiansToDegrees(double radians) => radians * 180 / math.pi;

  /// Calculates simple LAB distance for performance comparison
  static double labDistance(LabColor lab1, LabColor lab2) {
    return ColorConversionUtils.labDistance(lab1, lab2);
  }

  /// Calculates weighted RGB distance (legacy method for comparison)
  static double weightedRgbDistance(Color color1, Color color2) {
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

  /// Determines if two colors are perceptually similar using CIEDE2000
  /// threshold: ΔE < 1.0 = identical, < 3.0 = similar, < 6.0 = acceptable
  static bool areColorsSimilar(Color color1, Color color2, {double threshold = 3.0}) {
    return ciede2000Distance(color1, color2) < threshold;
  }

  /// Finds the most similar color from a list using CIEDE2000
  static T findMostSimilarColor<T>(
    Color targetColor,
    List<T> colors,
    Color Function(T) colorExtractor,
  ) {
    if (colors.isEmpty) {
      throw ArgumentError('Colors list cannot be empty');
    }

    double minDistance = double.infinity;
    late T bestMatch;

    for (final color in colors) {
      final distance = ciede2000Distance(targetColor, colorExtractor(color));
      if (distance < minDistance) {
        minDistance = distance;
        bestMatch = color;
      }
    }

    return bestMatch;
  }

  /// Calculates color difference percentage (0-100%) based on CIEDE2000
  /// Uses maximum perceptual difference of ~100 ΔE as reference
  static double calculateSimilarityPercentage(Color color1, Color color2) {
    final distance = ciede2000Distance(color1, color2);
    const maxPerceptualDistance = 100.0; // Practical maximum ΔE00
    
    final similarity = math.max(0, 1 - (distance / maxPerceptualDistance));
    return (similarity * 100).clamp(0, 100).toDouble();
  }
}


/// Color space enumeration for algorithm selection
enum ColorSpace {
  /// RGB color space (0-255 per component)
  rgb,
  
  /// LAB color space (perceptually uniform)
  cieLab,
}