import 'package:flutter/material.dart';

import '../../../design_system/primitives/app_spacings.dart';
import '../../../design_system/primitives/quanitya_palette.dart';
import '../../../design_system/widgets/quanitya_empty_state.dart';
import '../../../support/extensions/context_extensions.dart';

/// Analysis page for the Results section.
///
/// Receives a [templateId] and displays the analysis pipeline viewer.
/// When no template is selected, shows an empty state.
class ResultsAnalysisPage extends StatelessWidget {
  final String? templateId;

  const ResultsAnalysisPage({super.key, this.templateId});

  @override
  Widget build(BuildContext context) {
    if (templateId == null) {
      return const _EmptyTemplateState(
        message: 'Select an experiment to view analysis',
      );
    }

    return _AnalysisContent(templateId: templateId!);
  }
}

class _AnalysisContent extends StatelessWidget {
  final String templateId;

  const _AnalysisContent({required this.templateId});

  @override
  Widget build(BuildContext context) {
    final palette = QuanityaPalette.primary;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.analytics_outlined,
              size: 64,
              color: palette.textSecondary.withValues(alpha: 0.5),
            ),
            VSpace.x2,
            Text(
              'Analysis Pipeline',
              style: context.text.headlineSmall?.copyWith(
                color: palette.textPrimary,
              ),
            ),
            VSpace.x1,
            Text(
              'Analysis pipelines for this experiment will display here.',
              textAlign: TextAlign.center,
              style: context.text.bodyMedium?.copyWith(
                color: palette.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyTemplateState extends StatelessWidget {
  final String message;
  const _EmptyTemplateState({required this.message});

  @override
  Widget build(BuildContext context) {
    final palette = QuanityaPalette.primary;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const QuanityaEmptyState(size: 80, opacity: 0.2),
          VSpace.x2,
          Text(
            message,
            style: context.text.bodyMedium?.copyWith(
              color: palette.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
