import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:cubit_ui_flow/cubit_ui_flow.dart';

import '../../../design_system/primitives/quanitya_palette.dart';
import '../../../design_system/widgets/swipeable_page_shell.dart';
import '../../../design_system/widgets/ui_flow_listener.dart';
import '../../../support/extensions/context_extensions.dart';
import '../../analytics_inbox/cubits/analytics_inbox_cubit.dart';
import '../../analytics_inbox/cubits/analytics_inbox_state.dart';
import '../../analytics_inbox/cubits/analytics_inbox_message_mapper.dart';
import '../../analytics_inbox/pages/analytics_inbox_page.dart';
import '../../error_reporting/cubits/error_box_cubit.dart';
import '../../error_reporting/cubits/error_box_state.dart';
import '../../error_reporting/cubits/error_box_message_mapper.dart';
import '../../error_reporting/pages/error_box_page.dart';
import '../../notifications/cubits/notification_inbox_cubit.dart';
import '../../notifications/mappers/notification_message_mapper.dart';
import '../../notifications/pages/notification_inbox_page.dart';
import '../../user_feedback/cubits/feedback_cubit.dart';
import '../../user_feedback/cubits/feedback_state.dart';
import '../../user_feedback/mappers/feedback_message_mapper.dart';
import '../../user_feedback/pages/feedback_page.dart';
import '../../../l10n/app_localizations.dart';

/// Unified Postage page with swipeable pages for Notices, Feedback, Analytics, and Errors.
class PostagePage extends StatefulWidget {
  const PostagePage({super.key});

  @override
  State<PostagePage> createState() => _PostagePageState();
}

class _PostagePageState extends State<PostagePage> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final palette = QuanityaPalette.primary;

    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => GetIt.instance<NotificationInboxCubit>()..loadNotifications(),
        ),
        BlocProvider(
          create: (_) => GetIt.instance<FeedbackCubit>(),
        ),
        BlocProvider(
          create: (_) => GetIt.instance<AnalyticsInboxCubit>()..load(),
        ),
        BlocProvider(
          create: (_) => GetIt.instance<ErrorBoxCubit>()..load(),
        ),
      ],
      child: UiFlowStateListener<NotificationInboxCubit, NotificationInboxState>(
        mapper: GetIt.instance<NotificationMessageMapper>(),
        uiService: GetIt.instance<IUiFlowService>(),
        child: UiFlowListener<AnalyticsInboxCubit, AnalyticsInboxState>(
          mapper: GetIt.instance<AnalyticsInboxMessageMapper>(),
          child: UiFlowListener<FeedbackCubit, FeedbackState>(
            mapper: GetIt.instance<FeedbackMessageMapper>(),
            child: UiFlowListener<ErrorBoxCubit, ErrorBoxState>(
              mapper: GetIt.instance<ErrorBoxMessageMapper>(),
              child: SwipeablePageShell(
                onPageChanged: (index) => setState(() => _currentIndex = index),
                pages: const [
                  NotificationInboxContent(),
                  FeedbackTabContent(),
                  AnalyticsTabContent(),
                  ErrorsTabContent(),
                ],
                labels: [
                  Text(
                    l10n.postageTabNotices,
                    style: context.text.bodySmall?.copyWith(
                      fontWeight: _currentIndex == 0 ? FontWeight.w900 : FontWeight.w500,
                      color: _currentIndex == 0 ? palette.textPrimary : palette.interactableColor,
                    ),
                  ),
                  Text(
                    l10n.outboxTabFeedback,
                    style: context.text.bodySmall?.copyWith(
                      fontWeight: _currentIndex == 1 ? FontWeight.w900 : FontWeight.w500,
                      color: _currentIndex == 1 ? palette.textPrimary : palette.interactableColor,
                    ),
                  ),
                  Text(
                    l10n.outboxTabAnalytics,
                    style: context.text.bodySmall?.copyWith(
                      fontWeight: _currentIndex == 2 ? FontWeight.w900 : FontWeight.w500,
                      color: _currentIndex == 2 ? palette.textPrimary : palette.interactableColor,
                    ),
                  ),
                  Text(
                    l10n.outboxTabErrors,
                    style: context.text.bodySmall?.copyWith(
                      fontWeight: _currentIndex == 3 ? FontWeight.w900 : FontWeight.w500,
                      color: _currentIndex == 3 ? palette.textPrimary : palette.interactableColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
