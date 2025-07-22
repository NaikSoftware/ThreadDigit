import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:thread_digit/colors/color_manager_bloc.dart';
import 'package:thread_digit/colors/color_manager_events.dart';
import 'package:thread_digit/colors/color_manager_state.dart';
import 'package:file_picker/file_picker.dart';
import 'package:thread_digit/colors/model/embroidery_machine.dart';
import 'package:thread_digit/colors/service/color_manager.dart';
import 'package:thread_digit/colors/service/color_reader.dart';
import 'package:thread_digit/colors/widgets/color_sequence.dart';
import 'package:thread_digit/colors/widgets/steps_visualization.dart';
import 'package:thread_digit/common/buttons_panel.dart';
import 'package:thread_digit/generated/l10n.dart';
import 'package:thread_digit/colors/widgets/bobbin_visualization.dart';

class ColorManagerPage extends StatelessWidget {
  static const double _kButtonsPanelHeight = 48.0;

  const ColorManagerPage({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
        create: (context) => ColorManagerBloc(
          colorManager: ColorManager(),
          colorReader: ColorReader(),
        ),
        child: BlocBuilder<ColorManagerBloc, ColorManagerState>(
          builder: (context, state) {
            if (state.machine == null) {
              return Scaffold(
                appBar: AppBar(
                  title: const Text('Color Manager'),
                ),
                body: Center(
                  child: FilledButton.icon(
                    onPressed: () => _showMachineSelector(context),
                    icon: const Icon(Icons.add),
                    label: Text(S.of(context).colorManagerSelectMachine),
                  ),
                ),
              );
            }

            final double expandedHeight =
                BobbinVisualization.calculateHeight(context, state.machine!) + _kButtonsPanelHeight + kToolbarHeight + 24;

            return DefaultTabController(
              length: 2,
              child: Scaffold(
                body: NestedScrollView(
                  headerSliverBuilder: (context, innerBoxIsScrolled) => [
                    SliverAppBar(
                      title: const Text('Color Manager'),
                      pinned: true,
                      expandedHeight: expandedHeight,
                      flexibleSpace: FlexibleSpaceBar(
                        background: Column(
                          children: [
                            SizedBox(height: kToolbarHeight + 16),
                            ButtonsPanel(
                              buttons: [
                                FilledButton.icon(
                                  onPressed: () => _handleColorOptimization(context),
                                  icon: const Icon(Icons.color_lens),
                                  label: Text(S.of(context).optimizeColors),
                                ),
                              ],
                            ),
                            Expanded(
                              child: Stack(
                                children: [
                                  BobbinVisualization(machine: state.machine!),
                                  Positioned(
                                    top: 8,
                                    right: 8,
                                    child: FloatingActionButton.small(
                                      onPressed: () => _showMachineSelector(context),
                                      tooltip: S.of(context).changeMachine,
                                      child: const Icon(Icons.edit),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      bottom: TabBar(
                        tabs: [
                          Tab(text: S.of(context).sequence),
                          Tab(text: S.of(context).steps),
                        ],
                      ),
                    ),
                  ],
                  body: TabBarView(
                    children: [
                      ColorSequenceVisualizer(
                        colorSequence: state.sequence,
                      ),
                      EmbroideryStepsVisualizer(
                        steps: state.steps,
                        threadColors: state.colorsMap,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      );

  Future<void> _showMachineSelector(BuildContext context) async {
    final machine = await showDialog<EmbroideryMachine>(
      context: context,
      builder: (BuildContext context) => MachineSelectionDialog(),
    );

    if (machine != null && context.mounted) {
      context.read<ColorManagerBloc>().add(SelectMachineEvent(machine));
    }
  }

  Future<void> _handleColorOptimization(BuildContext context) async {
    final result = await FilePicker.platform.pickFiles();
    if (result != null && result.files.single.path != null && context.mounted) {
      context.read<ColorManagerBloc>().add(OptimizeColorsEvent(result.files.single.path!));
    }
  }
}

class MachineSelectionDialog extends StatelessWidget {
  const MachineSelectionDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Text(
                S.of(context).colorManagerSelectMachine,
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: ThreadTemplateLayout.popular.map((machine) {
                    return ListTile(
                      title: Text(machine.name),
                      subtitle: Text('${machine.threads.length} ${S.of(context).needles}'),
                      onTap: () {
                        Navigator.of(context).pop(machine);
                      },
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(S.of(context).cancel),
            ),
          ],
        ),
      ),
    );
  }
}
