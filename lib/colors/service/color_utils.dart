import 'dart:ui';

import 'package:thread_digit/colors/model/thread_color.dart';

class ColorUtils {
  static bool isLightColor(Color color) => isLight(r: color.r, g: color.g, b: color.b);

  static bool isLightThread(ThreadColor threadColor) =>
      isLight(r: threadColor.red, g: threadColor.green, b: threadColor.blue);

  static bool isLight({
    required num r,
    required num g,
    required num b,
  }) =>
      (r * 0.299 + g * 0.587 + b * 0.114) > 186;
}
