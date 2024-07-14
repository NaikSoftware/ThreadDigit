import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;

class ImageDataWidget extends StatefulWidget {
  final img.Image image;

  const ImageDataWidget({
    required this.image,
    super.key,
  });

  @override
  State<ImageDataWidget> createState() => _ImageDataWidgetState();
}

class _ImageDataWidgetState extends State<ImageDataWidget> {
  late Future<ui.Image> uiImage;

  @override
  void initState() {
    super.initState();
    uiImage = _imageToUiImage();
  }

  @override
  void didUpdateWidget(covariant ImageDataWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.image != widget.image) {
      uiImage = _imageToUiImage();
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    return FutureBuilder(
      future: uiImage,
      builder: (context, snapshot) {
        final ui.Image? uiImage = snapshot.data;
        if (uiImage == null) {
          return SizedBox(
            width: screenSize.width,
            height: 400,
            child: const Center(child: CircularProgressIndicator()),
          );
        } else if (snapshot.hasError) {
          return Text('Error loading image: ${snapshot.error}');
        }
        return SizedBox(
          width: max(uiImage.width.toDouble(), screenSize.width),
          height: max(uiImage.height.toDouble(), screenSize.height),
          child: CustomPaint(
            painter: ImageDataPainter(snapshot.data!),
          ),
        );
      },
    );
  }

  Future<ui.Image> _imageToUiImage() async {
    // Convert the image to a Flutter Image
    final completer = Completer<ui.Image>();
    ui.decodeImageFromList(
      img.encodeBmp(widget.image),
      completer.complete,
    );
    return completer.future;
  }
}

class ImageDataPainter extends CustomPainter {
  final ui.Image image;

  ImageDataPainter(this.image);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawImage(image, Offset.zero, Paint());
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
