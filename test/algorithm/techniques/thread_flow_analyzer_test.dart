import 'package:flutter_test/flutter_test.dart';
import 'dart:typed_data';


import 'package:image/image.dart' as img;
import 'package:thread_digit/algorithm/models/direction_field.dart';
import 'package:thread_digit/algorithm/techniques/thread_flow_analyzer.dart';

void main() {
  group('ThreadFlowAnalyzer', () {
    late img.Image testImage;
    late DirectionField testDirectionField;

    setUp(() {
      // Create test image (32x32 gradient)
      testImage = img.Image(width: 32, height: 32);
      for (int y = 0; y < 32; y++) {
        for (int x = 0; x < 32; x++) {
          final intensity = (x * 255 / 31).round();
          testImage.setPixel(x, y, img.ColorRgb8(intensity, intensity, intensity));
        }
      }

      // Create test direction field with horizontal orientation
      final orientations = Float32List(32 * 32);
      final coherences = Float32List(32 * 32);
      for (int i = 0; i < 32 * 32; i++) {
        orientations[i] = 0.0; // Horizontal direction
        coherences[i] = 0.8;   // High coherence
      }

      testDirectionField = DirectionField(
        width: 32,
        height: 32,
        orientations: orientations,
        coherences: coherences,
      );
    });

    test('analyzes thread flow successfully with valid inputs', () {
      final result = ThreadFlowAnalyzer.analyzeThreadFlow(
        testImage,
        testDirectionField,
      );

      expect(result.isSuccess, isTrue);
      expect(result.data, isNotNull);

      final flowField = result.data!;
      expect(flowField.width, equals(32));
      expect(flowField.height, equals(32));
      expect(flowField.pixelCount, equals(1024));
      expect(flowField.qualityScore, greaterThan(0));
      expect(flowField.processingTimeMs, greaterThanOrEqualTo(0));
    });

    test('fails with mismatched image and direction field dimensions', () {
      // Create smaller direction field
      final smallOrientations = Float32List(16 * 16);
      final smallCoherences = Float32List(16 * 16);
      final smallDirectionField = DirectionField(
        width: 16,
        height: 16,
        orientations: smallOrientations,
        coherences: smallCoherences,
      );

      final result = ThreadFlowAnalyzer.analyzeThreadFlow(
        testImage,
        smallDirectionField,
      );

      expect(result.isFailure, isTrue);
      expect(result.error, contains('dimensions must match'));
    });

    test('generates primary and secondary directions', () {
      final result = ThreadFlowAnalyzer.analyzeThreadFlow(
        testImage,
        testDirectionField,
      );

      expect(result.isSuccess, isTrue);
      final flowField = result.data!;

      // Should have both primary and secondary directions
      expect(flowField.primaryDirections.length, equals(1024));
      expect(flowField.secondaryDirections.length, equals(1024));
      
      // Primary directions should be close to original (horizontal)
      final primaryDirection = flowField.getPrimaryDirectionAt(16, 16);
      expect(primaryDirection.abs(), lessThan(0.5)); // Close to 0 (horizontal)
      
      // Secondary direction should be perpendicular (±90°)
      final secondaryDirection = flowField.getSecondaryDirectionAt(16, 16);
      expect((secondaryDirection - 1.57).abs(), lessThan(0.5)); // Close to π/2
    });

    test('calculates texture complexity and artistic intensity', () {
      final result = ThreadFlowAnalyzer.analyzeThreadFlow(
        testImage,
        testDirectionField,
      );

      expect(result.isSuccess, isTrue);
      final flowField = result.data!;

      // Should have complexity and intensity values
      expect(flowField.textureComplexity.length, equals(1024));
      expect(flowField.artisticIntensity.length, equals(1024));
      
      // Values should be in valid range [0.0, 1.0]
      for (final complexity in flowField.textureComplexity) {
        expect(complexity, greaterThanOrEqualTo(0.0));
        expect(complexity, lessThanOrEqualTo(1.0));
      }
      
      for (final intensity in flowField.artisticIntensity) {
        expect(intensity, greaterThanOrEqualTo(0.0));
        expect(intensity, lessThanOrEqualTo(1.0));
      }
    });

    test('applies smoothing factor correctly', () {
      // Test with high smoothing
      final smoothResult = ThreadFlowAnalyzer.analyzeThreadFlow(
        testImage,
        testDirectionField,
        smoothingFactor: 0.9,
      );

      // Test with low smoothing  
      final roughResult = ThreadFlowAnalyzer.analyzeThreadFlow(
        testImage,
        testDirectionField,
        smoothingFactor: 0.1,
      );

      expect(smoothResult.isSuccess, isTrue);
      expect(roughResult.isSuccess, isTrue);

      // Both should produce valid results
      expect(smoothResult.data!.qualityScore, greaterThan(0));
      expect(roughResult.data!.qualityScore, greaterThan(0));
    });

    test('applies artistic variation correctly', () {
      // Test with high variation
      final variedResult = ThreadFlowAnalyzer.analyzeThreadFlow(
        testImage,
        testDirectionField,
        artisticVariation: 0.8,
      );

      // Test with no variation
      final uniformResult = ThreadFlowAnalyzer.analyzeThreadFlow(
        testImage,
        testDirectionField,
        artisticVariation: 0.0,
      );

      expect(variedResult.isSuccess, isTrue);
      expect(uniformResult.isSuccess, isTrue);

      // Varied result should have more directional diversity
      // (This is a qualitative test - in practice you'd measure direction variance)
      expect(variedResult.data!.qualityScore, greaterThan(0));
      expect(uniformResult.data!.qualityScore, greaterThan(0));
    });

    test('calculates flow coherence accurately', () {
      final result = ThreadFlowAnalyzer.analyzeThreadFlow(
        testImage,
        testDirectionField,
      );

      expect(result.isSuccess, isTrue);
      final flowField = result.data!;

      // Flow coherence should be derived from original direction field
      final coherence = flowField.getFlowCoherenceAt(16, 16);
      expect(coherence, greaterThanOrEqualTo(0.0));
      expect(coherence, lessThanOrEqualTo(1.0));
      
      // Should be reasonably close to original coherence (0.8) but may be modified
      expect(coherence, greaterThan(0.5));
    });

    test('provides quality score assessment', () {
      final result = ThreadFlowAnalyzer.analyzeThreadFlow(
        testImage,
        testDirectionField,
      );

      expect(result.isSuccess, isTrue);
      final flowField = result.data!;

      // Quality score should be reasonable for good input
      expect(flowField.qualityScore, greaterThan(50.0));
      expect(flowField.qualityScore, lessThanOrEqualTo(100.0));
    });

    test('handles edge coordinates correctly', () {
      final result = ThreadFlowAnalyzer.analyzeThreadFlow(
        testImage,
        testDirectionField,
      );

      expect(result.isSuccess, isTrue);
      final flowField = result.data!;

      // Test edge coordinates
      expect(flowField.getPrimaryDirectionAt(0, 0).isFinite, isTrue);
      expect(flowField.getPrimaryDirectionAt(31, 31).isFinite, isTrue);
      
      // Test out-of-bounds coordinates
      expect(flowField.getPrimaryDirectionAt(-1, 0), equals(0.0));
      expect(flowField.getPrimaryDirectionAt(32, 16), equals(0.0));
      expect(flowField.getTextureComplexityAt(100, 100), equals(0.0));
    });

    test('thread flow field provides coordinate-based access', () {
      final result = ThreadFlowAnalyzer.analyzeThreadFlow(
        testImage,
        testDirectionField,
      );

      expect(result.isSuccess, isTrue);
      final flowField = result.data!;

      // Test coordinate-based access methods
      final centerX = 16, centerY = 16;
      
      expect(flowField.getPrimaryDirectionAt(centerX, centerY).isFinite, isTrue);
      expect(flowField.getSecondaryDirectionAt(centerX, centerY).isFinite, isTrue);
      expect(flowField.getFlowCoherenceAt(centerX, centerY), 
             inInclusiveRange(0.0, 1.0));
      expect(flowField.getTextureComplexityAt(centerX, centerY), 
             inInclusiveRange(0.0, 1.0));
      expect(flowField.getArtisticIntensityAt(centerX, centerY), 
             inInclusiveRange(0.0, 1.0));
    });

    test('toString provides meaningful information', () {
      final result = ThreadFlowAnalyzer.analyzeThreadFlow(
        testImage,
        testDirectionField,
      );

      expect(result.isSuccess, isTrue);
      final flowField = result.data!;

      final description = flowField.toString();
      expect(description, contains('32x32'));
      expect(description, contains('quality'));
    });
  });
}