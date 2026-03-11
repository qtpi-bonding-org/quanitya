import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:get_it/get_it.dart';

import 'app/root_navigator_key.dart';
import 'features/templates/pages/template_generator_page.dart';
import 'features/templates/pages/template_editor_page.dart';
import 'features/templates/pages/template_preview_page.dart';
import 'features/analytics/pages/analysis_builder_page.dart';
import 'features/settings/pages/settings_page.dart';
import 'features/settings/pages/app_info_page.dart';
import 'features/analytics_inbox/pages/analytics_inbox_page.dart';
import 'features/error_reporting/pages/error_box_page.dart';
import 'features/user_feedback/pages/feedback_page.dart';
import 'features/outbox/pages/outbox_page.dart';
import 'l10n/app_localizations.dart';
import 'features/notifications/pages/notification_inbox_page.dart';
import 'features/log_entry/pages/log_entry_page.dart';
import 'features/log_entry/pages/logged_entry_page.dart';
import 'features/log_entry/pages/logged_entry_editor_page.dart';

import 'data/repositories/template_with_aesthetics_repository.dart';
import 'data/dao/log_entry_query_dao.dart';
import 'features/log_entry/pages/logged_entries_template_page.dart';
import 'features/home/pages/notebook_shell.dart';
import 'design_system/widgets/quanitya/general/zen_paper_background.dart';
import 'features/onboarding/pages/onboarding_page.dart';
import 'features/onboarding/pages/about_page.dart';
import 'features/onboarding/pages/recovery_key_backup_page.dart';
import 'features/onboarding/pages/account_recovery_page.dart';
import 'features/onboarding/cubits/onboarding_cubit.dart';
import 'features/templates/pages/template_list_page.dart';
import 'features/templates/pages/template_import_page.dart';
import 'features/health/pages/health_sync_page.dart';
import 'features/purchase/pages/purchase_page.dart';
import 'features/visualization/pages/visualization_page.dart';
import 'features/device_pairing/pages/show_pairing_qr_page.dart';
import 'features/device_pairing/pages/scan_pairing_qr_page.dart';
import 'features/onboarding/pages/connect_device_page.dart';
import 'infrastructure/crypto/crypto_key_repository.dart';

/// Arguments for TemplatePreviewPage navigation
class TemplatePreviewPageArgs {
  final TemplateWithAesthetics templateWithAesthetics;
  final Map<String, dynamic>? initialValues;
  final dynamic editorCubit; // TemplateEditorCubit but avoiding import

  const TemplatePreviewPageArgs({
    required this.templateWithAesthetics,
    this.initialValues,
    this.editorCubit,
  });
}

class AppRouter {
  AppRouter._();

  // Track if we've checked keys (to avoid checking on every navigation)
  static bool? _hasKeys;

  /// Determine initial route based on device key status.
  /// Call this BEFORE accessing router to set the correct initial location.
  static Future<void> initialize() async {
    final keyRepo = GetIt.instance<ICryptoKeyRepository>();
    final status = await keyRepo.getKeyStatus();
    _hasKeys = status == CryptoKeyStatus.ready;
    _createRouter();
  }

  static String get _initialLocation =>
      _hasKeys == true ? AppRoutes.home : AppRoutes.onboarding;

  static Future<String?> _redirectToOnboardingIfNeeded(
    BuildContext context,
    GoRouterState state,
  ) async {
    // Skip redirect for onboarding-related routes
    if (state.matchedLocation == AppRoutes.onboarding ||
        state.matchedLocation == AppRoutes.about ||
        state.matchedLocation == AppRoutes.recoveryKeyBackup ||
        state.matchedLocation == AppRoutes.accountRecovery ||
        state.matchedLocation == AppRoutes.showPairingQr ||
        state.matchedLocation == AppRoutes.connectDevice) {
      return null;
    }

    // Check keys only once per app session (or if explicitly reset)
    if (_hasKeys == null) {
      final keyRepo = GetIt.instance<ICryptoKeyRepository>();
      final status = await keyRepo.getKeyStatus();
      _hasKeys = status == CryptoKeyStatus.ready;
    }

    // Redirect to onboarding if no keys
    if (_hasKeys == false) {
      return AppRoutes.onboarding;
    }

    return null;
  }

  /// Call this after wiping keys to force re-check on next navigation
  static void resetKeyCheck() {
    _hasKeys = null;
  }

  static GoRouter? _routerInstance;

  static GoRouter get router {
    if (_routerInstance == null) {
      throw StateError(
        'AppRouter not initialized. Call AppRouter.initialize() before accessing router.',
      );
    }
    return _routerInstance!;
  }

  static void _createRouter() {
    _routerInstance = GoRouter(
      navigatorKey: rootNavigatorKey,
      initialLocation: _initialLocation,
      redirect: _redirectToOnboardingIfNeeded,
      routes: [
      ShellRoute(
        builder: (context, state, child) {
          return ZenPaperBackground(child: child);
        },
        routes: [
          GoRoute(
            path: AppRoutes.home,
            name: RouteNames.home,
            builder: (context, state) => const NotebookShell(),
          ),
          GoRoute(
            path: AppRoutes.onboarding,
            name: RouteNames.onboarding,
            builder: (context, state) => const OnboardingPage(),
          ),
          GoRoute(
            path: AppRoutes.recoveryKeyBackup,
            name: RouteNames.recoveryKeyBackup,
            builder: (context, state) {
              // Get the cubit from the parent route's context
              final cubit = state.extra as OnboardingCubit?;
              if (cubit != null) {
                return BlocProvider.value(
                  value: cubit,
                  child: const RecoveryKeyBackupPage(),
                );
              }
              // Fallback - shouldn't happen in normal flow
              return const OnboardingPage();
            },
          ),
          GoRoute(
            path: AppRoutes.accountRecovery,
            name: RouteNames.accountRecovery,
            builder: (context, state) => const AccountRecoveryPage(),
          ),
          GoRoute(
            path: AppRoutes.showPairingQr,
            name: RouteNames.showPairingQr,
            builder: (context, state) => const ShowPairingQrPage(),
          ),
          GoRoute(
            path: AppRoutes.scanPairingQr,
            name: RouteNames.scanPairingQr,
            builder: (context, state) => const ScanPairingQrPage(),
          ),
          GoRoute(
            path: AppRoutes.about,
            name: RouteNames.about,
            builder: (context, state) => const AboutPage(),
          ),
          GoRoute(
            path: AppRoutes.connectDevice,
            name: RouteNames.connectDevice,
            builder: (context, state) => const ConnectDevicePage(),
          ),

          GoRoute(
            path: AppRoutes.templateEditor,
            name: RouteNames.templateEditor,
            builder: (context, state) {
              // Simple: pass TemplateWithAesthetics or null
              final templateWithAesthetics =
                  state.extra as TemplateWithAesthetics?;
              return TemplateGeneratorPage(
                templateWithAesthetics: templateWithAesthetics,
              );
            },
          ),
          GoRoute(
            path: AppRoutes.templatePreview,
            name: RouteNames.templatePreview,
            builder: (context, state) {
              final args = state.extra as TemplatePreviewPageArgs;
              return TemplatePreviewPage(
                templateWithAesthetics: args.templateWithAesthetics,
                initialValues: args.initialValues,
                editorCubit: args.editorCubit,
              );
            },
          ),
          GoRoute(
            path: AppRoutes.logEntry,
            name: RouteNames.logEntry,
            builder: (context, state) {
              final templateId = state.extra as String;
              return LogEntryPage(templateId: templateId);
            },
          ),
          GoRoute(
            path: AppRoutes.logHistory,
            name: RouteNames.logHistory,
            builder: (context, state) {
              final templateId = state.pathParameters['templateId']!;
              return LoggedEntriesTemplatePage(templateId: templateId);
            },
          ),
          GoRoute(
            path: AppRoutes.templateDetail,
            name: RouteNames.templateDetail,
            builder: (context, state) {
              final templateId = state.pathParameters['templateId']!;
              return TemplateEditorPage(templateId: templateId);
            },
          ),
          GoRoute(
            path: AppRoutes.settings,
            name: RouteNames.settings,
            builder: (context, state) => const SettingsPage(),
          ),
          GoRoute(
            path: AppRoutes.appInfo,
            name: RouteNames.appInfo,
            builder: (context, state) => const AppInfoPage(),
          ),
          GoRoute(
            path: AppRoutes.errorBox,
            name: RouteNames.errorBox,
            builder: (context, state) => const ErrorBoxPage(),
          ),
          GoRoute(
            path: AppRoutes.analyticsInbox,
            name: RouteNames.analyticsInbox,
            builder: (context, state) => const AnalyticsInboxPage(),
          ),
          GoRoute(
            path: AppRoutes.feedback,
            name: RouteNames.feedback,
            builder: (context, state) => const FeedbackPage(),
          ),
          GoRoute(
            path: AppRoutes.outbox,
            name: RouteNames.outbox,
            builder: (context, state) => const PostagePage(),
          ),
          GoRoute(
            path: AppRoutes.notificationInbox,
            name: RouteNames.notificationInbox,
            builder: (context, state) => const NotificationInboxPage(),
          ),
          GoRoute(
            path: AppRoutes.purchase,
            name: RouteNames.purchase,
            builder: (context, state) => const PurchasePage(),
          ),
          GoRoute(
            path: AppRoutes.templateList,
            name: RouteNames.templateList,
            builder: (context, state) => const TemplateListPage(),
          ),
          GoRoute(
            path: AppRoutes.templateImport,
            name: RouteNames.templateImport,
            builder: (context, state) => const TemplateImportPage(),
          ),
          GoRoute(
            path: AppRoutes.healthSync,
            name: RouteNames.healthSync,
            builder: (context, state) => const HealthSyncPage(),
          ),
          GoRoute(
            path: AppRoutes.entryDetail,
            name: RouteNames.entryDetail,
            builder: (context, state) {
              final entryWithContext = state.extra as LogEntryWithContext;
              return LoggedEntryPage(entryWithContext: entryWithContext);
            },
          ),
          GoRoute(
            path: AppRoutes.visualization,
            name: RouteNames.visualization,
            builder: (context, state) {
              final templateId = state.extra as String?;
              return VisualizationPage(templateId: templateId);
            },
          ),
          GoRoute(
            path: AppRoutes.editEntry,
            name: RouteNames.editEntry,
            builder: (context, state) {
              final entryWithContext = state.extra as LogEntryWithContext;
              return LoggedEntryEditorPage(entryWithContext: entryWithContext);
            },
          ),
          GoRoute(
            path: AppRoutes.scriptBuilder,
            name: RouteNames.scriptBuilder,
            builder: (context, state) {
              final params = state.extra as Map<String, dynamic>?;
              final fieldId = params?['fieldId'] as String? ?? 'demo-field';
              final templateId = params?['templateId'] as String?;
              
              return AnalysisBuilderPage(
                fieldId: fieldId,
                templateId: templateId,
              );
            },
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) {
      final l10n = AppLocalizations.of(context)!;
      return ZenPaperBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(title: Text(l10n.errorPageTitle)),
          body: Center(child: Text(l10n.errorPageNotFound(state.matchedLocation))),
        ),
      );
    },
    );
  }
}

class AppRoutes {
  AppRoutes._();
  static const String home = '/';
  static const String onboarding = '/onboarding';
  static const String recoveryKeyBackup = '/recovery-key-backup';
  static const String accountRecovery = '/account-recovery';
  static const String showPairingQr = '/show-pairing-qr';
  static const String scanPairingQr = '/scan-pairing-qr';
  static const String about = '/about';
  static const String templateEditor = '/template-editor';
  static const String templatePreview = '/template-preview';
  static const String logEntry = '/log-entry';
  static const String logHistory = '/log-history/:templateId';
  static const String templateDetail = '/template/:templateId';
  static const String entryDetail = '/entry-detail';
  static const String editEntry = '/edit-entry';
  static const String visualization = '/visualization';
  static const String settings = '/settings';
  static const String appInfo = '/app-info';
  static const String errorBox = '/error-box';
  static const String analyticsInbox = '/analytics-inbox';
  static const String feedback = '/feedback';
  static const String outbox = '/outbox';
  static const String notificationInbox = '/notification-inbox';
  static const String connectDevice = '/connect-device';
  static const String scriptBuilder = '/script-builder';
  static const String purchase = '/purchase';
  static const String templateList = '/templates';
  static const String templateImport = '/template-import';
  static const String healthSync = '/health-sync';
}

class RouteNames {
  RouteNames._();
  static const String home = 'home';
  static const String onboarding = 'onboarding';
  static const String recoveryKeyBackup = 'recoveryKeyBackup';
  static const String accountRecovery = 'accountRecovery';
  static const String showPairingQr = 'showPairingQr';
  static const String scanPairingQr = 'scanPairingQr';
  static const String about = 'about';
  static const String templateEditor = 'templateEditor';
  static const String templatePreview = 'templatePreview';
  static const String logEntry = 'logEntry';
  static const String logHistory = 'logHistory';
  static const String templateDetail = 'templateDetail';
  static const String entryDetail = 'entryDetail';
  static const String editEntry = 'editEntry';
  static const String visualization = 'visualization';
  static const String settings = 'settings';
  static const String appInfo = 'appInfo';
  static const String errorBox = 'errorBox';
  static const String analyticsInbox = 'analyticsInbox';
  static const String feedback = 'feedback';
  static const String outbox = 'outbox';
  static const String notificationInbox = 'notificationInbox';
  static const String connectDevice = 'connectDevice';
  static const String scriptBuilder = 'scriptBuilder';
  static const String purchase = 'purchase';
  static const String templateList = 'templateList';
  static const String templateImport = 'templateImport';
  static const String healthSync = 'healthSync';
}

class AppNavigation {
  AppNavigation._();

  static void toHome(BuildContext context) => context.goNamed(RouteNames.home);

  /// Navigate to template generator for new/edit template
  static void toTemplateGenerator(
    BuildContext context, [
    TemplateWithAesthetics? template,
  ]) {
    context.pushNamed(RouteNames.templateEditor, extra: template);
  }

  static void toLogEntry(BuildContext context, String templateId) {
    context.pushNamed(RouteNames.logEntry, extra: templateId);
  }

  static void toLogHistory(BuildContext context, String templateId) {
    context.pushNamed(
      RouteNames.logHistory,
      pathParameters: {'templateId': templateId},
    );
  }

  /// Navigate to template editor (detail view) for existing template
  static void toTemplateEditor(BuildContext context, String templateId) {
    context.pushNamed(
      RouteNames.templateDetail,
      pathParameters: {'templateId': templateId},
    );
  }

  static void toSettings(BuildContext context) {
    context.pushNamed(RouteNames.settings);
  }

  static void toAppInfo(BuildContext context) {
    context.pushNamed(RouteNames.appInfo);
  }

  static void toErrorBox(BuildContext context) {
    context.pushNamed(RouteNames.errorBox);
  }

  static void toAnalyticsInbox(BuildContext context) {
    context.pushNamed(RouteNames.analyticsInbox);
  }

  static void toOutbox(BuildContext context) {
    context.pushNamed(RouteNames.outbox);
  }

  static void toNotificationInbox(BuildContext context) {
    context.pushNamed(RouteNames.notificationInbox);
  }

  static void toPurchase(BuildContext context) {
    context.pushNamed(RouteNames.purchase);
  }

  static void toFeedback(BuildContext context) {
    context.pushNamed(RouteNames.feedback);
  }

  static void back(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      toHome(context);
    }
  }

  static void toLoggedEntry(BuildContext context, dynamic entryWithContext) {
    context.pushNamed(RouteNames.entryDetail, extra: entryWithContext);
  }

  static void toVisualization(BuildContext context, [String? templateId]) {
    context.pushNamed(RouteNames.visualization, extra: templateId);
  }

  static void toLoggedEntryEditor(BuildContext context, LogEntryWithContext entryWithContext) {
    context.pushNamed(RouteNames.editEntry, extra: entryWithContext);
  }

  static void toShowPairingQr(BuildContext context) {
    context.pushNamed(RouteNames.showPairingQr);
  }

  static void toScanPairingQr(BuildContext context) {
    context.pushNamed(RouteNames.scanPairingQr);
  }

  static void toConnectDevice(BuildContext context) {
    context.pushNamed(RouteNames.connectDevice);
  }

  static void toAccountRecovery(BuildContext context) {
    context.pushNamed(RouteNames.accountRecovery);
  }

  static void toAbout(BuildContext context) {
    context.pushNamed(RouteNames.about);
  }

  static void toRecoveryKeyBackup(BuildContext context, OnboardingCubit cubit) {
    context.pushNamed(RouteNames.recoveryKeyBackup, extra: cubit);
  }

  static void toTemplateList(BuildContext context) {
    context.pushNamed(RouteNames.templateList);
  }

  static void toTemplateImport(BuildContext context) {
    context.pushNamed(RouteNames.templateImport);
  }

  static void toHealthSync(BuildContext context) {
    context.pushNamed(RouteNames.healthSync);
  }

  static void toAnalysisBuilder(BuildContext context, {String? fieldId, String? templateId}) {
    context.pushNamed(
      RouteNames.scriptBuilder,
      extra: {
        'fieldId': fieldId ?? 'demo-field',
        'templateId': templateId,
      },
    );
  }

  static void toTemplatePreview(
    BuildContext context,
    TemplateWithAesthetics templateWithAesthetics, {
    Map<String, dynamic>? initialValues,
    dynamic editorCubit,
  }) {
    context.pushNamed(
      RouteNames.templatePreview,
      extra: TemplatePreviewPageArgs(
        templateWithAesthetics: templateWithAesthetics,
        initialValues: initialValues,
        editorCubit: editorCubit,
      ),
    );
  }
}
