import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
  final void Function(double)? onScrollOffsetChanged;

  const TemporalPastPanel({
    super.key,
    this.onScrollOffsetChanged,
  });

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification is ScrollUpdateNotification &&
            notification.metrics.axis == Axis.vertical) {
          onScrollOffsetChanged?.call(notification.metrics.pixels);
        }
        return false;
      },
      child: BlocBuilder<TimelineDataCubit, TimelineDataState>(
        builder: (context, state) {
          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          return TimelineWidget(
            items: state.pastItems,
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
      ),
    );
  }
}