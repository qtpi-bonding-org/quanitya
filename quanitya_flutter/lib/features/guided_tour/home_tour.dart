import 'package:flutter/material.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

import '../../support/extensions/context_extensions.dart';
import 'tour_runner.dart';

List<TargetFocus> _buildHomeTourTargets({
  required GlobalKey temporalLabelsKey,
  required GlobalKey designerButtonKey,
  required GlobalKey resultsTabKey,
  required GlobalKey postageTabKey,
  required GlobalKey officeTabKey,
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
          child: tourText(context, context.l10n.tourHomeTemporalLabels),
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
          child: tourText(context, context.l10n.tourHomeDesignerButton),
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
          child: tourText(context, context.l10n.tourHomeResultsTab),
        ),
      ],
    ),
    TargetFocus(
      identify: 'postage_tab',
      keyTarget: postageTabKey,
      enableOverlayTab: true,
      enableTargetTab: true,
      contents: [
        TargetContent(
          align: ContentAlign.custom,
          customPosition: CustomTargetContentPosition(top: centerY),
          child: tourText(context, context.l10n.tourHomePostageTab),
        ),
      ],
    ),
    TargetFocus(
      identify: 'office_tab',
      keyTarget: officeTabKey,
      enableOverlayTab: true,
      enableTargetTab: true,
      contents: [
        TargetContent(
          align: ContentAlign.custom,
          customPosition: CustomTargetContentPosition(top: centerY),
          child: tourText(context, context.l10n.tourHomeOfficeTab),
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
  required GlobalKey postageTabKey,
  required GlobalKey officeTabKey,
  VoidCallback? onFinish,
}) {
  runTour(
    context,
    targets: _buildHomeTourTargets(
      temporalLabelsKey: temporalLabelsKey,
      designerButtonKey: designerButtonKey,
      resultsTabKey: resultsTabKey,
      postageTabKey: postageTabKey,
      officeTabKey: officeTabKey,
      context: context,
    ),
    onFinish: onFinish,
  );
}
