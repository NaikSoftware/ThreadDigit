import 'dart:ui';

import 'package:image/image.dart' as img;

final class Stitch {
  final double x;
  final double y;
  final double endX;
  final double endY;

  Stitch({
    required this.x,
    required this.y,
    required this.endX,
    required this.endY,
  });
}

final class StitchSequence {
  final List<Stitch> stitches;
  final Color color;

  const StitchSequence({
    required this.stitches,
    required this.color,
  });
}

/// Analyze an image and generate a list of stitch sequences. The stitch sequences are generated based
/// on the image analysis (colors, gradients, edges, etc.).
/// [image] - the image to analyze
/// [maxStitchLength] - maximum length of stitches in mm
/// [stitchSpacing] - spacing between stitches in mm
List<StitchSequence> stitchImage(
  img.Image image, {
  double minStitchLength = 0.5,
  double maxStitchLength = 7.0,
  double stitchSpacing = 0.4,
}) {
  List<StitchSequence> stitchSequences = [];

  // Convert image to a list of colors
  Map<img.Pixel, List<Stitch>> colorStitchesMap = {};

  for (int y = 0; y < image.height; y++) {
    for (int x = 0; x < image.width; x++) {
      final pixel = image.getPixel(x, y);
      if (!colorStitchesMap.containsKey(pixel)) {
        colorStitchesMap[pixel] = [];
      }

      // Generate stitches for the current pixel
      double startX = x.toDouble();
      double startY = y.toDouble();
      double endX = startX + stitchSpacing;
      double endY = startY + stitchSpacing;

      // Ensure the stitch length is within the specified range
      double stitchLength = ((endX - startX).abs() + (endY - startY).abs()).clamp(minStitchLength, maxStitchLength);

      if (stitchLength >= minStitchLength && stitchLength <= maxStitchLength) {
        colorStitchesMap[pixel]!.add(Stitch(
          x: startX,
          y: startY,
          endX: endX,
          endY: endY,
        ));
      }
    }
  }

  // Convert the map to a list of StitchSequence
  colorStitchesMap.forEach((pixel, stitches) {
    stitchSequences.add(StitchSequence(
      stitches: stitches,
      color: Color.fromARGB(0xFF, pixel.r.toInt(), pixel.g.toInt(), pixel.b.toInt()),
    ));
  });

  return stitchSequences;
}
