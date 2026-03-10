import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_error_privserver/flutter_error_privserver.dart';
import 'package:get_it/get_it.dart';

import '../../../design_system/primitives/app_sizes.dart';
import '../../../design_system/primitives/quanitya_palette.dart';
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
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const ClampingScrollPhysics(),
                  onPageChanged: (index) => setState(() => _currentIndex = index),
                  children: const [
                    FeedbackTabContent(),
                    AnalyticsTabContent(),
                    ErrorsTabContent(),
                  ],
                ),
              ),
              // Indicator at bottom, in the layout flow
              Padding(
                padding: EdgeInsets.symmetric(vertical: AppSizes.space * 0.25),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _PageLabel(
                      label: l10n.outboxTabFeedback,
                      isActive: _currentIndex == 0,
                      onTap: () => _pageController.animateToPage(0, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut),
                    ),
                    _PageLabel(
                      label: l10n.outboxTabAnalytics,
                      isActive: _currentIndex == 1,
                      onTap: () => _pageController.animateToPage(1, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut),
                    ),
                    _PageLabel(
                      label: l10n.outboxTabErrors,
                      isActive: _currentIndex == 2,
                      onTap: () => _pageController.animateToPage(2, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut),
                    ),
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

class _PageLabel extends StatelessWidget {
  const _PageLabel({
    required this.label,
    required this.isActive,
    this.onTap,
  });

  final String label;
  final bool isActive;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final palette = QuanityaPalette.primary;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: AppSizes.space * 1.5,
          vertical: AppSizes.space * 0.5,
        ),
        child: Text(
          label,
          style: context.text.bodySmall?.copyWith(
            fontWeight: isActive ? FontWeight.w900 : FontWeight.w500,
            color: isActive ? palette.textPrimary : palette.interactableColor,
          ),
        ),
      ),
    );
  }
}
