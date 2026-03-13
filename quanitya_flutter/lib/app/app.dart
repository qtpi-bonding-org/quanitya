import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:cubit_ui_flow/cubit_ui_flow.dart' as cubit_ui_flow;
import 'package:flutter_adaptable_group/flutter_adaptable_group.dart';

import '../l10n/app_localizations.dart';
import '../design_system/primitives/app_sizes.dart';
import '../app_router.dart';
import '../infrastructure/feedback/localization_service.dart';
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
            return ResponsiveLayoutConfig(
              baseSpacing: AppSizes.space,
              child: child ?? const SizedBox.shrink(),
            );
          },
        );
      },
    );
  }
}
