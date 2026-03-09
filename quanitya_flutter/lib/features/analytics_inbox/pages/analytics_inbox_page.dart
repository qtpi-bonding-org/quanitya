import 'package:cubit_ui_flow/cubit_ui_flow.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/intl.dart';

import '../../../app_router.dart';
import '../../../support/extensions/context_extensions.dart';
import '../../../design_system/primitives/app_sizes.dart';
import '../../../design_system/primitives/app_spacings.dart';
import '../../../design_system/primitives/quanitya_palette.dart';
import '../../../design_system/widgets/quanitya_icon_button.dart';
import '../../../design_system/widgets/quanitya/general/quanitya_text_button.dart';
import '../../../design_system/widgets/quanitya_confirmation_dialog.dart';
import '../../../design_system/widgets/ui_flow_listener.dart';
import '../../../data/dao/analytics_inbox_dao.dart';
import '../cubits/analytics_inbox_cubit.dart';
import '../cubits/analytics_inbox_state.dart';
import '../cubits/analytics_inbox_message_mapper.dart';

/// Analytics Inbox Page - Review and send usage analytics events
///
/// Shows grouped analytics events with counts and timestamps.
/// Users can toggle auto-send, send all, or clear events.
class AnalyticsInboxPage extends StatelessWidget {
  const AnalyticsInboxPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => GetIt.instance<AnalyticsInboxCubit>()..load(),
      child: const _AnalyticsInboxView(),
    );
  }
}

class _AnalyticsInboxView extends StatelessWidget {
  const _AnalyticsInboxView();

  @override
  Widget build(BuildContext context) {
    return UiFlowListener<AnalyticsInboxCubit, AnalyticsInboxState>(
      mapper: GetIt.instance<AnalyticsInboxMessageMapper>(),
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            context.l10n.analyticsInboxTitle,
            style: context.text.headlineMedium,
          ),
          leading: QuanityaIconButton(
            icon: Icons.arrow_back,
            onPressed: () => AppNavigation.back(context),
          ),
        ),
        body: BlocBuilder<AnalyticsInboxCubit, AnalyticsInboxState>(
          builder: (context, state) {
            return Column(
              children: [
                _PrivacyBanner(),
                _AutoSendToggle(),
                Expanded(
                  child: state.groupedEvents.isEmpty
                      ? _EmptyState()
                      : _EventList(),
                ),
                if (state.groupedEvents.isNotEmpty) _BottomActions(),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _PrivacyBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: AppPadding.allDouble,
      decoration: BoxDecoration(
        color: context.colors.infoColor.withValues(alpha: 0.1),
        border: Border(
          bottom: BorderSide(
            color: context.colors.infoColor.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.privacy_tip_outlined,
            size: AppSizes.iconMedium,
            color: context.colors.infoColor,
          ),
          HSpace.x2,
          Expanded(
            child: Text(
              context.l10n.analyticsInboxPrivacyNotice,
              style: context.text.bodySmall?.copyWith(
                color: context.colors.textPrimary,
              ),
            ),
          ),
        ],
      ),
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
              Switch(
                value: state.autoSendEnabled,
                onChanged: (value) =>
                    context.read<AnalyticsInboxCubit>().toggleAutoSend(value),
                activeThumbColor: context.colors.successColor,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: AppPadding.page,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.analytics_outlined,
              size: AppSizes.iconLarge * 2,
              color: context.colors.textSecondary,
            ),
            VSpace.x4,
            Text(
              context.l10n.analyticsInboxEmpty,
              style: context.text.headlineMedium?.copyWith(
                color: context.colors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            VSpace.x2,
            Text(
              context.l10n.analyticsInboxEmptyDescription,
              style: context.text.bodyMedium?.copyWith(
                color: context.colors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
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
            color: context.colors.backgroundPrimary,
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
                        : () => context.read<AnalyticsInboxCubit>().sendAll(),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _confirmClearAll(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => QuanityaConfirmationDialog(
        title: context.l10n.analyticsInboxClearAllTitle,
        message: context.l10n.analyticsInboxClearAllMessage,
        confirmText: context.l10n.analyticsInboxClearAll,
        isDestructive: true,
        onConfirm: () => context.read<AnalyticsInboxCubit>().clearAll(),
      ),
    );
  }
}
