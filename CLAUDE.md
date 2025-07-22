# Key Features

- **Thread Color Management**: Manages thread catalogs from multiple manufacturers (Madeira, Gunold, Isacord, etc.)
- **Color Matching**: Matches colors between different thread catalogs
- **Visualization**: Shows embroidery steps, color sequences, and bobbin visualization
- **Photo Processing**: Includes photo stitching functionality
- **Internationalization**: Multi-language support using intl

## Important for AI Agents

When working on tasks in this project, **ALWAYS read the documentation in the `docs/` folder first**. The documentation contains:

- `ai_agent_subtasks.md` - Detailed task breakdowns and prompts for implementing the embroidery algorithm
- `algorithm_implementation_roadmap.md` - Development phases, timeline, and success metrics
- `embroidery_algorithm_analysis.md` - Technical specifications, algorithms, and data structures

These documents provide essential context, requirements, and implementation details that must be understood before starting any work.

## Project Structure

```
thread_digit/
├── lib/
│   ├── colors/          # Thread color management
│   │   ├── catalog/     # Thread manufacturer catalogs
│   │   ├── model/       # Data models (ThreadColor, EmbroideryStep, etc.)
│   │   ├── service/     # Business logic (ColorManager, ColorMatcher)
│   │   ├── widgets/     # UI components for color visualization
│   │   └── reader/      # File format readers (PES, EDR)
│   ├── photostitch/     # Photo processing features
│   ├── viewport/        # Viewport management
│   ├── generated/       # Generated code (translations)
│   └── main.dart        # App entry point
├── tools/               # Build scripts
└── test/                # Unit tests
```

## Development Commands

### Code Quality

```bash
# Analyze single file
dart analyze path/to/file.dart

# Analyze entire project
dart analyze

# Format code (use 120 character line length)
dart format --line-length=120 path/to/file.dart
```

### Translations

```bash
# Generate translation files
./tools/generate_translations.sh
# or
dart run intl_utils:generate
```

### Testing

```bash
# Run all tests
flutter test

# Run specific test
flutter test test/specific_test.dart
```

## Important Conventions

1. **State Management**: Uses BLoC pattern with flutter_bloc
2. **Equality**: Uses Equatable for value equality in models
3. **File Formats**: Supports PES and EDR embroidery formats
4. **Color Models**: ThreadColor is the core model with RGB values and catalog info
5. **Localization**: Uses flutter_intl with ARB files

## Thread Catalogs

Thread catalogs are stored as Dart constants in `lib/colors/catalog/`. Each catalog contains:
- Thread name
- Color code
- RGB values
- Catalog identifier

## Testing Guidelines

- Write simple, self-documenting tests
- Avoid unnecessary comments like "Act", "Assert", "Arrange"
- Focus on real use cases
- Keep tests concise and readable
