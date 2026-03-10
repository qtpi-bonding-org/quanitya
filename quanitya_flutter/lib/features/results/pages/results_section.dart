import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

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
      child: Builder(
        builder: (innerContext) => Stack(
          children: [
            // Page content with top bookmark selector
            Column(
              children: [
                // Bookmark selector at top
                SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: EdgeInsets.only(
                      top: AppSizes.space,
                      right: AppSizes.space,
                    ),
                    child: Align(
                      alignment: Alignment.topRight,
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
            // Page indicator at bottom
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: AppSizes.space * 0.25),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _PageLabel(
                      label: 'Graphs',
                      isActive: _currentPageIndex == 0,
                      onTap: () => _pageController.animateToPage(0,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut),
                    ),
                    _PageLabel(
                      label: 'Analysis',
                      isActive: _currentPageIndex == 1,
                      onTap: () => _pageController.animateToPage(1,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut),
                    ),
                  ],
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
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: AppSizes.space * 1.5,
          vertical: AppSizes.space,
        ),
        child: Text(
          label,
          style: context.text.bodySmall?.copyWith(
            fontWeight: isActive ? FontWeight.w900 : FontWeight.w500,
            color: isActive ? palette.textPrimary : palette.interactableColor,
          ),
        ),
      ),
    );
  }
}
