# Technology Stack

## Core Framework
- **Flutter**: Cross-platform UI framework
- **Dart**: Primary programming language
- **BLoC Pattern**: State management using flutter_bloc

## Image Processing
- **dart:typed_data**: Efficient pixel manipulation
- **image**: Image processing library for Dart
- **vector_math**: Mathematical operations for geometry

## Computer Vision & Algorithms
- **Built-in Implementations**: Custom Dart implementations for:
  - Floyd-Steinberg dithering
  - Structure tensor analysis  
  - K-means clustering
  - TSP optimization algorithms
  - CIEDE2000 color distance

## Data Management
- **Equatable**: Value equality for data models
- **Collection**: Advanced collection operations
- **Meta**: Annotations for code generation

## Testing & Quality
- **flutter_test**: Unit and widget testing
- **mockito**: Mocking for testing
- **test**: Core testing framework
- **flutter_lints**: Code quality enforcement

## Internationalization
- **flutter_localizations**: Multi-language support
- **intl**: Internationalization utilities

## File I/O
- **path**: File path manipulation
- **dart:io**: File system operations
- **dart:convert**: JSON and binary data handling

## Performance Libraries
- **dart:isolate**: Background processing for heavy computations
- **dart:ffi**: Native code integration if needed
- **compute**: Flutter's compute function for isolates

## Existing Thread System Integration
- **ThreadColor model**: RGB color representation with catalog info
- **ColorMatcher**: Thread catalog matching utilities
- **Catalog system**: Pre-built thread color databases (Madeira, Gunold, etc.)

## Development Tools
- **build_runner**: Code generation
- **dart_style**: Code formatting
- **analyzer**: Static analysis

## Constraints & Decisions

### Why Custom Implementations?
- **Mobile Performance**: Optimized for Flutter's constraints
- **Dependency Minimization**: Reduce external dependencies
- **Algorithm Control**: Full control over algorithm behavior
- **Memory Efficiency**: Tailored for mobile memory limits

### Rejected Alternatives
- **OpenCV**: Too heavy for Flutter mobile
- **TensorFlow Lite**: Overkill for our specific algorithms
- **Native Libraries**: Complexity vs benefit trade-off