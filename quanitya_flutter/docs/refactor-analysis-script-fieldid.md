# Refactor: Analysis Script fieldId → field UUID + templateId

## Problem

`fieldId` on `AnalysisScript` is a composite string `"templateId:fieldLabel"`. This:
- Breaks on field rename
- Collides if two fields share a label
- Mismatches gallery template JSON (which uses field UUIDs)
- Is a denormalized composite key stored as a string

## Solution

- `fieldId` becomes the field's UUID (stable, unique)
- Add `templateId` column (the template's UUID)
- Queries use `templateId` for filtering, `fieldId` for specific field lookup

## No migration needed

Pre-launch — no real users. Flat migration: delete and regenerate.

---

## Changes (in order)

### 1. Schema — add templateId column
- [ ] `lib/data/tables/tables.dart:280` — add `TextColumn get templateId => text().named('template_id')();` to `AnalysisScripts`

### 2. Model — add templateId field
- [ ] `lib/logic/analysis/models/analysis_script.dart:15` — add `required String templateId` after `fieldId`
- [ ] Run `dart run build_runner build --delete-conflicting-outputs`

### 3. DAO write — entity↔model conversion
- [ ] `lib/data/dao/analysis_script_dual_dao.dart` — update `modelToEntity()` and `entityToModel()` to map `templateId`

### 4. DAO query — add templateId filtering
- [ ] `lib/data/dao/analysis_script_query_dao.dart:52` — `findByFieldId` → add `findByTemplateId(String templateId)` method
- [ ] `lib/data/dao/analysis_script_query_dao.dart:85` — `watchByFieldId` → add `watchByTemplateId(String templateId)` method
- [ ] Keep existing methods but also add template-aware variants

### 5. Repository interface
- [ ] `lib/data/interfaces/analysis_script_interface.dart:24` — add `getScriptsForTemplate(String templateId)`
- [ ] `lib/data/interfaces/analysis_script_interface.dart:39` — update `getScriptsForField` to take `(String templateId, String fieldId)`
- [ ] `lib/data/interfaces/analysis_script_interface.dart:86` — `fetchFieldTimeSeries` takes `(String templateId, String fieldId, ...)` instead of composite string

### 6. Repository implementation
- [ ] `lib/data/repositories/analysis_script_repository.dart:37` — `watchScriptsForField` → update signature
- [ ] `lib/data/repositories/analysis_script_repository.dart:61` — `getScriptsForField` → update signature
- [ ] `lib/data/repositories/analysis_script_repository.dart:132-197` — `fetchFieldTimeSeries` → remove `split(':')` parsing, use separate params

### 7. Visualization cubit — template filtering
- [ ] `lib/features/visualization/cubits/visualization_cubit.dart:43-46` — replace `startsWith('$templateId:')` with `s.templateId == templateId`

### 8. Analysis builder cubit — remove composite construction
- [ ] `lib/logic/analysis/cubits/analysis_builder_cubit.dart:107-109` — remove `'$templateId:$fieldId'` construction
- [ ] `lib/logic/analysis/cubits/analysis_builder_cubit.dart:114` — replace `startsWith('$templateId:')` with `templateId == templateId`
- [ ] `lib/logic/analysis/cubits/analysis_builder_cubit.dart:200-203` — remove `effectiveFieldId` composite construction
- [ ] `lib/logic/analysis/cubits/analysis_builder_cubit.dart:351-353` — same in `saveScript()`
- [ ] `lib/logic/analysis/cubits/analysis_builder_cubit.dart:398` — update `_fieldShapeResolver.resolve()` call

### 9. Field shape resolver — remove split parsing
- [ ] `lib/logic/analysis/services/field_shape_resolver.dart:24-36` — change signature to `resolve(String templateId, String fieldId)`, remove `split(':')`

### 10. Streaming analytics service — remove extraction helper
- [ ] `lib/logic/analysis/services/streaming_analytics_service.dart:50-51` — use `script.templateId` directly
- [ ] `lib/logic/analysis/services/streaming_analytics_service.dart:79` — remove fallback extraction
- [ ] `lib/logic/analysis/services/streaming_analytics_service.dart:137-146` — delete `_extractTemplateId()` helper

### 11. WASM analysis service
- [ ] `lib/logic/analysis/services/wasm_analysis_service.dart:45-49` — pass `script.templateId` and `script.fieldId` separately to `fetchFieldTimeSeries`

### 12. Template import service — simplify mapping
- [ ] `lib/logic/templates/services/sharing/template_import_service.dart:241-253` — field ID map becomes UUID→UUID (simple positional mapping)
- [ ] Set `templateId` on imported scripts

### 13. Shareable template staging — simplify remapping
- [ ] `lib/logic/templates/services/sharing/shareable_template_staging.dart` — `remappedScripts` maps UUID→UUID and sets `templateId`

### 14. Template export service
- [ ] `lib/logic/templates/services/sharing/template_export_service.dart:85-112` — update `getAvailableScripts` to use templateId

### 15. Shareable template sanitization
- [ ] `lib/logic/templates/models/shared/shareable_template.dart:122-128` — sanitize fieldId stays as UUID remapping (already correct for export)

### 16. Template editor cubit — update save
- [ ] `lib/features/templates/cubits/editor/template_editor_cubit.dart` — update staged script filter to use field UUID matching

### 17. Dev seeder
- [ ] `lib/dev/services/dev_seeder_service.dart:688,710,739,756,792-808` — use field UUID + templateId instead of composite format

### 18. Tests
- [ ] `test/logic/analysis/cubits/analysis_builder_cubit_test.dart:87-147` — update test data and mock expectations
- [ ] `test/logic/templates/services/sharing/template_export_import_roundtrip_test.dart:61-88,220-247` — update assertions

### 19. Regenerate
- [ ] `serverpod generate` (if encrypted table schema changed)
- [ ] `dart run build_runner build --delete-conflicting-outputs`
- [ ] `flutter analyze`
- [ ] Run tests

### 20. Commit and push
