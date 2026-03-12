import 'package:cubit_ui_flow/cubit_ui_flow.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../support/extensions/context_extensions.dart';
import '../../../design_system/primitives/app_sizes.dart';
import '../../../design_system/primitives/app_spacings.dart';
import '../../../design_system/primitives/quanitya_palette.dart';
import '../../../design_system/widgets/quanitya/general/quanitya_text_button.dart';
import '../../../design_system/widgets/quanitya/generatable/quanitya_toggle.dart';
import '../../../design_system/widgets/quanitya_confirmation_dialog.dart';
import '../../../data/dao/analytics_inbox_dao.dart';
import '../cubits/analytics_inbox_cubit.dart';
import '../cubits/analytics_inbox_state.dart';
import '../../outbox/widgets/outbox_tab_content.dart';

/// Analytics inbox content — embedded in [NotebookShell] via PostagePage.
class AnalyticsTabContent extends StatelessWidget {
  const AnalyticsTabContent({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AnalyticsInboxCubit, AnalyticsInboxState>(
      builder: (context, state) {
        return OutboxTabContent(
          isEmpty: state.groupedEvents.isEmpty,
          emptyState: OutboxEmptyState(
            icon: Icons.analytics_outlined,
            title: context.l10n.analyticsInboxEmpty,
            description: context.l10n.analyticsInboxEmptyDescription,
          ),
          banner: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              OutboxPrivacyBanner(text: context.l10n.analyticsInboxPrivacyNotice),
              _AutoSendToggle(),
            ],
          ),
          content: _EventList(),
          bottomAction: _BottomActions(),
        );
      },
    );
  }
}

class _AutoSendToggle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AnalyticsInboxCubit, AnalyticsInboxState>(
      builder: (context, state) {
        return Container(
          padding: AppPadding.page,
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: context.colors.textSecondary.withValues(alpha: 0.1),
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.analyticsInboxAutoSend,
                      style: context.text.bodyLarge?.copyWith(
                        color: context.colors.textPrimary,
                      ),
                    ),
                    VSpace.x05,
                    Text(
                      context.l10n.analyticsInboxAutoSendDescription,
                      style: context.text.bodySmall?.copyWith(
                        color: context.colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              QuanityaToggle(
                value: state.autoSendEnabled,
                onChanged: (value) =>
                    context.read<AnalyticsInboxCubit>().toggleAutoSend(value),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _EventList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AnalyticsInboxCubit, AnalyticsInboxState>(
      builder: (context, state) {
        return ListView.separated(
          padding: AppPadding.page,
          itemCount: state.groupedEvents.length,
          separatorBuilder: (_, _) => VSpace.x2,
          itemBuilder: (context, index) {
            final event = state.groupedEvents[index];
            return _EventCard(event: event);
          },
        );
      },
    );
  }
}

class _EventCard extends StatelessWidget {
  final AnalyticsInboxGroupedEntry event;

  const _EventCard({required this.event});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat.yMd().add_jm();

    return Container(
      padding: AppPadding.allDouble,
      decoration: BoxDecoration(
        color: context.colors.textSecondary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
      ),
      child: Row(
        children: [
          Container(
            padding: AppPadding.listItem,
            decoration: BoxDecoration(
              color: context.colors.interactableColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
            ),
            child: Text(
              '${event.count}',
              style: context.text.titleMedium?.copyWith(
                color: context.colors.interactableColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          HSpace.x3,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _formatEventName(event.eventName),
                  style: context.text.bodyLarge?.copyWith(
                    color: context.colors.textPrimary,
                  ),
                ),
                VSpace.x05,
                Text(
                  event.count == 1
                      ? dateFormat.format(event.latestTimestamp.toLocal())
                      : '${dateFormat.format(event.earliestTimestamp.toLocal())} — '
                        '${dateFormat.format(event.latestTimestamp.toLocal())}',
                  style: context.text.bodySmall?.copyWith(
                    color: context.colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatEventName(String name) {
    return name.replaceAll('_', ' ').split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1);
    }).join(' ');
  }
}

class _BottomActions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AnalyticsInboxCubit, AnalyticsInboxState>(
      builder: (context, state) {
        return Container(
          width: double.infinity,
          padding: AppPadding.allDouble,
          decoration: BoxDecoration(
            color: Colors.transparent,
            border: Border(
              top: BorderSide(
                color: context.colors.textSecondary.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Row(
              children: [
                Expanded(
                  child: QuanityaTextButton(
                    text: context.l10n.analyticsInboxClearAll,
                    isDestructive: true,
                    onPressed: () => _confirmClearAll(context),
                  ),
                ),
                HSpace.x3,
                Expanded(
                  child: QuanityaTextButton(
                    text: context.l10n.analyticsInboxSendAll(state.unsentCount),
                    onPressed: state.status == UiFlowStatus.loading
                        ? null
                        : () => _sendAndPromptClear(context),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _sendAndPromptClear(BuildContext context) async {
    final cubit = context.read<AnalyticsInboxCubit>();
    await cubit.sendAll();

    if (!context.mounted) return;

    // Only prompt to clear if send was successful
    final state = cubit.state;
    if (state.status == UiFlowStatus.success &&
        state.lastOperation == AnalyticsInboxOperation.sendAll &&
        state.lastSentCount > 0) {
      QuanityaConfirmationDialog.show(
        context: context,
        title: context.l10n.analyticsInboxClearSentTitle,
        message: context.l10n.analyticsInboxClearSentMessage(state.lastSentCount),
        confirmText: context.l10n.analyticsInboxClearSent,
        onConfirm: () => cubit.clearAll(),
      );
    }
  }

  void _confirmClearAll(BuildContext context) {
    QuanityaConfirmationDialog.show(
      context: context,
      title: context.l10n.analyticsInboxClearAllTitle,
      message: context.l10n.analyticsInboxClearAllMessage,
      confirmText: context.l10n.analyticsInboxClearAll,
      isDestructive: true,
      onConfirm: () => context.read<AnalyticsInboxCubit>().clearAll(),
    );
  }
}
