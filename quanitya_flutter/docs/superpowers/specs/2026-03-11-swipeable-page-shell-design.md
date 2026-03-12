# SwipeablePageShell — Design Spec

## Goal

Extract the sliding-paper + PageView + indicator pattern from TemporalHomePage into a reusable `SwipeablePageShell` widget. Migrate TemporalHomePage to use it as proof. Postage/Office/Results migration deferred to a follow-up after visual verification.

## Problem

Four pages repeat the same swipeable sub-tab pattern (PageView + bottom indicator labels). TemporalHomePage additionally has a sliding ZenPaper background that creates a "physical paper" feel. The other three pages lack this background, and all four duplicate the indicator layout code.

## Design

### `SwipeablePageShell` Widget

**Location:** `lib/design_system/widgets/swipeable_page_shell.dart`

**Parameters:**
- `List<Widget> pages` — content pages for the PageView
- `List<Widget> labels` — indicator label widgets (caller controls styling — any Text/widget)
- `int initialPage` — starting page index (default 0)
- `PageController? controller` — optional external controller; shell creates one internally if not provided
- `ValueChanged<int>? onPageChanged` — callback fired on page change
- `List<Widget> overlays` — extra widgets layered on top in the Stack (default empty)
- `List<double> scrollOffsets` — per-page vertical scroll offset forwarded to each paper strip's ZenPaperBackground (default all 0.0)

**Widget tree:**
```
Stack(
  Layer 0: _SlidingZenPaper(controller, pageCount, scrollOffsets)
  Layer 1: SafeArea(bottom: false) → Column(
    Expanded(PageView(controller, ClampingScrollPhysics, pages)),
    Padding(Row(mainAxisAlignment: center, [GestureDetector(label[i]) for i in labels]))
  )
  Layer 2+: ...overlays
)
```

The shell wraps each label in a GestureDetector that calls `controller.animateToPage(i)` on tap. Labels are laid out in a centered Row with consistent padding.

### `_SlidingZenPaper` (private, inside shell file)

Generalized from `TemporalZenPaper`. Renders N paper strips (one per page) instead of hardcoded 3.

- Listens to PageController via `AnimatedBuilder`
- Computes `dx = -page * screenWidth`
- Renders a `Row` of N `SizedBox(width: screenWidth)` each containing a `ZenPaperBackground(scrollOffset: scrollOffsets[i])`
- Wrapped in `Transform.translate(offset: Offset(dx, 0))` + `OverflowBox`

### TemporalHomePage Migration

TemporalHomePage replaces its manual Stack/TemporalZenPaper/Column/PageView with:

```dart
SwipeablePageShell(
  controller: _pageController,
  initialPage: 1,
  pages: [TemporalPastPanel(...), TemporalPresentPanel(), TemporalFuturePanel(...)],
  labels: [_buildTemporalLabel('-t', 0), _buildTemporalLabel('t', 1), _buildTemporalLabel('+t', 2)],
  scrollOffsets: [_pastScrollOffset, 0.0, _futureScrollOffset],
  onPageChanged: (index) { setState(...); _timelineCubit?.setCurrentPage(index); },
  overlays: [filterButtons, lockIcon, devFab],
)
```

Custom label widgets preserve the existing header font/large size styling. The scroll offset wiring stays in TemporalHomePage's state.

### Deletions

- `TemporalZenPaper` widget (replaced by `_SlidingZenPaper` inside shell)

### Not In Scope (deferred)

- Migrating PostagePage, OfficePage, ResultsSection (pending visual verification)
- Deleting duplicate `_PageLabel` classes from those files
