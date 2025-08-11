import 'package:flutter_test/flutter_test.dart';
import 'dart:ui';
import 'package:thread_digit/algorithm/models/quantization_result.dart';
import 'package:thread_digit/algorithm/utils/color_spaces.dart';
import 'package:thread_digit/algorithm/utils/color_conversion_utils.dart';

void main() {
  group('ColorSpaces', () {
    test('CIEDE2000 distance calculation works correctly', () {
      final color1 = Color.fromARGB(255, 255, 0, 0); // Red
      final color2 = Color.fromARGB(255, 255, 0, 0); // Same red
      final color3 = Color.fromARGB(255, 0, 255, 0); // Green
      
      // Distance from color to itself should be zero
      final sameDistance = ColorSpaces.ciede2000Distance(color1, color2);
      expect(sameDistance, closeTo(0, 0.001));
      
      // Distance between different colors should be positive
      final differentDistance = ColorSpaces.ciede2000Distance(color1, color3);
      expect(differentDistance, greaterThan(0));
      
      // CIEDE2000 should give reasonable values for common colors
      expect(differentDistance, lessThan(100)); // Practical upper bound
    });

    test('CIEDE2000 distance is symmetric', () {
      final color1 = Color.fromARGB(255, 128, 64, 192);
      final color2 = Color.fromARGB(255, 200, 100, 50);
      
      final distance1to2 = ColorSpaces.ciede2000Distance(color1, color2);
      final distance2to1 = ColorSpaces.ciede2000Distance(color2, color1);
      
      expect(distance1to2, closeTo(distance2to1, 0.001));
    });

    test('LAB distance calculation works correctly', () {
      final lab1 = LabColor(50, 0, 0);
      final lab2 = LabColor(60, 10, -5);
      
      final distance = ColorSpaces.labDistance(lab1, lab2);
      expect(distance, greaterThan(0));
      
      // Should match ColorConversionUtils.labDistance
      final expectedDistance = ColorConversionUtils.labDistance(lab1, lab2);
      expect(distance, closeTo(expectedDistance, 0.001));
    });

    test('weighted RGB distance calculation works correctly', () {
      final color1 = Color.fromARGB(255, 128, 128, 128);
      final color2 = Color.fromARGB(255, 130, 130, 130);
      
      final distance = ColorSpaces.weightedRgbDistance(color1, color2);
      expect(distance, greaterThan(0));
      expect(distance, lessThan(10)); // Should be small for similar colors
      
      // Distance from color to itself should be zero
      final sameDistance = ColorSpaces.weightedRgbDistance(color1, color1);
      expect(sameDistance, closeTo(0, 0.001));
    });

    test('color similarity detection works correctly', () {
      final color1 = Color.fromARGB(255, 100, 100, 100);
      final color2 = Color.fromARGB(255, 101, 101, 101); // Very similar
      final color3 = Color.fromARGB(255, 255, 0, 0); // Very different
      
      // Similar colors should be detected as similar
      expect(ColorSpaces.areColorsSimilar(color1, color2, threshold: 3.0), isTrue);
      
      // Different colors should not be similar
      expect(ColorSpaces.areColorsSimilar(color1, color3, threshold: 3.0), isFalse);
      
      // Test different thresholds - very tight threshold should fail for slightly different colors
      expect(ColorSpaces.areColorsSimilar(color1, color2, threshold: 0.1), isFalse);
      expect(ColorSpaces.areColorsSimilar(color1, color2, threshold: 10.0), isTrue);
    });

    test('most similar color finding works correctly', () {
      final targetColor = Color.fromARGB(255, 128, 64, 192);
      
      final candidates = [
        'Red',
        'Green',
        'Blue',
        'Purple',
      ];
      
      final candidateColors = [
        Color.fromARGB(255, 255, 0, 0),   // Red
        Color.fromARGB(255, 0, 255, 0),   // Green  
        Color.fromARGB(255, 0, 0, 255),   // Blue
        Color.fromARGB(255, 128, 0, 128), // Purple (closest to target)
      ];
      
      final mostSimilar = ColorSpaces.findMostSimilarColor(
        targetColor,
        candidates,
        (name) => candidateColors[candidates.indexOf(name)],
      );
      
      expect(mostSimilar, equals('Purple'));
    });

    test('most similar color finding throws on empty list', () {
      final targetColor = Color.fromARGB(255, 128, 64, 192);
      
      expect(
        () => ColorSpaces.findMostSimilarColor(
          targetColor,
          <String>[],
          (name) => Color.fromARGB(255, 0, 0, 0),
        ),
        throwsArgumentError,
      );
    });

    test('similarity percentage calculation works correctly', () {
      final color1 = Color.fromARGB(255, 128, 128, 128);
      final color2 = Color.fromARGB(255, 128, 128, 128); // Identical
      final color3 = Color.fromARGB(255, 130, 130, 130); // Very similar
      final color4 = Color.fromARGB(255, 255, 0, 0);     // Very different
      
      final identicalSimilarity = ColorSpaces.calculateSimilarityPercentage(color1, color2);
      final verySimilarSimilarity = ColorSpaces.calculateSimilarityPercentage(color1, color3);
      final differentSimilarity = ColorSpaces.calculateSimilarityPercentage(color1, color4);
      
      // Identical colors should have 100% similarity
      expect(identicalSimilarity, closeTo(100, 0.1));
      
      // Very similar colors should have high similarity
      expect(verySimilarSimilarity, greaterThan(90));
      
      // Different colors should have lower similarity
      expect(differentSimilarity, lessThan(verySimilarSimilarity));
      
      // All percentages should be in valid range
      expect(identicalSimilarity, greaterThanOrEqualTo(0));
      expect(identicalSimilarity, lessThanOrEqualTo(100));
      expect(verySimilarSimilarity, greaterThanOrEqualTo(0));
      expect(verySimilarSimilarity, lessThanOrEqualTo(100));
      expect(differentSimilarity, greaterThanOrEqualTo(0));
      expect(differentSimilarity, lessThanOrEqualTo(100));
    });

    test('CIEDE2000 gives reasonable results for known color pairs', () {
      // Test some known color pairs that should have specific relationships
      final red = Color.fromARGB(255, 255, 0, 0);
      final darkRed = Color.fromARGB(255, 128, 0, 0);
      final blue = Color.fromARGB(255, 0, 0, 255);
      
      final redToDarkRed = ColorSpaces.ciede2000Distance(red, darkRed);
      final redToBlue = ColorSpaces.ciede2000Distance(red, blue);
      
      // Red to dark red should be closer than red to blue
      expect(redToDarkRed, lessThan(redToBlue));
    });

    test('ColorDistanceAlgorithm enum has expected values', () {
      expect(ColorDistanceAlgorithm.values, contains(ColorDistanceAlgorithm.ciede2000));
      expect(ColorDistanceAlgorithm.values, contains(ColorDistanceAlgorithm.labEuclidean));
      expect(ColorDistanceAlgorithm.values, contains(ColorDistanceAlgorithm.euclidean));
    });

    test('ColorSpace enum has expected values', () {
      expect(ColorSpace.values, contains(ColorSpace.rgb));
      expect(ColorSpace.values, contains(ColorSpace.cieLab));
    });
  });
}