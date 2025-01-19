import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:thread_digit/colors/model/embroidery_machine.dart';
import 'package:thread_digit/colors/service/color_utils.dart';

class BobbinVisualization extends StatelessWidget {
  static const double _kSidePadding = 80.0;

  final EmbroideryMachine machine;

  const BobbinVisualization({required this.machine, super.key});

  @override
  Widget build(BuildContext context) {
    Map<int, List<ThreadConfig>> threadsByY = {};
    int columnCount = 0;
    for (var thread in machine.threads) {
      columnCount = math.max(columnCount, thread.positionX + 1);
      threadsByY.putIfAbsent(thread.positionY, () => []).add(thread);
    }
    List<int> sortedYPositions = threadsByY.keys.toList()..sort((a, b) => b.compareTo(a));
    final int rowCount = sortedYPositions.length;
    final double containerHeight = calculateHeight(context, machine);
    final double rowHeight = (containerHeight - 16) / rowCount;

    return Container(
      height: containerHeight,
      padding: const EdgeInsets.all(8),
      child: Column(
        children: sortedYPositions.map<Widget>((y) {
          final List<ThreadConfig> rowThreads = threadsByY[y]!;
          rowThreads.sort((a, b) => b.positionX.compareTo(a.positionX));

          return SizedBox(
            height: rowHeight,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: rowThreads.map<Widget>((thread) {
                return _BobbinWidget(
                  thread: thread,
                  size: rowHeight,
                  number: (thread.positionX + thread.positionY * columnCount + 1).toString(),
                );
              }).toList(),
            ),
          );
        }).toList(),
      ),
    );
  }

  static double calculateHeight(BuildContext context, EmbroideryMachine machine) {
    final MediaQueryData mediaQuery = MediaQuery.of(context);
    final double screenWidth = mediaQuery.size.width - _kSidePadding;
    Map<int, List<ThreadConfig>> threadsByY = {};
    int columnCount = 0;
    for (var thread in machine.threads) {
      columnCount = math.max(columnCount, thread.positionX + 1);
      threadsByY.putIfAbsent(thread.positionY, () => []).add(thread);
    }

    final int rowCount = threadsByY.length;
    final double rowHeight = (screenWidth / columnCount).clamp(0, mediaQuery.size.height / 3 / rowCount);
    final double bobbinHeight = (rowCount * rowHeight) + 16.0;
    return bobbinHeight;
  }
}

class _BobbinWidget extends StatelessWidget {
  final ThreadConfig thread;
  final double size;
  final String number;

  const _BobbinWidget({
    required this.thread,
    required this.size,
    required this.number,
  });

  @override
  Widget build(BuildContext context) {
    final color = thread.color;
    final bobbinColor = Color.fromARGB(255, color.red, color.green, color.blue);
    final textColor = ColorUtils.isLightColor(bobbinColor) ? Colors.black : Colors.white;

    return Padding(
      padding: const EdgeInsets.all(2.0),
      child: CustomPaint(
        painter: _BobbinPainter(color: bobbinColor),
        child: SizedBox(
          width: size - 4,
          height: size - 4,
          child: Center(
            child: Text(
              number,
              style: TextStyle(color: textColor, fontSize: size * 0.3),
            ),
          ),
        ),
      ),
    );
  }
}

class _BobbinPainter extends CustomPainter {
  final Color color;

  _BobbinPainter({required this.color});

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
