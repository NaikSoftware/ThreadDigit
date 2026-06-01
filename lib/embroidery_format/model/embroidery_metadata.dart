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
    this.createdAt,
    this.threads = const {},
  });

  /// Human-readable design name.
  final String? name;

  /// Design author or digitizer.
  final String? author;

  /// Free-form notes.
  final String? notes;

  /// Creation timestamp (stored as ISO-8601).
  final DateTime? createdAt;

  /// Thread palette keyed by thread id. Carries full catalog data per thread.
  final Map<String, ThreadColor> threads;

  EmbroideryMetadata copyWith({
    String? name,
    String? author,
    String? notes,
    DateTime? createdAt,
    Map<String, ThreadColor>? threads,
  }) {
    return EmbroideryMetadata(
      name: name ?? this.name,
      author: author ?? this.author,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      threads: threads ?? this.threads,
    );
  }

  @override
  List<Object?> get props => [name, author, notes, createdAt, threads];

  @override
  String toString() => 'EmbroideryMetadata(name: $name, threads: ${threads.length})';
}
