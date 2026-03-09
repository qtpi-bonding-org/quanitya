import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:cubit_ui_flow/cubit_ui_flow.dart';

import '../../../app_router.dart';
import '../../../support/extensions/context_extensions.dart';
import '../../../design_system/primitives/app_spacings.dart';
import '../../../design_system/primitives/quanitya_palette.dart';
import '../../../design_system/widgets/quanitya_icon_button.dart';
import '../cubits/notification_inbox_cubit.dart';
import '../mappers/notification_message_mapper.dart';
import '../widgets/notification_card.dart';

class NotificationInboxPage extends StatelessWidget {
  const NotificationInboxPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => GetIt.instance<NotificationInboxCubit>()..loadNotifications(),
      child: UiFlowStateListener<NotificationInboxCubit, NotificationInboxState>(
        mapper: GetIt.instance<NotificationMessageMapper>(),
        uiService: GetIt.instance<IUiFlowService>(),
        child: const _NotificationInboxView(),
      ),
    );
  }
}

class _NotificationInboxView extends StatelessWidget {
  const _NotificationInboxView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.notificationsTitle, style: context.text.headlineMedium),
        leading: QuanityaIconButton(
          icon: Icons.arrow_back,
          onPressed: () => AppNavigation.back(context),
        ),
        actions: [
          BlocBuilder<NotificationInboxCubit, NotificationInboxState>(
            builder: (context, state) {
              if (state.notifications.isEmpty) return const SizedBox.shrink();
              return TextButton(
                onPressed: () => context.read<NotificationInboxCubit>().markAllAsReceived(),
                child: Text(context.l10n.notificationsMarkAll),
              );
            },
          ),
        ],
      ),
      body: BlocBuilder<NotificationInboxCubit, NotificationInboxState>(
        builder: (context, state) {
          if (state.notifications.isEmpty) {
            return _EmptyState();
          }

          return ListView.separated(
            padding: AppPadding.page,
            itemCount: state.notifications.length,
            separatorBuilder: (context, index) => VSpace.x3,
            itemBuilder: (context, index) {
              final notification = state.notifications[index];
              return NotificationCard(
                notification: notification,
                onMark: () => context.read<NotificationInboxCubit>()
                  .markAsReceived(notification.id),
                onDismiss: () => context.read<NotificationInboxCubit>()
                  .dismiss(notification.id),
              );
            },
          );
        },
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_none, size: 64, color: context.colors.textPrimary.withValues(alpha: 0.5)),
          VSpace.x4,
          Text(context.l10n.notificationsEmpty, style: context.text.headlineMedium),
          VSpace.x2,
          Text(context.l10n.notificationsCaughtUp, style: context.text.bodyMedium),
        ],
      ),
    );
  }
}
