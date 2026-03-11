# Results Page Redesign Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the blank Results landing with a scrollable list of NotebookFold sections per template, lazy-loading chart/analysis data on expand.

**Architecture:** New `ResultsListCubit` loads lightweight template summaries (name, entry count, last logged). Graphs/Analysis pages become scrollable fold lists. Each fold lazy-loads a `VisualizationCubit` on expand. No bookmark selector.

**Tech Stack:** Flutter, Drift (for summary query), NotebookFold, VisualizationCubit

---

## Chunk 1: Data Layer — Template Summary Query

### Task 1: Add batch template summary query to LogEntryQueryDao

**Files:**
- Modify: `lib/data/dao/log_entry_query_dao.dart`

- [ ] **Step 1: Add `getTemplateSummaries()` method**

Add a Drift query that returns entry count and last logged date per template in one query:

```dart
/// Summary data for each template's log entries.
class TemplateSummary {
  final String templateId;
  final int entryCount;
  final DateTime? lastLoggedAt;

  const TemplateSummary({
    required this.templateId,
    required this.entryCount,
    this.lastLoggedAt,
  });
}

/// Get entry count and last logged date for all templates in one query.
Future<List<TemplateSummary>> getTemplateSummaries() async {
  final templateId = _db.logEntries.templateId;
  final countExp = _db.logEntries.id.count();
  final maxDateExp = coalesce([_db.logEntries.occurredAt, _db.logEntries.scheduledFor]).max();

  final query = _db.selectOnly(_db.logEntries)
    ..addColumns([templateId, countExp, maxDateExp])
    ..groupBy([templateId]);

  final results = await query.get();
  return results.map((row) {
    return TemplateSummary(
      templateId: row.read(templateId)!,
      entryCount: row.read(countExp) ?? 0,
      lastLoggedAt: row.read(maxDateExp),
    );
  }).toList();
}
```

- [ ] **Step 2: Verify it compiles**

Run: `flutter analyze --no-pub lib/data/dao/log_entry_query_dao.dart`

- [ ] **Step 3: Commit**

```bash
git add lib/data/dao/log_entry_query_dao.dart
git commit -m "feat: add batch getTemplateSummaries query for Results page"
```

---

### Task 2: Add `getTemplateSummaries` to LogEntryRepository interface and implementation

**Files:**
- Modify: `lib/data/interfaces/log_entry_interface.dart`
- Modify: `lib/data/repositories/log_entry_repository.dart`

- [ ] **Step 1: Add to interface**

```dart
/// Gets entry count and last logged date for all templates.
Future<List<TemplateSummary>> getTemplateSummaries();
```

Import `TemplateSummary` from `log_entry_query_dao.dart`.

- [ ] **Step 2: Add to implementation**

```dart
@override
Future<List<TemplateSummary>> getTemplateSummaries() async {
  return _queryDao.getTemplateSummaries();
}
```

- [ ] **Step 3: Verify it compiles**

Run: `flutter analyze --no-pub lib/data/interfaces/log_entry_interface.dart lib/data/repositories/log_entry_repository.dart`

- [ ] **Step 4: Commit**

```bash
git add lib/data/interfaces/log_entry_interface.dart lib/data/repositories/log_entry_repository.dart
git commit -m "feat: expose getTemplateSummaries via LogEntryRepository"
```

---

## Chunk 2: Results List Cubit

### Task 3: Create `ResultsListCubit` and state

**Files:**
- Create: `lib/features/results/cubits/results_list_cubit.dart`
- Create: `lib/features/results/cubits/results_list_state.dart`

This cubit loads ALL templates with their entry summaries, sorted by most recently logged. It merges `TemplateListCubit` data (template names, fields) with `TemplateSummary` data (entry counts, last logged).

- [ ] **Step 1: Create state**

```dart
// results_list_state.dart
import 'package:cubit_ui_flow/cubit_ui_flow.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'results_list_state.freezed.dart';

/// A template with its entry summary for the Results list.
class ResultsTemplateItem {
  final String templateId;
  final String templateName;
  final int entryCount;
  final DateTime? lastLoggedAt;

  const ResultsTemplateItem({
    required this.templateId,
    required this.templateName,
    required this.entryCount,
    this.lastLoggedAt,
  });
}

@freezed
class ResultsListState
    with _$ResultsListState, UiFlowStateMixin
    implements IUiFlowState {
  const ResultsListState._();

  const factory ResultsListState({
    @Default(UiFlowStatus.idle) UiFlowStatus status,
    Object? error,
    @Default([]) List<ResultsTemplateItem> templates,
  }) = _ResultsListState;
}
```

- [ ] **Step 2: Create cubit**

```dart
// results_list_cubit.dart
import 'package:injectable/injectable.dart';
import 'package:cubit_ui_flow/cubit_ui_flow.dart';

import '../../../data/interfaces/log_entry_interface.dart';
import '../../../data/repositories/template_with_aesthetics_repository.dart';
import '../../../support/extensions/cubit_ui_flow_extension.dart';
import 'results_list_state.dart';

export 'results_list_state.dart';

@injectable
class ResultsListCubit extends QuanityaCubit<ResultsListState> {
  final ILogEntryRepository _logEntryRepo;
  final TemplateWithAestheticsRepository _templateRepo;

  ResultsListCubit(this._logEntryRepo, this._templateRepo)
      : super(const ResultsListState());

  Future<void> load() => tryOperation(() async {
    // Get all template summaries (entry count + last logged)
    final summaries = await _logEntryRepo.getTemplateSummaries();

    // Get all active templates for names
    final templates = await _templateRepo.findAll(isArchived: false);

    // Build map of templateId -> template name
    final nameMap = {
      for (final t in templates) t.template.id: t.template.name,
    };

    // Merge and filter: only templates with entries, sorted by last logged
    final items = summaries
        .where((s) => s.entryCount > 0 && nameMap.containsKey(s.templateId))
        .map((s) => ResultsTemplateItem(
              templateId: s.templateId,
              templateName: nameMap[s.templateId]!,
              entryCount: s.entryCount,
              lastLoggedAt: s.lastLoggedAt,
            ))
        .toList()
      ..sort((a, b) {
        // Most recently logged first
        if (a.lastLoggedAt == null && b.lastLoggedAt == null) return 0;
        if (a.lastLoggedAt == null) return 1;
        if (b.lastLoggedAt == null) return -1;
        return b.lastLoggedAt!.compareTo(a.lastLoggedAt!);
      });

    return state.copyWith(
      status: UiFlowStatus.success,
      templates: items,
    );
  }, emitLoading: true);
}
```

- [ ] **Step 3: Register with GetIt**

Add `@injectable` annotation is already on the class. Check that `TemplateWithAestheticsRepository` has a `findAll` method (it likely does — search and verify). If it uses a different method name, adjust.

- [ ] **Step 4: Run build_runner**

```bash
dart run build_runner build --delete-conflicting-outputs
```

- [ ] **Step 5: Verify it compiles**

Run: `flutter analyze --no-pub lib/features/results/cubits/`

- [ ] **Step 6: Commit**

```bash
git add lib/features/results/cubits/
git commit -m "feat: add ResultsListCubit for template summary list"
```

---

## Chunk 3: Rewrite Results Pages

### Task 4: Rewrite `ResultsGraphsPage` as a fold list

**Files:**
- Modify: `lib/features/results/pages/results_graphs_page.dart`

The page becomes a scrollable list of `NotebookFold` widgets, one per template. Each fold lazy-loads its `VisualizationCubit` on expand.

- [ ] **Step 1: Rewrite the page**

Key changes:
- Remove `templateId` parameter — page no longer receives a selected template
- Remove `_EmptyTemplateState` widget
- Expect `ResultsListCubit` to be provided above (from ResultsSection)
- Use `BlocBuilder<ResultsListCubit, ResultsListState>` to build the fold list
- Each fold:
  - Header: template name + entry count + last logged date (use `intl` DateFormat)
  - Body: `_TemplateFoldBody` widget that creates a `BlocProvider<VisualizationCubit>` and loads on first expand
  - Use `onExpansionChanged` to trigger load
- Keep all existing chart widgets (`_NumericChartSection`, `_BooleanChartSection`, `_CategoricalChartSection`, `_StatsSummary`, `_noDataPlaceholder`) — they render inside each fold body
- Remove the per-template header Row (icon + template name + subtitle) — the fold header replaces it
- Add empty state when `state.templates.isEmpty`: icon + "No Results Yet" + description

- [ ] **Step 2: Verify it compiles**

Run: `flutter analyze --no-pub lib/features/results/pages/results_graphs_page.dart`

- [ ] **Step 3: Commit**

```bash
git add lib/features/results/pages/results_graphs_page.dart
git commit -m "refactor: rewrite ResultsGraphsPage as fold list with lazy loading"
```

---

### Task 5: Rewrite `ResultsAnalysisPage` as a fold list

**Files:**
- Modify: `lib/features/results/pages/results_analysis_page.dart`

Same pattern as Graphs — scrollable fold list, lazy-load on expand.

- [ ] **Step 1: Rewrite the page**

Key changes:
- Remove `templateId` parameter
- Remove `_EmptyTemplateState` widget
- Expect `ResultsListCubit` from above
- Each fold:
  - Header: template name + pipeline count (from `state.analysisResults.length` after load)
  - Body: `_TemplateFoldBody` that creates `BlocProvider<VisualizationCubit>` and loads on expand
- Keep all existing analysis widgets (`_AnalysisResultsSection`, `_AnalysisResultCard`, `_FieldAnalysisCard`, `_NoAnalysisPlaceholder`)
- Remove per-template header (icon + name + subtitle)
- Add empty state when `state.templates.isEmpty`

- [ ] **Step 2: Verify it compiles**

Run: `flutter analyze --no-pub lib/features/results/pages/results_analysis_page.dart`

- [ ] **Step 3: Commit**

```bash
git add lib/features/results/pages/results_analysis_page.dart
git commit -m "refactor: rewrite ResultsAnalysisPage as fold list with lazy loading"
```

---

### Task 6: Update `ResultsSection` — remove bookmark, add cubit

**Files:**
- Modify: `lib/features/results/pages/results_section.dart`

- [ ] **Step 1: Update ResultsSection**

Key changes:
- Remove `_selectedTemplateId` state
- Remove `_selectTemplate` method
- Remove bookmark icon from `overlays` (empty overlays list or remove param)
- Remove `Builder` widget (no longer need innerContext for template selector)
- Add `BlocProvider<ResultsListCubit>` — create and call `..load()`
- Pages no longer take `templateId` parameter: `ResultsGraphsPage()`, `ResultsAnalysisPage()`
- Remove imports: `quanitya_icon_button.dart`, `template_selector_sheet.dart`, `template_list_cubit.dart`, `app_sizes.dart`
- Add import for `ResultsListCubit`

- [ ] **Step 2: Verify it compiles**

Run: `flutter analyze --no-pub lib/features/results/pages/results_section.dart`

- [ ] **Step 3: Commit**

```bash
git add lib/features/results/pages/results_section.dart
git commit -m "refactor: remove bookmark selector, add ResultsListCubit to ResultsSection"
```

---

## Chunk 4: Cleanup

### Task 7: Add l10n keys and clean up

**Files:**
- Modify: `lib/l10n/app_en.arb`

- [ ] **Step 1: Add new l10n keys**

```json
{
  "resultsNoResults": "No Results Yet",
  "resultsNoResultsDescription": "Log entries to see visualizations and analysis here.",
  "resultsEntries": "{count} entries",
  "resultsLastLogged": "Last logged {date}"
}
```

- [ ] **Step 2: Run flutter gen-l10n**

```bash
flutter gen-l10n
```

- [ ] **Step 3: Check for unused imports/dead code**

Search for remaining references to `_EmptyTemplateState`, `TemplateSelectorSheet` in results pages.

- [ ] **Step 4: Commit**

```bash
git add lib/l10n/
git commit -m "feat: add l10n keys for Results page redesign"
```

---

### Stop Point: Visual Verification

After all tasks, verify:
- Landing on Results shows template folds (or empty state if no logs)
- Folds sorted by most recently logged first
- Expanding a fold shows loading then charts (Graphs) or analysis (Analysis)
- Re-collapsing and re-expanding doesn't re-fetch
- Templates with no log data are hidden
- Swiping between Graphs/Analysis tabs preserves fold states
