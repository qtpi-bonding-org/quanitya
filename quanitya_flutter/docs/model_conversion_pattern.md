# Model-Database Conversion Pattern

## Overview

This pattern ensures type-safe, comprehensive conversion between Freezed models and Drift database entities. It prevents bugs like missing field conversions by centralizing conversion logic and providing comprehensive tests.

## Implementation

### 1. Conversion Extension

Add a conversion extension to your model file:

```dart
extension TemplateAestheticsConversion on TemplateAestheticsModel {
  /// Convert model to database companion for saving
  TemplateAestheticsCompanion toCompanion() {
    return TemplateAestheticsCompanion.insert(
      id: id,
      templateId: templateId,
      themeName: drift.Value(themeName),
      icon: drift.Value(icon),
      emoji: drift.Value(emoji),
      paletteJson: paletteJson,
      fontConfigJson: fontConfigJson,
      colorMappingsJson: colorMappingsJson,
      containerStyle: drift.Value(containerStyle?.name), // Convert enum to string
      updatedAt: updatedAt,
    );
  }

  /// Create model from database entity
  static TemplateAestheticsModel fromEntity(TemplateAesthetic entity) {
    return TemplateAestheticsModel(
      id: entity.id,
      templateId: entity.templateId,
      themeName: entity.themeName,
      icon: entity.icon,
      emoji: entity.emoji,
      palette: entity.paletteJson.isNotEmpty
          ? ColorPaletteData.fromJson(jsonDecode(entity.paletteJson))
          : ColorPaletteData.defaults(),
      fontConfig: entity.fontConfigJson.isNotEmpty
          ? FontConfigData.fromJson(jsonDecode(entity.fontConfigJson))
          : FontConfigData.defaults(),
      colorMappings: entity.colorMappingsJson.isNotEmpty
          ? Map<String, Map<String, String>>.from(
              (jsonDecode(entity.colorMappingsJson) as Map).map(
                (k, v) => MapEntry(k as String, Map<String, String>.from(v)),
              ),
            )
          : {},
      containerStyle: entity.containerStyle != null 
          ? TemplateContainerStyleX.fromName(entity.containerStyle!) 
          : null,
      updatedAt: entity.updatedAt,
    );
  }
}
```

### 2. DAO Integration

Update your DAOs to use the conversion methods:

```dart
// In TemplateAestheticsDao
TemplateAestheticsModel _entityToModel(TemplateAesthetic entity) {
  return TemplateAestheticsConversion.fromEntity(entity);
}

// For saves, use the model's conversion method
final companion = model.toCompanion();
```

### 3. Comprehensive Tests

Create roundtrip tests that verify all fields are preserved:

```dart
test('preserves all fields through complete roundtrip', () {
  // Act - Convert model → companion → entity → model
  final companion = testModel.toCompanion();
  
  // Simulate what the database would return
  final simulatedEntity = TemplateAesthetic(
    id: companion.id.value,
    templateId: companion.templateId.value,
    // ... all fields
  );
  
  final restoredModel = TemplateAestheticsConversion.fromEntity(simulatedEntity);

  // Assert - All fields should be preserved
  expect(restoredModel.id, equals(testModel.id));
  expect(restoredModel.containerStyle, equals(testModel.containerStyle));
  // ... test all fields
});
```

## Benefits

### Single Source of Truth
- Conversion logic lives with the model
- Changes to model automatically update conversion
- No scattered conversion code

### Bug Prevention
- Explicit field handling prevents missing conversions
- Compiler catches field mismatches
- Tests verify roundtrip integrity

### Type Safety
- Enum conversions are explicit and safe
- JSON serialization is centralized
- Null handling is consistent

### Maintainability
- Easy to add new fields
- Clear separation of concerns
- Testable conversion logic

## Example Bug Prevention

**Before:** Missing `containerStyle` conversion in DAO
```dart
// Bug: containerStyle field forgotten in conversion
return TemplateAestheticsModel(
  id: entity.id,
  templateId: entity.templateId,
  // ... other fields
  // containerStyle: missing!
);
```

**After:** Conversion extension catches all fields
```dart
// All fields explicitly handled in extension
static TemplateAestheticsModel fromEntity(TemplateAesthetic entity) {
  return TemplateAestheticsModel(
    // ... all fields must be provided
    containerStyle: entity.containerStyle != null 
        ? TemplatePresetX.fromName(entity.containerStyle!) 
        : null,
  );
}
```

**Test catches the bug:**
```dart
test('handles all TemplateContainerStyle enum values', () {
  for (final style in TemplateContainerStyle.values) {
    // Roundtrip test would fail if containerStyle conversion was missing
    final restoredModel = TemplateAestheticsConversion.fromEntity(simulatedEntity);
    expect(restoredModel.containerStyle, equals(style));
  }
});
```

## Usage Guidelines

1. **Always use conversion methods** - Don't manually convert in DAOs
2. **Test all fields** - Comprehensive roundtrip tests catch missing conversions
3. **Handle edge cases** - Test null values, empty JSON, invalid enums
4. **Use qualified imports** - Avoid conflicts between Drift and json_annotation
5. **Centralize JSON logic** - Keep serialization helpers in the model

This pattern ensures robust, maintainable model-database conversions that prevent subtle bugs and make the codebase more reliable.