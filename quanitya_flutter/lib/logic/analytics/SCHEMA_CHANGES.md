# Analysis Pipeline Schema Changes

## Summary
Refactored the `AnalysisPipelines` table to store only the essential user-defined snippet, removing redundant template storage and improving type safety with enums.

## Changes Made

### 1. Removed Column
- **`analysisShell`** - Removed entirely. The Jinja template (`mvs_shell.js.j2`) is now the single source of truth and loaded at runtime.

### 2. Renamed Columns
- **`scriptJs`** → **`snippet`** - Clearer name for the user's code fragment
- **`displayConfigJson`** → **`metadataJson`** - More generic name (removed color reference)

### 3. New Enum Columns
- **`outputMode`** - Changed from `text()` to `textEnum<AnalysisOutputMode>()`
  - Values: `scalar`, `vector`, `matrix`
  - Provides compile-time type safety
  
- **`snippetLanguage`** - New column with `textEnum<AnalysisSnippetLanguage>()`
  - Values: `js` (currently only JavaScript)
  - Future-proof for other languages (Python, Lua, etc.)

## New Enums

Created `lib/logic/analytics/models/analysis_enums.dart`:

```dart
enum AnalysisOutputMode {
  scalar,  // Single numeric value
  vector,  // Array of values
  matrix,  // 2D array
}

enum AnalysisSnippetLanguage {
  js,  // JavaScript (executed via WASM)
}
```

## Benefits

1. **Reduced Storage** - No duplicate template storage per record
2. **Single Source of Truth** - Template lives in one place (`mvs_shell.js.j2`)
3. **Type Safety** - Enums prevent invalid values at compile time
4. **Easier Updates** - Template improvements automatically apply to all analyses
5. **Cleaner Semantics** - `snippet` + `snippetLanguage` is more intuitive than `scriptJs` + `analysisShell`

## Migration Notes

When updating existing code:
- Replace `analysisShell` references with the static template path
- Rename `scriptJs` to `snippet`
- Rename `displayConfigJson` to `metadataJson`
- Use enum values instead of strings for `outputMode`
- Set `snippetLanguage` to `AnalysisSnippetLanguage.js` for all JavaScript snippets

## Next Steps

1. Update DAOs and repositories to use new column names
2. Update services to inject snippet into static template
3. Run database migration (Drift will auto-generate)
4. Update tests to use new schema
