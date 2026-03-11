import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

import '../../outbox/pages/outbox_page.dart';
import '../../outbox/widgets/folder_tab_bar.dart';
import '../../settings/cubits/data_export/data_export_cubit.dart';
import '../../settings/cubits/recovery_key/recovery_key_cubit.dart';
import '../../settings/cubits/device_management/device_management_cubit.dart';
import '../../settings/cubits/webhook/webhook_cubit.dart';
import '../../settings/cubits/llm_provider/llm_provider_cubit.dart';
import '../../app_operating_mode/cubits/app_operating_cubit.dart';
import '../../results/pages/results_section.dart';
import '../../settings/pages/settings_page.dart';
import 'temporal_home_page.dart';

/// Root-level shell that wraps all four major sections with a [FolderTabBar].
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
    FolderTab(icon: Icons.mail_outline, label: 'Postage'),
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
                // Postage (Notices + Feedback + Analytics + Errors)
                const PostagePage(),
                // Settings
                MultiBlocProvider(
                  providers: [
                    BlocProvider(create: (_) => GetIt.instance<DataExportCubit>()),
                    BlocProvider(create: (_) => GetIt.instance<RecoveryKeyCubit>()),
                    BlocProvider(create: (_) => GetIt.instance<DeviceManagementCubit>()),
                    BlocProvider(create: (_) => GetIt.instance<WebhookCubit>()..load()),
                    BlocProvider(create: (_) => GetIt.instance<LlmProviderCubit>()..load()),
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
