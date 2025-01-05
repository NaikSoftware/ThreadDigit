import 'dart:collection';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;

class EmbroideryGenerator {
  final int maxColors = 10;
  final double minStitchLength = 0.5;
  final double maxStitchLength = 7.0;
  final double stitchSpacingMm = 0.4; // Stitch spacing in millimeters

  List<StitchSequence> generateEmbroidery(img.Image inputImage) {
    // Resize the image for faster processing
    final img.Image image = img.copyResize(inputImage, width: 300);

    final (List<List<Point<int>>> segments, colors) = segmentImage(image, 7, 6, 2);

    final textureDirections = _analyzeTextureDirections(image);

    return _generateStitches(textureDirections, segments, image);
    // var segments = _segmentImage(image);
    // var edges = _detectEdges(image);
    //
    // List<StitchSequence> stitchSequences = [];
    //
    // for (var segment in segments) {
    //   var color = _getDominantColor(segment);
    //   var stitches = [];
    //
    //   if (isEdge(segment, edges)) {
    //     stitches = generateEdgeStitches(segment, textureDirections);
    //   } else if (isLargeDetail(segment)) {
    //     stitches = generateLongStitches(segment, textureDirections, maxLength: 7.0);
    //   } else {
    //     stitches = generateShortStitches(segment, textureDirections, maxLength: 2.0);
    //   }
    //
    //   stitchSequences.add(StitchSequence(stitches: stitches, color: color));
    // }
    //
    // return optimizeStitchLengths(stitchSequences);
  }

  (List<List<Point<int>>>, List<Color>) segmentImage(img.Image image, double maxDistanceMm, int mainColorsCount, int minSegmentSize) {
    final width = image.width;
    final height = image.height;
    final visited = List.generate(height, (_) => List.filled(width, false));
    final segments = <List<Point<int>>>[];

    // Create a palette with the specified number of main colors
    final List<Color> palette = _createPalette(mainColorsCount, image);

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        if (!visited[y][x]) {
          final segment = <Point<int>>[];
          final pixelColor = Color(_getPixel(image, x, y));
          final colorIndex = _findClosestColorIndex(pixelColor, palette);
          _floodFill(image, x, y, colorIndex, maxDistanceMm, visited, segment, palette);

          if (segment.length >= minSegmentSize) {
            segments.add(segment);
          } else {
            _handleSmallSegment(segment, segments, visited, image, palette, minSegmentSize);
          }
        }
      }
    }

    // Sort segments by color (according to palette order) and then by size
    final sortedSegments = <List<Point<int>>>[];
    final sortedColors = <Color>[];

    for (int i = 0; i < palette.length; i++) {
      final segmentsOfColor = segments.where((segment) {
        final dominantColor = _getDominantColor(segment, image);
        return _findClosestColorIndex(dominantColor, palette) == i;
      }).toList();

      // Sort segments of the same color by size (largest to smallest)
      segmentsOfColor.sort((a, b) => b.length.compareTo(a.length));

      sortedSegments.addAll(segmentsOfColor);
      sortedColors.addAll(List.filled(segmentsOfColor.length, palette[i]));
    }

    return (sortedSegments, sortedColors);
  }

  void _handleSmallSegment(
    List<Point<int>> smallSegment,
    List<List<Point<int>>> segments,
    List<List<bool>> visited,
    img.Image image,
    List<Color> palette,
    int minSegmentSize,
  ) {
    final smallSegmentColor = _getDominantColor(smallSegment, image);
    final smallSegmentColorIndex = _findClosestColorIndex(smallSegmentColor, palette);

    var closestSegment = _findClosestCompatibleSegment(smallSegment, segments, image, palette, smallSegmentColorIndex);

    if (closestSegment != null) {
      // Merge small segment with the closest compatible segment
      closestSegment.addAll(smallSegment);
      for (var point in smallSegment) {
        visited[point.y][point.x] = true;
      }
    } else {
      // If no compatible segment found, try to grow the small segment
      _growSmallSegment(smallSegment, segments, visited, image, palette, minSegmentSize);
    }
  }

  List<Point<int>>? _findClosestCompatibleSegment(
    List<Point<int>> smallSegment,
    List<List<Point<int>>> segments,
    img.Image image,
    List<Color> palette,
    int smallSegmentColorIndex,
  ) {
    double minDistance = double.infinity;
    List<Point<int>>? closestSegment;

    for (var segment in segments) {
      var segmentColor = _getDominantColor(segment, image);
      var segmentColorIndex = _findClosestColorIndex(segmentColor, palette);

      if ((segmentColorIndex - smallSegmentColorIndex).abs() <= 1) {
        for (var smallPoint in smallSegment) {
          for (var segmentPoint in segment) {
            double distance = _calculateDistance(smallPoint, segmentPoint);
            if (distance < minDistance) {
              minDistance = distance;
              closestSegment = segment;
            }
          }
        }
      }
    }

    return closestSegment;
  }

  void _growSmallSegment(
    List<Point<int>> smallSegment,
    List<List<Point<int>>> segments,
    List<List<bool>> visited,
    img.Image image,
    List<Color> palette,
    int minSegmentSize,
  ) {
    final queue = Queue<Point<int>>.from(smallSegment);
    final smallSegmentColor = _getDominantColor(smallSegment, image);
    final smallSegmentColorIndex = _findClosestColorIndex(smallSegmentColor, palette);

    while (smallSegment.length < minSegmentSize && queue.isNotEmpty) {
      final point = queue.removeFirst();

      for (int dy = -1; dy <= 1; dy++) {
        for (int dx = -1; dx <= 1; dx++) {
          if (dx == 0 && dy == 0) continue;
          final newX = point.x + dx;
          final newY = point.y + dy;

          if (newX >= 0 && newX < image.width && newY >= 0 && newY < image.height && !visited[newY][newX]) {
            final newColor = Color(_getPixel(image, newX, newY));
            final newColorIndex = _findClosestColorIndex(newColor, palette);

            if ((newColorIndex - smallSegmentColorIndex).abs() <= 1) {
              smallSegment.add(Point(newX, newY));
              visited[newY][newX] = true;
              queue.add(Point(newX, newY));

              if (smallSegment.length >= minSegmentSize) {
                segments.add(smallSegment);
                return;
              }
            }
          }
        }
      }
    }

    // If we couldn't grow the segment enough, we'll add it anyway
    if (smallSegment.isNotEmpty) {
      segments.add(smallSegment);
    }
  }

  double _calculateDistance(Point<int> p1, Point<int> p2) {
    return sqrt(pow(p1.x - p2.x, 2) + pow(p1.y - p2.y, 2));
  }

  void _floodFill(
    img.Image image,
    int x,
    int y,
    int colorIndex,
    double maxDistanceMm,
    List<List<bool>> visited,
    List<Point<int>> segment,
    List<Color> palette,
  ) {
    final queue = Queue<Point<int>>();
    queue.add(Point(x, y));

    while (queue.isNotEmpty) {
      final point = queue.removeFirst();
      final px = point.x;
      final py = point.y;

      if (px < 0 || px >= image.width || py < 0 || py >= image.height || visited[py][px]) {
        continue;
      }

      if (_findClosestColorIndex(Color(_getPixel(image, px, py)), palette) == colorIndex) {
        visited[py][px] = true;
        segment.add(Point(px, py));

        for (int dy = -1; dy <= 1; dy++) {
          for (int dx = -1; dx <= 1; dx++) {
            if (dx == 0 && dy == 0) continue;
            final newX = px + dx;
            final newY = py + dy;
            if (_isWithinDistance(px, py, newX, newY, maxDistanceMm)) {
              queue.add(Point(newX, newY));
            }
          }
        }
      }
    }
  }

  bool _isWithinDistance(int x1, int y1, int x2, int y2, double maxDistanceMm) {
    final dx = x2 - x1;
    final dy = y2 - y1;
    final distancePixels = sqrt(dx * dx + dy * dy);
    final distanceMm = distancePixels * (25.4 / 300); // Assuming the image has a resolution of 300 DPI
    return distanceMm <= maxDistanceMm;
  }

  List<Color> _createPalette(int mainColorsCount, img.Image image) {
    final Map<Color, int> colorCount = {};
    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final color = Color(_getPixel(image, x, y));
        colorCount[color] = (colorCount[color] ?? 0) + 1;
      }
    }
    final sortedColors = colorCount.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return sortedColors.take(mainColorsCount).map((e) => e.key).toList();
  }

  int _findClosestColorIndex(Color color, List<Color> palette) {
    return palette.indexOf(palette.reduce((a, b) => _colorDistance(color, a) < _colorDistance(color, b) ? a : b));
  }

  double _colorDistance(Color c1, Color c2) {
    final rDiff = c1.red - c2.red;
    final gDiff = c1.green - c2.green;
    final bDiff = c1.blue - c2.blue;
    return sqrt(rDiff * rDiff + gDiff * gDiff + bDiff * bDiff);
  }

  List<StitchSequence> _generateStitches(
    List<List<TextureDirection>> textureDirections,
    List<List<Point<int>>> segments,
    img.Image image,
  ) {
    List<StitchSequence> stitchSequences = [];

    for (var segment in segments) {
      Color color = _getDominantColor(segment, image);
      List<Stitch> stitches = [];
      Point<int>? lastPoint;

      // Sort points to create a continuous path
      segment = _sortSegmentPoints(segment);

      for (int i = 0; i < segment.length; i++) {
        Point<int> currentPoint = segment[i];
        if (lastPoint == null) {
          lastPoint = currentPoint;
          continue;
        }

        double distance = _calculateDistance(lastPoint, currentPoint);
        TextureDirection direction = textureDirections[currentPoint.y][currentPoint.x];

        if (distance < minStitchLength) {
          continue; // Skip if points are too close
        }

        if (distance > maxStitchLength) {
          // Split into multiple stitches
          int parts = (distance / maxStitchLength).ceil();
          for (int j = 1; j <= parts; j++) {
            double ratio = j / parts;
            double endX = lastPoint!.x.toDouble() + (currentPoint.x - lastPoint.x) * ratio;
            double endY = lastPoint.y.toDouble() + (currentPoint.y - lastPoint.y) * ratio;

            stitches.add(Stitch(
              x: lastPoint.x.toDouble(),
              y: lastPoint.y.toDouble(),
              endX: endX,
              endY: endY,
            ));

            lastPoint = Point(endX.round(), endY.round());
          }
        } else {
          // Adjust stitch direction based on texture
          double angleAdjustment = direction.confidence * direction.angle;
          double dx = currentPoint.x.toDouble() - lastPoint.x.toDouble();
          double dy = currentPoint.y.toDouble() - lastPoint.y.toDouble();
          double adjustedX = lastPoint.x + (dx * cos(angleAdjustment) - dy * sin(angleAdjustment));
          double adjustedY = lastPoint.y + (dx * sin(angleAdjustment) + dy * cos(angleAdjustment));

          stitches.add(Stitch(
            x: lastPoint.x.toDouble(),
            y: lastPoint.y.toDouble(),
            endX: adjustedX,
            endY: adjustedY,
          ));

          lastPoint = Point(adjustedX.round(), adjustedY.round());
        }
      }

      if (stitches.isNotEmpty) {
        stitchSequences.add(StitchSequence(stitches: stitches, color: color));
      }
    }

    return stitchSequences;
  }

  List<Point<int>> _sortSegmentPoints(List<Point<int>> segment) {
    List<Point<int>> sorted = [segment.first];
    Set<Point<int>> remaining = segment.toSet()..remove(segment.first);

    while (remaining.isNotEmpty) {
      Point<int> last = sorted.last;
      Point<int> next = remaining.reduce((a, b) => _calculateDistance(last, a) < _calculateDistance(last, b) ? a : b);
      sorted.add(next);
      remaining.remove(next);
    }

    return sorted;
  }

  Color _getDominantColor(List<Point<int>> segment, img.Image image) {
    final colorCount = <Color, int>{};

    for (var point in segment) {
      final color = Color(_getPixel(image, point.x, point.y));
      colorCount[color] = (colorCount[color] ?? 0) + 1;
    }

    return colorCount.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  }

  List<List<TextureDirection>> _analyzeTextureDirections(img.Image image) {
    final width = image.width;
    final height = image.height;
    final directions = List.generate(
      height,
      (_) => List.generate(width, (_) => TextureDirection(0, 0)),
    );

    const kernelSize = 20;
    const halfKernel = kernelSize ~/ 2;

    for (int y = halfKernel; y < height - halfKernel; y++) {
      for (int x = halfKernel; x < width - halfKernel; x++) {
        var sumX = 0.0, sumY = 0.0, sumXX = 0.0, sumYY = 0.0, sumXY = 0.0;
        var maxGradient = 0.0;

        for (int ky = -halfKernel; ky <= halfKernel; ky++) {
          for (int kx = -halfKernel; kx <= halfKernel; kx++) {
            final gx =
                _rgbToGray(_getPixel(image, x + kx + 1, y + ky)) - _rgbToGray(_getPixel(image, x + kx - 1, y + ky));
            final gy =
                _rgbToGray(_getPixel(image, x + kx, y + ky + 1)) - _rgbToGray(_getPixel(image, x + kx, y + ky - 1));

            sumX += gx;
            sumY += gy;
            sumXX += gx * gx;
            sumYY += gy * gy;
            sumXY += gx * gy;

            maxGradient = max(maxGradient, sqrt(gx * gx + gy * gy));
          }
        }

        const windowSize = kernelSize * kernelSize;
        final meanX = sumX / windowSize;
        final meanY = sumY / windowSize;
        final varX = sumXX / windowSize - meanX * meanX;
        final varY = sumYY / windowSize - meanY * meanY;
        final covarXY = sumXY / windowSize - meanX * meanY;

        double angle = 0.5 * atan2(2 * covarXY, varX - varY);
        double confidence = sqrt(pow(varX - varY, 2) + 4 * covarXY * covarXY) / (varX + varY);

        // Перевірка на однотонний фон
        if (maxGradient < 0.05) {
          angle = 0;
          confidence = 0;
        }

        // Перевірка на лінію або волосину
        if (confidence > 0.8 && maxGradient > 0.2) {
          // Уточнення кута для ліній та волосин
          angle = atan2(sumY, sumX);
          confidence = min(confidence * 1.5, 1.0); // Підвищуємо впевненість для чітких ліній
        }

        // Перевірка на шерсть або текстуру з багатьма напрямками
        if (confidence < 0.3 && maxGradient > 0.1) {
          // Використовуємо локальний напрямок градієнта
          angle = atan2(sumY, sumX);
          confidence = min(maxGradient, 0.5); // Обмежуємо впевненість для неоднорідних текстур
        }

        // Перевірка на NaN та нескінченність
        if (angle.isNaN || angle.isInfinite) angle = 0;
        if (confidence.isNaN || confidence.isInfinite) confidence = 0;

        directions[y][x] = TextureDirection(angle, confidence);
      }
    }

    return directions;
  }

  int _getPixel(img.Image image, int x, int y) {
    if (x < 0) {
      x = 0;
    } else if (x >= image.width) {
      x = image.width - 1;
    }
    if (y < 0) {
      y = 0;
    } else if (y >= image.height) {
      y = image.height - 1;
    }
    final pixel = image.getPixel(x, y);

    return Color.fromARGB(0xFF, pixel.r.toInt(), pixel.g.toInt(), pixel.b.toInt()).value;
  }

  double _rgbToGray(int color) {
    final r = (color >> 16) & 0xFF;
    final g = (color >> 8) & 0xFF;
    final b = color & 0xFF;
    return (0.299 * r + 0.587 * g + 0.114 * b) / 255.0;
  }
}

class TextureDirection {
  final double angle;
  final double confidence;

  TextureDirection(this.angle, this.confidence);
}

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
