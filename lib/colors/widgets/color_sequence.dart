import 'package:flutter/material.dart';
import 'package:thread_digit/colors/model/thread_color.dart';
import 'package:thread_digit/colors/service/color_utils.dart';

class ColorSequenceVisualizer extends StatelessWidget {
  final List<ThreadColor>? colorSequence;
  final int? currentColorIndex;

  const ColorSequenceVisualizer({
    required this.colorSequence,
    this.currentColorIndex,
    super.key,
  });

  @override
  Widget build(BuildContext context) => colorSequence == null || colorSequence!.isEmpty
      ? Center(child: Text('No color sequence provided'))
      : ListView.builder(
          padding: EdgeInsets.only(bottom: 72),
          itemCount: colorSequence!.length,
          itemBuilder: (context, index) {
            final threadColor = colorSequence![index];
            return _ColorSequenceItem(
              key: ObjectKey(threadColor),
              threadColor: threadColor,
              isCurrentColor: index == currentColorIndex,
              index: index,
            );
          },
        );
}

class _ColorSequenceItem extends StatelessWidget {
  final ThreadColor threadColor;
  final bool isCurrentColor;
  final int index;

  const _ColorSequenceItem({
    required this.threadColor,
    required this.isCurrentColor,
    required this.index,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      decoration: BoxDecoration(
        border: Border.all(
          color: isCurrentColor ? Colors.orangeAccent : Colors.transparent,
          width: isCurrentColor ? 3 : 0,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Color.fromRGBO(threadColor.red, threadColor.green, threadColor.blue, 1),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.black, width: 1),
              ),
            ),
            Text(
              '${index + 1}',
              style: TextStyle(
                color: ColorUtils.isLightThread(threadColor) ? Colors.black : Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14
              ),
            ),
          ],
        ),
        title: Text('${threadColor.catalog} - ${threadColor.name}'),
        subtitle: Text(
          'Code: ${threadColor.code}',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        trailing: Text(
          '${threadColor.percentage.toStringAsFixed(1)}%',
          style: TextStyle(
            color: threadColor.percentage < 100 ? Colors.red : null,
            fontWeight: threadColor.percentage < 100 ? FontWeight.bold : null,
          ),
        ),
      ),
    );
  }
}
