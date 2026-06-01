import 'package:equatable/equatable.dart';
import 'package:thread_digit/colors/model/thread_color.dart';

/// Design-level metadata stored in the `<metadata>` block of an `.emb.svg`.
///
/// Holds the thread palette (the catalog data Ink/Stitch does not persist) plus
/// optional design fields. Elements reference a palette entry by its key.
class EmbroideryMetadata extends Equatable {
  const EmbroideryMetadata({
    this.name,
    this.author,
    this.notes,
    this.machineName,
    this.createdAt,
    this.threads = const {},
    this.needleByThreadId = const {},
  });

  /// Human-readable design name.
  final String? name;

  /// Design author or digitizer.
  final String? author;

  /// Free-form notes.
  final String? notes;

  /// Target machine name, if known.
  final String? machineName;

  /// Creation timestamp (stored as ISO-8601).
  final DateTime? createdAt;

  /// Thread palette keyed by thread id. Carries full catalog data per thread.
  final Map<String, ThreadColor> threads;

  /// Optional needle assignment per thread id (1-based needle numbers).
  final Map<String, int> needleByThreadId;

  EmbroideryMetadata copyWith({
    String? name,
    String? author,
    String? notes,
    String? machineName,
    DateTime? createdAt,
    Map<String, ThreadColor>? threads,
    Map<String, int>? needleByThreadId,
  }) {
    return EmbroideryMetadata(
      name: name ?? this.name,
      author: author ?? this.author,
      notes: notes ?? this.notes,
      machineName: machineName ?? this.machineName,
      createdAt: createdAt ?? this.createdAt,
      threads: threads ?? this.threads,
      needleByThreadId: needleByThreadId ?? this.needleByThreadId,
    );
  }

  @override
  List<Object?> get props => [name, author, notes, machineName, createdAt, threads, needleByThreadId];

  @override
  String toString() => 'EmbroideryMetadata(name: $name, threads: ${threads.length})';
}
