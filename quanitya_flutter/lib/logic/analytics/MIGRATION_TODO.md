# Schema Migration TODO

## Status
Schema updated in database, but code still references old fields. Need to update all usages.

## Completed
- ✅ Updated `AnalysisPipelines` table schema
- ✅ Created `AnalysisOutputMode` and `AnalysisSnippetLanguage` enums
- ✅ Updated `AnalysisPipelineModel` freezed class
- ✅ Updated `e2ee_puller.dart` JSON serialization
- ✅ Ran build_runner to regenerate code

## Files That Need Updates

### 1. DAOs (Data Access Objects)
- `lib/data/dao/analysis_pipeline_dual_dao.dart`
  - Update `entityToInsertable()`: `analysisShell` → `snippetLanguage`, `scriptJs` → `snippet`, `displayConfigJson` → `metadataJson`
  - Update `modelToEntity()`: same field renames
  - Update `entityToModel()`: same field renames + remove `AnalysisShell` enum usage

- `lib/data/dao/analysis_pipeline_query_dao.dart`
  - Update `toModel()`: same field renames + remove `AnalysisShell` enum usage

### 2. Services
- `lib/logic/analytics/services/wasm_analysis_service.dart`
  - Update `execute()`: `pipeline.scriptJs` → `pipeline.snippet`
  - Update `_renderTemplate()`: `scriptJs` parameter → `snippet`

- `lib/logic/analytics/services/analysis_orchestrator.dart`
  - Update `streamLivePreview()`: remove `shell` parameter, add `snippetLanguage`
  - Update parameter: `scriptJs` → `snippet`

- `lib/logic/analytics/services/streaming_analytics_service.dart`
  - Update `streamResultsForLivePreview()`: remove `shell` parameter, add `snippetLanguage`
  - Update parameter: `scriptJs` → `snippet`
  - Update temp pipeline creation

- `lib/logic/analytics/services/pipeline_factory.dart`
  - Update `create()`: remove `shell` parameter, add `snippetLanguage`
  - Update parameters: `scriptJs` → `snippet`, `displayConfigJson` → `metadataJson`
  - Update `createEmpty()`: remove `shell`, add `snippetLanguage: AnalysisSnippetLanguage.js`
  - Update `createLegacyBridge()`: same changes

### 3. AI Services
- `lib/logic/analytics/services/ai/ai_analysis_orchestrator.dart`
  - Update `PipelineSuggestion` class: remove `shell` field, add `snippetLanguage`
  - Update parameter: `scriptJs` → `snippet`
  - Update `_parseSuggestion()`: remove `shell: AnalysisShell.scalar`, add `snippetLanguage: AnalysisSnippetLanguage.js`

### 4. Cubits (State Management)
- `lib/logic/analytics/cubits/mvs_pipeline_builder_cubit.dart`
  - Update state fields: `scriptJs` → `snippet`, remove `shell`, add `snippetLanguage`
  - Update `updateScript()` method name → `updateSnippet()`
  - Update `applySuggestion()`: remove `shell` parameter, add `snippetLanguage`
  - Update `startLivePreview()`: pass `snippetLanguage` instead of `shell`
  - Update `savePipeline()`: use new field names

- `lib/logic/analytics/cubits/mvs_pipeline_builder_state.dart`
  - Update freezed class fields: `scriptJs` → `snippet`, remove `shell`, add `snippetLanguage`
  - Run build_runner after changes

### 5. UI Pages
- `lib/features/analytics/pages/analysis_builder_page.dart`
  - Update display: `state.scriptJs` → `state.snippet`

## Field Mapping Reference

| Old Field | New Field | Type Change |
|-----------|-----------|-------------|
| `analysisShell` | (removed) | Was storing template name, now use static template |
| `scriptJs` | `snippet` | Renamed for clarity |
| `displayConfigJson` | `metadataJson` | Renamed (removed color reference) |
| `shell` (model) | (removed) | Replaced by `snippetLanguage` |
| - | `snippetLanguage` | New field (enum: `js`) |
| `outputMode` | `outputMode` | Changed from String to enum |

## Enum Changes

### Removed
- `AnalysisShell` enum (scalar/vector/matrix) - was redundant with `outputMode`

### Added
- `AnalysisSnippetLanguage` enum (currently just `js`)
- `AnalysisOutputMode` enum (scalar/vector/matrix) - now properly typed

## Migration Strategy

1. Update all DAOs first (data layer)
2. Update services (business logic)
3. Update cubits and state (state management)
4. Update UI (presentation)
5. Run build_runner after each layer
6. Test incrementally

## Notes

- The static Jinja template is at `assets/scripts/mvs_shell.js.j2`
- All existing analyses will need data migration (old JSON → new JSON)
- PowerSync/Serverpod don't need changes (they only store encrypted blobs)
