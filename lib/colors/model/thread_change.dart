import 'package:equatable/equatable.dart';

class ThreadChange extends Equatable {
  final int needleIndex;
  final String oldThread;
  final String newThread;

  const ThreadChange(this.needleIndex, this.oldThread, this.newThread);
  
  @override
  List<Object?> get props => [needleIndex, oldThread, newThread];

  @override
  String toString() => 'Needle ${needleIndex + 1}: $oldThread -> $newThread';
}
