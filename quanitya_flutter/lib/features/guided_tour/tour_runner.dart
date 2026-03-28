import 'package:flutter/material.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

import '../../design_system/primitives/app_sizes.dart';

/// Shared tour text widget — centered white text with breathing room.
Widget tourText(BuildContext context, String text, {TextStyle? style}) {
  return Padding(
    padding: EdgeInsets.symmetric(vertical: AppSizes.space * 2),
    child: Text(
      text,
      textAlign: TextAlign.center,
      style: style ??
          Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.white,
                height: 1.5,
              ),
    ),
  );
}

/// Runs a [TutorialCoachMark] with automatic scrolling to each target.
///
/// Before the first target is shown, scrolls it into view. When the user
/// taps to advance, scrolls the next target into view before the coach mark
/// transitions.
void runTour(
  BuildContext context, {
  required List<TargetFocus> targets,
  VoidCallback? onFinish,
}) {
  if (targets.isEmpty) return;

  var currentIndex = 0;

  // Scroll the first target into view before showing the tour.
  _scrollToTarget(targets.first);

  TutorialCoachMark(
    targets: targets,
    colorShadow: Colors.black,
    opacityShadow: 0.8,
    hideSkip: true,
    onFinish: onFinish,
    onClickTarget: (_) => _advanceScroll(targets, ++currentIndex),
    onClickOverlay: (_) => _advanceScroll(targets, ++currentIndex),
  ).show(context: context);
}

void _advanceScroll(List<TargetFocus> targets, int nextIndex) {
  if (nextIndex < targets.length) {
    _scrollToTarget(targets[nextIndex]);
  }
}

void _scrollToTarget(TargetFocus target) {
  final key = target.keyTarget;
  if (key == null) return;
  final ctx = key.currentContext;
  if (ctx == null) return;

  Scrollable.ensureVisible(
    ctx,
    duration: const Duration(milliseconds: 300),
    curve: Curves.easeInOut,
    alignment: 0.3,
  );
}
