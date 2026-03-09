# L10n Cleanup Plan

## 1. BUG: Duplicate Keys ✅
Deleted duplicate keys (pipelineStepAdded, pipelineStepRemoved, pipelineStepUpdated, pipelineSaved) that appeared twice in `app_en.arb`.

## 2. Tone: Drop "successfully" and "!" ✅
Standardized ~25 success messages to short past-tense, no "!", no "successfully".

## 3. Redundant Keys ✅
Audited all pairs:
- `templateGenerationSuccess` — deleted (unused, `templateGenerated` already exists)
- `saveAction` — deleted, replaced with `actionSave` (1 widget updated)
- `cancel` — deleted, replaced with `actionCancel` (3 widgets updated)
- `delete` — deleted (unused, `actionDelete` already used)
- `clear` — deleted (unused, `actionClear` already used)
- `templateSaved` vs `pipelineSaved` — kept both (different domains)
- `logEntrySaved` vs `entrySubmitted` — kept both (different workflows)

## 4. Debug-sounding Toasts ✅
Removed loading toasts from 8 message mappers. Loading content is expected behavior — users don't need a toast for it.

Removed: `templateFormLoaded`, `templateFormValidated`, `entryLoaded`, `entryHistoryLoaded`, `timelineLoaded`, `visualizationLoaded`, `templateSharingPreviewLoaded`, `templateLoaded` (2 mappers).

## 5. Developer Jargon → User Language ✅
Rephrased ~15 jargon strings (e.g., "Widget Type" → "Input Style", "Pipeline error" → "Something went wrong").

## 6. Sentence Fragments ✅
Merged `aboutSubtitlePrefix` + `aboutSubtitleQuaMeaning` + `aboutSubtitleAnityaMeaning` into single `aboutSubtitle` key with `{quaWord}` and `{anityaWord}` placeholders.

## 7. Terse Warnings ✅
Changed "Lost device = lost key" → "If you lose this device, you'll lose this backup" for both `backupBiometricsWarning` and `backupDeviceAuthWarning`.

## 8. Inconsistent Capitalization ✅
Standardized to Title Case:
- `"BASIC INFO"` → `"Basic Info"`
- `"TEMPLATE NAME"` → `"Template Name"`
- `"DESCRIPTION (OPTIONAL)"` → `"Description (Optional)"`
- `"{count} FIELDS"` → `"{count} Fields"`

## 9. Minor Nits ✅
- `aboutPronounciation` → `aboutPronunciation` (typo in key name fixed)
- `templateUnhidden`: already "Template shown" — no change needed
- `recoveryKeysExistWarning` vs `errorKeysAlreadyExist` — kept both (different contexts: UI warning card vs exception toast)
- `errorStateInvalid` — kept as-is (maps from StateError in exception mapper)

## 10. Hardcoded Strings ✅ (partial)
- `feedback_page.dart` ✅
- `smart_parameter_dialog.dart` ✅
- `app_router.dart` ✅
- `operation_registry.dart` — deferred (requires adding ~105 ARB entries for 35 operations × 3 strings)

## Infrastructure Improvements
- Upgraded `dart_l10n_key_resolver` — `L10nKeys` now generates typed `(String, Map)` methods for parameterized entries
- Upgraded `cubit_ui_flow` — added `MessageKey.xFrom()` factories accepting typed records
- Bumped `flutter_error_privserver` for `cubit_ui_flow` compatibility
