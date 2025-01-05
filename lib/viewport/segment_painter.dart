import 'dart:math';

import 'package:flutter/material.dart';

class SegmentPainter extends CustomPainter {
  final List<List<Point<int>>> segments;
  final List<Color> colors;
  final int currentIndex;

  SegmentPainter(this.segments, this.colors, this.currentIndex);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawColor(Colors.indigo, BlendMode.src);
    for (int i = 0; i < currentIndex && i < segments.length; i++) {
      final paint = Paint()
        ..color = colors[i]
        ..strokeWidth = 1
        ..style = PaintingStyle.fill;

      for (var point in segments[i]) {
        canvas.drawCircle(Offset(point.x.toDouble(), point.y.toDouble()), 1, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
