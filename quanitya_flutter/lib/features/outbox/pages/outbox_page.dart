import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_error_privserver/flutter_error_privserver.dart';
import 'package:get_it/get_it.dart';

import '../../../design_system/primitives/app_sizes.dart';
import '../../../design_system/widgets/ui_flow_listener.dart';
import '../../../support/extensions/context_extensions.dart';
import '../../analytics_inbox/cubits/analytics_inbox_cubit.dart';
import '../../analytics_inbox/cubits/analytics_inbox_state.dart';
import '../../analytics_inbox/cubits/analytics_inbox_message_mapper.dart';
import '../../analytics_inbox/pages/analytics_inbox_page.dart';
import '../../error_reporting/pages/error_box_page.dart';
import '../../user_feedback/cubits/feedback_cubit.dart';
import '../../user_feedback/cubits/feedback_state.dart';
import '../../user_feedback/mappers/feedback_message_mapper.dart';
import '../../user_feedback/pages/feedback_page.dart';
import '../../../l10n/app_localizations.dart';

/// Unified Outbox page with swipeable pages for Feedback, Analytics, and Errors.
class OutboxPage extends StatefulWidget {
  const OutboxPage({super.key});

  @override
  State<OutboxPage> createState() => _OutboxPageState();
}

class _OutboxPageState extends State<OutboxPage> {
  int _currentIndex = 0;
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => GetIt.instance<FeedbackCubit>(),
        ),
        BlocProvider(
          create: (_) => GetIt.instance<AnalyticsInboxCubit>()..load(),
        ),
        BlocProvider(
          create: (_) => GetIt.instance<ErrorBoxPageCubit>()..loadErrors(),
        ),
      ],
      child: UiFlowListener<AnalyticsInboxCubit, AnalyticsInboxState>(
        mapper: GetIt.instance<AnalyticsInboxMessageMapper>(),
        child: UiFlowListener<FeedbackCubit, FeedbackState>(
          mapper: GetIt.instance<FeedbackMessageMapper>(),
          child: Column(
            children: [
              SafeArea(
                bottom: false,
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSizes.space),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _PageDot(
                        label: l10n.outboxTabFeedback,
                        isActive: _currentIndex == 0,
                      ),
                      _PageDot(
                        label: l10n.outboxTabAnalytics,
                        isActive: _currentIndex == 1,
                      ),
                      _PageDot(
                        label: l10n.outboxTabErrors,
                        isActive: _currentIndex == 2,
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const ClampingScrollPhysics(),
                  onPageChanged: (index) =>
                      setState(() => _currentIndex = index),
                  children: const [
                    FeedbackTabContent(),
                    AnalyticsTabContent(),
                    ErrorsTabContent(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PageDot extends StatelessWidget {
  const _PageDot({
    required this.label,
    required this.isActive,
  });

  final String label;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Text(
        label,
        style: context.text.bodySmall?.copyWith(
          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          color: isActive
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
        ),
      ),
    );
  }
}
