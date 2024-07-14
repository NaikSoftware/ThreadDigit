import 'package:flutter/material.dart';
import 'package:thread_digit/photostitch/photo_stitch.dart';

class StitchesWidget extends StatelessWidget {
  final List<StitchSequence> stitchSequences;

  const StitchesWidget({
    required this.stitchSequences,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: StitchesPainter(stitchSequences),
    );
  }
}

class StitchesPainter extends CustomPainter {
  final List<StitchSequence> stitchSequences;

  StitchesPainter(this.stitchSequences);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawColor(Colors.amber.shade50, BlendMode.src);
    for (var sequence in stitchSequences) {
      final paint = Paint()
        ..color = sequence.color
        ..strokeWidth = 1.0;

      for (var stitch in sequence.stitches) {
        canvas.drawLine(
          Offset(stitch.x, stitch.y),
          Offset(stitch.endX, stitch.endY),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
