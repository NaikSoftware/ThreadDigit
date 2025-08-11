# Development Commands for ThreadDigit

## Code Quality Commands

### Format Code
```bash
dart format --line-length=120 lib/
dart format --line-length=120 test/
```

### Analyze Code
```bash
dart analyze
# or analyze specific files:
dart analyze lib/specific_file.dart
```

### Run Tests
Use Dart MCP for this

## Localization Commands

### Generate Translation Files
```bash
./tools/generate_translations.sh
# or directly:
dart run intl_utils:generate
```

## Development Scripts
- `./tools/generate_catalog.sh` - Generate thread catalog data
- `./tools/generate_sources.sh` - Generate source files
- `./tools/generate_translations.sh` - Generate translation files

## Project Commands

### Clean Build
```bash
flutter clean
flutter pub get
```

### Run Application
```bash
flutter run
```

## Git Commands
- Always add new files to git: `git add <new_files>`
- Follow branch naming: `{type}/{task-number}_{description}`
- Types: feature/, bugfix/, improvement/
