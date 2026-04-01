import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

import '../../../design_system/primitives/quanitya_palette.dart';
import '../../../design_system/widgets/swipeable_page_shell.dart';
import '../../../design_system/widgets/ui_flow_listener.dart';
import '../../../support/extensions/context_extensions.dart';
import '../../analytics/cubits/analytics_cubit.dart';
import '../../analytics/cubits/analytics_state.dart';
import '../../analytics/cubits/analytics_message_mapper.dart';
import '../../analytics/pages/analytics_page.dart';
import '../../errors/cubits/errors_cubit.dart';
import '../../errors/cubits/errors_state.dart';
import '../../errors/cubits/errors_message_mapper.dart';
import '../../errors/pages/errors_page.dart';
import '../../notices/cubits/notices_cubit.dart';
import '../../notices/mappers/notices_message_mapper.dart';
import '../../notices/pages/notices_page.dart';
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

    // NoticesCubit and ErrorsCubit are provided by NotebookShell
    // (shared with the tab bar for incoming/outgoing indicators).
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => GetIt.instance<FeedbackCubit>(),
        ),
        BlocProvider(
          create: (_) => GetIt.instance<AnalyticsCubit>()..load(),
        ),
      ],
      child: UiFlowListener<NoticesCubit, NoticesState>(
        mapper: context.read<NoticesMessageMapper>(),
        child: UiFlowListener<AnalyticsCubit, AnalyticsState>(
          mapper: context.read<AnalyticsMessageMapper>(),
          child: UiFlowListener<FeedbackCubit, FeedbackState>(
            mapper: context.read<FeedbackMessageMapper>(),
            child: UiFlowListener<ErrorsCubit, ErrorsState>(
              mapper: context.read<ErrorsMessageMapper>(),
              child: SwipeablePageShell(
                onPageChanged: (index) => setState(() => _currentIndex = index),
                pages: const [
                  NoticesTabContent(),
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
