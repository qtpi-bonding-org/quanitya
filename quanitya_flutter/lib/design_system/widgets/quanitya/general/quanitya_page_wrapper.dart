import 'package:flutter/material.dart';
import 'zen_paper_background.dart';

/// A page wrapper that composes ZenPaperBackground with SafeArea.
/// Use this as the root widget for pages that need both.
class QuanityaPageWrapper extends StatelessWidget {
  final Widget child;
  final Color? backgroundColor;
  final double? scrollOffset;

  const QuanityaPageWrapper({
    super.key,
    required this.child,
    this.backgroundColor,
    this.scrollOffset,
  });

  @override
  Widget build(BuildContext context) {
    return ZenPaperBackground(
      baseColor: backgroundColor,
      scrollOffset: scrollOffset,
      child: SafeArea(child: child),
    );
  }
}
