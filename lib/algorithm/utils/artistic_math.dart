import 'dart:math' as math;
import 'dart:ui';

/// Advanced mathematical utilities for photorealistic embroidery techniques.
///
/// Provides sophisticated calculations for color temperature, gradient analysis,
/// and artistic transformations used in silk shading and sfumato techniques.
class ArtisticMath {
  /// Private constructor to prevent instantiation
  ArtisticMath._();

  // Color temperature constants (in Kelvin)
  static const double warmTemperature = 3000.0; // Candlelight/sunset
  static const double neutralTemperature = 6500.0; // Daylight
  static const double coolTemperature = 10000.0; // Blue sky

  /// Calculates the artistic color temperature shift for depth perception.
  ///
  /// Warmer colors appear closer, cooler colors recede into distance.
  /// Used for atmospheric perspective in photorealistic embroidery.
  static Color applyColorTemperature(Color baseColor, double temperature) {
    // Normalize temperature to 0.0-1.0 range
    final normalizedTemp = ((temperature - warmTemperature) / 
        (coolTemperature - warmTemperature)).clamp(0.0, 1.0);

    final r = (baseColor.r * 255.0).round() & 0xff;
    final g = (baseColor.g * 255.0).round() & 0xff;
    final b = (baseColor.b * 255.0).round() & 0xff;

    // Apply temperature bias
    if (normalizedTemp < 0.5) {
      // Warm bias - enhance reds and yellows
      final warmFactor = 1.0 - (normalizedTemp * 2.0);
      final newR = (r + (255 - r) * warmFactor * 0.1).round().clamp(0, 255);
      final newG = (g + (255 - g) * warmFactor * 0.05).round().clamp(0, 255);
      return Color.fromARGB((baseColor.a * 255.0).round() & 0xff, newR, newG, b);
    } else {
      // Cool bias - enhance blues
      final coolFactor = (normalizedTemp - 0.5) * 2.0;
      final newB = (b + (255 - b) * coolFactor * 0.1).round().clamp(0, 255);
      final newG = (g + (255 - g) * coolFactor * 0.02).round().clamp(0, 255);
      return Color.fromARGB((baseColor.a * 255.0).round() & 0xff, r, newG, newB);
    }
  }

  /// Calculates gradient magnitude at a specific point for artistic analysis.
  ///
  /// Used to determine stitch density and artistic treatment intensity.
  /// Higher gradients indicate areas needing more detailed artistic treatment.
  static double calculateGradientMagnitude(double dx, double dy) {
    return math.sqrt(dx * dx + dy * dy);
  }

  /// Computes artistic smoothing coefficient for sfumato effects.
  ///
  /// Based on Leonardo da Vinci's sfumato technique - creates smooth
  /// transitions "like smoke" without harsh edges.
  static double calculateSfumatoSmoothing(
    double gradientMagnitude,
    double maxGradient,
    double sfumatoStrength,
  ) {
    if (maxGradient == 0) return 1.0;
    
    // Normalize gradient strength
    final normalizedGradient = (gradientMagnitude / maxGradient).clamp(0.0, 1.0);
    
    // Apply sfumato curve - stronger smoothing for higher gradients
    final smoothingFactor = 1.0 - math.pow(normalizedGradient, 0.5);
    
    return (sfumatoStrength * smoothingFactor).clamp(0.0, 1.0);
  }

  /// Calculates artistic thread opacity for layered silk shading effects.
  ///
  /// Simulates thread density variations to create natural shading
  /// similar to brush stroke opacity in traditional painting.
  static double calculateThreadOpacity(
    double baseOpacity,
    double localContrast,
    double artisticIntensity,
  ) {
    // Base opacity adjusted by local image characteristics
    final contrastBoost = localContrast * 0.3; // Enhance contrast areas
    final artisticModifier = artisticIntensity * 0.2; // Artist control
    
    final finalOpacity = baseOpacity + contrastBoost + artisticModifier;
    return finalOpacity.clamp(0.1, 1.0); // Maintain visibility range
  }

  /// Computes stitch angle variation for natural artistic appearance.
  ///
  /// Adds subtle randomness to prevent mechanical appearance while
  /// maintaining the primary direction field orientation.
  static double addArtisticVariation(
    double baseAngle,
    double variationStrength,
    math.Random random,
  ) {
    // Generate artistic variation (±15 degrees maximum)
    final maxVariation = math.pi / 12; // 15 degrees in radians
    final variation = (random.nextDouble() - 0.5) * 2 * maxVariation * variationStrength;
    
    return baseAngle + variation;
  }

  /// Calculates distance-based atmospheric perspective factor.
  ///
  /// Objects farther away appear lighter, cooler, and less detailed.
  /// Used for creating depth in photorealistic embroidery.
  static double calculateAtmosphericFactor(double depth, double maxDepth) {
    if (maxDepth == 0) return 1.0;
    
    final normalizedDepth = (depth / maxDepth).clamp(0.0, 1.0);
    
    // Atmospheric perspective curve - exponential fade
    return math.exp(-normalizedDepth * 2.0); // Factor from 1.0 to ~0.135
  }

  /// Computes color mixing coefficient for adjacent thread interaction.
  ///
  /// Simulates how threads naturally blend when placed close together,
  /// creating optical mixing effects similar to pointillism.
  static Color blendThreadColors(
    Color color1,
    Color color2,
    double blendFactor,
  ) {
    final factor = blendFactor.clamp(0.0, 1.0);
    final inverseFactor = 1.0 - factor;
    
    final r = (((color1.r * 255.0).round() & 0xff) * inverseFactor + ((color2.r * 255.0).round() & 0xff) * factor).round().clamp(0, 255);
    final g = (((color1.g * 255.0).round() & 0xff) * inverseFactor + ((color2.g * 255.0).round() & 0xff) * factor).round().clamp(0, 255);
    final b = (((color1.b * 255.0).round() & 0xff) * inverseFactor + ((color2.b * 255.0).round() & 0xff) * factor).round().clamp(0, 255);
    final a = (((color1.a * 255.0).round() & 0xff) * inverseFactor + ((color2.a * 255.0).round() & 0xff) * factor).round().clamp(0, 255);
    
    return Color.fromARGB(a, r, g, b);
  }

  /// Calculates adaptive stitch length for artistic control.
  ///
  /// Varies stitch length based on image complexity and artistic requirements.
  /// Shorter stitches for detailed areas, longer for smooth gradients.
  static double calculateArtisticStitchLength(
    double baseLength,
    double minLength,
    double maxLength,
    double imageComplexity,
    double artisticControl,
  ) {
    // Higher complexity = shorter stitches for detail preservation
    final complexityFactor = 1.0 - imageComplexity;
    
    // Apply artistic control (0.0 = more automatic, 1.0 = more artistic variation)
    final artisticLength = baseLength + (artisticControl - 0.5) * (maxLength - minLength) * 0.3;
    
    final finalLength = artisticLength * (0.5 + complexityFactor * 0.5);
    
    return finalLength.clamp(minLength, maxLength);
  }

  /// Computes silk shading intensity based on image analysis.
  ///
  /// Determines how strongly to apply silk shading technique in each region.
  /// Higher intensity for areas requiring more artistic treatment.
  static double calculateSilkShadingIntensity(
    double gradientMagnitude,
    double textureCoherence,
    double colorComplexity,
  ) {
    // Combine multiple factors for artistic decision
    final gradientContribution = gradientMagnitude * 0.4; // Edge importance
    final textureContribution = textureCoherence * 0.3; // Structure clarity
    final colorContribution = colorComplexity * 0.3; // Color variation
    
    final totalIntensity = gradientContribution + textureContribution + colorContribution;
    
    return totalIntensity.clamp(0.0, 1.0);
  }

  /// Applies Leonardo's golden ratio proportions to stitch spacing.
  ///
  /// Uses the mathematical harmony of the golden ratio (φ ≈ 1.618)
  /// for naturally pleasing stitch arrangements.
  static double applyGoldenRatioSpacing(double baseSpacing) {
    const double phi = 1.618033988749;
    
    // Apply subtle golden ratio influence for natural aesthetics
    return baseSpacing * (0.8 + 0.2 / phi);
  }

  /// Calculates thread tension simulation for realistic appearance.
  ///
  /// Simulates how thread tension affects stitch appearance,
  /// adding subtle curvature and natural variation.
  static Offset applyThreadTension(
    Offset startPoint,
    Offset endPoint,
    double tensionFactor,
  ) {
    if (tensionFactor <= 0.0) return endPoint;
    
    // Calculate perpendicular offset for thread sag/pull
    final dx = endPoint.dx - startPoint.dx;
    final dy = endPoint.dy - startPoint.dy;
    final length = math.sqrt(dx * dx + dy * dy);
    
    if (length == 0) return endPoint;
    
    // Perpendicular vector for tension effect
    final perpX = -dy / length;
    final perpY = dx / length;
    
    // Apply subtle tension displacement (maximum 5% of stitch length)
    final maxDisplacement = length * 0.05 * tensionFactor;
    final displacement = maxDisplacement * (0.5 - math.Random().nextDouble());
    
    return Offset(
      endPoint.dx + perpX * displacement,
      endPoint.dy + perpY * displacement,
    );
  }
}