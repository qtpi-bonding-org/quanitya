import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

import '../../../design_system/primitives/app_sizes.dart';
import '../../../design_system/primitives/quanitya_palette.dart';
import '../../../design_system/widgets/quanitya_icon_button.dart';
import '../../../design_system/widgets/swipeable_page_shell.dart';
import '../../../support/extensions/context_extensions.dart';
import '../../templates/cubits/list/template_list_cubit.dart';
import '../widgets/template_selector_sheet.dart';
import 'results_analysis_page.dart';
import 'results_graphs_page.dart';

/// Main Results section with two swipeable pages (Graphs and Analysis)
/// and a template selector.
class ResultsSection extends StatefulWidget {
  const ResultsSection({super.key});

  @override
  State<ResultsSection> createState() => _ResultsSectionState();
}

class _ResultsSectionState extends State<ResultsSection> {
  String? _selectedTemplateId;
  int _currentPageIndex = 0;

  @override
  Widget build(BuildContext context) {
    final palette = QuanityaPalette.primary;
    return BlocProvider(
      create: (_) => GetIt.I<TemplateListCubit>()..load(),
      child: Builder(
        builder: (innerContext) => SwipeablePageShell(
          onPageChanged: (i) => setState(() => _currentPageIndex = i),
          pages: [
            ResultsGraphsPage(templateId: _selectedTemplateId),
            ResultsAnalysisPage(templateId: _selectedTemplateId),
          ],
          labels: [
            Text(
              'Graphs',
              style: context.text.bodySmall?.copyWith(
                fontWeight:
                    _currentPageIndex == 0 ? FontWeight.w900 : FontWeight.w500,
                color: _currentPageIndex == 0
                    ? palette.textPrimary
                    : palette.interactableColor,
              ),
            ),
            Text(
              'Analysis',
              style: context.text.bodySmall?.copyWith(
                fontWeight:
                    _currentPageIndex == 1 ? FontWeight.w900 : FontWeight.w500,
                color: _currentPageIndex == 1
                    ? palette.textPrimary
                    : palette.interactableColor,
              ),
            ),
          ],
          overlays: [
            Positioned(
              top: 0,
              right: 0,
              child: SafeArea(
                child: Padding(
                  padding: EdgeInsets.only(
                    top: AppSizes.space,
                    right: AppSizes.space,
                  ),
                  child: QuanityaIconButton(
                    icon: _selectedTemplateId != null
                        ? Icons.bookmark
                        : Icons.bookmark_outline,
                    onPressed: () => _selectTemplate(innerContext),
                    tooltip: 'Select experiment',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectTemplate(BuildContext context) async {
    final cubit = context.read<TemplateListCubit>();
    final templates = cubit.state.templates
        .map((t) => t.template)
        .toList();

    if (templates.isEmpty) return;

    final selectedId = await TemplateSelectorSheet.show(context, templates);
    if (selectedId != null && mounted) {
      setState(() => _selectedTemplateId = selectedId);
    }
  }
}
