import 'dart:io';

/// Represents a thread color in Embird design.
class EmThreadColor {
  final int red;
  final int green;
  final int blue;

  const EmThreadColor({
    required this.red,
    required this.green,
    required this.blue,
  });

  @override
  String toString() => 'EMThread(RGB: $red,$green,$blue)';
}

/// Reader for Embird EDR color files
class EmbirdEdrReader {

  static Future<List<EmThreadColor>> readColorSequence(String filePath) async {
    final file = File(filePath);
    final bytes = await file.readAsBytes();

    final colors = <EmThreadColor>[];
    int i = 0;

    while (i < bytes.length - 2) {
      final red = bytes[i];
      final green = bytes[i + 1];
      final blue = bytes[i + 2];

      if (red <= 255 && green <= 255 && blue <= 255) {
        colors.add(EmThreadColor(red: red, green: green, blue: blue));
      }

      // To the next color.
      i += 4;
    }

    // Remove the last color. It is background color for preview mode.
    return colors.isEmpty ? colors : colors.sublist(0, colors.length - 1);
  }
}
