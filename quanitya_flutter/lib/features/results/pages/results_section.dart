import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

import '../../../design_system/primitives/quanitya_palette.dart';
import '../../../design_system/widgets/swipeable_page_shell.dart';
import '../../../support/extensions/context_extensions.dart';
import '../cubits/results_list_cubit.dart';
import 'results_analysis_page.dart';
import 'results_graphs_page.dart';

/// Main Results section with two swipeable pages (Graphs and Analysis).
class ResultsSection extends StatefulWidget {
  const ResultsSection({super.key});

  @override
  State<ResultsSection> createState() => _ResultsSectionState();
}

class _ResultsSectionState extends State<ResultsSection> {
  int _currentPageIndex = 0;

  @override
  Widget build(BuildContext context) {
    final palette = QuanityaPalette.primary;
    return BlocProvider(
      create: (_) => GetIt.I<ResultsListCubit>()..load(),
      child: SwipeablePageShell(
        onPageChanged: (i) => setState(() => _currentPageIndex = i),
        pages: const [
          ResultsGraphsPage(),
          ResultsAnalysisPage(),
        ],
        labels: [
          Text(
            context.l10n.resultsTabGraphs,
            style: context.text.bodySmall?.copyWith(
              fontWeight:
                  _currentPageIndex == 0 ? FontWeight.w900 : FontWeight.w500,
              color: _currentPageIndex == 0
                  ? palette.textPrimary
                  : palette.interactableColor,
            ),
          ),
          Text(
            context.l10n.resultsTabAnalysis,
            style: context.text.bodySmall?.copyWith(
              fontWeight:
                  _currentPageIndex == 1 ? FontWeight.w900 : FontWeight.w500,
              color: _currentPageIndex == 1
                  ? palette.textPrimary
                  : palette.interactableColor,
            ),
          ),
        ],
      ),
    );
  }
}
