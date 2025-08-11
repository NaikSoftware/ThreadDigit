# Code Style and Conventions

## Dart/Flutter Conventions

### Code Style
- **Line Length**: 120 characters (use `dart format --line-length=120`)
- **State Management**: BLoC pattern using flutter_bloc
- **File Organization**: Clean architecture with processors/, models/, services/, techniques/
- **Naming**: snake_case for files, camelCase for variables, PascalCase for classes
- **Documentation**: Brief but clear documentation for public APIs

### Architecture Patterns
- **ProcessingResult<T>**: Wrapper for operations that can fail
- **Static Methods**: Most algorithm processors use static methods
- **Equatable**: Used for value equality in models
- **Image Processing**: Uses `image` package, not `ui.Image` for algorithm processing

### Testing Guidelines
- Write simple, self-documenting tests
- No "Act/Arrange/Assert" comments
- Focus on real use cases
- Keep tests concise and readable

### Error Handling
- Use ProcessingResult<T> pattern for fallible operations
- Provide clear error messages
- Validate inputs at method boundaries

### Memory Management
- Be conscious of large image processing operations
- Use typed data (Float32List, etc.) for performance
- Clean up resources properly