import 'dart:math' as math;
import 'dart:ui';

/// Color space conversion utilities for embroidery algorithm optimization.
///
/// Provides accurate conversions between RGB and LAB color spaces using
/// standard illuminant D65 for perceptual color processing.
class ColorConversionUtils {
  /// Standard illuminant D65 white point values for LAB conversion
  static const double xn = 95.047;
  static const double yn = 100.0;
  static const double zn = 108.883;

  /// Conversion constants for LAB color space
  static const double kappa = 24389.0 / 27.0;
  static const double epsilon = 216.0 / 24389.0;
  static const double cubicRoot = 1.0 / 3.0;

  /// Converts RGB color (0-255) to LAB color space.
  /// Returns LAB values where L: 0-100, a: -128 to +127, b: -128 to +127
  static LabColor rgbToLab(int red, int green, int blue) {
    // Step 1: Convert RGB to XYZ color space
    final xyz = _rgbToXyz(red, green, blue);

    // Step 2: Convert XYZ to LAB color space
    return _xyzToLab(xyz.x, xyz.y, xyz.z);
  }

  /// Converts LAB color to RGB color space.
  /// Returns RGB values clamped to 0-255 range
  static Color labToRgb(LabColor lab) {
    // Step 1: Convert LAB to XYZ color space
    final xyz = _labToXyz(lab);

    // Step 2: Convert XYZ to RGB color space
    return _xyzToRgb(xyz.x, xyz.y, xyz.z);
  }

  /// Converts RGB to XYZ color space (intermediate step for LAB conversion)
  static XyzColor _rgbToXyz(int red, int green, int blue) {
    // Normalize RGB values to 0-1 range
    double r = red / 255.0;
    double g = green / 255.0;
    double b = blue / 255.0;

    // Apply gamma correction (sRGB to linear RGB)
    r = _gammaCorrection(r);
    g = _gammaCorrection(g);
    b = _gammaCorrection(b);

    // Convert linear RGB to XYZ using sRGB matrix
    final x = r * 0.4124564 + g * 0.3575761 + b * 0.1804375;
    final y = r * 0.2126729 + g * 0.7151522 + b * 0.0721750;
    final z = r * 0.0193339 + g * 0.1191920 + b * 0.9503041;

    return XyzColor(x * 100, y * 100, z * 100);
  }

  /// Applies gamma correction for sRGB color space
  static double _gammaCorrection(double value) {
    if (value <= 0.04045) {
      return value / 12.92;
    } else {
      return math.pow((value + 0.055) / 1.055, 2.4).toDouble();
    }
  }

  /// Converts XYZ to LAB color space using D65 illuminant
  static LabColor _xyzToLab(double x, double y, double z) {
    // Normalize by D65 white point
    final fx = _labFunction(x / xn);
    final fy = _labFunction(y / yn);
    final fz = _labFunction(z / zn);

    // Calculate LAB components
    final l = 116 * fy - 16;
    final a = 500 * (fx - fy);
    final b = 200 * (fy - fz);

    return LabColor(l, a, b);
  }

  /// LAB conversion function with cubic root and linear fallback
  static double _labFunction(double t) {
    if (t > epsilon) {
      return math.pow(t, cubicRoot).toDouble();
    } else {
      return (kappa * t + 16) / 116;
    }
  }

  /// Converts LAB to XYZ color space
  static XyzColor _labToXyz(LabColor lab) {
    final fy = (lab.l + 16) / 116;
    final fx = lab.a / 500 + fy;
    final fz = fy - lab.b / 200;

    final x = _inverseLab(fx) * xn;
    final y = _inverseLab(fy) * yn;
    final z = _inverseLab(fz) * zn;

    return XyzColor(x, y, z);
  }

  /// Inverse LAB function
  static double _inverseLab(double t) {
    if (t > 216.0 / 24389.0) {
      return math.pow(t, 3).toDouble();
    } else {
      return (116 * t - 16) / kappa;
    }
  }

  /// Converts XYZ to RGB color space
  static Color _xyzToRgb(double x, double y, double z) {
    // Normalize XYZ values
    x /= 100;
    y /= 100;
    z /= 100;

    // Convert XYZ to linear RGB using inverse sRGB matrix
    double r = x * 3.2404542 + y * -1.5371385 + z * -0.4985314;
    double g = x * -0.9692660 + y * 1.8760108 + z * 0.0415560;
    double b = x * 0.0556434 + y * -0.2040259 + z * 1.0572252;

    // Apply inverse gamma correction
    r = _inverseGammaCorrection(r);
    g = _inverseGammaCorrection(g);
    b = _inverseGammaCorrection(b);

    // Convert to 0-255 range and clamp
    final red = (r * 255).round().clamp(0, 255);
    final green = (g * 255).round().clamp(0, 255);
    final blue = (b * 255).round().clamp(0, 255);

    return Color.fromARGB(255, red, green, blue);
  }

  /// Applies inverse gamma correction for sRGB color space
  static double _inverseGammaCorrection(double value) {
    if (value <= 0.0031308) {
      return 12.92 * value;
    } else {
      return 1.055 * math.pow(value, 1.0 / 2.4) - 0.055;
    }
  }

  /// Validates LAB color values are within expected ranges
  static bool isValidLab(LabColor lab) {
    return lab.l >= 0 && lab.l <= 100 &&
           lab.a >= -128 && lab.a <= 127 &&
           lab.b >= -128 && lab.b <= 127;
  }

  /// Validates RGB color values are within 0-255 range
  static bool isValidRgb(int red, int green, int blue) {
    return red >= 0 && red <= 255 &&
           green >= 0 && green <= 255 &&
           blue >= 0 && blue <= 255;
  }

  /// Calculates Euclidean distance in LAB color space
  static double labDistance(LabColor lab1, LabColor lab2) {
    final dl = lab1.l - lab2.l;
    final da = lab1.a - lab2.a;
    final db = lab1.b - lab2.b;
    return math.sqrt(dl * dl + da * da + db * db);
  }
}

/// Represents a color in LAB color space
class LabColor {
  const LabColor(this.l, this.a, this.b);

  /// Lightness component (0-100)
  final double l;

  /// Green-red color component (-128 to +127)
  final double a;

  /// Blue-yellow color component (-128 to +127)
  final double b;

  @override
  String toString() => 'LAB($l, $a, $b)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LabColor &&
          runtimeType == other.runtimeType &&
          (l - other.l).abs() < 0.001 &&
          (a - other.a).abs() < 0.001 &&
          (b - other.b).abs() < 0.001;

  @override
  int get hashCode => Object.hash(
    (l * 1000).round(),
    (a * 1000).round(),
    (b * 1000).round(),
  );
}

/// Represents a color in XYZ color space (intermediate for conversions)
class XyzColor {
  const XyzColor(this.x, this.y, this.z);

  final double x;
  final double y;
  final double z;

  @override
  String toString() => 'XYZ($x, $y, $z)';
}
