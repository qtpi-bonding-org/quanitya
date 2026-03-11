import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:get_it/get_it.dart';

import 'app/root_navigator_key.dart';
import 'features/templates/pages/template_designer_page.dart';
import 'features/analytics/pages/analysis_builder_page.dart';
import 'features/settings/pages/settings_page.dart';
import 'features/settings/pages/app_info_page.dart';
import 'features/analytics_inbox/pages/analytics_inbox_page.dart';
import 'features/error_reporting/pages/error_box_page.dart';
import 'features/user_feedback/pages/feedback_page.dart';
import 'features/outbox/pages/outbox_page.dart';
import 'l10n/app_localizations.dart';
import 'features/notifications/pages/notification_inbox_page.dart';
import 'data/repositories/template_with_aesthetics_repository.dart';
import 'features/log_entry/pages/logged_entries_template_page.dart';
import 'features/home/pages/notebook_shell.dart';
import 'design_system/widgets/quanitya/general/zen_paper_background.dart';
import 'features/onboarding/pages/onboarding_page.dart';
import 'features/onboarding/pages/about_page.dart';
import 'features/onboarding/pages/recovery_key_backup_page.dart';
import 'features/onboarding/pages/account_recovery_page.dart';
import 'features/onboarding/cubits/onboarding_cubit.dart';
import 'features/templates/pages/template_import_page.dart';
import 'features/purchase/pages/purchase_page.dart';
import 'features/device_pairing/pages/show_pairing_qr_page.dart';
import 'features/device_pairing/pages/scan_pairing_qr_page.dart';
import 'features/onboarding/pages/connect_device_page.dart';
import 'infrastructure/crypto/crypto_key_repository.dart';

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
              final templateWithAesthetics =
                  state.extra as TemplateWithAesthetics?;
              return TemplateDesignerPage(
                templateWithAesthetics: templateWithAesthetics,
              );
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
            path: AppRoutes.templateImport,
            name: RouteNames.templateImport,
            builder: (context, state) => const TemplateImportPage(),
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
  static const String logHistory = '/log-history/:templateId';
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
  static const String templateImport = '/template-import';
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
  static const String logHistory = 'logHistory';
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
  static const String templateImport = 'templateImport';
}

class AppNavigation {
  AppNavigation._();

  static void toHome(BuildContext context) => context.goNamed(RouteNames.home);

  /// Navigate to template designer for new/edit template
  static void toTemplateDesigner(
    BuildContext context, [
    TemplateWithAesthetics? template,
  ]) {
    context.pushNamed(RouteNames.templateEditor, extra: template);
  }

  static void toLogHistory(BuildContext context, String templateId) {
    context.pushNamed(
      RouteNames.logHistory,
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

  static void toTemplateImport(BuildContext context) {
    context.pushNamed(RouteNames.templateImport);
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

}
