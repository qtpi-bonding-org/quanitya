import 'package:flutter/material.dart';
import 'package:flutter_color_palette/flutter_color_palette.dart';
import 'package:get_it/get_it.dart';
import '../../l10n/app_localizations.dart';
import '../../design_system/theme/theme_service.dart';

extension QuanityaContextExtensions on BuildContext {
  /// Unified typography access
  /// Returns standard TextTheme which has QuanityaTextStyles extension applied
  TextTheme get text => Theme.of(this).textTheme;

  /// Unified color palette access via ThemeService
  IColorPalette get colors => GetIt.instance<ThemeService>().currentPalette;

  /// Localization access
  AppLocalizations get l10n => AppLocalizations.of(this)!;
  
  /// Quick helper for screen size
  Size get screenSize => MediaQuery.sizeOf(this);
  
  /// Quick helper for theme brightness
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;
}
