# Results Page Redesign — Design Spec

## Goal

Replace the blank landing state + hidden bookmark selector with a scrollable list of NotebookFold sections per template, showing all templates with log data. No template selector needed — everything is visible and collapsible.

## Problem

- Results page lands on a blank screen with a faded logo watermark
- The only way to see data is via a cryptic bookmark icon (no label, no guidance)
- No way to browse across templates — one-at-a-time via hidden selector
- Users don't know what the page does or how to use it

## Design

### Both Tabs (Graphs & Analysis)

- On page load, fetch all templates that have log entries
- Sort by most recently logged first
- Render each template as a `NotebookFold` (all collapsed by default)
- Templates with no log data are hidden entirely
- If no templates have log data at all, show an empty state message

### Data Loading

**Lightweight list on page load:**
- Load template list with basic metadata (name, entry count, last logged date)
- This is the TemplateListCubit data + a lightweight query for entry counts/dates

**Lazy load on fold expand:**
- When a NotebookFold expands (`onExpansionChanged: true`), fetch that template's full aggregated data
- For Graphs: field charts, stats, contribution heatmap
- For Analysis: pipeline results, field analysis cards
- Once loaded, cache so re-collapse/re-expand doesn't re-fetch

### Graphs Tab

**Fold header:** Template name + entry count + last logged date (compact, single row)

**Fold body (on expand):**
- Loading indicator while fetching
- Field charts in grid layout (same as current):
  - Numeric → TimeSeriesChart
  - Boolean → BooleanHeatmapChart
  - Categorical → CategoricalScatterChart
- Stats summary (entry count, consistency %, contribution heatmap)

### Analysis Tab

**Fold header:** Template name + pipeline count

**Fold body (on expand):**
- Loading indicator while fetching
- Pipeline results section (if pipelines exist)
- Analyze Fields section (numeric fields with tap-to-build navigation)
- No analysis placeholder (if no pipelines and no numeric fields)

### Removals

- Bookmark icon overlay from ResultsSection
- TemplateSelectorSheet usage from Results (keep the widget — may be used elsewhere)
- `_selectedTemplateId` state
- `QuanityaEmptyState` logo watermark in both pages
- Per-template header/subtitle inside graphs/analysis content (fold header replaces this)

### New Empty State

When no templates have any log data:
- Icon: `Icons.insights` (or similar)
- Title: "No Results Yet"
- Description: "Log entries to see visualizations and analysis here."

### Architecture

The current `VisualizationCubit` loads data for one template. The new design needs:
- A list-level data source for template metadata (already have TemplateListCubit)
- Per-fold VisualizationCubit created on expand, providing data for that template's fold body
- No shared state needed — the AnalysisBuilderPage is fully self-contained

### Not In Scope

- Cached/shared cubits across features
- Changes to AnalysisBuilderPage
- Changes to VisualizationCubit internals
