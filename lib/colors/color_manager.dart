import 'package:flutter/foundation.dart';

class ThreadChange {
  final int needleIndex;
  final String oldThread;
  final String newThread;

  ThreadChange(this.needleIndex, this.oldThread, this.newThread);

  @override
  String toString() => 'Needle ${needleIndex + 1}: $oldThread -> $newThread';
}

class StitchOperation {
  final String thread;
  final int needleIndex;

  StitchOperation(this.thread, this.needleIndex);

  @override
  String toString() => '$thread(${needleIndex + 1})';
}

class EmbroideryStep {
  final List<ThreadChange> changes;
  final List<StitchOperation> stitchOperations;
  final List<String> currentSetup;

  EmbroideryStep(this.changes, this.stitchOperations, this.currentSetup);

  void addOperations(List<StitchOperation> operations) {
    stitchOperations.addAll(operations);
  }

  @override
  String toString() {
    String result = '';
    if (changes.isNotEmpty) {
      result += 'Thread changes:\n${changes.join('\n')}\n';
    }
    result += 'Embroidery sequence: ${stitchOperations.join(' -> ')}';
    return result;
  }
}

class EmbroideryMachine {
  final int needleCount;
  List<String> currentSetup;
  Map<String, int> threadToNeedle = {};

  EmbroideryMachine(List<String> initialThreads)
      : needleCount = initialThreads.length,
        currentSetup = List.from(initialThreads) {
    if (initialThreads.any((thread) => thread.isEmpty)) {
      throw ArgumentError('All needles must have threads at initialization');
    }

    var uniqueThreads = Set<String>.from(initialThreads);
    if (uniqueThreads.length != initialThreads.length) {
      throw ArgumentError('Each thread can only be installed on one needle');
    }

    for (int i = 0; i < initialThreads.length; i++) {
      threadToNeedle[initialThreads[i]] = i;
    }
  }

  List<EmbroideryStep> optimizeThreadChanges(List<String> designThreads) {
    List<EmbroideryStep> steps = [];
    int currentIndex = 0;

    while (currentIndex < designThreads.length) {
      // First check if thread changes are needed
      var remainingThreads = designThreads.sublist(currentIndex);
      var frequency = _calculateThreadFrequency(remainingThreads);
      var changes = _planThreadChanges(remainingThreads, frequency);

      // Apply changes if any
      if (changes.isNotEmpty) {
        for (var change in changes) {
          currentSetup[change.needleIndex] = change.newThread;
          threadToNeedle.remove(change.oldThread);
          threadToNeedle[change.newThread] = change.needleIndex;
        }
      }

      // Find the next sequence of operations
      var nextSequence = _findMaxSequence(designThreads, currentIndex);

      if (nextSequence.stitchOperations.isEmpty) {
        // If no operations possible after changes, it's a configuration error
        if (changes.isEmpty) break;
        continue;
      }

      // Create new step or add to previous one
      if (changes.isNotEmpty || steps.isEmpty) {
        steps.add(EmbroideryStep(changes, nextSequence.stitchOperations, List.from(currentSetup)));
      } else {
        steps.last.addOperations(nextSequence.stitchOperations);
      }

      currentIndex += nextSequence.stitchOperations.length;
    }

    return steps;
  }

  ({List<StitchOperation> stitchOperations, Set<String> usedThreads}) _findMaxSequence(
      List<String> threads, int startIndex) {
    List<StitchOperation> operations = [];
    Set<String> usedThreads = {};

    for (int i = startIndex; i < threads.length; i++) {
      String thread = threads[i];
      int? needleIndex = threadToNeedle[thread];

      if (needleIndex != null) {
        operations.add(StitchOperation(thread, needleIndex));
        usedThreads.add(thread);
      } else {
        break;
      }
    }

    return (stitchOperations: operations, usedThreads: usedThreads);
  }

  List<ThreadChange> _planThreadChanges(List<String> remainingThreads, Map<String, int> threadFrequency) {
    List<ThreadChange> changes = [];
    var neededThreads = _getNextNeededThreads(remainingThreads);
    var threadsToKeep = _determineThreadsToKeep(threadFrequency);
    var needlesToChange = _findNeedlesToChange(neededThreads, threadsToKeep);

    var remainingNeededThreads = neededThreads.where((thread) => !threadToNeedle.containsKey(thread)).toList();

    for (int i = 0; i < needlesToChange.length && i < remainingNeededThreads.length; i++) {
      var needleIndex = needlesToChange[i];
      var newThread = remainingNeededThreads[i];
      changes.add(ThreadChange(needleIndex, currentSetup[needleIndex], newThread));
    }

    return changes;
  }

  Set<String> _getNextNeededThreads(List<String> remainingThreads) {
    Set<String> neededThreads = {};
    Set<String> currentThreads = currentSetup.toSet();

    // Check next unique threads that are needed
    for (int i = 0; i < remainingThreads.length && neededThreads.length < needleCount; i++) {
      String thread = remainingThreads[i];
      if (!currentThreads.contains(thread) && !neededThreads.contains(thread)) {
        neededThreads.add(thread);
      }
    }

    return neededThreads;
  }

  Set<String> _determineThreadsToKeep(Map<String, int> threadFrequency) {
    // Sort current threads by frequency of use
    var currentThreadsWithFrequency = currentSetup.where((thread) => threadFrequency.containsKey(thread)).toList();

    currentThreadsWithFrequency.sort((a, b) => (threadFrequency[b] ?? 0).compareTo(threadFrequency[a] ?? 0));

    // Keep half of the most frequently used threads
    return currentThreadsWithFrequency.take((needleCount / 2).ceil()).toSet();
  }

  List<int> _findNeedlesToChange(Set<String> neededThreads, Set<String> threadsToKeep) {
    List<int> needlesToChange = [];

    // First use needles with least needed threads
    for (int i = 0; i < currentSetup.length && needlesToChange.length < neededThreads.length; i++) {
      if (!threadsToKeep.contains(currentSetup[i])) {
        needlesToChange.add(i);
      }
    }

    return needlesToChange;
  }

  Map<String, int> _calculateThreadFrequency(List<String> threads) {
    Map<String, int> frequency = {};
    for (String thread in threads) {
      frequency[thread] = (frequency[thread] ?? 0) + 1;
    }
    return frequency;
  }
}

class ColorManager {
  List<EmbroideryStep> optimizeColors(List<String> designColors, List<String> initialThreads) {
    var machine = EmbroideryMachine(initialThreads);
    var design = [];

    debugPrint('Initial configuration:');
    for (int i = 0; i < machine.currentSetup.length; i++) {
      debugPrint('Needle ${i + 1}: ${machine.currentSetup[i]}');
    }
    debugPrint('\nDesign thread sequence: $design\n');

    var steps = machine.optimizeThreadChanges(designColors);

    debugPrint('Optimized embroidery steps:');
    for (int i = 0; i < steps.length; i++) {
      debugPrint('\nStep ${i + 1}:');
      debugPrint(steps[i].toString());
    }

    return steps;
  }
}
