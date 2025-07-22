import 'package:thread_digit/colors/catalog/gunold_cotty_catalog.dart';
import 'package:thread_digit/colors/catalog/gunold_cotty_zusatz_catalog.dart';
import 'package:thread_digit/colors/catalog/gunold_sulky_catalog.dart';
import 'package:thread_digit/colors/catalog/isacord_catalog.dart';
import 'package:thread_digit/colors/catalog/madeira_catalog.dart';
import 'package:thread_digit/colors/model/thread_color.dart';

final class ColorCatalog {
  static const Map<String, List<ThreadColor>> map = {
    'Gunold Sulky': gunoldSulkyColors,
    'Isacord Polyester': isacordColors,
    'Gunold COTTY': gunoldCottyColors,
    'Gunold COTTY-Zusatz': gunoldCottyZusatzColors,
    'Madeira Rayon': madeiraRayonColors,
  };

  static List<List<ThreadColor>> list = map.values.toList(growable: false);
}
