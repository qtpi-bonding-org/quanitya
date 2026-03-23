import 'package:flutter/material.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

import '../../design_system/primitives/app_sizes.dart';
import '../../support/extensions/context_extensions.dart';

Widget _tourText(BuildContext context, String text) {
  return Padding(
    padding: EdgeInsets.symmetric(vertical: AppSizes.space * 2),
    child: Text(
      text,
      textAlign: TextAlign.center,
      style: context.text.bodyMedium?.copyWith(
        color: Colors.white,
        height: 1.5,
      ),
    ),
  );
}

List<TargetFocus> _buildHomeTourTargets({
  required GlobalKey temporalLabelsKey,
  required GlobalKey designerButtonKey,
  required GlobalKey resultsTabKey,
  required BuildContext context,
}) {
  final centerY = MediaQuery.sizeOf(context).height * 0.4;

  return [
    TargetFocus(
      identify: 'temporal_labels',
      keyTarget: temporalLabelsKey,
      enableOverlayTab: true,
      enableTargetTab: true,
      contents: [
        TargetContent(
          align: ContentAlign.custom,
          customPosition: CustomTargetContentPosition(top: centerY),
          child: _tourText(context, context.l10n.tourHomeTemporalLabels),
        ),
      ],
      shape: ShapeLightFocus.RRect,
    ),
    TargetFocus(
      identify: 'designer_button',
      keyTarget: designerButtonKey,
      enableOverlayTab: true,
      enableTargetTab: true,
      contents: [
        TargetContent(
          align: ContentAlign.custom,
          customPosition: CustomTargetContentPosition(top: centerY),
          child: _tourText(context, context.l10n.tourHomeDesignerButton),
        ),
      ],
    ),
    TargetFocus(
      identify: 'results_tab',
      keyTarget: resultsTabKey,
      enableOverlayTab: true,
      enableTargetTab: true,
      contents: [
        TargetContent(
          align: ContentAlign.custom,
          customPosition: CustomTargetContentPosition(top: centerY),
          child: _tourText(context, context.l10n.tourHomeResultsTab),
        ),
      ],
    ),
  ];
}

void showHomeTour(
  BuildContext context, {
  required GlobalKey temporalLabelsKey,
  required GlobalKey designerButtonKey,
  required GlobalKey resultsTabKey,
  VoidCallback? onFinish,
}) {
  final targets = _buildHomeTourTargets(
    temporalLabelsKey: temporalLabelsKey,
    designerButtonKey: designerButtonKey,
    resultsTabKey: resultsTabKey,
    context: context,
  );

  TutorialCoachMark(
    targets: targets,
    colorShadow: Colors.black,
    opacityShadow: 0.8,
    hideSkip: true,
    onFinish: onFinish,
  ).show(context: context);
}
