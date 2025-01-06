import 'package:equatable/equatable.dart';
import 'package:thread_digit/colors/model/thread_color.dart';

class EmbroideryMachine extends Equatable {
  final String name;
  final List<ThreadConfig> threads;

  const EmbroideryMachine({
    required this.name,
    required this.threads,
  });

  @override
  List<Object?> get props => [name, threads];
}

class ThreadConfig extends Equatable {
  final int positionX;
  final int positionY;
  final ThreadColor color;

  const ThreadConfig({
    required this.positionX,
    required this.positionY,
    required this.color,
  });

  @override
  List<Object?> get props => [positionX, positionY, color];
}

final class ThreadTemplateLayout {
  static const int width = 8;
  static const int height = 8;
  static const int maxNeedles = width * height;

  static final List<EmbroideryMachine> popular = [
    EmbroideryMachine(
      name: 'Ricoma 1501',
      threads: List.generate(15, (index) {
        return ThreadConfig(
          positionX: index % 5,
          positionY: index ~/ 5,
          color: ThreadColor.empty(code: index.toString()),
        );
      }),
    ),
    EmbroideryMachine(
      name: 'Melco EMT16X',
      threads: List.generate(16, (index) {
        return ThreadConfig(
          positionX: index % 4,
          positionY: index ~/ 4,
          color: ThreadColor.empty(code: index.toString()),
        );
      }),
    ),
    EmbroideryMachine(
      name: 'Ricoma 2001',
      threads: List.generate(20, (index) {
        return ThreadConfig(
          positionX: index % 5,
          positionY: index ~/ 5,
          color: ThreadColor.empty(code: index.toString()),
        );
      }),
    ),
    EmbroideryMachine(
      name: 'Tajima TMBP-SC1501',
      threads: List.generate(15, (index) {
        return ThreadConfig(
          positionX: index % 5,
          positionY: index ~/ 5,
          color: ThreadColor.empty(code: index.toString()),
        );
      }),
    ),
    EmbroideryMachine(
      name: 'Janome MB-7',
      threads: List.generate(7, (index) {
        return ThreadConfig(
          positionX: index % 4,
          positionY: index ~/ 4,
          color: ThreadColor.empty(code: index.toString()),
        );
      }),
    ),
    EmbroideryMachine(
      name: 'Bernina E 16',
      threads: List.generate(16, (index) {
        return ThreadConfig(
          positionX: index % 4,
          positionY: index ~/ 4,
          color: ThreadColor.empty(code: index.toString()),
        );
      }),
    ),
    EmbroideryMachine(
      name: 'Pfaff Creative 1.5',
      threads: List.generate(6, (index) {
        return ThreadConfig(
          positionX: index % 3,
          positionY: index ~/ 3,
          color: ThreadColor.empty(code: index.toString()),
        );
      }),
    ),
    EmbroideryMachine(
      name: 'Husqvarna Viking Designer EPIC',
      threads: List.generate(8, (index) {
        return ThreadConfig(
          positionX: index % 4,
          positionY: index ~/ 4,
          color: ThreadColor.empty(code: index.toString()),
        );
      }),
    ),
    EmbroideryMachine(
      name: 'Singer Futura XL-580',
      threads: List.generate(6, (index) {
        return ThreadConfig(
          positionX: index % 3,
          positionY: index ~/ 3,
          color: ThreadColor.empty(code: index.toString()),
        );
      }),
    ),
    EmbroideryMachine(
      name: 'Baby Lock Valiant',
      threads: List.generate(10, (index) {
        return ThreadConfig(
          positionX: index % 5,
          positionY: index ~/ 5,
          color: ThreadColor.empty(code: index.toString()),
        );
      }),
    ),
  ];
}
