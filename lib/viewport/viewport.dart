import 'dart:math' as math;
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:thread_digit/photostitch/photo_stitch.dart';
import 'package:thread_digit/viewport/image_data_painter.dart';
import 'package:thread_digit/viewport/segment_painter.dart';
import 'package:thread_digit/viewport/stitch_painter.dart';

/*
  Create algorithm in stitchImage function body.
  It should analyze image (size, colors) and for each color generate one or more
  StitchSequence with stitches. Each stitch should be between minStitchLength and maxStitchLength.
  If we draw all stitches on the canvas we should get embroidery by image.
 */

class EditorViewport extends StatefulWidget {
  final img.Image image;

  const EditorViewport({
    required this.image,
    super.key,
  });

  @override
  State<EditorViewport> createState() => _EditorViewportState();
}

class _EditorViewportState extends State<EditorViewport> {
  late img.Image image;
  List<StitchSequence> stitchSequences = [];
  bool _isPlaying = false;
  int _currentStitchIndex = 0;
  int _currentSequenceIndex = 0;
  static const Duration stitchDelay = Duration(milliseconds: 1);
  bool _showingSegments = false;
  List<List<Point<int>>> _segments = [];
  List<Color> _segmentColors = [];
  int _currentSegmentIndex = 0;

  @override
  void initState() {
    super.initState();
    image = widget.image;
  }

  @override
  void didUpdateWidget(covariant EditorViewport oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.image != widget.image) {
      image = widget.image;
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editor'),
        actions: <Widget>[
          IconButton(icon: const Icon(Icons.compare_outlined), onPressed: _onPrepareImage),
          IconButton(icon: const Icon(Icons.stacked_line_chart), onPressed: _onStitchImage),
          IconButton(icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow), onPressed: _togglePlay),
          IconButton(icon: const Icon(Icons.animation), onPressed: _animateSegments),
          IconButton(
            icon: const Icon(Icons.visibility),
            onPressed: _showAllStitches,
          ),
        ],
      ),
      body: InteractiveViewer(
        constrained: false,
        minScale: 0.1,
        maxScale: 10,
        child: SizedBox(
          width: math.max(image.width.toDouble(), screenSize.width),
          height: math.max(image.height.toDouble(), screenSize.height),
          child: stitchSequences.isNotEmpty
              ? CustomPaint(
                  painter: _showingSegments
                      ? SegmentPainter(_segments, _segmentColors, _currentSegmentIndex)
                      : StitchesPainter(
                          stitchSequences,
                          currentSequenceIndex: _currentSequenceIndex,
                          currentStitchIndex: _currentStitchIndex,
                        ),
                )
              : ImageDataWidget(image: image),
        ),
      ),
    );
  }

  void _onPrepareImage() {
    setState(() {
      image = img.quantize(image, numberOfColors: 8);
    });
  }

  void _onStitchImage() {
    setState(() {
      stitchSequences = EmbroideryGenerator().generateEmbroidery(image);
    });
  }

  void _togglePlay() {
    setState(() {
      _isPlaying = !_isPlaying;
    });
    if (_isPlaying) {
      _playNextStitch();
    }
  }

  void _playNextStitch() {
    if (!_isPlaying) return;

    if (_currentSequenceIndex < stitchSequences.length) {
      var sequence = stitchSequences[_currentSequenceIndex];
      if (_currentStitchIndex < sequence.stitches.length) {
        setState(() {
          _currentStitchIndex++;
        });
        Future.delayed(stitchDelay, _playNextStitch);
      } else {
        if (_currentSequenceIndex < stitchSequences.length - 1) {
          _currentSequenceIndex++;
          _currentStitchIndex = 0;
        }
        _togglePlay(); // Pause at the end of each sequence
      }
    }
  }

  void _showAllStitches() {
    setState(() {
      _currentSequenceIndex = stitchSequences.length - 1;
      _currentStitchIndex = stitchSequences.isNotEmpty ? stitchSequences[_currentSequenceIndex].stitches.length : 0;
      _isPlaying = false;
    });
  }

  void _animateSegments() {
    if (_segments.isEmpty) {
      final embroideryGenerator = EmbroideryGenerator();
      final result = embroideryGenerator.segmentImage(img.copyResize(image, width: 300), 7, 10, 5);
      _segments = result.$1;
      _segmentColors = result.$2;
    }

    setState(() {
      _showingSegments = true;
      _currentSegmentIndex = 0;
    });

    _animateNextSegment();
  }

  void _animateNextSegment() {
    if (_currentSegmentIndex < _segments.length) {
      setState(() {
        _currentSegmentIndex++;
      });
      Future.delayed(const Duration(milliseconds: 100), _animateNextSegment);
    } else {
      setState(() {
        // _showingSegments = false;
      });
    }
  }
}
