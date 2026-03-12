# SwipeablePageShell Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Extract the sliding-paper swipeable page pattern into a reusable `SwipeablePageShell` widget and migrate TemporalHomePage to use it.

**Architecture:** Generalize `TemporalZenPaper` into `_SlidingZenPaper` inside a new `SwipeablePageShell` widget. The shell composes sliding paper background + PageView + indicator labels + optional overlays. TemporalHomePage becomes the first consumer.

**Tech Stack:** Flutter, ZenPaperBackground

---

### Task 1: Create `SwipeablePageShell` widget

**Files:**
- Create: `lib/design_system/widgets/swipeable_page_shell.dart`
- Reference: `lib/features/home/widgets/temporal_zen_paper.dart` (pattern to generalize)
- Reference: `lib/design_system/widgets/quanitya/general/zen_paper_background.dart`

- [ ] **Step 1: Create the file with `_SlidingZenPaper`**

Generalize `TemporalZenPaper` to support N pages instead of hardcoded 3:

```dart
import 'package:flutter/material.dart';
import 'primitives/quanitya_palette.dart';
import 'quanitya/general/zen_paper_background.dart';
import '../primitives/app_sizes.dart';

class _SlidingZenPaper extends StatelessWidget {
  final PageController controller;
  final int pageCount;
  final List<double> scrollOffsets;

  const _SlidingZenPaper({
    required this.controller,
    required this.pageCount,
    required this.scrollOffsets,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final screenWidth = MediaQuery.sizeOf(context).width;
        final page = controller.hasClients
            ? (controller.page ?? 0.0)
            : 0.0;
        final dx = -page * screenWidth;
        final backgroundColor = QuanityaPalette.primary.backgroundPrimary;

        return Transform.translate(
          offset: Offset(dx, 0),
          child: OverflowBox(
            minWidth: 0,
            maxWidth: double.infinity,
            alignment: Alignment.centerLeft,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(pageCount, (i) => SizedBox(
                width: screenWidth,
                height: double.infinity,
                child: ZenPaperBackground(
                  baseColor: backgroundColor,
                  scrollOffset: i < scrollOffsets.length ? scrollOffsets[i] : 0.0,
                  child: const SizedBox.expand(),
                ),
              )),
            ),
          ),
        );
      },
    );
  }
}
```

- [ ] **Step 2: Add `SwipeablePageShell` widget**

```dart
class SwipeablePageShell extends StatefulWidget {
  final List<Widget> pages;
  final List<Widget> labels;
  final int initialPage;
  final PageController? controller;
  final ValueChanged<int>? onPageChanged;
  final List<Widget> overlays;
  final List<double> scrollOffsets;

  const SwipeablePageShell({
    super.key,
    required this.pages,
    required this.labels,
    this.initialPage = 0,
    this.controller,
    this.onPageChanged,
    this.overlays = const [],
    this.scrollOffsets = const [],
  });

  @override
  State<SwipeablePageShell> createState() => _SwipeablePageShellState();
}

class _SwipeablePageShellState extends State<SwipeablePageShell> {
  late final PageController _internalController;
  PageController get _controller => widget.controller ?? _internalController;
  bool get _ownsController => widget.controller == null;

  @override
  void initState() {
    super.initState();
    _internalController = PageController(initialPage: widget.initialPage);
  }

  @override
  void dispose() {
    if (_ownsController) _internalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Layer 0: Sliding paper background
        _SlidingZenPaper(
          controller: _controller,
          pageCount: widget.pages.length,
          scrollOffsets: widget.scrollOffsets,
        ),

        // Layer 1: Content + indicator
        SafeArea(
          bottom: false,
          child: Column(
            children: [
              Expanded(
                child: PageView(
                  controller: _controller,
                  physics: const ClampingScrollPhysics(),
                  onPageChanged: widget.onPageChanged,
                  children: widget.pages,
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(vertical: AppSizes.space * 0.25),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (int i = 0; i < widget.labels.length; i++)
                      GestureDetector(
                        onTap: () => _controller.animateToPage(
                          i,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        ),
                        behavior: HitTestBehavior.opaque,
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: AppSizes.space * 1.5,
                            vertical: AppSizes.space * 0.5,
                          ),
                          child: widget.labels[i],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Layer 2+: Overlays
        ...widget.overlays,
      ],
    );
  }
}
```

- [ ] **Step 3: Verify it compiles**

Run: `cd /Users/aicoder/Documents/openops/project/quanitya/public/quanitya_flutter && flutter analyze lib/design_system/widgets/swipeable_page_shell.dart`

- [ ] **Step 4: Commit**

```bash
git add lib/design_system/widgets/swipeable_page_shell.dart
git commit -m "feat: add SwipeablePageShell reusable widget with sliding paper background"
```

---

### Task 2: Migrate TemporalHomePage to use `SwipeablePageShell`

**Files:**
- Modify: `lib/features/home/pages/temporal_home_page.dart`
- Delete: `lib/features/home/widgets/temporal_zen_paper.dart`
- Reference: `lib/features/home/widgets/temporal_indicator.dart` (label styling to preserve)

- [ ] **Step 1: Refactor TemporalHomePage to use SwipeablePageShell**

Replace the manual Stack/TemporalZenPaper/Column/PageView with SwipeablePageShell. Key changes:

1. Remove `TemporalZenPaper` import, add `SwipeablePageShell` import
2. Extract temporal label builder method (preserving header font, large size, teal/black colors)
3. Replace the `Stack(children: [...])` body with `SwipeablePageShell(...)`:
   - `controller: _pageController`
   - `initialPage: 1`
   - `pages: [TemporalPastPanel(...), TemporalPresentPanel(), TemporalFuturePanel(...)]`
   - `labels: [_buildLabel('-t', 0), _buildLabel('t', 1), _buildLabel('+t', 2)]` — each returns a Text widget with header font/size styling, color based on `_currentIndex`
   - `scrollOffsets: [_pastScrollOffset, 0.0, _futureScrollOffset]`
   - `onPageChanged: (index) { setState(() => _currentIndex = index); _timelineCubit?.setCurrentPage(index); }`
   - `overlays: [filterButtonsPositioned, lockIconPositioned, devFabPositioned]`

4. Remove `TemporalIndicator` import (labels are now inline)

- [ ] **Step 2: Delete `temporal_zen_paper.dart`**

```bash
git rm lib/features/home/widgets/temporal_zen_paper.dart
```

- [ ] **Step 3: Verify it compiles**

Run: `cd /Users/aicoder/Documents/openops/project/quanitya/public/quanitya_flutter && flutter analyze lib/features/home/pages/temporal_home_page.dart`

- [ ] **Step 4: Check for unused imports / dead references to TemporalZenPaper**

Search codebase for any remaining references to `TemporalZenPaper` or `temporal_zen_paper.dart`.

- [ ] **Step 5: Commit**

```bash
git add -A
git commit -m "refactor: migrate TemporalHomePage to SwipeablePageShell"
```

---

### Stop Point: Visual Verification

After Task 2, the user will visually verify that TemporalHomePage looks and behaves identically:
- Paper slides horizontally with swipe
- Dots scroll vertically on Past/Future panels
- `-t` / `t` / `+t` labels show correct font and color
- Filter buttons and lock icon positioned correctly
- Page snapping works

Migration of PostagePage, OfficePage, and ResultsSection will proceed in a follow-up after verification.
