import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'infrastructure/config/debug_log.dart';
import 'package:go_router/go_router.dart';
import 'package:get_it/get_it.dart';

import 'app/root_navigator_key.dart';
import 'features/hidden_visibility/cubits/hidden_visibility_cubit.dart';
import 'features/templates/pages/template_designer_page.dart';
import 'features/analytics/pages/analysis_builder_page.dart';
import 'l10n/app_localizations.dart';
import 'data/repositories/template_with_aesthetics_repository.dart';
import 'features/home/pages/notebook_shell.dart';
import 'design_system/widgets/quanitya/general/zen_paper_background.dart';
import 'features/catalog/pages/template_gallery_page.dart';
import 'features/onboarding/pages/onboarding_page.dart';
import 'features/onboarding/pages/about_page.dart';
import 'features/onboarding/pages/recovery_key_backup_page.dart';
import 'features/onboarding/pages/account_recovery_page.dart';
import 'features/onboarding/cubits/onboarding_cubit.dart';
import 'features/device_pairing/pages/show_pairing_qr_page.dart';
import 'features/onboarding/pages/connect_device_page.dart';
import 'infrastructure/auth/account_service.dart';
import 'infrastructure/crypto/crypto_key_repository.dart';
import 'infrastructure/device/device_info_service.dart';

const _tag = 'app_router';

class AppRouter {
  AppRouter._();

  // Track if we've checked keys (to avoid checking on every navigation)
  static bool? _hasKeys;

  /// Determine initial route based on device key status.
  /// Call this BEFORE accessing router to set the correct initial location.
  static Future<void> initialize() async {
    final keyRepo = GetIt.instance<ICryptoKeyRepository>();
    final status = await keyRepo.getKeyStatus();

    if (status == CryptoKeyStatus.crossDeviceRecoveryAvailable) {
      // Attempt automatic recovery from cross-device key
      _hasKeys = await _attemptCrossDeviceRecovery();
    } else {
      _hasKeys = status == CryptoKeyStatus.ready;
    }

    _createRouter();
  }

  /// Attempt to recover account using cross-device key (iCloud / Block Store).
  /// Returns true if recovery succeeded, false otherwise.
  static Future<bool> _attemptCrossDeviceRecovery() async {
    try {
      Log.d(_tag, 'AppRouter: Cross-device key found — attempting recovery...');
      final accountService = GetIt.instance<AccountService>();
      final deviceInfo = GetIt.instance<DeviceInfoService>();
      final deviceLabel = await deviceInfo.getDeviceName();

      await accountService.recoverFromCrossDeviceKey(deviceLabel: deviceLabel);
      Log.d(_tag, 'AppRouter: Cross-device recovery succeeded');
      return true;
    } catch (e) {
      Log.d(_tag, 'AppRouter: Cross-device recovery failed, falling back to onboarding: $e');
      return false;
    }
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
        state.matchedLocation == AppRoutes.connectDevice ||
        state.matchedLocation == AppRoutes.templateGallery) {
      return null;
    }

    // Check keys only once per app session (or if explicitly reset)
    if (_hasKeys == null) {
      final keyRepo = GetIt.instance<ICryptoKeyRepository>();
      final status = await keyRepo.getKeyStatus();
      if (status == CryptoKeyStatus.crossDeviceRecoveryAvailable) {
        _hasKeys = await _attemptCrossDeviceRecovery();
      } else {
        _hasKeys = status == CryptoKeyStatus.ready;
      }
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
          return BlocProvider.value(
            value: GetIt.instance<HiddenVisibilityCubit>(),
            child: ZenPaperBackground(child: child),
          );
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
            path: AppRoutes.templateGallery,
            name: RouteNames.templateGallery,
            builder: (context, state) => const TemplateGalleryPage(),
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
  static const String about = '/about';
  static const String templateEditor = '/template-editor';
  static const String connectDevice = '/connect-device';
  static const String scriptBuilder = '/script-builder';
  static const String templateGallery = '/template-gallery';
}

class RouteNames {
  RouteNames._();
  static const String home = 'home';
  static const String onboarding = 'onboarding';
  static const String recoveryKeyBackup = 'recoveryKeyBackup';
  static const String accountRecovery = 'accountRecovery';
  static const String showPairingQr = 'showPairingQr';
  static const String about = 'about';
  static const String templateEditor = 'templateEditor';
  static const String connectDevice = 'connectDevice';
  static const String scriptBuilder = 'scriptBuilder';
  static const String templateGallery = 'templateGallery';
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

  static void toTemplateGallery(BuildContext context) {
    context.pushNamed(RouteNames.templateGallery);
  }

  static Future<Object?> toAnalysisBuilder(BuildContext context, {String? fieldId, String? templateId}) {
    return context.pushNamed(
      RouteNames.scriptBuilder,
      extra: {
        'fieldId': fieldId ?? 'demo-field',
        'templateId': templateId,
      },
    );
  }

}
