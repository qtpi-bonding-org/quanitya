# Screenshot Translation Gaps

Untranslated strings visible in non-English screenshots.

## Easy fixes (fake data translations in `fake_template_data.dart` + test)

- [ ] Log entry form buttons: "Discard" / "Save" → add to `_t` map
- [ ] Timeline date dividers: "Apr 1", "Mar 31", "Mar 30" → add localized month abbrevs
- [ ] Timeline time strings: "2:30 PM", "7:15 AM" → use 24h format for es/fr/pt
- [ ] Analysis reasoning: "Computes basic statistics..." → add to `_t` map
- [ ] DevFab visible → DONE (added `hideForScreenshots` flag)

## Skip (intentional — leave in English)

- JS code string literals (`"Mean"`, `"kg"` etc.) — it's actual JavaScript code,
  translating string literals inside code looks artificial. The code editor is a
  developer tool; English code is authentic.
- Analysis result labels ("Mean", "Max", "Min", "Trend", "kg") — these come from
  the JS code output. In the real app, results show whatever the script returns.
  Translating them without translating the code creates a mismatch.

## App L10n issues (not screenshot-specific — separate task)

- [ ] `scalar` / `vector` / `matrix` — AnalysisOutputMode enum displayed raw via `.name`
- [ ] `Text` / `Decimal` — field type labels in template designer (e.g. "Text · Campo de texto")
- These are real app l10n gaps. Fixing requires adding ARB keys + updating widgets.
  Not worth doing just for screenshots — they're semi-universal technical terms.
