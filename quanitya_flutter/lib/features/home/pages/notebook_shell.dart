import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:cubit_ui_flow/cubit_ui_flow.dart';

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
class NotebookShell extends StatefulWidget {
  const NotebookShell({super.key});

  @override
  State<NotebookShell> createState() => _NotebookShellState();
}

class _NotebookShellState extends State<NotebookShell> {
  int _currentIndex = 0;

  static const _tabs = [
    FolderTab(icon: Icons.auto_stories, label: 'Logbook'),
    FolderTab(icon: Icons.insights, label: 'Results'),
    FolderTab(icon: Icons.inbox, label: 'Inbox'),
    FolderTab(icon: Icons.outbox, label: 'Outbox'),
    FolderTab(icon: Icons.settings, label: 'Settings'),
  ];

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
                const TemporalHomePage(),
                const ResultsSection(),
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
                const OutboxPage(),
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
          FolderTabBar(
            currentIndex: _currentIndex,
            onTabSelected: (index) => setState(() => _currentIndex = index),
            tabs: _tabs,
          ),
        ],
      ),
    );
  }
}
