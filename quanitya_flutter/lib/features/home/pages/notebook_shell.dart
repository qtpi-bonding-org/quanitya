import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

import '../../../support/extensions/context_extensions.dart';
import '../../app_syncing_mode/cubits/app_syncing_cubit.dart';
import '../../app_syncing_mode/models/app_syncing_mode.dart';
import '../../errors/cubits/errors_cubit.dart';
import '../../notices/cubits/notices_cubit.dart';
import '../../purchase/cubits/entitlement_cubit.dart';
import '../../purchase/cubits/entitlement_state.dart';
import '../../postage/pages/postage_page.dart';
import '../../guided_tour/guided_tour_service.dart';
import '../../postage/widgets/folder_tab_bar.dart';
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
        BlocProvider.value(value: GetIt.instance<AppSyncingCubit>()),
        BlocProvider.value(value: GetIt.instance<EntitlementCubit>()),
        BlocProvider(
          create: (_) =>
              GetIt.instance<NoticesCubit>()..loadNotifications(),
        ),
        BlocProvider.value(value: GetIt.instance<ErrorsCubit>()),
      ],
      child: BlocListener<EntitlementCubit, EntitlementState>(
        listenWhen: (prev, curr) => prev.hasSyncAccess != curr.hasSyncAccess,
        listener: (context, state) {
          final syncCubit = context.read<AppSyncingCubit>();
          if (state.hasSyncAccess && syncCubit.state.mode.supportsSync) {
            syncCubit.retryConnection();
          }
        },
        child: Builder(
          builder: (context) {
            final hasNotifications = context.select<NoticesCubit, bool>(
              (c) => c.state.notifications.isNotEmpty,
            );
            final hasErrors = context.select<ErrorsCubit, bool>(
              (c) => c.state.unsentErrors.isNotEmpty,
            );

            final tabs = [
              FolderTab(icon: Icons.auto_stories, label: context.l10n.tabLogbook),
              FolderTab(icon: Icons.insights, label: context.l10n.tabResults, tourKey: HomeTourKeys.resultsTab),
              FolderTab(
                icon: Icons.mail_outline,
                label: context.l10n.tabPostage,
                tourKey: HomeTourKeys.postageTab,
                leftIndicator:
                    hasNotifications ? Icons.south : null,
                rightIndicator:
                    hasErrors ? Icons.north : null,
              ),
              FolderTab(icon: Icons.desk, label: context.l10n.tabOffice, tourKey: HomeTourKeys.officeTab),
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
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
