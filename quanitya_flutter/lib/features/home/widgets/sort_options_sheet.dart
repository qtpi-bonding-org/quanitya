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

/// Shows sort and time-range options in a LooseInsertSheet.
///
/// The sheet stays open so the user can tap multiple options;
/// changes apply immediately via the cubit.
class SortOptionsSheet {
  static Future<void> show(
    BuildContext context,
    TimelineDataCubit cubit,
  ) async {
    await LooseInsertSheet.show(
      context: context,
      title: context.l10n.tooltipSortAndTime,
      builder: (context) => BlocProvider.value(
        value: cubit,
        child: const _SortOptionsContent(),
      ),
    );
  }
}

class _SortOptionsContent extends StatelessWidget {
  const _SortOptionsContent();

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
              // ── Direction ────────────────────────────────────────────
              _OptionRow(
                label: dataState.pastSort.ascending
                    ? context.l10n.sortOldestFirst
                    : context.l10n.sortNewestFirst,
                icon: dataState.pastSort.ascending
                    ? Icons.arrow_upward
                    : Icons.arrow_downward,
                isSelected: false,
                palette: palette,
                onTap: () => cubit.togglePastSort(),
              ),

              Divider(color: palette.textSecondary.withAlpha(51)),

              // ── Time range ───────────────────────────────────────────
              _SectionHeader(label: context.l10n.timeRangeHeader),
              ...TimelineTimeRange.values.map((range) {
                String label = _getTimeRangeLabel(context, range);
                if (range == TimelineTimeRange.custom &&
                    dataState.filters.customStartDate != null) {
                  final start = dataState.filters.customStartDate!;
                  final end = dataState.filters.customEndDate ?? start;
                  label =
                      '${start.month}/${start.day} - ${end.month}/${end.day}';
                }

                return _OptionRow(
                  label: label,
                  isSelected: dataState.filters.timeRange == range,
                  palette: palette,
                  onTap: () async {
                    if (range == TimelineTimeRange.custom) {
                      final picked = await showDateRangePicker(
                        context: context,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2030),
                        initialDateRange:
                            dataState.filters.customStartDate != null &&
                                    dataState.filters.customEndDate != null
                                ? DateTimeRange(
                                    start: dataState.filters.customStartDate!,
                                    end: dataState.filters.customEndDate!,
                                  )
                                : null,
                      );
                      if (picked != null) {
                        cubit.setTimeRange(
                          TimelineTimeRange.custom,
                          start: picked.start,
                          end: picked.end,
                        );
                      }
                    } else {
                      cubit.setTimeRange(range);
                    }
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

  String _getTimeRangeLabel(BuildContext context, TimelineTimeRange range) {
    return switch (range) {
      TimelineTimeRange.all => context.l10n.timeRangeAll,
      TimelineTimeRange.today => context.l10n.timeRangeToday,
      TimelineTimeRange.week => context.l10n.timeRangeWeek,
      TimelineTimeRange.month => context.l10n.timeRangeMonth,
      TimelineTimeRange.custom => context.l10n.timeRangeCustom,
    };
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Private helper widgets
// ─────────────────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    final palette = QuanityaPalette.primary;
    return Padding(
      padding: EdgeInsets.only(
        top: AppSizes.space,
        bottom: AppSizes.space * 0.5,
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: AppSizes.fontMini,
          fontWeight: FontWeight.bold,
          color: palette.textPrimary,
        ),
      ),
    );
  }
}

class _OptionRow extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool isSelected;
  final IColorPalette palette;
  final VoidCallback onTap;

  const _OptionRow({
    required this.label,
    this.icon,
    required this.isSelected,
    required this.palette,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: isSelected,
      label: label,
      child: InkWell(
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
                icon ?? (isSelected ? Icons.check : null),
                size: AppSizes.iconSmall,
                color: palette.interactableColor,
              ),
              HSpace.x1,
              Expanded(child: Text(label)),
            ],
          ),
        ),
      ),
    );
  }
}
