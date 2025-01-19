import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:thread_digit/colors/color_manager_events.dart';
import 'package:thread_digit/colors/color_manager_state.dart';
import 'package:thread_digit/colors/model/embroidery_machine.dart';
import 'package:thread_digit/colors/model/embroidery_step.dart';
import 'package:thread_digit/colors/model/thread_color.dart';
import 'package:thread_digit/colors/service/color_manager.dart';
import 'package:thread_digit/colors/service/color_reader.dart';

class ColorManagerBloc extends Bloc<ColorManagerEvent, ColorManagerState> {
  final ColorManager colorManager;
  final ColorReader colorReader;

  ColorManagerBloc({
    required this.colorManager,
    required this.colorReader,
  }) : super(const ColorManagerState()) {
    on<OptimizeColorsEvent>(_handleColorOptimization);
    on<SelectMachineEvent>(_handleMachineSelection);
  }

  Future<void> _handleColorOptimization(
    OptimizeColorsEvent event,
    Emitter<ColorManagerState> emit,
  ) async {
    try {
      final List<ThreadConfig>? machineThreads = state.machine?.threads;
      if (machineThreads == null || machineThreads.isEmpty) {
        return;
      }
      final List<ThreadColor> colorsList = await colorReader.read(filePath: event.filePath);
      final Map<String, ThreadColor> colorsMap =
          Map.fromEntries(colorsList.map((color) => MapEntry(color.toString(), color)));
      final List<EmbroideryStep> steps = colorManager.optimizeColors(
        colorsMap.keys.toList(),
        machineThreads.map((ThreadConfig e) => e.toString()).toList(),
      );
      emit(state.copyWith(
        steps: steps,
        sequence: colorsList,
        colorsMap: colorsMap,
      ));
    } catch (e) {
      // Handle error
      emit(ColorManagerState(error: e.toString()));
    }
  }

  Future<void> _handleMachineSelection(
    SelectMachineEvent event,
    Emitter<ColorManagerState> emit,
  ) async {
    emit(state.copyWith(machine: event.machine));
  }
}
