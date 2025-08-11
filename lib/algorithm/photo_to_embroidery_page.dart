import 'package:flutter/material.dart';
import 'dart:ui' as ui;

import 'models/embroidery_parameters.dart';
import 'services/photo_to_embroidery_service.dart';
import 'package:image_picker/image_picker.dart';
import '../colors/widgets/color_sequence_widget.dart';

/// Main page for photo-to-embroidery conversion
class PhotoToEmbroideryPage extends StatefulWidget {
  const PhotoToEmbroideryPage({super.key});

  @override
  State<PhotoToEmbroideryPage> createState() => _PhotoToEmbroideryPageState();
}

class _PhotoToEmbroideryPageState extends State<PhotoToEmbroideryPage> {
  final PhotoToEmbroideryService _service = PhotoToEmbroideryService();
  final ImagePicker _imagePicker = ImagePicker();
  
  ui.Image? _selectedImage;
  bool _isProcessing = false;
  double _progress = 0.0;
  String _progressText = '';
  EmbroideryGenerationResult? _result;
  
  // Simple algorithm parameters
  int _colorLimit = 8;
  double _maxStitchLength = 4.0;
  double _density = 4.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Photo to Embroidery'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image selection
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    if (_selectedImage != null) ...[
                      Text('Image: ${_selectedImage!.width}x${_selectedImage!.height}px'),
                      const SizedBox(height: 16),
                    ],
                    ElevatedButton.icon(
                      onPressed: _isProcessing ? null : _pickImage,
                      icon: const Icon(Icons.photo),
                      label: const Text('Select Photo'),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Simple parameters
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Settings', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    
                    Text('Colors: $_colorLimit'),
                    Slider(
                      value: _colorLimit.toDouble(),
                      min: 2,
                      max: 16,
                      divisions: 14,
                      onChanged: _isProcessing ? null : (value) {
                        setState(() {
                          _colorLimit = value.toInt();
                        });
                      },
                    ),
                    
                    Text('Max Stitch Length: ${_maxStitchLength.toStringAsFixed(1)} mm'),
                    Slider(
                      value: _maxStitchLength,
                      min: 1.0,
                      max: 10.0,
                      divisions: 18,
                      onChanged: _isProcessing ? null : (value) {
                        setState(() {
                          _maxStitchLength = value;
                        });
                      },
                    ),
                    
                    Text('Density: ${_density.toStringAsFixed(1)}'),
                    Slider(
                      value: _density,
                      min: 2.0,
                      max: 8.0,
                      divisions: 12,
                      onChanged: _isProcessing ? null : (value) {
                        setState(() {
                          _density = value;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Process button
            ElevatedButton.icon(
              onPressed: (_selectedImage != null && !_isProcessing) ? _processImage : null,
              icon: _isProcessing 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.auto_fix_high),
              label: Text(_isProcessing ? 'Processing...' : 'Generate Embroidery'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            
            // Progress
            if (_isProcessing) ...[
              const SizedBox(height: 16),
              LinearProgressIndicator(value: _progress),
              const SizedBox(height: 8),
              Text(_progressText, textAlign: TextAlign.center),
            ],
            
            const SizedBox(height: 16),
            
            // Results
            Expanded(
              child: _buildResults(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResults() {
    if (_result == null) {
      return const Center(
        child: Text('Select a photo and generate embroidery to see results'),
      );
    }

    if (!_result!.isSuccess) {
      return Card(
        color: Colors.red.shade50,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Error:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
              const SizedBox(height: 8),
              Text(_result!.error ?? 'Unknown error'),
            ],
          ),
        ),
      );
    }

    final pattern = _result!.pattern!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Success!', style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.green)),
            const SizedBox(height: 16),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStat('Stitches', pattern.totalStitches.toString()),
                _buildStat('Colors', pattern.threads.length.toString()),
                _buildStat('Sequences', pattern.sequenceCount.toString()),
                _buildStat('Time', '${_result!.processingTimeMs}ms'),
              ],
            ),
            
            const SizedBox(height: 16),
            
            const Text('Thread Colors:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            SizedBox(
              height: 60,
              child: ColorSequenceWidget(threadColors: pattern.threads.values.toList()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStat(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Future<void> _pickImage() async {
    try {
      final pickedFile = await _imagePicker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        final imageData = await pickedFile.readAsBytes();
        final codec = await ui.instantiateImageCodec(imageData);
        final frame = await codec.getNextFrame();
        setState(() {
          _selectedImage = frame.image;
          _result = null;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: $e')),
        );
      }
    }
  }

  Future<void> _processImage() async {
    if (_selectedImage == null) return;

    setState(() {
      _isProcessing = true;
      _progress = 0.0;
      _progressText = 'Starting...';
    });

    try {
      final parameters = EmbroideryParameters(
        colorLimit: _colorLimit,
        maxStitchLength: _maxStitchLength,
        minStitchLength: 1.0,
        density: _density,
      );

      final result = await _service.generateEmbroideryFromPhoto(
        uiImage: _selectedImage!,
        parameters: parameters,
        onProgress: (progress, text) {
          setState(() {
            _progress = progress;
            _progressText = text;
          });
        },
      );

      setState(() {
        _result = result;
        _isProcessing = false;
      });

      if (result.isSuccess && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Embroidery pattern generated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isProcessing = false;
        _result = EmbroideryGenerationResult.failure(
          error: 'Processing failed: $e',
          processingTimeMs: 0,
        );
      });
    }
  }
}