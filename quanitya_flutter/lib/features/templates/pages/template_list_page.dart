import 'package:flutter/material.dart';

import '../../../app_router.dart';
import '../../../support/extensions/context_extensions.dart';
import '../../../design_system/widgets/quanitya_icon_button.dart';
import '../widgets/list/template_list_widget.dart';

/// Standalone page for browsing all templates.
///
/// Wraps [TemplateListWidget] (which handles state, grid, and empty state)
/// in a proper page scaffold with AppBar navigation.
class TemplateListPage extends StatelessWidget {
  const TemplateListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Templates',
          style: context.text.headlineMedium,
        ),
        leading: QuanityaIconButton(
          icon: Icons.arrow_back,
          onPressed: () => AppNavigation.back(context),
        ),
      ),
      body: const TemplateListWidget(),
    );
  }
}
