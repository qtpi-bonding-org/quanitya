import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:quanitya_flutter/design_system/primitives/quanitya_date_format.dart';

import '../../../design_system/primitives/app_spacings.dart';
import '../../../design_system/primitives/quanitya_palette.dart';
import '../../../design_system/widgets/quanitya/general/notebook_fold.dart';
import '../../../design_system/widgets/template_icon_bubble.dart';
import '../../../support/extensions/context_extensions.dart';
import '../../visualization/cubits/visualization_cubit.dart';
import '../cubits/results_list_cubit.dart';

/// Shared fold widget for Results pages. Lazily creates a [VisualizationCubit]
/// on first expand and provides it to [bodyBuilder].
class ResultsTemplateFold extends StatefulWidget {
  final ResultsTemplateItem item;
  final Widget Function() bodyBuilder;

  const ResultsTemplateFold({
    super.key,
    required this.item,
    required this.bodyBuilder,
  });

  @override
  State<ResultsTemplateFold> createState() => _ResultsTemplateFoldState();
}

class _ResultsTemplateFoldState extends State<ResultsTemplateFold> {
  VisualizationCubit? _cubit;

  void _onExpansionChanged(bool expanded) {
    if (expanded) {
      _cubit ??= GetIt.I<VisualizationCubit>();
      _cubit!.loadForTemplate(widget.item.templateId);
      setState(() {});
    }
  }

  @override
  void dispose() {
    _cubit?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = QuanityaPalette.primary;

    return NotebookFold(
      onExpansionChanged: _onExpansionChanged,
      semanticLabel: widget.item.templateName,
      header: Row(
        children: [
          TemplateIconBubble(
            iconString: widget.item.icon,
            emoji: widget.item.emoji,
            accentColorHex: widget.item.accentColorHex,
            isHidden: widget.item.isHidden,
          ),
          HSpace.x2,
          Expanded(
            child: Text(
              widget.item.templateName,
              style: context.text.titleMedium?.copyWith(
                color: palette.textPrimary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          HSpace.x2,
          if (widget.item.lastLoggedAt != null) ...[
            Text(
              QuanityaDateFormat.monthDayCompact(widget.item.lastLoggedAt!),
              style: context.text.bodyMedium
                  ?.copyWith(color: palette.textSecondary),
            ),
            HSpace.x1,
          ],
          Text(
            '(${widget.item.entryCount})',
            style:
                context.text.bodyMedium?.copyWith(color: palette.textSecondary),
          ),
        ],
      ),
      child: _cubit == null
          ? const SizedBox.shrink()
          : BlocProvider.value(
              value: _cubit!,
              child: widget.bodyBuilder(),
            ),
    );
  }
}
