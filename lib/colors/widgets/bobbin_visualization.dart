import 'package:flutter/material.dart';
import 'package:thread_digit/colors/model/embroidery_machine.dart';

class BobbinVisualization extends StatelessWidget {
  final EmbroideryMachine machine;

  const BobbinVisualization({required this.machine, super.key});

  @override
  Widget build(BuildContext context) {
    final int threadCount = machine.threads.length;
    return SizedBox(
      height: 200,
      child: GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: (threadCount / 2).ceil(),
          childAspectRatio: 1,
        ),
        itemCount: threadCount,
        itemBuilder: (context, index) {
          final color = machine.threads[index].color;
          return Padding(
            padding: const EdgeInsets.all(4.0),
            child: CustomPaint(
              painter: BobbinPainter(color: Color.fromARGB(255, color.red, color.green, color.blue)),
              child: Center(child: Text('${machine.threads[index].positionX},${machine.threads[index].positionY}')),
            ),
          );
        },
      ),
    );
  }
}

class BobbinPainter extends CustomPainter {
  final Color color;

  BobbinPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(size.width / 2, size.height / 2), size.width / 2, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
