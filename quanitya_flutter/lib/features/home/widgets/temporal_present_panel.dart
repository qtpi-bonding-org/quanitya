import 'package:flutter/material.dart';
import '../../../app_router.dart';
import '../../../design_system/primitives/app_sizes.dart';
import '../../../design_system/primitives/app_spacings.dart';
import '../../../design_system/primitives/quanitya_palette.dart';
import '../../../design_system/widgets/quanitya_icon_button.dart';
import '../../../support/extensions/context_extensions.dart';
import '../../templates/widgets/list/template_list_widget.dart';

/// Present Panel - Shows template management interface
///
/// This panel is the main workspace where users manage their tracker templates.
/// It's the "now" - what templates are available for logging.
class TemporalPresentPanel extends StatelessWidget {
  const TemporalPresentPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = QuanityaPalette.primary;

    return Padding(
      padding: AppPadding.pageHorizontal,
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: QuanityaIconButton(
              icon: Icons.assignment_add,
              iconSize: AppSizes.iconMedium,
              color: palette.interactableColor,
              tooltip: context.l10n.createTemplateTitle,
              onPressed: () => AppNavigation.toTemplateDesigner(context),
            ),
          ),
          VSpace.x2,
          const Expanded(child: TemplateListWidget()),
        ],
      ),
    );
  }
}
