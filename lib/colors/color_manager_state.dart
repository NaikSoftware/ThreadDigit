import 'package:thread_digit/colors/model/embroidery_machine.dart';
import 'package:equatable/equatable.dart';
import 'package:thread_digit/colors/model/embroidery_step.dart';

final class ColorManagerState extends Equatable {
  final EmbroideryMachine? machine;
  final List<EmbroideryStep>? steps;
  final String? error;

  const ColorManagerState({
    this.machine,
    this.steps,
    this.error,
  });

  @override
  List<Object?> get props => [machine, steps, error];

  @override
  bool get stringify => true;

  ColorManagerState copyWith({
    EmbroideryMachine? machine,
    List<EmbroideryStep>? steps,
    String? error,
  }) {
    return ColorManagerState(
      machine: machine ?? this.machine,
      steps: steps ?? this.steps,
      error: error ?? this.error,
    );
  }
}
