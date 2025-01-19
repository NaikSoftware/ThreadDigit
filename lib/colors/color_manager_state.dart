import 'package:thread_digit/colors/model/embroidery_machine.dart';
import 'package:equatable/equatable.dart';
import 'package:thread_digit/colors/model/embroidery_step.dart';
import 'package:thread_digit/colors/model/thread_color.dart';

final class ColorManagerState extends Equatable {
  final EmbroideryMachine? machine;
  final List<EmbroideryStep>? steps;
  final List<ThreadColor>? sequence;
  final Map<String, ThreadColor>? colorsMap;
  final String? error;

  const ColorManagerState({
    this.machine,
    this.steps,
    this.sequence,
    this.colorsMap,
    this.error,
  });

  @override
  List<Object?> get props => [machine, steps, error, sequence, colorsMap];

  @override
  bool get stringify => true;

  ColorManagerState copyWith({
    EmbroideryMachine? machine,
    List<EmbroideryStep>? steps,
    List<ThreadColor>? sequence,
    Map<String, ThreadColor>? colorsMap,
    String? error,
  }) {
    return ColorManagerState(
      machine: machine ?? this.machine,
      steps: steps ?? this.steps,
      sequence: sequence?? this.sequence,
      colorsMap: colorsMap?? this.colorsMap,
      error: error ?? this.error,
    );
  }
}
