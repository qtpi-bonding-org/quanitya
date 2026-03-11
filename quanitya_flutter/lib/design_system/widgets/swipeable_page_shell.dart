import 'package:flutter/material.dart';

import '../primitives/app_sizes.dart';
import '../primitives/quanitya_palette.dart';
import 'quanitya/general/zen_paper_background.dart';

/// A sliding zen-paper background that creates a "physical paper sliding"
/// illusion as pages are swiped. Generalized from [TemporalZenPaper].
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
        final page =
            controller.hasClients ? (controller.page ?? 0.0) : 0.0;
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
              children: List.generate(pageCount, (i) {
                final scrollOffset =
                    i < scrollOffsets.length ? scrollOffsets[i] : 0.0;
                final totalWidth = screenWidth * pageCount;
                return SizedBox(
                  width: screenWidth,
                  height: double.infinity,
                  child: ZenPaperBackground(
                    baseColor: backgroundColor,
                    scrollOffset: scrollOffset,
                    stripOriginX: i * screenWidth,
                    totalStripWidth: totalWidth,
                    child: const SizedBox.expand(),
                  ),
                );
              }),
            ),
          ),
        );
      },
    );
  }
}

/// A reusable shell that combines a [PageView] with a sliding zen-paper
/// background and bottom indicator labels.
///
/// Provides the swipeable-page-with-paper-illusion pattern used across
/// multiple sections of the app.
class SwipeablePageShell extends StatefulWidget {
  /// Content pages for the [PageView].
  final List<Widget> pages;

  /// Indicator label widgets shown at the bottom. Tapping a label
  /// animates to the corresponding page.
  final List<Widget> labels;

  /// The initial page index. Defaults to 0.
  final int initialPage;

  /// Optional external [PageController]. If null, an internal controller
  /// is created and disposed automatically.
  final PageController? controller;

  /// Called when the current page changes.
  final ValueChanged<int>? onPageChanged;

  /// Extra widgets layered on top of the page content in the [Stack].
  final List<Widget> overlays;

  /// Per-page scroll offsets passed to the sliding paper strips.
  /// Index corresponds to page index; out-of-bounds defaults to 0.0.
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
  late PageController _controller;
  bool _ownsController = false;

  @override
  void initState() {
    super.initState();
    _initController();
  }

  @override
  void didUpdateWidget(SwipeablePageShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      _disposeOwnedController();
      _initController();
    }
  }

  void _initController() {
    if (widget.controller != null) {
      _controller = widget.controller!;
      _ownsController = false;
    } else {
      _controller = PageController(initialPage: widget.initialPage);
      _ownsController = true;
    }
  }

  void _disposeOwnedController() {
    if (_ownsController) {
      _controller.dispose();
    }
  }

  @override
  void dispose() {
    _disposeOwnedController();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        _SlidingZenPaper(
          controller: _controller,
          pageCount: widget.pages.length,
          scrollOffsets: widget.scrollOffsets,
        ),
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
                padding: EdgeInsets.symmetric(
                  vertical: AppSizes.space * 0.25,
                ),
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
        ...widget.overlays,
      ],
    );
  }
}
