import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart' as image_picker;
import 'package:image/image.dart' as img;

class ImagePicker extends StatelessWidget {
  const ImagePicker({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Image Picker'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text('No image selected.'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _pickImage(context),
              child: const Text('Pick Image'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(BuildContext context) async {
    final picker = image_picker.ImagePicker();
    final pickedFile = await picker.pickImage(source: image_picker.ImageSource.gallery);

    if (pickedFile != null) {
      final File imageFile = File(pickedFile.path);
      final Uint8List imageBytes = await imageFile.readAsBytes();
      final img.Image? image = img.decodeImage(imageBytes);

      // if (image != null && context.mounted) {
      //   Navigator.of(context).push(MaterialPageRoute(
      //     builder: (context) => /* some route here */,
      //   ));
      // }
    }
  }
}
