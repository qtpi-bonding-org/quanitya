# flutter_adaptable_group Migration Map

> **Package:** `/Users/aicoder/Documents/my-libs/flutter_adaptable_group`
> **Target:** `/Users/aicoder/Documents/openops/project/quanitya/public/quanitya_flutter`
>
> **Scope:** Only `grid()` and `row()` — places where adaptive behavior adds real value.
> `QuanityaColumn` stays as-is (functionally equivalent to `LayoutGroup.col()`).

## Prerequisites

| Step | What | Where |
|------|------|-------|
| 1 | Add `flutter_adaptable_group` as dependency | `pubspec.yaml` |
| 2 | Wrap app with `ResponsiveLayoutConfig(baseSpacing: AppSizes.space)` | `app.dart` or `main.dart` |
| 3 | Add `implements ResponsiveSpace` to `VSpace` | `design_system/primitives/app_spacings.dart` |
| 4 | Add `implements ResponsiveSpace` to `HSpace` | `design_system/primitives/app_spacings.dart` |

---

## `LayoutGroup.grid()` — 8 spots

Items that reflow into multi-column on wider screens.

| # | File | Line | Current | Content | minItemWidth |
|---|------|------|---------|---------|--------------|
| 1 | `templates/widgets/list/template_list_widget.dart` | 60 | `GridView.builder` | Template card grid (currently hardcoded 2 columns) | ~20 (card width) |
| 2 | `templates/widgets/editor/template_basic_info_editor.dart` | 562 | `Wrap` | Container style preset cards | ~12 (small cards) |
| 3 | `visualization/pages/visualization_page.dart` | 724 | `Wrap` | Scalar value cards (stats) | ~15 (value boxes) |
| 4 | `results/pages/results_analysis_page.dart` | 269 | `Wrap` | Scalar value cards (analysis results) | ~15 (value boxes) |
| 5 | `analytics/widgets/live_results_panel.dart` | 131 | `Wrap` | Scalar result cards (live preview) | ~15 (value boxes) |
| 6 | `purchase/pages/purchase_page.dart` | 284 | `Row` | Product cards (monthly/yearly) — flatten into grid of cards | ~20 (card width) |
| 7 | `visualization/pages/visualization_page.dart` | 80-123 | `QuanityaColumn` | Chart sections (numeric, boolean, categorical) via `.map()` | ~30 (charts need width) |
| 8 | `results/pages/results_graphs_page.dart` | 62-107 | `QuanityaColumn` | Chart sections (same pattern as visualization) | ~30 (charts need width) |

**Why:** On phone these show 1-2 columns. On tablet they could show 3-4 (or 2-up for charts). Currently hardcoded or using Wrap with uneven widths.

---

## `LayoutGroup.row()` — 2 spots

Side-by-side content blocks that should collapse to vertical on narrow screens.

| # | File | Line | Current | Content | minChildWidth |
|---|------|------|---------|---------|---------------|
| 1 | `analytics/pages/analysis_builder_page.dart` | 101 | `Row` (flex 3:2) | Code editor + live results preview | ~30 (each panel needs room) |
| 2 | `templates/widgets/editor/template_basic_info_editor.dart` | 311 | `Row` | Title font + body font dropdowns | ~18 (each dropdown) |

**Why:** These are content blocks that benefit from side-by-side on wide screens but should stack on narrow screens.

---

## Not Migrated

| Widget | Count | Reason |
|--------|-------|--------|
| `QuanityaColumn` | ~20 | Functionally same as `LayoutGroup.col()` — no adaptive benefit |
| `Column` (raw) | ~25 | Same — just vertical stacking |
| `QuanityaRow` | ~15 | 3-slot semantic layout — always horizontal, no collapse needed |
| `QuanityaGroup` | ~5 | Tappable container — not a layout widget |
| `Row` (action bars, nav, toolbars) | ~20 | Always horizontal — buttons, chips, indicators |
| `ListView` / `ListView.separated` | ~12 | Scrollable lists — not replaceable |
| `PageView` | 3 | Horizontal paging — not replaceable |
| `Wrap` (chips) | ~5 | Selection chips — intrinsic widths correct, grid would look wrong |
| Design system internals | all | Primitives, form controls, charts — no change needed |

---

## Summary

**10 total changes** (8 grid + 2 row) across the app. 4 prerequisite setup steps. Everything else stays as-is.
