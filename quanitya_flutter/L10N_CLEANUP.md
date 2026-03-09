# L10n Cleanup Plan

## 1. BUG: Duplicate Keys (fix immediately)
Lines 639-642 in `app_en.arb` duplicate keys from lines 57-72. JSON last-value-wins means the `@` metadata descriptions are orphaned.

| Key | Line 57-72 value | Line 639-642 value (wins) |
|-----|-----------------|--------------------------|
| `pipelineSaved` | "Pipeline saved successfully!" | "Pipeline saved successfully" |
| `pipelineStepUpdated` | "Step parameters updated" | "Step updated successfully" |

**Action:** Delete lines 639-642 and keep the first set (which has `@` metadata).

---

## 2. Tone: Drop "successfully" and "!" everywhere
Two styles fighting:
- Older: `"Template generated successfully!"`, `"Analysis pipeline saved successfully!"`
- Newer toast: `"Template saved"`, `"Entry logged"`, `"Field added"`

Newer style is better -- concise, consistent. A 3-second toast doesn't need enthusiasm.

**Action:** Standardize all success feedback to short past-tense, no "!", no "successfully":
- `templateGenerationSuccess` -> "Template generated"
- `templateRegenerationSuccess` -> "Template regenerated"
- `templatePreviewSuccess` -> "Preview created"
- `templateValidationSuccess` -> "Template validated"
- `llmTemplateGenerated` -> "Template generated with AI"
- `llmTemplateRegenerated` -> "Template updated"
- `analyticsPipelineExecuted` -> "Analysis complete"
- `analyticsPipelineSaved` -> "Analysis saved"
- `analyticsPipelineUpdated` -> "Analysis updated"
- `analyticsPipelineDeleted` -> "Analysis deleted"
- `devSeeded` -> "Fake data seeded"
- `devCleared` -> "All data cleared"
- `devConnected` -> "Connected to cloud"
- `devAccountCreated` -> "Account created"
- `devAccountRegistered` -> "Account registered"
- `pairingCompleted` -> "Device paired"
- `feedbackSubmitted` -> KEEP "Thank you for your feedback!" (gratitude is fine)

---

## 3. Redundant Keys
| Keep | Remove/Merge | Reason |
|------|-------------|--------|
| `templateGenerated` | `templateGenerationSuccess` | Same event |
| `templateSaved` | possibly `pipelineSaved` | If pipeline = analysis, use "Analysis saved" |
| `logEntrySaved` ("Entry logged") | `entrySubmitted` ("Entry submitted") | Audit if same action |
| `actionSave` | `saveAction` | Duplicate button labels |
| `actionCancel` | `cancel` | Duplicate button labels |
| `actionDelete` | `delete` | Duplicate button labels |
| `actionClear` | `clear` | Duplicate button labels |

**Action:** Audit usage and consolidate.

---

## 4. Debug-sounding Toasts
Shown as 3-second info toasts but read like log statements:

| Key | Current | Question |
|-----|---------|----------|
| `templateFormLoaded` | "Form loaded" | Does the user need this? |
| `templateFormValidated` | "Form validated" | Same |
| `entryLoaded` | "Entry loaded" | Same |
| `entryHistoryLoaded` | "Entry history loaded" | Same |
| `timelineLoaded` | "Timeline loaded" | Same |
| `visualizationLoaded` | "Visualization loaded" | Same |
| `templateSharingPreviewLoaded` | "Sharing preview loaded" | Same |
| `templateLoaded` | "Template loaded" | Same |

**Action:** Consider whether these should be toasts at all. Loading content is expected.

---

## 5. Developer Jargon -> User Language

| Current | Suggested | Why |
|---------|-----------|-----|
| "Operating mode updated" | "Settings updated" or "Mode switched" | Users don't know "operating mode" |
| "Operating mode error" | "Connection mode error" | Slightly better |
| "Operating mode was changed externally" | "Your sync settings were updated from another device" | Explain what happened |
| "Pipeline error. Please try again." | "Something went wrong. Please try again." | Users don't see pipelines |
| "Failed to generate field combinations" | "Could not create this template. Try simpler fields." | No jargon |
| "Failed to convert schema" | "Template conversion failed. Please try again." | No jargon |
| "Failed to generate widgets" | "Could not build the form. Try different field types." | No jargon |
| "Generating Cryptographic Keys" | "Setting up encryption" | Simpler |
| "Failed to generate proof-of-work" | "Verification failed. Please try again." | No jargon |
| "Widget Type" | "Input Style" or "Display Style" | Users pick how a field looks |
| "Trigger URL (GET request only)..." | "When an entry is logged, this URL will be called. Note: URLs are stored unencrypted." | Clear |
| "Keys already exist on this device." | "This device already has an account." | User-facing |
| "Paste your recovery key (JWK) below" | "Paste your recovery key below" | Drop "(JWK)" |
| "Paste JWK here..." | "Paste recovery key here..." | Drop "JWK" |

---

## 6. Sentence Fragments (translation hazard)
`aboutSubtitlePrefix` + `aboutSubtitleQuaMeaning` + `aboutSubtitleAnityaMeaning` are concatenated fragments. Breaks in languages with different word order.

**Action:** Merge into one string with placeholders or rich text.

---

## 7. Terse Warnings
`backupBiometricsWarning` / `backupDeviceAuthWarning`: "Lost device = lost key"

**Action:** Consider "If you lose this device, you'll lose this backup"

---

## 8. Inconsistent Capitalization
- ALL CAPS: `"BASIC INFO"`, `"TEMPLATE NAME"`, `"DESCRIPTION (OPTIONAL)"`, `"{count} FIELDS"`
- Title Case: `"Color Theme"`, `"Typography"`

**Action:** Pick one style for section headers.

---

## 9. Minor Nits
- `templateUnhidden`: "Template visible" -> "Template shown" (matches "Template hidden")
- `errorStateInvalid`: "Invalid operation state." -- pure developer error, user can't act
- `recoveryKeysExistWarning` vs `errorKeysAlreadyExist` -- redundant?
- `aboutPronounciation` -- typo in key name (should be `aboutPronunciation`)

---

## 10. Hardcoded Strings to Extract

### feedback_page.dart
Replace hardcoded titles, labels, hints, button text, and validation messages.

### smart_parameter_dialog.dart
Replace hardcoded labels, button text, and validation messages.

### operation_registry.dart
Externalize technical labels and descriptions for analytical operations.

### app_router.dart
Replace hardcoded error page text.

---

## Effort Summary

| Category | Count | Effort |
|----------|-------|--------|
| Delete duplicate lines | 4 keys | Trivial |
| Drop "successfully" / "!" | ~25 strings | Small |
| Remove/merge redundant keys | ~8 pairs | Medium |
| Rephrase jargon | ~15 strings | Small |
| Evaluate debug toasts | ~8 strings | Design decision |
| Merge about fragments | 3 -> 1 string | Small |
| Fix capitalization | ~4 strings | Trivial |
| Extract hardcoded strings | 4 files | Medium |
