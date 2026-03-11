import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:cubit_ui_flow/cubit_ui_flow.dart';

import '../../../design_system/primitives/app_sizes.dart';
import '../../../design_system/primitives/quanitya_palette.dart';
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
              child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  Expanded(
                    child: PageView(
                      controller: _pageController,
                      physics: const ClampingScrollPhysics(),
                      onPageChanged: (index) => setState(() => _currentIndex = index),
                      children: const [
                        NotificationInboxContent(),
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
                          label: l10n.postageTabNotices,
                          isActive: _currentIndex == 0,
                          onTap: () => _pageController.animateToPage(0, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut),
                        ),
                        _PageLabel(
                          label: l10n.outboxTabFeedback,
                          isActive: _currentIndex == 1,
                          onTap: () => _pageController.animateToPage(1, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut),
                        ),
                        _PageLabel(
                          label: l10n.outboxTabAnalytics,
                          isActive: _currentIndex == 2,
                          onTap: () => _pageController.animateToPage(2, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut),
                        ),
                        _PageLabel(
                          label: l10n.outboxTabErrors,
                          isActive: _currentIndex == 3,
                          onTap: () => _pageController.animateToPage(3, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            ),
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
