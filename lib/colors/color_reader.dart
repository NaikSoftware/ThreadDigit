import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:thread_digit/colors/catalog/gunold_cotty_catalog.dart';
import 'package:thread_digit/colors/catalog/gunold_cotty_zusatz_catalog.dart';
import 'package:thread_digit/colors/catalog/gunold_sulky_catalog.dart';
import 'package:thread_digit/colors/catalog/isacord_catalog.dart';
import 'package:thread_digit/colors/catalog/madeira_catalog.dart';
import 'package:thread_digit/colors/color_matcher.dart';
import 'package:thread_digit/colors/thread_color.dart';

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
class EmbirdsEdrReader {
  /// Reads color sequence from an Embird EDR file
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

class ColorReader {
  Future<List<ThreadColor>> read({required String filePath}) async {
    try {
      final emColors = await EmbirdsEdrReader.readColorSequence(filePath);
      final colors = emColors
          .map((c) =>
              ColorMatcherUtil.findColor(
                c.red,
                c.green,
                c.blue,
                [
                  gunoldSulkyColors,
                  isacordColors,
                  gunoldCottyColors,
                  gunoldCottyZusatzColors,
                  madeiraRayonColors,
                ],
                allowNearby: true,
              ) ??
              ThreadColor(
                name: 'Unknown',
                code: '${c.red},${c.green},${c.blue}',
                catalog: 'Unknown Catalog',
                red: c.red,
                green: c.green,
                blue: c.blue,
              ))
          .toList();
      debugPrint('Colors in design:');
      for (var i = 0; i < colors.length; i++) {
        final color = colors[i];
        debugPrint('${i + 1}. ${color.toString()}');
      }
      return colors;
    } catch (e) {
      debugPrint('Error: $e');
    }
    return [];
  }
}
