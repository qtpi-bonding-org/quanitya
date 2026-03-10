import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_error_privserver/flutter_error_privserver.dart';
import 'package:get_it/get_it.dart';

import '../../../design_system/widgets/ui_flow_listener.dart';
import '../../analytics_inbox/cubits/analytics_inbox_cubit.dart';
import '../../analytics_inbox/cubits/analytics_inbox_state.dart';
import '../../analytics_inbox/cubits/analytics_inbox_message_mapper.dart';
import '../../analytics_inbox/pages/analytics_inbox_page.dart';
import '../../error_reporting/pages/error_box_page.dart';
import '../../user_feedback/cubits/feedback_cubit.dart';
import '../../user_feedback/cubits/feedback_state.dart';
import '../../user_feedback/mappers/feedback_message_mapper.dart';
import '../../user_feedback/pages/feedback_page.dart';

/// Unified Outbox page with swipeable pages for Feedback, Analytics, and Errors.
class OutboxPage extends StatefulWidget {
  final ValueChanged<int>? onPageChanged;

  const OutboxPage({super.key, this.onPageChanged});

  @override
  State<OutboxPage> createState() => OutboxPageState();
}

class OutboxPageState extends State<OutboxPage> {
  final PageController _pageController = PageController();

  void goToPage(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
          child: PageView(
            controller: _pageController,
            physics: const ClampingScrollPhysics(),
            onPageChanged: (index) {
              widget.onPageChanged?.call(index);
            },
            children: const [
              FeedbackTabContent(),
              AnalyticsTabContent(),
              ErrorsTabContent(),
            ],
          ),
        ),
      ),
    );
  }
}
