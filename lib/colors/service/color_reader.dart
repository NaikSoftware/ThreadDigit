import 'package:flutter/foundation.dart';
import 'package:thread_digit/colors/catalog/catalog.dart';
import 'package:thread_digit/colors/service/color_matcher.dart';
import 'package:thread_digit/colors/model/thread_color.dart';
import 'package:thread_digit/colors/service/reader/embird_edr_reader.dart';
import 'package:thread_digit/colors/service/reader/pes_reader.dart';

class ColorReader {
  Future<List<ThreadColor>> read({required String filePath}) async {
    try {
      if (filePath.toLowerCase().endsWith('.edr')) {
        return _readEdrColors(filePath);
      } else if (filePath.toLowerCase().endsWith('.pes')) {
        return _readPesColors(filePath);
      }
    } catch (e) {
      debugPrint('Error: $e');
    }
    return [];
  }

  Future<List<ThreadColor>> _readPesColors(String filePath) async {
    final List<PesThreadColor> pesColors = await PesReader.readColorSequence(filePath);
    return pesColors
        .map((c) => ColorMatcherUtil.findByCodeAndCatalog(
              c.code,
              c.catalog,
              ColorCatalog.map,
            ))
        .toList();
  }

  Future<List<ThreadColor>> _readEdrColors(String filePath) async {
    final List<EmThreadColor> emColors = await EmbirdEdrReader.readColorSequence(filePath);
    final List<ThreadColor> colors = emColors
        .map((c) =>
            ColorMatcherUtil.findColor(
              c.red,
              c.green,
              c.blue,
              ColorCatalog.list,
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
  }
}
