import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_error_privserver/flutter_error_privserver.dart';
import 'package:cubit_ui_flow/cubit_ui_flow.dart' show UiFlowStatus;

import '../../../support/extensions/context_extensions.dart';
import '../../account/cubits/account_info_cubit.dart';
import '../../app_syncing_mode/cubits/app_syncing_cubit.dart';
import '../../errors/cubits/errors_cubit.dart';
import '../../notices/cubits/notices_cubit.dart';
import '../../purchase/cubits/entitlement_cubit.dart';
import '../../purchase/cubits/entitlement_state.dart';
import '../../purchase/cubits/purchase_cubit.dart';
import '../../purchase/cubits/purchase_state.dart';
import '../../settings/cubits/llm_provider/llm_provider_cubit.dart';
import '../../postage/pages/postage_page.dart';
import '../../guided_tour/guided_tour_service.dart';
import '../../guided_tour/home_tour.dart';
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

class _NotebookShellState extends State<NotebookShell>
    with WidgetsBindingObserver {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _maybeShowHomeTour();
  }

  Future<void> _maybeShowHomeTour() async {
    final tourService = context.read<GuidedTourService>();
    if (!await tourService.shouldShowTour(GuidedTourService.homeKey)) return;

    // Wait one frame for IndexedStack children + FolderTabBar to attach keys
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      if (HomeTourKeys.temporalLabels.currentContext == null ||
          HomeTourKeys.designerButton.currentContext == null ||
          HomeTourKeys.resultsTab.currentContext == null ||
          HomeTourKeys.postageTab.currentContext == null ||
          HomeTourKeys.officeTab.currentContext == null) {
        return;
      }

      showHomeTour(
        context,
        temporalLabelsKey: HomeTourKeys.temporalLabels,
        designerButtonKey: HomeTourKeys.designerButton,
        resultsTabKey: HomeTourKeys.resultsTab,
        postageTabKey: HomeTourKeys.postageTab,
        officeTabKey: HomeTourKeys.officeTab,
        onFinish: () => tourService.markTourSeen(GuidedTourService.homeKey),
      );
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      context.read<EntitlementCubit>().refreshIfStale();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
        listeners: [
          BlocListener<EntitlementCubit, EntitlementState>(
            listenWhen: (prev, curr) => prev.hasSyncAccess != curr.hasSyncAccess,
            listener: (context, state) async {
              try {
                final syncCubit = context.read<AppSyncingCubit>();
                if (state.hasSyncAccess) {
                  await syncCubit.switchToCloud(emitLoading: false);
                } else {
                  await syncCubit.switchToLocal(emitLoading: false);
                }
              } catch (e, stack) {
                await ErrorPrivserver.captureError(e, stack, source: 'NotebookShell.entitlementListener');
              }
            },
          ),
          BlocListener<EntitlementCubit, EntitlementState>(
            listenWhen: (prev, curr) =>
                !prev.hasAiAccess && curr.hasAiAccess,
            listener: (context, state) async {
              try {
                await context.read<LlmProviderCubit>().selectQuanitya();
              } catch (e, stack) {
                await ErrorPrivserver.captureError(e, stack, source: 'NotebookShell.llmEntitlementListener');
              }
            },
          ),
          BlocListener<PurchaseCubit, PurchaseState>(
            listenWhen: (prev, curr) =>
                (curr.lastOperation == PurchaseOperation.purchase ||
                 curr.lastOperation == PurchaseOperation.recoverPurchases) &&
                curr.status == UiFlowStatus.success &&
                prev.status != curr.status,
            listener: (context, _) async {
              try {
                await context.read<EntitlementCubit>().loadEntitlements();
              } catch (e, stack) {
                await ErrorPrivserver.captureError(e, stack, source: 'NotebookShell.purchaseListener');
              }
            },
          ),
        ],
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
    );
  }
}
