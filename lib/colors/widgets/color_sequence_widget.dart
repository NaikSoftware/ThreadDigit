import 'package:flutter/material.dart';
import '../model/thread_color.dart';

/// Widget that displays a horizontal sequence of thread colors
class ColorSequenceWidget extends StatelessWidget {
  final List<ThreadColor> threadColors;

  const ColorSequenceWidget({
    super.key,
    required this.threadColors,
  });

  @override
  Widget build(BuildContext context) {
    if (threadColors.isEmpty) {
      return const Center(
        child: Text('No thread colors'),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: threadColors.map((threadColor) {
          return Container(
            width: 40,
            height: 40,
            margin: const EdgeInsets.only(right: 4),
            decoration: BoxDecoration(
              color: Color.fromRGBO(threadColor.red, threadColor.green, threadColor.blue, 1.0),
              border: Border.all(color: Colors.grey, width: 1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Tooltip(
              message: '${threadColor.name}\n${threadColor.code}\n${threadColor.catalog}',
              child: Container(),
            ),
          );
        }).toList(),
      ),
    );
  }
}