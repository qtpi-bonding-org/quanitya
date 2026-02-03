import 'package:flutter/material.dart';
import '../../../design_system/primitives/quanitya_palette.dart';
import '../../../design_system/widgets/quanitya/general/zen_paper_background.dart';

/// A specialized Zen Paper background that handles horizontal scrolling physics.
///
/// It renders 3 vertical "strips" of paper (Left, Center, Right) side-by-side.
/// It listens to the [PageController] to slide these strips horizontally, creating
/// a continuous "Infinite Paper" illusion without exceeding GPU texture limits.
class TemporalZenPaper extends StatefulWidget {
  final PageController controller;
  final Widget? child; // Optional content to float on top
  final double pastScrollOffset;
  final double futureScrollOffset;

  const TemporalZenPaper({
    super.key,
    required this.controller,
    this.child,
    this.pastScrollOffset = 0.0,
    this.futureScrollOffset = 0.0,
  });

  @override
  State<TemporalZenPaper> createState() => _TemporalZenPaperState();
}

class _TemporalZenPaperState extends State<TemporalZenPaper> {
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        final screenWidth = MediaQuery.sizeOf(context).width;

        final page = widget.controller.hasClients
            ? (widget.controller.page ?? 1.0)
            : 1.0;
        final dx = -page * screenWidth;
        final backgroundColor = QuanityaPalette.primary.backgroundPrimary;

        return Stack(
          children: [
            // The Sliding Paper Layer
            Transform.translate(
              offset: Offset(dx, 0),
              child: OverflowBox(
                // Allow the Row to be wider than the screen (3x width)
                minWidth: 0,
                maxWidth: double.infinity,
                alignment: Alignment
                    .centerLeft, // Anchor to left so translation works from 0
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // LEFT STRIP (Past)
                    SizedBox(
                      width: screenWidth,
                      height: double.infinity,
                      child: ZenPaperBackground(
                        baseColor: backgroundColor,
                        scrollOffset: widget.pastScrollOffset,
                        child: const SizedBox.expand(),
                      ),
                    ),

                    // CENTER STRIP (Present)
                    SizedBox(
                      width: screenWidth,
                      height: double.infinity,
                      child: ZenPaperBackground(
                        baseColor: backgroundColor,
                        child: const SizedBox.expand(),
                      ),
                    ),

                    // RIGHT STRIP (Future)
                    SizedBox(
                      width: screenWidth,
                      height: double.infinity,
                      child: ZenPaperBackground(
                        baseColor: backgroundColor,
                        scrollOffset: widget.futureScrollOffset,
                        child: const SizedBox.expand(),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Content Layer (Optional)
            if (widget.child != null) widget.child!,
          ],
        );
      },
    );
  }
}
