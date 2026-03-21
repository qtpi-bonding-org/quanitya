import 'package:flutter/material.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

import '../../support/extensions/context_extensions.dart';

List<TargetFocus> _buildHomeTourTargets({
  required GlobalKey temporalLabelsKey,
  required GlobalKey templateCardKey,
  required GlobalKey quickEntryKey,
  required GlobalKey resultsTabKey,
  required BuildContext context,
}) {
  return [
    TargetFocus(
      identify: 'temporal_labels',
      keyTarget: temporalLabelsKey,
      contents: [
        TargetContent(
          align: ContentAlign.bottom,
          child: Text(
            context.l10n.tourHomeTemporalLabels,
            style: context.text.bodyMedium?.copyWith(
              color: Colors.white,
            ),
          ),
        ),
      ],
      shape: ShapeLightFocus.RRect,
    ),
    TargetFocus(
      identify: 'template_card',
      keyTarget: templateCardKey,
      contents: [
        TargetContent(
          align: ContentAlign.bottom,
          child: Text(
            context.l10n.tourHomeTemplateCard,
            style: context.text.bodyMedium?.copyWith(
              color: Colors.white,
            ),
          ),
        ),
      ],
    ),
    TargetFocus(
      identify: 'quick_entry',
      keyTarget: quickEntryKey,
      contents: [
        TargetContent(
          align: ContentAlign.top,
          child: Text(
            context.l10n.tourHomeQuickEntry,
            style: context.text.bodyMedium?.copyWith(
              color: Colors.white,
            ),
          ),
        ),
      ],
    ),
    TargetFocus(
      identify: 'results_tab',
      keyTarget: resultsTabKey,
      contents: [
        TargetContent(
          align: ContentAlign.top,
          child: Text(
            context.l10n.tourHomeResultsTab,
            style: context.text.bodyMedium?.copyWith(
              color: Colors.white,
            ),
          ),
        ),
      ],
    ),
  ];
}

void showHomeTour(
  BuildContext context, {
  required GlobalKey temporalLabelsKey,
  required GlobalKey templateCardKey,
  required GlobalKey quickEntryKey,
  required GlobalKey resultsTabKey,
}) {
  final targets = _buildHomeTourTargets(
    temporalLabelsKey: temporalLabelsKey,
    templateCardKey: templateCardKey,
    quickEntryKey: quickEntryKey,
    resultsTabKey: resultsTabKey,
    context: context,
  );

  TutorialCoachMark(
    targets: targets,
    colorShadow: Colors.black,
    opacityShadow: 0.8,
    hideSkip: true,
  ).show(context: context);
}
