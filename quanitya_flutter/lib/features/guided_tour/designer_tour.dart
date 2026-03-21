import 'package:flutter/material.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

import '../../support/extensions/context_extensions.dart';

List<TargetFocus> _buildDesignerTourTargets({
  required GlobalKey aiPromptKey,
  required GlobalKey nameFieldKey,
  required GlobalKey fieldsSectionKey,
  required GlobalKey scheduleFoldKey,
  required GlobalKey previewButtonKey,
  required BuildContext context,
}) {
  return [
    TargetFocus(
      identify: 'ai_prompt',
      keyTarget: aiPromptKey,
      contents: [
        TargetContent(
          align: ContentAlign.bottom,
          child: Text(
            context.l10n.tourDesignerAiPrompt,
            style: context.text.bodyMedium?.copyWith(
              color: Colors.white,
            ),
          ),
        ),
      ],
      shape: ShapeLightFocus.RRect,
    ),
    TargetFocus(
      identify: 'name_field',
      keyTarget: nameFieldKey,
      contents: [
        TargetContent(
          align: ContentAlign.bottom,
          child: Text(
            context.l10n.tourDesignerNameField,
            style: context.text.bodyMedium?.copyWith(
              color: Colors.white,
            ),
          ),
        ),
      ],
      shape: ShapeLightFocus.RRect,
    ),
    TargetFocus(
      identify: 'fields_section',
      keyTarget: fieldsSectionKey,
      contents: [
        TargetContent(
          align: ContentAlign.bottom,
          child: Text(
            context.l10n.tourDesignerFields,
            style: context.text.bodyMedium?.copyWith(
              color: Colors.white,
            ),
          ),
        ),
      ],
      shape: ShapeLightFocus.RRect,
    ),
    TargetFocus(
      identify: 'schedule_fold',
      keyTarget: scheduleFoldKey,
      contents: [
        TargetContent(
          align: ContentAlign.top,
          child: Text(
            context.l10n.tourDesignerSchedule,
            style: context.text.bodyMedium?.copyWith(
              color: Colors.white,
            ),
          ),
        ),
      ],
      shape: ShapeLightFocus.RRect,
    ),
    TargetFocus(
      identify: 'preview_button',
      keyTarget: previewButtonKey,
      contents: [
        TargetContent(
          align: ContentAlign.top,
          child: Text(
            context.l10n.tourDesignerPreview,
            style: context.text.bodyMedium?.copyWith(
              color: Colors.white,
            ),
          ),
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
  ).show(context: context);
}
