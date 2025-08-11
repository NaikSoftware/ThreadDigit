# ThreadDigit Project Overview

## Purpose
ThreadDigit is a digitizing embroidery software built with Flutter/Dart that converts photographs into sophisticated embroidery patterns. The project implements advanced algorithms for photorealistic embroidery generation using techniques like silk shading, sfumato, and adaptive opacity control.

## Tech Stack
- **Flutter/Dart**: Main application framework
- **image package**: Image processing operations  
- **BLoC pattern**: State management using flutter_bloc
- **Localization**: flutter_intl with ARB files
- **Testing**: flutter_test for unit tests

## Key Features
- Photo-to-embroidery conversion with sophisticated algorithms
- Thread color management from multiple manufacturers (Madeira, Gunold, etc.)
- Advanced techniques: silk shading, sfumato, adaptive opacity
- Color quantization using K-means clustering in LAB color space
- Thread flow analysis for natural embroidery patterns
- Multi-stage preprocessing pipeline

## Architecture
- Clean separation between algorithm components in `lib/algorithm/`
- Models for data structures (colors, patterns, stitches)
- Processors for image processing operations
- Techniques for advanced embroidery algorithms
- Services for high-level orchestration