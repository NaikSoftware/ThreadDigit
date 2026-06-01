import 'dart:ui';

import 'package:equatable/equatable.dart';
import 'package:thread_digit/algorithm/models/embroidery_pattern.dart';
import 'package:thread_digit/embroidery_format/model/elements/manual_stitch_element.dart';
import 'package:thread_digit/embroidery_format/model/embroidery_element.dart';
import 'package:thread_digit/embroidery_format/model/embroidery_metadata.dart';

/// Top-level model serialized to and from the `.emb.svg` format.
///
/// A document is an ordered list of [elements] plus design [dimensions] and
/// [metadata]. Document order is stitching order. Each element is one SVG
/// shape with an embroidery meaning (line, manual stitches, fill, satin).
class EmbroideryDocument extends Equatable {
  const EmbroideryDocument({
    required this.dimensions,
    required this.elements,
    this.metadata = const EmbroideryMetadata(),
  });

  /// Builds a document from algorithm output, mapping each continuous
  /// [StitchSequence] to a [ManualStitchElement] (explicit stitches).
  factory EmbroideryDocument.fromPattern(EmbroideryPattern pattern, {EmbroideryMetadata? metadata}) {
    final elements = <EmbroideryElement>[
      for (final sequence in pattern.sequences) ManualStitchElement.fromSequence(sequence),
    ];
    final base = metadata ?? const EmbroideryMetadata();
    return EmbroideryDocument(
      dimensions: pattern.dimensions,
      elements: elements,
      metadata: base.threads.isEmpty ? base.copyWith(threads: pattern.threads) : base,
    );
  }

  /// Design size in millimeters.
  final Size dimensions;

  /// Embroidery elements in stitching order.
  final List<EmbroideryElement> elements;

  /// Design-level metadata, including the thread palette.
  final EmbroideryMetadata metadata;

  EmbroideryDocument copyWith({Size? dimensions, List<EmbroideryElement>? elements, EmbroideryMetadata? metadata}) {
    return EmbroideryDocument(
      dimensions: dimensions ?? this.dimensions,
      elements: elements ?? this.elements,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  List<Object?> get props => [dimensions, elements, metadata];

  @override
  String toString() => 'EmbroideryDocument(${dimensions.width}x${dimensions.height}mm, elements: ${elements.length})';
}
