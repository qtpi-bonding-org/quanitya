import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:cubit_ui_flow/cubit_ui_flow.dart';

import '../../../app_router.dart';
import '../../../support/extensions/context_extensions.dart';
import '../../../design_system/primitives/app_spacings.dart';
import '../../../design_system/widgets/quanitya_icon_button.dart';
import '../../../design_system/widgets/quanitya/general/quanitya_text_button.dart';
import '../../outbox/widgets/outbox_tab_content.dart';
import '../cubits/notification_inbox_cubit.dart';
import '../mappers/notification_message_mapper.dart';
import '../widgets/notification_card.dart';

/// The standalone page with Scaffold — used for deep-link / push navigation.
class NotificationInboxPage extends StatelessWidget {
  const NotificationInboxPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => GetIt.instance<NotificationInboxCubit>()..loadNotifications(),
      child: UiFlowStateListener<NotificationInboxCubit, NotificationInboxState>(
        mapper: GetIt.instance<NotificationMessageMapper>(),
        uiService: GetIt.instance<IUiFlowService>(),
        child: Scaffold(
          appBar: AppBar(
            title: Text(context.l10n.notificationsTitle, style: context.text.headlineMedium),
            leading: QuanityaIconButton(
              icon: Icons.arrow_back,
              onPressed: () => AppNavigation.back(context),
            ),
          ),
          body: const NotificationInboxContent(),
        ),
      ),
    );
  }
}

/// The content body, usable standalone or embedded in [NotebookShell].
///
/// Expects [NotificationInboxCubit] to be available via [BlocProvider] above.
class NotificationInboxContent extends StatelessWidget {
  const NotificationInboxContent({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NotificationInboxCubit, NotificationInboxState>(
      builder: (context, state) {
        return OutboxTabContent(
          isEmpty: state.notifications.isEmpty,
          emptyState: OutboxEmptyState(
            icon: Icons.notifications_none,
            title: context.l10n.noticesEmpty,
            description: context.l10n.noticesEmptyDescription,
          ),
          content: ListView.separated(
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
          ),
          bottomAction: state.notifications.isNotEmpty
              ? const _MarkAllAction()
              : null,
        );
      },
    );
  }
}

class _MarkAllAction extends StatelessWidget {
  const _MarkAllAction();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: AppPadding.page,
      child: Align(
        alignment: Alignment.centerRight,
        child: QuanityaTextButton(
          text: context.l10n.notificationsMarkAll,
          onPressed: () => context.read<NotificationInboxCubit>().markAllAsReceived(),
        ),
      ),
    );
  }
}
