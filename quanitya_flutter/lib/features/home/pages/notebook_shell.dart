import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:cubit_ui_flow/cubit_ui_flow.dart';

import '../../../design_system/primitives/app_sizes.dart';
import '../../../design_system/primitives/quanitya_palette.dart';
import '../../../support/extensions/context_extensions.dart';
import '../../notifications/cubits/notification_inbox_cubit.dart';
import '../../notifications/mappers/notification_message_mapper.dart';
import '../../notifications/pages/notification_inbox_page.dart';
import '../../outbox/pages/outbox_page.dart';
import '../../outbox/widgets/folder_tab_bar.dart';
import '../../settings/cubits/data_export/data_export_cubit.dart';
import '../../settings/cubits/recovery_key/recovery_key_cubit.dart';
import '../../settings/cubits/device_management/device_management_cubit.dart';
import '../../settings/cubits/webhook/webhook_cubit.dart';
import '../../app_operating_mode/cubits/app_operating_cubit.dart';
import '../../results/pages/results_section.dart';
import '../../settings/pages/settings_page.dart';
import 'temporal_home_page.dart';

/// Root-level shell that wraps all five major sections with a [FolderTabBar].
///
/// Page indicators for multi-page sections (Logbook, Results, Outbox) are
/// rendered between the content and the tab bar.
class NotebookShell extends StatefulWidget {
  const NotebookShell({super.key});

  @override
  State<NotebookShell> createState() => _NotebookShellState();
}

class _NotebookShellState extends State<NotebookShell> {
  int _currentIndex = 0;

  // Page indices reported by each multi-page section
  int _logbookPageIndex = 1; // Starts on Present (middle page)
  int _resultsPageIndex = 0;
  int _outboxPageIndex = 0;

  // Keys to call goToPage on child sections
  final _logbookKey = GlobalKey<TemporalHomePageState>();
  final _resultsKey = GlobalKey<ResultsSectionState>();
  final _outboxKey = GlobalKey<OutboxPageState>();

  static const _tabs = [
    FolderTab(icon: Icons.auto_stories, label: 'Logbook'),
    FolderTab(icon: Icons.insights, label: 'Results'),
    FolderTab(icon: Icons.inbox, label: 'Inbox'),
    FolderTab(icon: Icons.outbox, label: 'Outbox'),
    FolderTab(icon: Icons.settings, label: 'Settings'),
  ];

  static const _logbookLabels = ['-t', 't', '+t'];
  static const _resultsLabels = ['Graphs', 'Analysis'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          Expanded(
            child: IndexedStack(
              index: _currentIndex,
              children: [
                TemporalHomePage(
                  key: _logbookKey,
                  onPageChanged: (i) => setState(() => _logbookPageIndex = i),
                ),
                ResultsSection(
                  key: _resultsKey,
                  onPageChanged: (i) => setState(() => _resultsPageIndex = i),
                ),
                // Inbox
                BlocProvider(
                  create: (_) => GetIt.instance<NotificationInboxCubit>()..loadNotifications(),
                  child: UiFlowStateListener<NotificationInboxCubit, NotificationInboxState>(
                    mapper: GetIt.instance<NotificationMessageMapper>(),
                    uiService: GetIt.instance<IUiFlowService>(),
                    child: const NotificationInboxContent(),
                  ),
                ),
                // Outbox
                OutboxPage(
                  key: _outboxKey,
                  onPageChanged: (i) => setState(() => _outboxPageIndex = i),
                ),
                // Settings
                MultiBlocProvider(
                  providers: [
                    BlocProvider(create: (_) => GetIt.instance<DataExportCubit>()),
                    BlocProvider(create: (_) => GetIt.instance<RecoveryKeyCubit>()),
                    BlocProvider(create: (_) => GetIt.instance<DeviceManagementCubit>()),
                    BlocProvider(create: (_) => GetIt.instance<WebhookCubit>()..load()),
                    BlocProvider.value(value: GetIt.instance<AppOperatingCubit>()),
                  ],
                  child: const SettingsContent(),
                ),
              ],
            ),
          ),
          // Page indicator — between content and tab bar
          _buildPageIndicator(context),
          FolderTabBar(
            currentIndex: _currentIndex,
            onTabSelected: (index) => setState(() => _currentIndex = index),
            tabs: _tabs,
          ),
        ],
      ),
    );
  }

  Widget _buildPageIndicator(BuildContext context) {
    final labels = switch (_currentIndex) {
      0 => _logbookLabels,
      1 => _resultsLabels,
      3 => [
            context.l10n.outboxTabFeedback,
            context.l10n.outboxTabAnalytics,
            context.l10n.outboxTabErrors,
          ],
      _ => <String>[],
    };

    if (labels.isEmpty) return const SizedBox.shrink();

    final activeIndex = switch (_currentIndex) {
      0 => _logbookPageIndex,
      1 => _resultsPageIndex,
      3 => _outboxPageIndex,
      _ => 0,
    };

    final palette = QuanityaPalette.primary;

    return Padding(
      padding: EdgeInsets.only(bottom: AppSizes.space * 0.25),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(labels.length, (i) {
          final isActive = i == activeIndex;
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => _onIndicatorTap(i),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: AppSizes.space * 1.5,
                vertical: AppSizes.space * 0.5,
              ),
              child: Text(
                labels[i],
                style: context.text.bodySmall?.copyWith(
                  fontWeight: isActive ? FontWeight.w900 : FontWeight.w500,
                  color: isActive ? palette.textPrimary : palette.interactableColor,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  void _onIndicatorTap(int pageIndex) {
    switch (_currentIndex) {
      case 0:
        _logbookKey.currentState?.goToPage(pageIndex);
      case 1:
        _resultsKey.currentState?.goToPage(pageIndex);
      case 3:
        _outboxKey.currentState?.goToPage(pageIndex);
    }
  }
}
