import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:cubit_ui_flow/cubit_ui_flow.dart' as cubit_ui_flow;
import 'package:flutter_error_privserver/flutter_error_privserver.dart';

import '../l10n/app_localizations.dart';
import '../app_router.dart';
import '../infrastructure/feedback/localization_service.dart';
import '../infrastructure/error_reporting/quanitya_error_toast_builder.dart';
import '../design_system/theme/app_theme.dart';
import '../design_system/theme/theme_service.dart';
import '../design_system/primitives/ui_scaler.dart';
import 'bootstrap.dart';

class QuanityaApp extends StatefulWidget {
  const QuanityaApp({super.key});

  @override
  State<QuanityaApp> createState() => _QuanityaAppState();
}

class _QuanityaAppState extends State<QuanityaApp> {
  @override
  void initState() {
    super.initState();
    // Enable toasts after first frame (when BuildContext is available)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _enableErrorToasts();
    });
  }

  void _enableErrorToasts() {
    // Reconfigure ErrorPrivserver to enable toasts
    // This updates the singleton config without changing storage/reporter
    final currentConfig = ErrorPrivserverMixin.config;
    if (currentConfig != null) {
      ErrorPrivserver.configure(
        ErrorPrivserverConfig(
          storage: currentConfig.storage,
          reporter: currentConfig.reporter,
          errorCodeMapper: currentConfig.errorCodeMapper,
          exceptionMapper: currentConfig.exceptionMapper,
          showToast: true, // Enable toasts now that we have BuildContext
          toastBuilder: const QuanityaErrorToastBuilder(),
          pageBuilder: currentConfig.pageBuilder,
        ),
      );
      debugPrint('ErrorPrivserver: Toasts enabled');
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: getIt<ThemeService>(),
      builder: (context, child) {
        final themeService = getIt<ThemeService>();
        return MaterialApp.router(
          routerConfig: AppRouter.router,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeService.isDarkMode ? ThemeMode.dark : ThemeMode.light,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('en')],
          builder: (context, child) {
            UiScaler.instance.init(context);

            final l10n = AppLocalizations.of(context);
            if (l10n != null) {
              final service = getIt<cubit_ui_flow.ILocalizationService>();
              if (service is AppLocalizationService) {
                service.update(l10n);
              }
            }
            return child ?? const SizedBox.shrink();
          },
        );
      },
    );
  }
}
