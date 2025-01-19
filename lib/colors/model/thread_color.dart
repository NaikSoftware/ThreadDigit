import 'dart:ui';

import 'package:equatable/equatable.dart';

class ThreadColor with EquatableMixin {
  final String name;
  final String code;
  final int red;
  final int green;
  final int blue;
  final String catalog;
  final double percentage;

  const ThreadColor({
    required this.name,
    required this.code,
    required this.red,
    required this.green,
    required this.blue,
    required this.catalog,
    this.percentage = 100.0,
  });

  const ThreadColor.empty({required this.code})
      : name = '',
        red = 127,
        green = 127,
        blue = 127,
        catalog = '',
        percentage = 100.0;

  ThreadColor withPercentage(double newPercentage) => ThreadColor(
    name: name,
    code: code,
    red: red,
    green: green,
    blue: blue,
    catalog: catalog,
    percentage: newPercentage,
  );

  @override
  String toString() => '$catalog ($code) $percentage%';

  @override
  List<Object?> get props => [name, code, red, green, blue, catalog, percentage];

  Color toColor() => Color.fromARGB(255, red, green, blue);
}
