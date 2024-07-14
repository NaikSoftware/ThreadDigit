import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:thread_digit/photostitch/photo_stitch.dart';
import 'package:thread_digit/viewport/image_data_painter.dart';
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
          IconButton(
              icon: const Icon(Icons.compare_outlined),
              onPressed: () {
                _onPrepareImage();
              }),
          IconButton(
              icon: const Icon(Icons.stacked_line_chart),
              onPressed: () {
                _onStitchImage();
              }),
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
              ? StitchesWidget(stitchSequences: stitchSequences)
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
      stitchSequences = stitchImage(image);
    });
  }
}
