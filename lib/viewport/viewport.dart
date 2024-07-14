import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:thread_digit/photostitch/photo_stitch.dart';
import 'package:thread_digit/viewport/image_data_painter.dart';

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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editor'),
        actions: <Widget>[
          IconButton(icon: const Icon(Icons.compare_outlined), onPressed: () {
            _onPrepareImage();
          }),
          IconButton(icon: const Icon(Icons.stacked_line_chart), onPressed: () {

          }),
        ],
      ),
      body: InteractiveViewer(
        constrained: false,
        minScale: 0.1,
        child: ImageDataWidget(image: image),
      ),
    );
  }

  void _onPrepareImage() {
    setState(() {
      image = img.quantize(image, numberOfColors: 8);
    });
  }
}
