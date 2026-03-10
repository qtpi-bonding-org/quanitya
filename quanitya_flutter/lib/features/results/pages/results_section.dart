import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

import '../../../design_system/primitives/app_spacings.dart';
import '../../../design_system/primitives/app_sizes.dart';
import '../../../design_system/primitives/quanitya_palette.dart';
import '../../../design_system/widgets/quanitya_icon_button.dart';
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
  final _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => GetIt.I<TemplateListCubit>()..load(),
      child: Column(
        children: [
          // Header with page indicator and template selector
          SafeArea(
            bottom: false,
            child: Padding(
              padding: EdgeInsets.all(AppSizes.space),
              child: Row(
                children: [
                  _PageLabel(
                    label: 'Graphs',
                    isActive: _currentPageIndex == 0,
                    onTap: () => _pageController.animateToPage(
                      0,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    ),
                  ),
                  HSpace.x2,
                  _PageLabel(
                    label: 'Analysis',
                    isActive: _currentPageIndex == 1,
                    onTap: () => _pageController.animateToPage(
                      1,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    ),
                  ),
                  const Spacer(),
                  QuanityaIconButton(
                    icon: _selectedTemplateId != null
                        ? Icons.bookmark
                        : Icons.bookmark_outline,
                    onPressed: () => _selectTemplate(context),
                    tooltip: 'Select experiment',
                  ),
                ],
              ),
            ),
          ),
          // Swipeable pages
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const ClampingScrollPhysics(),
              onPageChanged: (i) => setState(() => _currentPageIndex = i),
              children: [
                ResultsGraphsPage(templateId: _selectedTemplateId),
                ResultsAnalysisPage(templateId: _selectedTemplateId),
              ],
            ),
          ),
        ],
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

class _PageLabel extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback? onTap;

  const _PageLabel({
    required this.label,
    required this.isActive,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final palette = QuanityaPalette.primary;
    return GestureDetector(
      onTap: onTap,
      child: Text(
        label,
        style: context.text.titleMedium?.copyWith(
          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          color: isActive ? palette.textPrimary : palette.textSecondary,
        ),
      ),
    );
  }
}
