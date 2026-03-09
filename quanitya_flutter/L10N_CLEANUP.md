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

## 10. Hardcoded Strings ✅
Extracted ~55 hardcoded strings across 18 files into 70+ ARB keys:
- `feedback_page.dart` ✅
- `app_router.dart` ✅
- `settings_page.dart` ✅ — Purchase, Error Reports, Analytics Inbox, Send Feedback
- `notification_inbox_page.dart` ✅ — title, mark all, empty state
- `temporal_home_page.dart` ✅ — sort/filter headers, tooltips, direction labels
- `purchase_page.dart` ✅ — title, products, success/failure
- `analytics_inbox_page.dart` ✅ — title, privacy notice, auto-send, empty state, actions, confirm dialog
- `analysis_builder_page.dart` ✅ — title, tooltips, empty state
- `template_editor_form.dart` ✅ — AI generator, API key dialog
- `template_basic_info_editor.dart` ✅ — Accent, Tone, Container Style
- `template_import_page.dart` ✅ — URL hint
- `error_entry_card.dart` ✅ — clipboard snackbar
- `show_pairing_qr_page.dart` ✅ — clipboard snackbar
- `device_list_section.dart` ✅ — cloud mode message
- `logged_entry_page.dart` ✅ — View insights tooltip
- `visualization_page.dart` ✅ — Analyze Data tooltip
- `dynamic_field_builder.dart` ✅ — timer tooltips (Stop/Start/Reset)
- 3 chart widgets ✅ — "No data" empty state
- `smart_parameter_dialog.dart` — deleted (dead code)
- `operation_registry.dart` — deleted (dead code)

**Remaining:** A few strings in `dynamic_field_builder.dart` static methods lack `BuildContext` access: `'Remove'`, `'Minimum items reached'`, `'No UI element defined'`, `'No options available'`, `'Add {label}'`. These would require a refactor to pass context through the static API.

## Infrastructure Improvements
- Upgraded `dart_l10n_key_resolver` — `L10nKeys` now generates typed `(String, Map)` methods for parameterized entries
- Upgraded `cubit_ui_flow` — added `MessageKey.xFrom()` factories accepting typed records
- Bumped `flutter_error_privserver` for `cubit_ui_flow` compatibility

## Dead Code Cleanup
Removed ~6,000 lines of legacy visual pipeline builder code that was replaced by JS/WASM analysis:
- 10 dead widgets, 5 dead services, 3 dead cubits, 5 dead models, 3 dead tests, 3 stale docs
- Renamed `MvsPipelineBuilderCubit` → `AnalysisBuilderCubit`
