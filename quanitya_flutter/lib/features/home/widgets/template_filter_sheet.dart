import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../design_system/primitives/app_sizes.dart';
import '../../../design_system/primitives/app_spacings.dart';
import 'package:flutter_color_palette/flutter_color_palette.dart';
import '../../../design_system/primitives/quanitya_palette.dart';
import '../../../design_system/widgets/quanitya/general/loose_insert_sheet.dart';
import '../../../support/extensions/context_extensions.dart';
import '../cubits/timeline_data_cubit.dart';
import '../cubits/timeline_data_state.dart';

/// Shows a template filter picker in a LooseInsertSheet.
///
/// Tapping a template applies the filter and closes the sheet.
class TemplateFilterSheet {
  static Future<void> show(
    BuildContext context,
    TimelineDataCubit cubit,
  ) async {
    await LooseInsertSheet.show(
      context: context,
      title: context.l10n.templateFilterHeader,
      builder: (context) => BlocProvider.value(
        value: cubit,
        child: const _TemplateFilterContent(),
      ),
    );
  }
}

class _TemplateFilterContent extends StatelessWidget {
  const _TemplateFilterContent();

  @override
  Widget build(BuildContext context) {
    final palette = QuanityaPalette.primary;

    return BlocBuilder<TimelineDataCubit, TimelineDataState>(
      builder: (context, dataState) {
        final cubit = context.read<TimelineDataCubit>();

        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // "All Templates" option
              _TemplateRow(
                label: context.l10n.allTemplates,
                isSelected: dataState.filters.templateId == null,
                palette: palette,
                onTap: () {
                  cubit.setTemplateFilter(null);
                  Navigator.of(context).pop();
                },
              ),

              Divider(color: palette.textSecondary.withAlpha(51)),

              // Individual templates
              ...dataState.availableTemplates.map((template) {
                return _TemplateRow(
                  label: template.name,
                  isSelected: dataState.filters.templateId == template.id,
                  palette: palette,
                  onTap: () {
                    cubit.setTemplateFilter(template.id);
                    Navigator.of(context).pop();
                  },
                );
              }),
              VSpace.x1,
            ],
          ),
        );
      },
    );
  }
}

class _TemplateRow extends StatelessWidget {
  final String label;
  final bool isSelected;
  final IColorPalette palette;
  final VoidCallback onTap;

  const _TemplateRow({
    required this.label,
    required this.isSelected,
    required this.palette,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
      child: Padding(
        padding: EdgeInsets.symmetric(
          vertical: AppSizes.space,
          horizontal: AppSizes.space * 0.5,
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.check : null,
              size: AppSizes.iconSmall,
              color: palette.interactableColor,
            ),
            HSpace.x1,
            Expanded(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
