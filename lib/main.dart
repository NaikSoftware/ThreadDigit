import 'package:flutter/material.dart';
import 'package:thread_digit/colors/color_manager.dart';
import 'package:thread_digit/colors/color_reader.dart';
import 'package:thread_digit/file/file_picker.dart';
import 'package:thread_digit/file/image_picker.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ThreadDigit',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MainPage(title: 'ThreadDigit'),
    );
  }
}

class MainPage extends StatelessWidget {
  const MainPage({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          title: Text(title),
        ),
        body: Column(
          children: [
            MaterialButton(
              onPressed: () => _handleColorOptimization(context),
              child: const Text('Optimize Colors'),
            ),
            MaterialButton(
              onPressed: () => _handlePhotoProcessing(context),
              child: const Text('Process photo'),
            ),
          ],
        ),
      );

  Future<void> _handleColorOptimization(BuildContext context) async {
    final file = await FilePicker().pick(context);
    if (file == null) return;
    final colors = await ColorReader().read(filePath: file.path);
    final steps = ColorManager().optimizeColors(
      colors.map((e) => e.toString()).toList(),
      ['1', '2', '3', '4', '5', '6', '7', '8', '9', '10', '11', '12', '13', '14', '15', '16', '17', '18', '19', '20'],
    );
  }

  void _handlePhotoProcessing(BuildContext context) async {
    Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const ImagePicker(),
        ));
  }
}
