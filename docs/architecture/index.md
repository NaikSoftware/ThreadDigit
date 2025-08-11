# ThreadDigit Architecture Overview

This document provides the architectural blueprint for the ThreadDigit photo-to-embroidery algorithm system.

## Architecture Documents

### Core Foundation
- [Tech Stack](tech-stack.md) - Technologies, frameworks, and libraries
- [Unified Project Structure](unified-project-structure.md) - File organization and module layout
- [Coding Standards](coding-standards.md) - Code style, conventions, and best practices

### System Architecture  
- [Data Models](data-models.md) - Core data structures and domain models
- [Algorithm Architecture](algorithm-architecture.md) - Processing pipeline and component design
- [Testing Strategy](testing-strategy.md) - Test approach and coverage requirements

### Implementation Details
- [Image Processing](image-processing.md) - Computer vision and analysis components
- [Stitch Generation](stitch-generation.md) - Core embroidery algorithm implementation
- [Optimization Strategies](optimization-strategies.md) - Performance and quality optimization approaches

## Architecture Principles

1. **Modular Design**: Each processing stage is independently testable and replaceable
2. **Immutable Data**: Core data structures are immutable with functional updates
3. **Performance First**: Algorithms optimized for mobile device constraints
4. **Extensible Framework**: Easy integration of new techniques and optimizations
5. **Quality Focused**: Built-in validation and quality metrics throughout pipeline

## Processing Pipeline Overview

```
Photo Input → Preprocessing → Analysis → Quantization → Stitch Generation → Optimization → Embroidery Output
     ↓              ↓           ↓            ↓              ↓               ↓              ↓
  Validation    Filtering   Direction    Color Mapping   Pattern Gen    Sequence Opt   Format Export
                            Fields      Thread Match    Silk Shading   Path Planning
```