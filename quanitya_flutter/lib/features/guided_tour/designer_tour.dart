import 'package:flutter/material.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

import '../../support/extensions/context_extensions.dart';
import 'tour_runner.dart';

List<TargetFocus> _buildDesignerTourTargets({
  required GlobalKey aiPromptKey,
  required GlobalKey nameFieldKey,
  required GlobalKey fieldsSectionKey,
  required GlobalKey scheduleFoldKey,
  required GlobalKey previewButtonKey,
  required BuildContext context,
}) {
  final centerY = MediaQuery.sizeOf(context).height * 0.4;

  return [
    TargetFocus(
      identify: 'ai_prompt',
      keyTarget: aiPromptKey,
      enableOverlayTab: true,
      enableTargetTab: true,
      contents: [
        TargetContent(
          align: ContentAlign.custom,
          customPosition: CustomTargetContentPosition(top: centerY),
          child: tourText(context, context.l10n.tourDesignerAiPrompt),
        ),
      ],
      shape: ShapeLightFocus.RRect,
    ),
    TargetFocus(
      identify: 'name_field',
      keyTarget: nameFieldKey,
      enableOverlayTab: true,
      enableTargetTab: true,
      contents: [
        TargetContent(
          align: ContentAlign.custom,
          customPosition: CustomTargetContentPosition(top: centerY),
          child: tourText(context, context.l10n.tourDesignerNameField),
        ),
      ],
      shape: ShapeLightFocus.RRect,
    ),
    TargetFocus(
      identify: 'fields_section',
      keyTarget: fieldsSectionKey,
      enableOverlayTab: true,
      enableTargetTab: true,
      contents: [
        TargetContent(
          align: ContentAlign.custom,
          customPosition: CustomTargetContentPosition(top: centerY),
          child: tourText(context, context.l10n.tourDesignerFields),
        ),
      ],
      shape: ShapeLightFocus.RRect,
    ),
    TargetFocus(
      identify: 'schedule_fold',
      keyTarget: scheduleFoldKey,
      enableOverlayTab: true,
      enableTargetTab: true,
      contents: [
        TargetContent(
          align: ContentAlign.custom,
          customPosition: CustomTargetContentPosition(top: centerY),
          child: tourText(context, context.l10n.tourDesignerSchedule),
        ),
      ],
      shape: ShapeLightFocus.RRect,
    ),
    TargetFocus(
      identify: 'preview_button',
      keyTarget: previewButtonKey,
      enableOverlayTab: true,
      enableTargetTab: true,
      contents: [
        TargetContent(
          align: ContentAlign.custom,
          customPosition: CustomTargetContentPosition(top: centerY),
          child: tourText(context, context.l10n.tourDesignerPreview),
        ),
      ],
    ),
  ];
}

void showDesignerTour(
  BuildContext context, {
  required GlobalKey aiPromptKey,
  required GlobalKey nameFieldKey,
  required GlobalKey fieldsSectionKey,
  required GlobalKey scheduleFoldKey,
  required GlobalKey previewButtonKey,
  VoidCallback? onFinish,
}) {
  runTour(
    context,
    targets: _buildDesignerTourTargets(
      aiPromptKey: aiPromptKey,
      nameFieldKey: nameFieldKey,
      fieldsSectionKey: fieldsSectionKey,
      scheduleFoldKey: scheduleFoldKey,
      previewButtonKey: previewButtonKey,
      context: context,
    ),
    onFinish: onFinish,
  );
}
