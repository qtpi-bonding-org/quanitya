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
          child: _tourText(context, context.l10n.tourDesignerAiPrompt),
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
          child: _tourText(context, context.l10n.tourDesignerNameField),
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
          child: _tourText(context, context.l10n.tourDesignerFields),
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
          child: _tourText(context, context.l10n.tourDesignerSchedule),
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
          child: _tourText(context, context.l10n.tourDesignerPreview),
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
  final targets = _buildDesignerTourTargets(
    aiPromptKey: aiPromptKey,
    nameFieldKey: nameFieldKey,
    fieldsSectionKey: fieldsSectionKey,
    scheduleFoldKey: scheduleFoldKey,
    previewButtonKey: previewButtonKey,
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
