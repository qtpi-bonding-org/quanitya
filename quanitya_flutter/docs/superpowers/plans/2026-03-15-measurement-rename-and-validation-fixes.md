# Measurement Rename & Validation Fixes Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Rename DimensionEnum to MeasurementDimension and UnitEnum to MeasurementUnit with proper Dimension linkage, update TemplateField to use `unit` instead of `dimension`, and fix all validation bugs in the template JSON schema system.

**Architecture:** The math layer (`Dimension` class) stays untouched. `MeasurementDimension` becomes a curated whitelist of SI dimensions carrying their `Dimension` object. `MeasurementUnit` carries its `MeasurementDimension` and stubs for future conversion. `TemplateField` replaces `DimensionEnum? dimension` with `MeasurementUnit? unit` — the dimension is derivable from the unit. Validation bugs (isList, location, reference, custom, dimension validator) are fixed in `FieldValidators` and `LogEntryRepository`.

**Tech Stack:** Dart, Flutter, Freezed, Drift, json_serializable

**No migration needed** — MVP not launched, no users.

---

## Chunk 1: MeasurementDimension and MeasurementUnit Enums

### Task 1: Create MeasurementDimension enum (replaces DimensionEnum)

**Files:**
- Create: `lib/logic/templates/enums/measurement_dimension.dart`
- Create: `test/logic/templates/enums/measurement_dimension_test.dart`

- [ ] **Step 1: Write failing tests for MeasurementDimension**

Create `test/logic/templates/enums/measurement_dimension_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:quanitya_flutter/logic/templates/enums/measurement_dimension.dart';
import 'package:quanitya_flutter/logic/templates/models/dimension.dart';

void main() {
  group('MeasurementDimension', () {
    test('mass carries Dimension.M', () {
      expect(MeasurementDimension.mass.dimension, equals(Dimension.M));
    });

    test('length carries Dimension.L', () {
      expect(MeasurementDimension.length.dimension, equals(Dimension.L));
    });

    test('volume carries Dimension.volume (L cubed)', () {
      expect(MeasurementDimension.volume.dimension, equals(Dimension.volume));
    });

    test('time carries Dimension.T', () {
      expect(MeasurementDimension.time.dimension, equals(Dimension.T));
    });

    test('all values have unique dimensions', () {
      final dimensions = MeasurementDimension.values.map((d) => d.dimension).toSet();
      expect(dimensions.length, equals(MeasurementDimension.values.length));
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd /Users/aicoder/Documents/openops/project/quanitya/public/quanitya_flutter && flutter test test/logic/templates/enums/measurement_dimension_test.dart --no-pub 2>&1 > /tmp/test_results.txt && cat /tmp/test_results.txt`
Expected: FAIL — import not found.

- [ ] **Step 3: Create MeasurementDimension enum**

Create `lib/logic/templates/enums/measurement_dimension.dart`:

```dart
import '../models/dimension.dart';

/// Curated whitelist of measurement dimensions available for template fields.
///
/// Each value carries its SI [Dimension] for mathematical operations.
/// This is a UX gate — it controls which dimensions users can select,
/// while [Dimension] defines what's physically possible.
///
/// To add a new dimension (e.g., temperature):
/// 1. Add enum value here with its SI Dimension
/// 2. Add corresponding units to MeasurementUnit
/// 3. Units and conversion come for free from the math layer
enum MeasurementDimension {
  /// Weight or mass measurements (kg, lbs, grams, etc.)
  mass(Dimension.M),

  /// Distance or length measurements (meters, feet, inches, etc.)
  length(Dimension.L),

  /// Volume or capacity measurements (liters, gallons, etc.)
  volume(Dimension.volume),

  /// Time duration measurements (seconds, minutes, hours, etc.)
  time(Dimension.T);

  const MeasurementDimension(this.dimension);

  /// The SI dimensional analysis representation.
  final Dimension dimension;
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd /Users/aicoder/Documents/openops/project/quanitya/public/quanitya_flutter && flutter test test/logic/templates/enums/measurement_dimension_test.dart --no-pub 2>&1 > /tmp/test_results.txt && cat /tmp/test_results.txt`
Expected: All 5 tests PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/logic/templates/enums/measurement_dimension.dart test/logic/templates/enums/measurement_dimension_test.dart
git commit -m "feat: add MeasurementDimension enum carrying SI Dimension"
```

---

### Task 2: Create MeasurementUnit enum (replaces UnitEnum)

**Files:**
- Create: `lib/logic/templates/enums/measurement_unit.dart`
- Create: `test/logic/templates/enums/measurement_unit_test.dart`

- [ ] **Step 1: Write failing tests for MeasurementUnit**

Create `test/logic/templates/enums/measurement_unit_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:quanitya_flutter/logic/templates/enums/measurement_dimension.dart';
import 'package:quanitya_flutter/logic/templates/enums/measurement_unit.dart';
import 'package:quanitya_flutter/logic/templates/models/dimension.dart';

void main() {
  group('MeasurementUnit', () {
    group('dimension linkage', () {
      test('kilograms belongs to mass dimension', () {
        expect(
          MeasurementUnit.kilograms.measurementDimension,
          equals(MeasurementDimension.mass),
        );
      });

      test('meters belongs to length dimension', () {
        expect(
          MeasurementUnit.meters.measurementDimension,
          equals(MeasurementDimension.length),
        );
      });

      test('liters belongs to volume dimension', () {
        expect(
          MeasurementUnit.liters.measurementDimension,
          equals(MeasurementDimension.volume),
        );
      });

      test('seconds belongs to time dimension', () {
        expect(
          MeasurementUnit.seconds.measurementDimension,
          equals(MeasurementDimension.time),
        );
      });

      test('SI dimension is derivable through chain', () {
        expect(
          MeasurementUnit.kilograms.measurementDimension.dimension,
          equals(Dimension.M),
        );
      });
    });

    group('display', () {
      test('displayName returns short symbol', () {
        expect(MeasurementUnit.kilograms.displayName, equals('kg'));
        expect(MeasurementUnit.pounds.displayName, equals('lbs'));
        expect(MeasurementUnit.meters.displayName, equals('m'));
      });

      test('fullName returns long name', () {
        expect(MeasurementUnit.kilograms.fullName, equals('Kilograms'));
        expect(MeasurementUnit.pounds.fullName, equals('Pounds'));
      });
    });

    group('conversion stubs', () {
      test('toBase returns value unchanged (stub)', () {
        expect(MeasurementUnit.kilograms.toBase(72.5), equals(72.5));
      });

      test('fromBase returns value unchanged (stub)', () {
        expect(MeasurementUnit.kilograms.fromBase(72.5), equals(72.5));
      });
    });

    group('filtering', () {
      test('unitsFor returns only units of given dimension', () {
        final massUnits = MeasurementUnit.unitsFor(MeasurementDimension.mass);
        expect(massUnits, contains(MeasurementUnit.kilograms));
        expect(massUnits, contains(MeasurementUnit.pounds));
        expect(massUnits, isNot(contains(MeasurementUnit.meters)));
      });

      test('unitsFor returns correct count for each dimension', () {
        expect(MeasurementUnit.unitsFor(MeasurementDimension.mass).length, equals(6));
        expect(MeasurementUnit.unitsFor(MeasurementDimension.length).length, equals(8));
        expect(MeasurementUnit.unitsFor(MeasurementDimension.volume).length, equals(7));
        expect(MeasurementUnit.unitsFor(MeasurementDimension.time).length, equals(7));
      });
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd /Users/aicoder/Documents/openops/project/quanitya/public/quanitya_flutter && flutter test test/logic/templates/enums/measurement_unit_test.dart --no-pub 2>&1 > /tmp/test_results.txt && cat /tmp/test_results.txt`
Expected: FAIL — import not found.

- [ ] **Step 3: Create MeasurementUnit enum**

Create `lib/logic/templates/enums/measurement_unit.dart`:

```dart
import 'measurement_dimension.dart';

/// Concrete measurement units, each linked to a [MeasurementDimension].
///
/// Full derivation chain:
/// ```
/// MeasurementUnit.kilograms
///   -> .measurementDimension -> MeasurementDimension.mass
///     -> .dimension -> Dimension.M (SI math)
/// ```
///
/// Conversion stubs ([toBase]/[fromBase]) return identity for now.
/// When conversion is needed, implement factors per unit
/// or wire to the `units_converter` package behind [IMeasurementService].
enum MeasurementUnit {
  // -- Mass -------------------------------------------------------------------
  kilograms(MeasurementDimension.mass, 'kg', 'Kilograms'),
  pounds(MeasurementDimension.mass, 'lbs', 'Pounds'),
  grams(MeasurementDimension.mass, 'g', 'Grams'),
  ounces(MeasurementDimension.mass, 'oz', 'Ounces'),
  stones(MeasurementDimension.mass, 'st', 'Stones'),
  tons(MeasurementDimension.mass, 't', 'Tons'),

  // -- Length -----------------------------------------------------------------
  meters(MeasurementDimension.length, 'm', 'Meters'),
  feet(MeasurementDimension.length, 'ft', 'Feet'),
  inches(MeasurementDimension.length, 'in', 'Inches'),
  centimeters(MeasurementDimension.length, 'cm', 'Centimeters'),
  millimeters(MeasurementDimension.length, 'mm', 'Millimeters'),
  kilometers(MeasurementDimension.length, 'km', 'Kilometers'),
  miles(MeasurementDimension.length, 'mi', 'Miles'),
  yards(MeasurementDimension.length, 'yd', 'Yards'),

  // -- Volume -----------------------------------------------------------------
  liters(MeasurementDimension.volume, 'L', 'Liters'),
  gallons(MeasurementDimension.volume, 'gal', 'Gallons'),
  milliliters(MeasurementDimension.volume, 'mL', 'Milliliters'),
  fluidOunces(MeasurementDimension.volume, 'fl oz', 'Fluid Ounces'),
  cups(MeasurementDimension.volume, 'cup', 'Cups'),
  pints(MeasurementDimension.volume, 'pt', 'Pints'),
  quarts(MeasurementDimension.volume, 'qt', 'Quarts'),

  // -- Time -------------------------------------------------------------------
  seconds(MeasurementDimension.time, 's', 'Seconds'),
  minutes(MeasurementDimension.time, 'min', 'Minutes'),
  hours(MeasurementDimension.time, 'h', 'Hours'),
  days(MeasurementDimension.time, 'd', 'Days'),
  weeks(MeasurementDimension.time, 'wk', 'Weeks'),
  months(MeasurementDimension.time, 'mo', 'Months'),
  years(MeasurementDimension.time, 'yr', 'Years');

  const MeasurementUnit(this.measurementDimension, this.displayName, this.fullName);

  /// The measurement dimension this unit belongs to.
  final MeasurementDimension measurementDimension;

  /// Short display symbol (e.g., 'kg', 'lbs', 'm').
  final String displayName;

  /// Full human-readable name (e.g., 'Kilograms', 'Pounds', 'Meters').
  final String fullName;

  /// Converts a value in this unit to the base unit of its dimension.
  ///
  /// Stub — returns value unchanged. Implement conversion factors
  /// or wire to `units_converter` package when needed.
  num toBase(num value) => value;

  /// Converts a value from the base unit of its dimension to this unit.
  ///
  /// Stub — returns value unchanged.
  num fromBase(num value) => value;

  /// Returns all units belonging to the given [MeasurementDimension].
  static List<MeasurementUnit> unitsFor(MeasurementDimension dimension) {
    return values.where((u) => u.measurementDimension == dimension).toList();
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd /Users/aicoder/Documents/openops/project/quanitya/public/quanitya_flutter && flutter test test/logic/templates/enums/measurement_unit_test.dart --no-pub 2>&1 > /tmp/test_results.txt && cat /tmp/test_results.txt`
Expected: All tests PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/logic/templates/enums/measurement_unit.dart test/logic/templates/enums/measurement_unit_test.dart
git commit -m "feat: add MeasurementUnit enum with dimension linkage and conversion stubs"
```

---

### Task 3: Delete old enums and update all imports

**Files:**
- Delete: `lib/logic/templates/enums/dimension_enum.dart`
- Delete: `lib/logic/templates/enums/unit_enum.dart`
- Modify: `lib/logic/templates/models/shared/template_field.dart` (replace DimensionEnum? dimension with MeasurementUnit? unit)
- Modify: `lib/infrastructure/units/unit_service.dart` (UnitEnum -> MeasurementUnit)
- Modify: `lib/logic/templates/enums/field_enum.dart` (doc comment)
- Modify: `lib/logic/templates/enums/field_enum_extensions.dart` (display name)
- Modify: `lib/logic/templates/models/shared/field_validator.dart` (doc comment)
- Modify: `lib/logic/templates/models/shared/field_widget_symbol.dart` (if references old enums)
- Modify: `lib/logic/templates/services/shared/dynamic_field_builder.dart` (if references old enums)
- Modify: `lib/logic/templates/services/engine/json_to_model_parser.dart` (if references old enums)
- Modify: `lib/features/templates/widgets/editor/inline_field_editor.dart` (if references old enums)
- Modify: `lib/data/repositories/data_retrieval_service.dart` (if references old enums)
- Modify: `lib/dev/services/dev_seeder_service.dart` (if references old enums)
- Modify: `test/infrastructure/units/unit_service_test.dart` (UnitEnum -> MeasurementUnit)

- [ ] **Step 1: Delete old DimensionEnum file**

Delete `lib/logic/templates/enums/dimension_enum.dart`.

- [ ] **Step 2: Delete old UnitEnum file**

Delete `lib/logic/templates/enums/unit_enum.dart`. This also removes `UnitsByDimension` and `UnitEnumExtension`, now folded into `MeasurementUnit`.

- [ ] **Step 3: Update TemplateField — replace dimension with unit**

In `lib/logic/templates/models/shared/template_field.dart`:

Replace import `'../../enums/dimension_enum.dart'` with `'../../enums/measurement_unit.dart'`.

Replace field:
```dart
    DimensionEnum? dimension,
```
with:
```dart
    MeasurementUnit? unit,
```

Update factory constructor parameter and body similarly.

- [ ] **Step 4: Update UnitService — UnitEnum to MeasurementUnit**

In `lib/infrastructure/units/unit_service.dart`:

Replace import `'../../logic/templates/enums/unit_enum.dart'` with `'../../logic/templates/enums/measurement_unit.dart'`.

Replace all `UnitEnum` with `MeasurementUnit` in interface and implementation.

Update `getUnitsForDimension`:
```dart
@override
List<MeasurementUnit> getUnitsForDimension(Dimension dimension) {
  return MeasurementUnit.values
      .where((unit) => unit.measurementDimension.dimension == dimension)
      .toList();
}
```

Update `isValidUnitForDimension`:
```dart
@override
bool isValidUnitForDimension(MeasurementUnit unit, Dimension dimension) {
  return unit.measurementDimension.dimension == dimension;
}
```

Update `format` — `unit.displayName` is now a direct field, no extension needed.

Update `getDimension`:
```dart
@override
Dimension getDimension(MeasurementUnit unit) {
  return unit.measurementDimension.dimension;
}
```

Update `areCompatible`:
```dart
@override
bool areCompatible(MeasurementUnit unit1, MeasurementUnit unit2) {
  return unit1.measurementDimension == unit2.measurementDimension;
}
```

- [ ] **Step 5: Update UnitService test**

In `test/infrastructure/units/unit_service_test.dart`:

Replace import and all `UnitEnum.` references with `MeasurementUnit.`.

- [ ] **Step 6: Update FieldEnum doc comment**

In `lib/logic/templates/enums/field_enum.dart:23`:
```dart
  /// Physical measurement with units (requires DimensionEnum)
```
to:
```dart
  /// Physical measurement with units (requires MeasurementUnit)
```

- [ ] **Step 7: Update FieldEnum display name**

In `lib/logic/templates/enums/field_enum_extensions.dart:16`:
```dart
      FieldEnum.dimension => 'Dimension',
```
to:
```dart
      FieldEnum.dimension => 'Measurement',
```

- [ ] **Step 8: Update FieldValidator doc comment**

In `lib/logic/templates/models/shared/field_validator.dart:22`:
```dart
    /// - dimension: {"allowedUnits": ["UnitEnum.kg", "UnitEnum.lbs"], "minValue": 0}
```
to:
```dart
    /// - dimension: {"minValue": 0, "maxValue": 500}
```

- [ ] **Step 9: Search and update all remaining references**

Run grep for `DimensionEnum`, `UnitEnum`, `UnitsByDimension`, `dimension_enum.dart`, `unit_enum.dart` across the codebase. Update every remaining import and reference. Key files to check:
- `lib/logic/templates/services/shared/dynamic_field_builder.dart`
- `lib/logic/templates/services/engine/json_to_model_parser.dart`
- `lib/logic/templates/models/shared/field_widget_symbol.dart`
- `lib/features/templates/widgets/editor/inline_field_editor.dart`
- `lib/data/repositories/data_retrieval_service.dart`
- `lib/dev/services/dev_seeder_service.dart`

For any code that reads `field.dimension`, change to `field.unit` or `field.unit?.measurementDimension` as appropriate.

- [ ] **Step 10: Run build_runner to regenerate Freezed/JSON code**

Run: `cd /Users/aicoder/Documents/openops/project/quanitya/public/quanitya_flutter && dart run build_runner build --delete-conflicting-outputs 2>&1 > /tmp/build_results.txt && tail -20 /tmp/build_results.txt`
Expected: Build succeeds. `template_field.freezed.dart` and `template_field.g.dart` regenerated with `unit` field.

- [ ] **Step 11: Run all tests**

Run: `cd /Users/aicoder/Documents/openops/project/quanitya/public/quanitya_flutter && flutter test --no-pub 2>&1 > /tmp/test_results.txt && tail -30 /tmp/test_results.txt`
Expected: All tests pass.

- [ ] **Step 12: Commit**

```bash
git add -A
git commit -m "refactor: rename DimensionEnum -> MeasurementDimension, UnitEnum -> MeasurementUnit

Replace TemplateField.dimension with TemplateField.unit.
Remove UnitsByDimension (now MeasurementUnit.unitsFor).
Update all imports and consumers."
```

---

## Chunk 2: Validation Bug Fixes

### Task 4: Fix isList type validation with per-item type checking

**Files:**
- Modify: `lib/data/repositories/log_entry_repository.dart:333-350`
- Create: `test/data/repositories/log_entry_validation_test.dart`

This is the most critical bug: `isList: true` fields always fail type validation because `_validateFieldType` checks scalar type against the whole list value.

- [ ] **Step 1: Write failing tests**

Create `test/data/repositories/log_entry_validation_test.dart`. Since `_validateDataAgainstTemplate` is private, we test through the validation logic. If needed, extract into a testable `TemplateDataValidator` class.

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:quanitya_flutter/logic/templates/enums/field_enum.dart';
import 'package:quanitya_flutter/logic/templates/models/shared/field_validator.dart';
import 'package:quanitya_flutter/logic/templates/models/shared/template_field.dart';
import 'package:quanitya_flutter/logic/templates/models/shared/tracker_template.dart';

void main() {
  group('isList type validation', () {
    // Tests will depend on how validation is exposed.
    // If _validateDataAgainstTemplate remains private,
    // extract to TemplateDataValidator and test that directly.

    test('list of integers passes for integer isList field', () {
      // {field.id: [10, 20, 30]} should pass
    });

    test('list with wrong item type fails', () {
      // {field.id: [1, "two", 3]} should fail on item 2
    });

    test('non-list value fails for isList field', () {
      // {field.id: 42} should fail — must be a list
    });

    test('empty list passes for optional isList field', () {
      // {field.id: []} should pass if field is optional
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd /Users/aicoder/Documents/openops/project/quanitya/public/quanitya_flutter && flutter test test/data/repositories/log_entry_validation_test.dart --no-pub 2>&1 > /tmp/test_results.txt && cat /tmp/test_results.txt`

- [ ] **Step 3: Fix _validateFieldType to handle isList**

In `lib/data/repositories/log_entry_repository.dart`, replace `_validateFieldType` (around line 333) with:

```dart
  /// Validates that a value matches the expected field type.
  /// For isList fields, validates the value is a List and checks each item.
  String? _validateFieldType(TemplateField field, dynamic value) {
    if (field.isList) {
      if (value is! List) return '${field.label} must be a list';
      for (int i = 0; i < value.length; i++) {
        final itemError = _validateScalarType(field, value[i]);
        if (itemError != null) return '$itemError (item ${i + 1})';
      }
      return null;
    }
    return _validateScalarType(field, value);
  }

  /// Validates a single scalar value against the field's expected type.
  String? _validateScalarType(TemplateField field, dynamic value) {
    final label = field.label;
    return switch (field.type) {
      FieldEnum.integer => value is int ? null : '$label must be an integer',
      FieldEnum.float => value is num ? null : '$label must be a number',
      FieldEnum.boolean => value is bool ? null : '$label must be a boolean',
      FieldEnum.text => value is String ? null : '$label must be text',
      FieldEnum.datetime => _validateDateTime(value, label),
      FieldEnum.enumerated => _validateEnumerated(value, field.options, label),
      FieldEnum.dimension => value is num ? null : '$label must be a number',
      FieldEnum.reference =>
        value is String ? null : '$label must be a reference ID',
      FieldEnum.location => _validateLocation(value, label),
    };
  }
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd /Users/aicoder/Documents/openops/project/quanitya/public/quanitya_flutter && flutter test test/data/repositories/log_entry_validation_test.dart --no-pub 2>&1 > /tmp/test_results.txt && cat /tmp/test_results.txt`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/data/repositories/log_entry_repository.dart test/data/repositories/log_entry_validation_test.dart
git commit -m "fix: handle isList fields in type validation with per-item checking"
```

---

### Task 5: Fix location validation

**Files:**
- Modify: `lib/data/repositories/log_entry_repository.dart` (add `_validateLocation`)
- Modify: `test/data/repositories/log_entry_validation_test.dart`

- [ ] **Step 1: Write failing tests for location validation**

Add to `test/data/repositories/log_entry_validation_test.dart`:

```dart
  group('location validation', () {
    test('valid location map passes', () {
      // {'latitude': 37.7749, 'longitude': -122.4194} should pass
    });

    test('map without latitude fails', () {
      // {'longitude': -122.4194} should fail
    });

    test('map without longitude fails', () {
      // {'latitude': 37.7749} should fail
    });

    test('non-numeric coordinates fail', () {
      // {'latitude': 'north', 'longitude': -122.4194} should fail
    });

    test('non-map value fails', () {
      // "some string" should fail
    });
  });
```

- [ ] **Step 2: Run test to verify it fails**

- [ ] **Step 3: Add _validateLocation method**

In `lib/data/repositories/log_entry_repository.dart`, add after `_validateEnumerated`:

```dart
  String? _validateLocation(dynamic value, String label) {
    if (value is! Map) return '$label must be a location';
    if (value['latitude'] is! num || value['longitude'] is! num) {
      return '$label must have numeric latitude and longitude';
    }
    return null;
  }
```

The `_validateScalarType` switch already calls this for `FieldEnum.location` (from Task 4).

- [ ] **Step 4: Run test to verify it passes**

- [ ] **Step 5: Commit**

```bash
git add lib/data/repositories/log_entry_repository.dart test/data/repositories/log_entry_validation_test.dart
git commit -m "fix: validate location fields require numeric latitude and longitude"
```

---

### Task 6: Fix dimension validator, custom validator, and reference consistency

**Files:**
- Modify: `lib/logic/templates/services/shared/field_validators.dart:160-198,245-291`
- Modify: `test/logic/templates/services/field_validators_test.dart`

- [ ] **Step 1: Write/update tests**

Update `test/logic/templates/services/field_validators_test.dart`:

Remove or update the `'validates map dimension value'` test (line 228) and `'validates allowed units'` test (line 237) — Map format is no longer supported.

Add:
```dart
    group('dimension (updated)', () {
      test('rejects Map format — only bare num accepted', () {
        final validator = FieldValidators.dimension(
          minValue: 0,
          label: 'Weight',
        );
        expect(validator({'value': 75, 'unit': 'kg'}), isNotNull);
      });
    });

    group('custom', () {
      test('throws UnimplementedError', () {
        final validators = [
          FieldValidator(
            validatorType: ValidatorType.custom,
            validatorData: {'name': 'some_custom'},
          ),
        ];
        final validator = FieldValidators.fromFieldValidators(validators, 'Field');
        expect(() => validator('anything'), throwsA(isA<UnimplementedError>()));
      });
    });

    group('reference', () {
      test('accepts non-empty string', () {
        final validator = FieldValidators.reference(label: 'Ref');
        expect(validator('some-uuid'), isNull);
      });

      test('rejects empty string', () {
        final validator = FieldValidators.reference(label: 'Ref');
        expect(validator(''), isNotNull);
      });

      test('rejects non-string', () {
        final validator = FieldValidators.reference(label: 'Ref');
        expect(validator(42), isNotNull);
      });
    });
```

- [ ] **Step 2: Run test to verify failures**

- [ ] **Step 3: Fix dimension validator — remove Map handling**

In `lib/logic/templates/services/shared/field_validators.dart`, replace `dimension` method (lines 160-198):

```dart
  /// Validates dimension values (numeric with optional bounds).
  static ValidatorFn dimension({
    num? minValue,
    num? maxValue,
    required String label,
  }) {
    return (value) {
      if (value == null) return null;
      if (value is! num) return '$label must be a number';

      if (minValue != null && value < minValue) {
        return '$label must be at least $minValue';
      }
      if (maxValue != null && value > maxValue) {
        return '$label must be at most $maxValue';
      }

      return null;
    };
  }
```

- [ ] **Step 4: Fix custom validator — throw UnimplementedError**

In `_fromModel` (around line 283), change:
```dart
ValidatorType.custom => (_) => null,
```
to:
```dart
ValidatorType.custom => (_) => throw UnimplementedError(
  'Custom validator "${data['name'] ?? 'unnamed'}" is not implemented.',
),
```

- [ ] **Step 5: Update _fromModel dimension case — remove allowedUnits**

In `_fromModel`, update the dimension case:
```dart
ValidatorType.dimension => wrap(dimension(
    minValue: data['minValue'] as num?,
    maxValue: data['maxValue'] as num?,
    label: label,
  )),
```

- [ ] **Step 6: Fix reference validator — align to String**

Replace `reference` method (lines 201-212):

```dart
  /// Validates reference field (must be a non-empty string ID).
  static ValidatorFn reference({required String label}) {
    return (value) {
      if (value == null) return null;
      if (value is! String) return '$label must be a reference ID';
      if (value.isEmpty) return '$label reference cannot be empty';
      return null;
    };
  }
```

- [ ] **Step 7: Run tests to verify they pass**

Run: `cd /Users/aicoder/Documents/openops/project/quanitya/public/quanitya_flutter && flutter test test/logic/templates/services/field_validators_test.dart --no-pub 2>&1 > /tmp/test_results.txt && cat /tmp/test_results.txt`
Expected: All tests pass.

- [ ] **Step 8: Commit**

```bash
git add lib/logic/templates/services/shared/field_validators.dart test/logic/templates/services/field_validators_test.dart
git commit -m "fix: remove Map from dimension validator, throw on custom, fix reference validator"
```

---

### Task 7: Fix DataRetrievalService — remove Map fallback

**Files:**
- Modify: `lib/data/repositories/data_retrieval_service.dart:360-369`

- [ ] **Step 1: Simplify _parseNumeric**

Since dimension values are always bare `num`, remove the Map fallback:

```dart
  num? _parseNumeric(dynamic value) {
    if (value == null) return null;
    if (value is num) return value;
    if (value is String) return num.tryParse(value);
    return null;
  }
```

- [ ] **Step 2: Run all tests**

Run: `cd /Users/aicoder/Documents/openops/project/quanitya/public/quanitya_flutter && flutter test --no-pub 2>&1 > /tmp/test_results.txt && tail -30 /tmp/test_results.txt`
Expected: All tests pass.

- [ ] **Step 3: Commit**

```bash
git add lib/data/repositories/data_retrieval_service.dart
git commit -m "fix: remove Map fallback from numeric parsing — dimensions are always scalar"
```

---

## Chunk 3: ValidatorData Safety and Final Verification

### Task 8: Add validatorData schema validation

**Files:**
- Create: `lib/logic/templates/services/shared/validator_data_schema.dart`
- Create: `test/logic/templates/services/validator_data_schema_test.dart`

Validates that `validatorData` has the right structure for its `validatorType`. Called at template save time, not on every log entry.

- [ ] **Step 1: Write failing tests**

Create `test/logic/templates/services/validator_data_schema_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:quanitya_flutter/logic/templates/models/shared/field_validator.dart';
import 'package:quanitya_flutter/logic/templates/services/shared/validator_data_schema.dart';

void main() {
  group('ValidatorDataSchema', () {
    group('numeric', () {
      test('accepts valid numeric config', () {
        final result = ValidatorDataSchema.validate(
          ValidatorType.numeric,
          {'min': 0, 'max': 100, 'allowDecimals': true},
        );
        expect(result, isNull);
      });

      test('accepts empty config', () {
        expect(ValidatorDataSchema.validate(ValidatorType.numeric, {}), isNull);
      });

      test('rejects min as string', () {
        final result = ValidatorDataSchema.validate(
          ValidatorType.numeric,
          {'min': '0'},
        );
        expect(result, isNotNull);
      });
    });

    group('text', () {
      test('accepts valid text config', () {
        final result = ValidatorDataSchema.validate(
          ValidatorType.text,
          {'minLength': 1, 'maxLength': 255},
        );
        expect(result, isNull);
      });

      test('rejects minLength as string', () {
        final result = ValidatorDataSchema.validate(
          ValidatorType.text,
          {'minLength': '1'},
        );
        expect(result, isNotNull);
      });
    });

    group('enumerated', () {
      test('accepts valid options list', () {
        final result = ValidatorDataSchema.validate(
          ValidatorType.enumerated,
          {'options': ['a', 'b', 'c']},
        );
        expect(result, isNull);
      });

      test('rejects options with non-string items', () {
        final result = ValidatorDataSchema.validate(
          ValidatorType.enumerated,
          {'options': [1, 2, 3]},
        );
        expect(result, isNotNull);
      });
    });

    group('dimension', () {
      test('accepts valid dimension config', () {
        final result = ValidatorDataSchema.validate(
          ValidatorType.dimension,
          {'minValue': 0, 'maxValue': 500},
        );
        expect(result, isNull);
      });

      test('rejects minValue as string', () {
        final result = ValidatorDataSchema.validate(
          ValidatorType.dimension,
          {'minValue': '0'},
        );
        expect(result, isNotNull);
      });
    });

    group('list', () {
      test('accepts valid list config', () {
        final result = ValidatorDataSchema.validate(
          ValidatorType.list,
          {'minItems': 1, 'maxItems': 10},
        );
        expect(result, isNull);
      });

      test('rejects minItems as string', () {
        final result = ValidatorDataSchema.validate(
          ValidatorType.list,
          {'minItems': '1'},
        );
        expect(result, isNotNull);
      });
    });

    group('optional', () {
      test('accepts empty config', () {
        expect(ValidatorDataSchema.validate(ValidatorType.optional, {}), isNull);
      });
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd /Users/aicoder/Documents/openops/project/quanitya/public/quanitya_flutter && flutter test test/logic/templates/services/validator_data_schema_test.dart --no-pub 2>&1 > /tmp/test_results.txt && cat /tmp/test_results.txt`

- [ ] **Step 3: Implement ValidatorDataSchema**

Create `lib/logic/templates/services/shared/validator_data_schema.dart`:

```dart
import '../../models/shared/field_validator.dart';

/// Validates that [FieldValidator.validatorData] has the correct structure
/// for its [ValidatorType].
///
/// Call at template save time to catch misconfigured validators early,
/// not on every log entry write.
class ValidatorDataSchema {
  ValidatorDataSchema._();

  /// Returns error message if [data] has wrong structure for [type].
  /// Returns null if valid.
  static String? validate(ValidatorType type, Map<String, dynamic> data) {
    return switch (type) {
      ValidatorType.optional => null,
      ValidatorType.numeric => _validateNumeric(data),
      ValidatorType.text => _validateText(data),
      ValidatorType.enumerated => _validateEnumerated(data),
      ValidatorType.dimension => _validateDimension(data),
      ValidatorType.reference => null,
      ValidatorType.custom => null,
      ValidatorType.list => _validateList(data),
    };
  }

  static String? _validateNumeric(Map<String, dynamic> data) {
    if (data.containsKey('min') && data['min'] is! num) {
      return 'numeric.min must be a number';
    }
    if (data.containsKey('max') && data['max'] is! num) {
      return 'numeric.max must be a number';
    }
    if (data.containsKey('allowDecimals') && data['allowDecimals'] is! bool) {
      return 'numeric.allowDecimals must be a boolean';
    }
    return null;
  }

  static String? _validateText(Map<String, dynamic> data) {
    if (data.containsKey('minLength') && data['minLength'] is! int) {
      return 'text.minLength must be an integer';
    }
    if (data.containsKey('maxLength') && data['maxLength'] is! int) {
      return 'text.maxLength must be an integer';
    }
    if (data.containsKey('pattern') && data['pattern'] is! String) {
      return 'text.pattern must be a string';
    }
    return null;
  }

  static String? _validateEnumerated(Map<String, dynamic> data) {
    if (data.containsKey('options')) {
      final options = data['options'];
      if (options is! List) return 'enumerated.options must be a list';
      if (options.any((o) => o is! String)) {
        return 'enumerated.options must contain only strings';
      }
    }
    return null;
  }

  static String? _validateDimension(Map<String, dynamic> data) {
    if (data.containsKey('minValue') && data['minValue'] is! num) {
      return 'dimension.minValue must be a number';
    }
    if (data.containsKey('maxValue') && data['maxValue'] is! num) {
      return 'dimension.maxValue must be a number';
    }
    return null;
  }

  static String? _validateList(Map<String, dynamic> data) {
    if (data.containsKey('minItems') && data['minItems'] is! int) {
      return 'list.minItems must be an integer';
    }
    if (data.containsKey('maxItems') && data['maxItems'] is! int) {
      return 'list.maxItems must be an integer';
    }
    return null;
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd /Users/aicoder/Documents/openops/project/quanitya/public/quanitya_flutter && flutter test test/logic/templates/services/validator_data_schema_test.dart --no-pub 2>&1 > /tmp/test_results.txt && cat /tmp/test_results.txt`
Expected: All tests PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/logic/templates/services/shared/validator_data_schema.dart test/logic/templates/services/validator_data_schema_test.dart
git commit -m "feat: add ValidatorDataSchema for validating validator config structure"
```

---

### Task 9: Run full analysis and test suite

- [ ] **Step 1: Run dart analyze**

Run: `cd /Users/aicoder/Documents/openops/project/quanitya/public/quanitya_flutter && dart analyze 2>&1 > /tmp/analyze_results.txt && cat /tmp/analyze_results.txt`
Expected: No errors.

- [ ] **Step 2: Run full test suite**

Run: `cd /Users/aicoder/Documents/openops/project/quanitya/public/quanitya_flutter && flutter test --no-pub 2>&1 > /tmp/test_results.txt && tail -30 /tmp/test_results.txt`
Expected: All tests pass.

- [ ] **Step 3: Fix any remaining issues**

Common things to watch for:
- Stale references to `DimensionEnum` in generated code — run `build_runner` again
- Stale references to `UnitEnum` in test fixtures
- `field.dimension` changed to `field.unit` in code that reads TemplateField
- `UnitsByDimension.massUnits` changed to `MeasurementUnit.unitsFor(MeasurementDimension.mass)`

- [ ] **Step 4: Final commit if needed**

```bash
git add -A
git commit -m "fix: resolve remaining references from measurement rename"
```
