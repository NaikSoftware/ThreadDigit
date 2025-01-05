import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:thread_digit/photostitch/photo_stitch.dart';

class StitchesPainter extends CustomPainter {
  final List<StitchSequence> stitchSequences;
  final int currentSequenceIndex;
  final int currentStitchIndex;

  StitchesPainter(this.stitchSequences, {
    required this.currentSequenceIndex,
    required this.currentStitchIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawColor(Colors.cyan, BlendMode.src);
    Offset? lastEndPoint;

    for (int i = 0; i <= currentSequenceIndex; i++) {
      var sequence = stitchSequences[i];
      if (sequence.color == Colors.white) continue;
      final threadShader = _createThreadShader(sequence.color);
      final paint = Paint()
        ..shader = threadShader
        ..strokeWidth = 1.0
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      int stitchLimit = (i == currentSequenceIndex) ? currentStitchIndex : sequence.stitches.length;
      for (int j = 0; j < stitchLimit; j++) {
        var stitch = sequence.stitches[j];
        Offset startPoint = Offset(stitch.x, stitch.y);
        Offset endPoint = Offset(stitch.endX, stitch.endY);

        if (lastEndPoint != null && startPoint != lastEndPoint) {
          // _drawThreadCut(canvas, startPoint);
        }

        _drawStitch(canvas, startPoint, endPoint, paint);
        lastEndPoint = endPoint;
      }
    }
  }

  void _drawStitch(Canvas canvas, Offset start, Offset end, Paint paint) {
    final path = Path()
      ..moveTo(start.dx, start.dy)
      ..lineTo(end.dx, end.dy);
    canvas.drawPath(path, paint);
  }

  void _drawThreadCut(Canvas canvas, Offset point) {
    final paint = Paint()
      ..color = Colors.red.withOpacity(0.5)
      ..strokeWidth = 1.0;

    canvas.drawCircle(point, 2.0, paint);
  }

  ui.Shader _createThreadShader(Color baseColor) {
    return ui.Gradient.linear(
      const Offset(0, 0),
      const Offset(10, 0),
      [
        baseColor.withOpacity(0.7),
        baseColor,
        baseColor.withOpacity(0.7),
      ],
      [0.0, 0.5, 1.0],
      TileMode.repeated,
      Matrix4.rotationZ(0.5).storage,
    );
  }

  @override
  bool shouldRepaint(covariant StitchesPainter oldDelegate) {
    return oldDelegate.currentSequenceIndex != currentSequenceIndex ||
        oldDelegate.currentStitchIndex != currentStitchIndex;
  }
}
