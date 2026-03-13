import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../hidden_visibility/cubits/hidden_visibility_cubit.dart';
import '../../log_entry/widgets/log_entry_sheet.dart';
import '../../../design_system/primitives/app_sizes.dart';
import '../../../support/extensions/context_extensions.dart';
import '../cubits/timeline_data_cubit.dart';
import '../cubits/timeline_data_state.dart';
import 'timeline_widget.dart';

/// Past Panel - Shows completed log entries in timeline format
///
/// This panel displays historical data that users have already logged.
/// Uses TimelineDataCubit to fetch and filter past entries.
class TemporalPastPanel extends StatelessWidget {
  const TemporalPastPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TimelineDataCubit, TimelineDataState>(
        builder: (context, state) {
          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          // Filter by HiddenVisibilityCubit
          final showHidden = context.watch<HiddenVisibilityCubit>().state.showingHidden;
          final items = showHidden
              ? state.pastItems
              : _filterVisibleItems(state.pastItems);

          return TimelineWidget(
            items: items,
            emptyMessage: context.l10n.homePastDescription,
            padding: EdgeInsets.only(
              top: AppSizes.space * 7.5,
              bottom: AppSizes.space * 12.5,
              left: AppSizes.space * 2,
              right: AppSizes.space * 2,
            ),
            onItemTap: (item) {
              item.whenOrNull(
                entry: (entryWithContext, _, _, _, _, _, _, _, _) {
                  LogEntrySheet.showView(
                    context: context,
                    entryWithContext: entryWithContext,
                  );
                },
              );
            },
          );
        },
      );
  }

  /// Filters out entries whose templates are hidden. Keeps date dividers.
  List<TimelineItem> _filterVisibleItems(List<TimelineItem> items) {
    return items.where((item) {
      if (item is TimelineEntryItem) {
        return item.entryWithContext.template.isHidden == false;
      }
      return true; // Keep date dividers
    }).toList();
  }
}
