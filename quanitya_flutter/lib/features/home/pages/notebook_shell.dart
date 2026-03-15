import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

import '../../../design_system/primitives/app_sizes.dart';
import '../../../support/extensions/context_extensions.dart';
import '../../app_syncing_mode/widgets/mode_indicator.dart';
import '../../error_reporting/cubits/error_box_cubit.dart';
import '../../notifications/cubits/notification_inbox_cubit.dart';
import '../../outbox/pages/outbox_page.dart';
import '../../outbox/widgets/folder_tab_bar.dart';
import '../../results/pages/results_section.dart';
import '../../office/pages/office_page.dart';
import 'temporal_home_page.dart';

/// Root-level shell that wraps all four major sections with a [FolderTabBar].
class NotebookShell extends StatefulWidget {
  const NotebookShell({super.key});

  @override
  State<NotebookShell> createState() => _NotebookShellState();
}

class _NotebookShellState extends State<NotebookShell> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) =>
              GetIt.instance<NotificationInboxCubit>()..loadNotifications(),
        ),
        BlocProvider(
          create: (_) => GetIt.instance<ErrorBoxCubit>()..load(),
        ),
      ],
      child: Builder(
        builder: (context) {
          final hasNotifications = context.select<NotificationInboxCubit, bool>(
            (c) => c.state.notifications.isNotEmpty,
          );
          final hasErrors = context.select<ErrorBoxCubit, bool>(
            (c) => c.state.unsentErrors.isNotEmpty,
          );

          final tabs = [
            FolderTab(icon: Icons.auto_stories, label: context.l10n.tabLogbook),
            FolderTab(icon: Icons.insights, label: context.l10n.tabResults),
            FolderTab(
              icon: Icons.mail_outline,
              label: context.l10n.tabPostage,
              leftIndicator:
                  hasNotifications ? Icons.south : null,
              rightIndicator:
                  hasErrors ? Icons.north : null,
            ),
            FolderTab(icon: Icons.desk, label: context.l10n.tabOffice),
          ];

          return Scaffold(
            backgroundColor: Colors.transparent,
            body: Stack(
              children: [
                Column(
                  children: [
                    Expanded(
                      child: IndexedStack(
                        index: _currentIndex,
                        children: const [
                          TemporalHomePage(),
                          ResultsSection(),
                          // Postage (Notices + Feedback + Analytics + Errors)
                          PostagePage(),
                          OfficePage(),
                        ],
                      ),
                    ),
                    FolderTabBar(
                      currentIndex: _currentIndex,
                      onTabSelected: (index) =>
                          setState(() => _currentIndex = index),
                      tabs: tabs,
                    ),
                  ],
                ),
                // Mode indicator — top-right, below safe area
                Positioned(
                  top: MediaQuery.of(context).padding.top + AppSizes.space,
                  right: AppSizes.space * 2,
                  child: const ModeIndicator(),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
