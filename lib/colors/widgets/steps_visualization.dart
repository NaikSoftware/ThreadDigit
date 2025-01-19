import 'package:flutter/material.dart';
import 'package:thread_digit/colors/model/embroidery_step.dart';
import 'package:thread_digit/colors/model/thread_change.dart';
import 'package:thread_digit/colors/model/stitch_operation.dart';
import 'package:thread_digit/colors/model/thread_color.dart';

class EmbroideryStepsVisualizer extends StatefulWidget {
  final List<EmbroideryStep>? steps;
  final Map<String, ThreadColor>? threadColors;

  const EmbroideryStepsVisualizer({
    super.key,
    this.steps,
    this.threadColors,
  });

  @override
  State<EmbroideryStepsVisualizer> createState() => _EmbroideryStepsVisualizerState();
}

class _EmbroideryStepsVisualizerState extends State<EmbroideryStepsVisualizer> {
  int _currentStep = 0;
  late PageController _pageController;
  final ScrollController _stitchScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentStep);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _stitchScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final steps = widget.steps;
    final threadColors = widget.threadColors;
    if (steps == null || threadColors == null) {
      return Center(child: Text('No embroidery steps provided'));
    }
    return Column(
      children: [
        _buildStepProgress(steps),
        const SizedBox(height: 16),
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() => _currentStep = index);
            },
            itemCount: steps.length,
            itemBuilder: (context, index) {
              return _buildStepContent(threadColors, steps[index]);
            },
          ),
        ),
        _buildNavigationControls(steps),
      ],
    );
  }

  Widget _buildStepProgress(List<EmbroideryStep> steps) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Text(
            'Step ${_currentStep + 1} of ${steps.length}',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: ((_currentStep + 1) / steps.length),
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor),
          ),
        ],
      ),
    );
  }

  Widget _buildStepContent(Map<String, ThreadColor> threadColors, EmbroideryStep step) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (step.changes.isNotEmpty) ...[
              _buildThreadChangesSection(threadColors, step.changes),
              const Divider(height: 32),
            ],
            _buildCurrentSetupSection(threadColors, step.currentSetup),
            const Divider(height: 32),
            _buildStitchSequenceSection(threadColors, step.stitchOperations),
          ],
        ),
      ),
    );
  }

  Widget _buildThreadChangesSection(Map<String, ThreadColor> threadColors,  List<ThreadChange> changes) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Thread Changes Required',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: changes.map((change) {
            return _buildThreadChangeCard(threadColors, change);
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildThreadChangeCard(Map<String, ThreadColor> threadColors,  ThreadChange change) {
    final oldColor = threadColors[change.oldThread];
    final newColor = threadColors[change.newThread];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Needle ${change.needleIndex + 1}',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildThreadColorBox(oldColor),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Icon(Icons.arrow_forward, size: 16),
                ),
                _buildThreadColorBox(newColor),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentSetupSection(Map<String, ThreadColor> threadColors, List<String> setup) {
    return ExpansionTile(
      title: Text(
        'Current Thread Setup',
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(setup.length, (index) {
              final thread = setup[index];
              final threadColor = threadColors[thread];
              return _buildNeedleCard(index, threadColor);
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildNeedleCard(int index, ThreadColor? threadColor) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Text('Needle ${index + 1}',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            _buildThreadColorBox(threadColor),
            if (threadColor != null)
              Text(threadColor.code,
                  style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }

  Widget _buildStitchSequenceSection(Map<String, ThreadColor> threadColors, List<StitchOperation> operations) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Stitch Sequence',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 88,
          child: ListView.separated(
            controller: _stitchScrollController,
            scrollDirection: Axis.horizontal,
            itemCount: operations.length,
            separatorBuilder: (context, index) => const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4),
              child: Icon(Icons.arrow_forward, size: 16),
            ),
            itemBuilder: (context, index) {
              final operation = operations[index];
              final threadColor = threadColors[operation.thread];
              return _buildStitchOperationCard(operation, threadColor);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStitchOperationCard(StitchOperation operation, ThreadColor? threadColor) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('N${operation.needleIndex + 1}',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            _buildThreadColorBox(threadColor),
            if (threadColor != null)
              Text(threadColor.code,
                  style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }

  Widget _buildThreadColorBox(ThreadColor? threadColor) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: threadColor != null
            ? Color.fromRGBO(
          threadColor.red,
          threadColor.green,
          threadColor.blue,
          1,
        )
            : ThreadColor.empty(code: '0').toColor(),
        border: Border.all(color: Colors.black26),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  Widget _buildNavigationControls(List<EmbroideryStep> steps) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.skip_previous),
            onPressed: _currentStep > 0
                ? () {
              _pageController.previousPage(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            }
                : null,
          ),
          IconButton(
            icon: const Icon(Icons.navigate_before),
            onPressed: _currentStep > 0
                ? () {
              _pageController.previousPage(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            }
                : null,
          ),
          const SizedBox(width: 16),
          IconButton(
            icon: const Icon(Icons.navigate_next),
            onPressed: _currentStep < steps.length - 1
                ? () {
              _pageController.nextPage(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            }
                : null,
          ),
          IconButton(
            icon: const Icon(Icons.skip_next),
            onPressed: _currentStep < steps.length - 1
                ? () {
              _pageController.animateToPage(
                steps.length - 1,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            }
                : null,
          ),
        ],
      ),
    );
  }
}
