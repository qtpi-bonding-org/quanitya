import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

import '../../../design_system/primitives/app_sizes.dart';
import '../../../design_system/widgets/quanitya_icon_button.dart';
import '../../templates/cubits/list/template_list_cubit.dart';
import '../widgets/template_selector_sheet.dart';
import 'results_analysis_page.dart';
import 'results_graphs_page.dart';

/// Main Results section with two swipeable pages (Graphs and Analysis)
/// and a template selector.
class ResultsSection extends StatefulWidget {
  final ValueChanged<int>? onPageChanged;

  const ResultsSection({super.key, this.onPageChanged});

  @override
  State<ResultsSection> createState() => ResultsSectionState();
}

class ResultsSectionState extends State<ResultsSection> {
  String? _selectedTemplateId;
  final _pageController = PageController();

  void goToPage(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

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
        builder: (innerContext) => Column(
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
                onPageChanged: (i) {
                  widget.onPageChanged?.call(i);
                },
                children: [
                  ResultsGraphsPage(templateId: _selectedTemplateId),
                  ResultsAnalysisPage(templateId: _selectedTemplateId),
                ],
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
