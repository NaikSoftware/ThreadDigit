import 'package:equatable/equatable.dart';
import 'thread_change.dart';
import 'stitch_operation.dart';

class EmbroideryStep extends Equatable {
  final List<ThreadChange> changes;
  final List<StitchOperation> stitchOperations;
  final List<String> currentSetup;

  const EmbroideryStep(this.changes, this.stitchOperations, this.currentSetup);

  void addOperations(List<StitchOperation> operations) {
    stitchOperations.addAll(operations);
  }
  
  @override
  List<Object?> get props => [changes, stitchOperations, currentSetup];

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
