import 'package:flutter/material.dart';

class ButtonsPanel extends StatelessWidget {
  final List<Widget> buttons;
  final bool expanded;

  const ButtonsPanel({
    super.key,
    required this.buttons,
    this.expanded = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: expanded
          ? Row(
              children: [
                Expanded(
                  child: OverflowBar(
                    alignment: MainAxisAlignment.end,
                    overflowSpacing: 8,
                    children: buttons,
                  ),
                ),
              ],
            )
          : OverflowBar(
              alignment: MainAxisAlignment.end,
              overflowSpacing: 8,
              children: buttons,
            ),
    );
  }
}
