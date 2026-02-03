import 'package:flutter/material.dart';
import '../../../design_system/primitives/app_spacings.dart';
import '../../templates/widgets/list/template_list_widget.dart';

/// Present Panel - Shows template management interface
/// 
/// This panel is the main workspace where users manage their tracker templates.
/// It's the "now" - what templates are available for logging.
class TemporalPresentPanel extends StatelessWidget {
  const TemporalPresentPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: AppPadding.pageHorizontal,
      child: const TemplateListWidget(),
    );
  }
}