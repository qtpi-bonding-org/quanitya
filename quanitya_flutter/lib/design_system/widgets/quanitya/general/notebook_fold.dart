import 'package:flutter/material.dart';

import '../../../primitives/app_sizes.dart';
import '../../../primitives/quanitya_palette.dart';
import '../../../../support/extensions/context_extensions.dart';

/// A taped-down flap with a visible header that unfolds to reveal content.
///
/// Replaces all ad-hoc expandable patterns in the design system.
/// Uses progressive disclosure — collapsed by default — so only the
/// header is visible until the user taps to unfold.
class NotebookFold extends StatefulWidget {
  /// Always-visible header content.
  final Widget header;

  /// Content revealed when unfolded.
  final Widget child;

  /// Whether the fold starts expanded. Defaults to `false` (collapsed).
  final bool initiallyExpanded;

  /// Optional callback fired when the expansion state changes.
  final ValueChanged<bool>? onExpansionChanged;

  /// Optional override for the default rotating chevron icon.
  final Widget? trailing;

  const NotebookFold({
    super.key,
    required this.header,
    required this.child,
    this.initiallyExpanded = false,
    this.onExpansionChanged,
    this.trailing,
  });

  @override
  State<NotebookFold> createState() => _NotebookFoldState();
}

class _NotebookFoldState extends State<NotebookFold>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _heightFactor;
  late final Animation<double> _iconTurns;

  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;

    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _heightFactor = _controller.drive(CurveTween(curve: Curves.easeOut));
    _iconTurns = _controller.drive(
      Tween<double>(begin: 0.0, end: 0.5),
    );

    if (_isExpanded) {
      _controller.value = 1.0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
      widget.onExpansionChanged?.call(_isExpanded);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            InkWell(
              onTap: _handleTap,
              child: Padding(
                padding: EdgeInsets.symmetric(
                  vertical: AppSizes.space,
                  horizontal: AppSizes.space,
                ),
                child: Row(
                  children: [
                    Expanded(child: widget.header),
                    widget.trailing ??
                        RotationTransition(
                          turns: _iconTurns,
                          child: Icon(
                            Icons.expand_more,
                            color: context.colors.textSecondary,
                            size: AppSizes.iconMedium,
                          ),
                        ),
                  ],
                ),
              ),
            ),
            ClipRect(
              child: Align(
                alignment: Alignment.topCenter,
                heightFactor: _heightFactor.value,
                child: child,
              ),
            ),
          ],
        );
      },
      child: Padding(
        padding: EdgeInsets.only(
          left: AppSizes.space,
          right: AppSizes.space,
          bottom: AppSizes.space,
        ),
        child: widget.child,
      ),
    );
  }
}
