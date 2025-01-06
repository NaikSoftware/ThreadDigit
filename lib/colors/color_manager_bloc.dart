import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:thread_digit/colors/color_manager_events.dart';
import 'package:thread_digit/colors/color_manager_state.dart';
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
      final machineThreads = state.machine?.threads;
      if (machineThreads == null || machineThreads.isEmpty) {
        return;
      }
      final colors = await colorReader.read(filePath: event.filePath);
      final steps = colorManager.optimizeColors(
        colors.map((e) => e.toString()).toList(),
        machineThreads.map((e) => e.toString()).toList(),
      );
      emit(state.copyWith(steps: steps));
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
