import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:thread_digit/colors/color_manager_bloc.dart';
import 'package:thread_digit/colors/color_manager_events.dart';
import 'package:thread_digit/colors/color_manager_state.dart';
import 'package:file_picker/file_picker.dart';
import 'package:thread_digit/colors/model/embroidery_machine.dart';
import 'package:thread_digit/colors/service/color_manager.dart';
import 'package:thread_digit/colors/service/color_reader.dart';
import 'package:thread_digit/generated/l10n.dart';
import 'package:thread_digit/colors/widgets/bobbin_visualization.dart';

class ColorManagerPage extends StatelessWidget {
  const ColorManagerPage({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
        create: (context) => ColorManagerBloc(
          colorManager: ColorManager(),
          colorReader: ColorReader(),
        ),
        child: BlocBuilder<ColorManagerBloc, ColorManagerState>(
          builder: (context, state) {
            return Scaffold(
              appBar: AppBar(title: const Text('Color Manager')),
              body: Column(
                children: [
                  _buildMachineSelector(context, state),
                  if (state.machine != null)
                    Expanded(
                      child: BobbinVisualization(machine: state.machine!),
                    ),
                  SafeArea(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton(
                          onPressed: state.machine == null ? null : () => _handleColorOptimization(context),
                          child: const Text('Optimize Colors'),
                        ),
                        if (state.steps != null) Text('Optimized Steps: ${state.steps!.length}'),
                        if (state.error != null) Text('Error: ${state.error}', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      );

  Widget _buildMachineSelector(BuildContext context, ColorManagerState state) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: DropdownButton<EmbroideryMachine>(
        isExpanded: true,
        value: state.machine,
        hint: Text(S.of(context).colorManagerSelectMachine),
        onChanged: (EmbroideryMachine? newValue) {
          if (newValue != null) {
            context.read<ColorManagerBloc>().add(SelectMachineEvent(newValue));
          }
        },
        items: ThreadTemplateLayout.popular.map<DropdownMenuItem<EmbroideryMachine>>((EmbroideryMachine machine) {
          return DropdownMenuItem<EmbroideryMachine>(
            value: machine,
            child: Text(machine.name),
          );
        }).toList(),
      ),
    );
  }

  Future<void> _handleColorOptimization(BuildContext context) async {
    final result = await FilePicker.platform.pickFiles();
    if (result != null && result.files.single.path != null && context.mounted) {
      context.read<ColorManagerBloc>().add(OptimizeColorsEvent(result.files.single.path!));
    }
  }
}
