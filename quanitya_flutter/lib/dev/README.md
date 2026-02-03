# Development Module

This directory contains all development-only functionality that is **completely excluded** from production builds.

## Build Exclusion

Dev code is excluded from release builds using two mechanisms:

1. **`.dartignore`** - Tells Flutter to ignore `lib/dev/` during builds
2. **`build_release.sh`** - Creates minimal stubs to prevent import errors

### Usage

```bash
# Build release APK (excludes dev code)
./build_release.sh android

# Build release iOS (excludes dev code)  
./build_release.sh ios

# Build release web (excludes dev code)
./build_release.sh web

# Regular debug build (includes dev code)
flutter run
```

## Structure

```
lib/dev/
├── dev_module.dart          # Main export file
├── services/
│   └── dev_seeder_service.dart  # Fake data generation
├── widgets/
│   ├── dev_fab.dart         # Development FAB (debug only)
│   └── dev_tools_sheet.dart # Dev tools bottom sheet
└── README.md               # This file
```

## Components

### DevFab
- **Location**: `widgets/dev_fab.dart`
- **Purpose**: Floating action button for dev tools access
- **Visibility**: Shows in debug builds, completely excluded from release

### DevToolsSheet
- **Location**: `widgets/dev_tools_sheet.dart`
- **Purpose**: Bottom sheet with development utilities
- **Features**:
  - Seed fake data
  - Clear all data
  - Wipe crypto keys
  - Navigation shortcuts

### DevSeederService
- **Location**: `services/dev_seeder_service.dart`
- **Purpose**: Generates realistic fake data for testing
- **Data Types**:
  - Mood tracking entries
  - Weight log entries
  - Workout entries
  - Sleep log entries
  - Private journal entries (hidden)
  - Medication tracking (hidden)

## Production Safety

✅ **Completely excluded** from release builds  
✅ **Zero bundle size impact** in production  
✅ **No security risk** - dev code not in production binary  
✅ **Import-safe** - stubs prevent build errors  

## Development Usage

Import the entire dev module:

```dart
import 'package:quanitya/dev/dev_module.dart';
```

Or import specific components:

```dart
import 'package:quanitya/dev/widgets/dev_fab.dart';
import 'package:quanitya/dev/services/dev_seeder_service.dart';
```

## Fake Data

The `DevSeederService` creates realistic test data including:
- 30 days of mood entries with realistic patterns
- Weekly weight measurements with natural fluctuation
- Workout entries with varied types and intensities
- Sleep tracking with quality scores
- Hidden templates for testing privacy features

All data uses proper encryption through the DualDAO pattern, so it tests the full E2EE flow.