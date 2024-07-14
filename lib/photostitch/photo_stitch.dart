import 'dart:developer';
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
  Map<int, List<Stitch>> colorStitches = {};

  // Convert mm to pixels (assuming 1mm = 3.779528 pixels)
  double pixelRatio = 3.779528;
  double minStitchLengthPx = minStitchLength * pixelRatio;
  double maxStitchLengthPx = maxStitchLength * pixelRatio;
  double stitchSpacingPx = stitchSpacing * pixelRatio;

  for (int y = 0; y < image.height; y += stitchSpacingPx.round()) {
    bool isEvenRow = (y ~/ stitchSpacingPx.round()) % 2 == 0;
    List<int> rowPixels = [];

    for (int x = 0; x < image.width; x++) {
      final pixel = image.getPixel(x, y);
      rowPixels.add(Color.fromARGB(0xFF, pixel.r.toInt(), pixel.g.toInt(), pixel.b.toInt()).value);
    }

    if (!isEvenRow) {
      rowPixels = rowPixels.reversed.toList();
    }

    double currentX = isEvenRow ? 0 : image.width.toDouble();
    int currentColor = rowPixels[isEvenRow ? 0 : rowPixels.length - 1];
    double startX = currentX;
    int colorCount = 0;

    for (int i = 0; i < rowPixels.length; i++) {
      int pixelColor = rowPixels[i];

      if (pixelColor != currentColor || i == rowPixels.length - 1) {
        double endX = isEvenRow ? i.toDouble() : (image.width - i).toDouble();
        double stitchLength = (endX - startX).abs();

        if (stitchLength >= minStitchLengthPx) {
          while (stitchLength > maxStitchLengthPx) {
            double partialEndX = startX + (isEvenRow ? maxStitchLengthPx : -maxStitchLengthPx);
            colorStitches.putIfAbsent(currentColor, () => []).add(
                Stitch(x: startX, y: y.toDouble(), endX: partialEndX, endY: y.toDouble())
            );
            startX = partialEndX;
            stitchLength -= maxStitchLengthPx;
          }

          colorStitches.putIfAbsent(currentColor, () => []).add(
              Stitch(x: startX, y: y.toDouble(), endX: endX, endY: y.toDouble())
          );
        }

        currentColor = pixelColor;
        startX = endX;
        colorCount = 1;
      } else {
        colorCount++;
      }

      currentX = isEvenRow ? (i + 1).toDouble() : (image.width - i - 1).toDouble();
    }
    log('Colors: $colorCount');
  }

  // Convert color stitches to StitchSequences
  colorStitches.forEach((color, stitches) {
    stitchSequences.add(StitchSequence(
      stitches: stitches,
      color: Color(color),
    ));
  });


  return stitchSequences;
}
