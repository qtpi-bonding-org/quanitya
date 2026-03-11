import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../design_system/primitives/app_sizes.dart';
import '../../../design_system/widgets/ui_flow_listener.dart';
import '../../../support/extensions/context_extensions.dart';
import '../../schedules/cubits/schedule_list_cubit.dart';
import '../../schedules/cubits/schedule_list_state.dart';
import '../../schedules/cubits/schedule_list_message_mapper.dart';
import '../../schedules/widgets/schedule_list_widget.dart';
import '../../log_entry/widgets/log_entry_sheet.dart';
import '../../../app/bootstrap.dart';

/// Future Panel - Shows scheduled reminders and upcoming tasks
/// 
/// This panel displays schedules/reminders that users have set up.
/// It shows WHAT needs to be done and WHEN, not completed entries.
/// Uses ScheduleListCubit to manage schedule data.
class TemporalFuturePanel extends StatelessWidget {
  final void Function(double)? onScrollOffsetChanged;

  const TemporalFuturePanel({
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
      child: UiFlowListener<ScheduleListCubit, ScheduleListState>(
        mapper: getIt<ScheduleListMessageMapper>(),
        child: BlocBuilder<ScheduleListCubit, ScheduleListState>(
          builder: (context, state) {
            if (state.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            return ScheduleListWidget(
              emptyMessage: context.l10n.homeFutureDescription,
              padding: EdgeInsets.only(
                top: AppSizes.space * 7.5,
                bottom: AppSizes.space * 12.5,
                left: AppSizes.space * 2,
                right: AppSizes.space * 2,
              ),
              onItemTap: (schedule) {
                LogEntrySheet.showCreate(
                  context: context,
                  templateId: schedule.template.id,
                );
              },
            );
          },
        ),
      ),
    );
  }
}