# Quanitya Flutter — Development Guide

## Core Philosophy
**Manuscript over Application. Typography over Topography.**
Privacy-first quantified-self tracker with E2E encryption. Lab notebook aesthetic, not SaaS dashboard.

## Architecture

```
UI (Widgets + Cubits) → Repository → Dual DAO → Drift DB (Local + Encrypted) → PowerSync → Backend
```

**Database is the single source of truth.** Write to DB, let streams update the UI. Never pass updated models after a write — that creates dual truth.

## Before Writing Code

Check what already exists. The codebase has ~28 cubits, ~14 DAOs, and a full design system. Search `lib/features/` for existing cubits and `lib/data/dao/` for DAOs before creating new ones. Search `lib/design_system/widgets/` before building any UI component.

## Development Standards

### Required Stack
- **Freezed** (`@freezed`) for all data classes and states
- **Drift** for database
- **Cubits** (not Blocs) for state management
- **Injectable + GetIt** (`@injectable`, `@lazySingleton`, `getIt<T>()`)
- **JSON Serializable** for API models

### Build Command
```bash
dart run build_runner build --delete-conflicting-outputs
```

## Cubit Pattern

States implement `IUiFlowState`. Cubits extend `QuanityaCubit`. Use `tryOperation` for all async work.

```dart
@freezed
class MyState with _$MyState implements IUiFlowState {
  const factory MyState({
    @Default(UiFlowStatus.idle) UiFlowStatus status,
    Object? error,
    MyOperation? lastOperation,
  }) = _MyState;
}

@injectable
class MyCubit extends QuanityaCubit<MyState> {
  MyCubit(this._repo) : super(const MyState());

  Future<void> save() => tryOperation(() async {
    await _repo.save(state.model);
    return state.copyWith(
      status: UiFlowStatus.success, // ⚠️ MUST set explicitly — library does NOT auto-set
      lastOperation: MyOperation.save,
    );
  }, emitLoading: true);
}
```

**Message flow**: State → `IStateMessageMapper` → dot-notation localization key → `UiFlowListener` → PostItToast.

Keys use dot-notation (`template.saved`) mapped to camelCase ARB keys (`templateSaved`). Add new keys to `lib/l10n/app_en.arb`, then rebuild.

## Data Flow Rules

### Allowed
- **Write-Only** (preferred): save to DB, let streams update UI
- **Read-Only Sharing**: multiple widgets reading same cubit state
- **Fresh Database Reads**: re-query DB when needed

### Never Do
- **Write + Pass**: saving AND passing the updated model to another component
- **Memory-to-Memory**: cubits passing state to each other as data source

## E2EE Dual DAO Pattern

Three core models: **TrackerTemplate** (WHAT), **Schedule** (WHEN), **LogEntry** (ACTUAL).

Every write goes to both a local plaintext table AND an encrypted shadow table atomically via `DualDao`. Only encrypted tables sync via PowerSync. Backend receives zero PII.

- **Dual DAOs** (write-only): `upsert()`, `bulkUpsert()`, `delete()`, `runInTransaction()`
- **Query DAOs** (read-only): `find*()`, `watch*()`, `count*()` with context-enriched joins

## Exception Handling

```
Repository throws TypedError → Service wraps via tryMethod → Cubit catches via tryOperation → UiFlowListener → PostItToast
```

- **Never** use `!` operator — use explicit null checks with typed exceptions
- Use `?.` and `??` when null is a valid state
- Wrap all public service/repo methods with `tryMethod`
- Import: `package:quanitya/infrastructure/core/try_operation.dart`

### Exception Classes

Simple domain exceptions:
```dart
class MyFeatureException implements Exception {
  final String message;
  final Object? cause;
  const MyFeatureException(this.message, [this.cause]);
}
```

### Global Exception Mapper

`lib/infrastructure/feedback/exception_mapper.dart` — `QuanityaExceptionKeyMapper` maps all exceptions to `MessageKey` via pattern matching. Add new exception types here:

```dart
MyFeatureException() => const MessageKey.error(L10nKeys.errorMyFeatureFailed),
```

### Feature Message Mapper

Each feature has an `IStateMessageMapper` that maps **success operations** to message keys. Returns `null` for errors (delegates to global mapper):

```dart
@injectable
class MyFeatureMessageMapper implements IStateMessageMapper<MyFeatureState> {
  @override
  MessageKey? map(MyFeatureState state) {
    if (state.status.isSuccess && state.lastOperation != null) {
      return switch (state.lastOperation!) {
        MyFeatureOperation.create => MessageKey.success(L10nKeys.myFeatureCreated),
        MyFeatureOperation.delete => MessageKey.success(L10nKeys.myFeatureDeleted),
      };
    }
    return null;
  }
}
```

### UI Wiring

```dart
UiFlowListener<MyCubit, MyState>(
  mapper: GetIt.instance<MyMessageMapper>(),
  child: /* page content */,
)
```

## Localization (L10n)

### Adding New Message Keys

1. Add to `lib/l10n/app_en.arb` (camelCase):
```json
{
  "myFeatureCreated": "Feature created successfully",
  "errorMyFeatureFailed": "Feature operation failed"
}
```

2. Rebuild: `dart run build_runner build --delete-conflicting-outputs`

3. Generated `l10n_key_resolver.g.dart` auto-maps dot-notation → camelCase:
   - Code uses: `MessageKey.success('my.feature.created')`
   - Resolver maps to: `_l10n.myFeatureCreated`

### Direct Access

```dart
// Via context extension
context.l10n.myFeatureCreated

// Via service (when no BuildContext)
getIt<AppLocalizationService>().translate('my.feature.created')
```

### Parameterized Messages

```json
{
  "templateFieldsCount": "{count} Fields",
  "@templateFieldsCount": {
    "placeholders": { "count": { "type": "int" } }
  }
}
```

## UI Design Standards

### Use Semantic Tokens Only — No Hardcoded Values

| Instead of | Use |
|------------|-----|
| `SizedBox(height: 10)` | `VSpace.x1` |
| `SizedBox(width: 8)` | `HSpace.x1` |
| `Theme.of(context).colorScheme.xxx` | `QuanityaPalette.primary.xxx` |
| `const EdgeInsets.all(8)` | `AppPadding.allSingle` |
| `BorderRadius.circular(12)` | `AppSizes.radiusSmall` |
| Raw `GestureDetector` on icons | `QuanityaIconButton` |
| Material `IconButton` | `QuanityaIconButton` (enforces 48dp target) |
| `Color(0xFF...)` / `Colors.blue` | `QuanityaPalette` tokens |

### Spacing Tokens
```dart
VSpace.x025  // Optical correction (2px)
VSpace.x05   // Text glue (header + subtitle)
VSpace.x1    // Component breath (icon + label)
VSpace.x2    // Standard margin
VSpace.x3    // Narrative flow (list items)
HSpace.x05, HSpace.x1, HSpace.x2  // Horizontal equivalents
```

### Color Semantics
- **Teal** (`interactableColor`) = "tap me" affordance
- **Black** = committed / selected / inked
- **Red** (`destructiveColor`) = danger / delete
- Touch targets: minimum **48dp** (`AppSizes.buttonHeight`)

### Typography
```dart
context.text.header   // Atkinson Hyperlegible Mono — anchors
context.text.body     // Noto Sans Mono — narrative
context.text.metadata // Noto Sans Mono Light — whispers
```

### Key Layout Widgets
- `QuanityaColumn` — auto-spaced column (default `VSpace.x1` between children)
- `QuanityaRow` — three-slot: start / middle (expanded) / end
- `QuanityaPageWrapper` — ZenPaperBackground + SafeArea
- `NotebookFold` — progressive disclosure (taped flap that unfolds)

### Key Interactive Widgets
- `QuanityaTextButton` — animated pen-circle (teal idle → black pressed → red destructive)
- `QuanityaIconButton` — 48dp target, use `.small()` / `.medium()` / `.large()`
- `PenCircledChip` — hand-drawn circle selection animation

### Key Feedback Widgets
- `UiFlowListener` — auto loading overlay + error/success toasts from cubit state
- `PostItToast` — manuscript-style toast (info/success/error/warning)
- `QuanityaEmptyOr` — conditional: show child OR empty state
- `LooseInsertSheet` — bottom sheet with drag handle
- `QuanityaConfirmationDialog` — bottom-sheet confirmation with destructive variant

### Generatable Form Widgets
`lib/design_system/widgets/quanitya/generatable/` — `QuanityaCheckbox`, `QuanityaChipGroup`, `QuanityaDatePicker`, `QuanityaDropdown`, `QuanityaRadioGroup`, `QuanityaSlider`, `QuanityaStepper`, `QuanityaTimePicker`, `QuanityaToggle`

### Charts
`lib/design_system/widgets/charts/` — `TimeSeriesChart`, `CategoricalScatterChart`, `MultiSeriesChart`, `BooleanHeatmapChart`, `ContributionHeatmap`

## Custom Libraries

1. **cubit_ui_flow** — automatic loading/error/success handling via state
2. **dart_jwk_duo** — type-safe crypto key pairs (SigningKeyPair, EncryptionKeyPair)
3. **flutter_color_palette** — enumerated colors with auto dark mode
4. **dart_l10n_key_resolver** — dot-notation keys → camelCase ARB getters
5. **flutter_error_privserver** — privacy-first error reporting, zero PII

## Responsive Scaling

All sizes scale via `UiScaler` (`.px()` / `.sp()`). Design baseline: iPhone 16 (393dp). Scale factor: 0.85x–1.15x. Called once from `MaterialApp.builder`. All `AppSizes` tokens are pre-scaled.
