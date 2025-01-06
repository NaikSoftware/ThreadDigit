import 'package:equatable/equatable.dart';

class StitchOperation extends Equatable {
  final String thread;
  final int needleIndex;

  const StitchOperation(this.thread, this.needleIndex);

  @override
  List<Object?> get props => [thread, needleIndex];

  @override
  String toString() => '$thread(${needleIndex + 1})';
}
