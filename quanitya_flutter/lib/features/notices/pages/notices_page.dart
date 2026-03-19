import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../support/extensions/context_extensions.dart';
import '../../../design_system/primitives/app_sizes.dart';
import '../../../design_system/primitives/app_spacings.dart';
import '../../../design_system/widgets/quanitya/general/quanitya_text_button.dart';
import '../../postage/widgets/postage_tab_content.dart';
import '../cubits/notices_cubit.dart';
import '../widgets/notice_card.dart';

/// The content body, embedded in [NotebookShell] via PostagePage.
///
/// Expects [NoticesCubit] to be available via [BlocProvider] above.
class NoticesTabContent extends StatelessWidget {
  const NoticesTabContent({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NoticesCubit, NoticesState>(
      builder: (context, state) {
        return PostageTabContent(
          isEmpty: state.notifications.isEmpty,
          emptyState: PostageEmptyState(
            icon: Icons.notifications_none,
            title: context.l10n.noticesEmpty,
            description: context.l10n.noticesEmptyDescription,
          ),
          content: ListView.separated(
            padding: AppPadding.page.copyWith(bottom: AppSizes.space * 12.5),
            itemCount: state.notifications.length,
            separatorBuilder: (context, index) => VSpace.x3,
            itemBuilder: (context, index) {
              final notification = state.notifications[index];
              return NoticeCard(
                notification: notification,
                onMark: () => context.read<NoticesCubit>()
                    .markAsReceived(notification.id),
                onDismiss: () => context.read<NoticesCubit>()
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
          onPressed: () => context.read<NoticesCubit>().markAllAsReceived(),
        ),
      ),
    );
  }
}
