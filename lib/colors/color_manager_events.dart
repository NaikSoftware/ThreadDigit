import 'package:equatable/equatable.dart';
import 'package:thread_digit/colors/model/embroidery_machine.dart';

abstract class ColorManagerEvent extends Equatable {
  const ColorManagerEvent();

  @override
  List<Object> get props => [];
}

class OptimizeColorsEvent extends ColorManagerEvent {
  final String filePath;

  const OptimizeColorsEvent(this.filePath);

  @override
  List<Object> get props => [filePath];
}

class SelectMachineEvent extends ColorManagerEvent {
  final EmbroideryMachine machine;

  const SelectMachineEvent(this.machine);
}
