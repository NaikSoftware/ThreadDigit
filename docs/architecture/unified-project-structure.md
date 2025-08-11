# Unified Project Structure

## Project Root Structure
```
thread_digit/
├── lib/                    # Main application code
│   ├── algorithm/          # NEW: Core embroidery algorithm
│   ├── colors/            # Existing: Thread color management  
│   ├── common/            # Existing: Shared UI components
│   ├── file/              # Existing: File I/O utilities
│   ├── generated/         # Generated code (intl, etc.)
│   ├── l10n/              # Localization files
│   ├── photostitch/       # Existing: Photo processing
│   ├── viewport/          # Existing: Viewport management
│   └── main.dart          # Application entry point
├── test/                  # Test files mirror lib/ structure
├── docs/                  # Project documentation
├── tools/                 # Build and utility scripts
└── pubspec.yaml          # Package configuration
```

## Core Algorithm Module Structure
```
lib/algorithm/
├── models/                # Data structures and domain models
│   ├── stitch.dart       # Core stitch representation
│   ├── stitch_sequence.dart # Stitch sequence management
│   ├── embroidery_pattern.dart # Complete pattern representation
│   ├── embroidery_parameters.dart # Algorithm configuration
│   ├── direction_field.dart # Texture direction analysis
│   └── region.dart       # Image region representation
├── processors/           # Processing pipeline components
│   ├── image_preprocessor.dart # Image preprocessing
│   ├── texture_analyzer.dart   # Direction field computation
│   ├── color_quantizer.dart    # Color reduction and mapping
│   ├── stitch_generator.dart   # Core stitch generation
│   └── sequence_optimizer.dart # Path optimization
├── techniques/           # Advanced embroidery techniques
│   ├── silk_shading.dart # Gradient and shading implementation
│   ├── sfumato.dart      # Soft edge technique
│   └── fill_patterns.dart # Standard fill algorithms
├── optimization/         # Performance and quality optimization
│   ├── path_planner.dart # TSP-based path planning
│   ├── sequence_merger.dart # Sequence connection optimization
│   └── quality_validator.dart # Output quality validation
├── services/            # Algorithm orchestration services
│   ├── embroidery_engine.dart # Main processing pipeline
│   ├── parameter_validator.dart # Input validation
│   └── progress_tracker.dart # Processing progress updates
└── utils/               # Algorithm-specific utilities
    ├── math_utils.dart  # Mathematical operations
    ├── geometry_utils.dart # Geometric calculations
    └── color_spaces.dart # Color space conversions
```

## Existing Color System Integration
```
lib/colors/
├── catalog/             # Existing thread catalogs
├── model/              # Existing models + NEW algorithm integration
│   ├── thread_color.dart # Existing
│   ├── embroidery_step.dart # Existing  
│   ├── stitch_operation.dart # Existing
│   └── thread_change.dart # Existing
├── service/            # Enhanced for algorithm integration
│   ├── color_manager.dart # Existing
│   ├── color_matcher.dart # Enhanced for CIEDE2000
│   └── reader/ # Existing PES/EDR readers
└── widgets/ # Existing UI components
```

## Test Structure
```
test/
├── algorithm/           # NEW: Algorithm component tests
│   ├── models/         # Data model tests
│   ├── processors/     # Processing pipeline tests  
│   ├── techniques/     # Technique implementation tests
│   ├── optimization/   # Optimization algorithm tests
│   └── integration/    # End-to-end pipeline tests
├── colors/             # Existing color system tests
└── test_utils/         # Shared testing utilities
```

## File Naming Conventions

### Dart Files
- **Classes**: PascalCase (`StitchGenerator`)
- **Files**: snake_case (`stitch_generator.dart`)
- **Private**: Leading underscore (`_internal_utils.dart`)

### Test Files  
- **Unit Tests**: `{filename}_test.dart`
- **Integration Tests**: `{feature}_integration_test.dart`
- **Test Data**: `test/fixtures/{category}/`

### Generated Files
- **Location**: `lib/generated/`
- **Exclusion**: Add to `.gitignore` 
- **Rebuild**: Use `flutter packages pub run build_runner build`

## Module Dependencies

### Algorithm Module Dependencies
```dart
// Internal dependencies only
import 'package:thread_digit/colors/model/thread_color.dart';
import 'package:thread_digit/colors/service/color_matcher.dart';

// External dependencies
import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';
import 'package:vector_math/vector_math.dart';
```

### Dependency Flow Rules
1. **Algorithm → Colors**: Algorithm can depend on existing color system
2. **Colors ← Algorithm**: Color system should not depend on algorithm
3. **Common**: Both can depend on common utilities
4. **External**: Minimize external dependencies

## Asset Organization
```
assets/
├── images/             # App images and icons
├── test_photos/        # Sample photos for testing
└── sample_patterns/    # Reference embroidery patterns
```

## Build Configuration
- **Flutter**: Use standard Flutter project structure
- **Code Generation**: Configure in `pubspec.yaml`
- **Linting**: Use `flutter_lints` package
- **Testing**: Mirror `lib/` structure in `test/`