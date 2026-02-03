import 'package:injectable/injectable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_color_palette/flutter_color_palette.dart';
import '../primitives/app_sizes.dart';
import '../primitives/quanitya_palette.dart';
import '../../logic/templates/models/engine/page_configuration.dart';

@singleton
class ThemeService extends ChangeNotifier {
  bool _isDarkMode = false;

  IColorPalette get currentPalette =>
      _isDarkMode ? QuanityaPalette.dark : QuanityaPalette.primary;

  bool get isDarkMode => _isDarkMode;

  void toggleDarkMode() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }

  void setDarkMode(bool isDark) {
    if (_isDarkMode != isDark) {
      _isDarkMode = isDark;
      notifyListeners();
    }
  }

  /// Build a theme using AI-generated color palette and font configuration
  ThemeData buildAiTheme({
    required IColorPalette colorPalette,
    FontsConfig? fonts,
    bool isDark = false,
  }) {
    final brightness = isDark ? Brightness.dark : Brightness.light;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,

      colorScheme: ColorScheme.fromSeed(
        seedColor: colorPalette.primaryColor,
        brightness: brightness,
        primary: colorPalette.primaryColor,
        secondary: colorPalette.secondaryColor,
        error: colorPalette.destructiveColor,
        surface: colorPalette.backgroundPrimary,
      ),

      textTheme: _buildTextTheme(fonts, brightness),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorPalette.primaryColor,
          foregroundColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
          ),
        ),
      ),

      cardTheme: CardThemeData(
        color: colorPalette.backgroundPrimary,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
        ),
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: colorPalette.primaryColor,
        foregroundColor: Colors.transparent,
        elevation: 0,
      ),

      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
          borderSide: BorderSide(color: colorPalette.textSecondary),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
          borderSide: BorderSide(color: colorPalette.primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
          borderSide: BorderSide(color: colorPalette.destructiveColor),
        ),
      ),
    );
  }

  /// Build text theme using AI font configuration
  TextTheme _buildTextTheme(FontsConfig? fonts, Brightness brightness) {
    final baseTheme = brightness == Brightness.dark
        ? ThemeData.dark().textTheme
        : ThemeData.light().textTheme;

    if (fonts == null) {
      return baseTheme;
    }

    return baseTheme.copyWith(
      // Title styles (headings)
      headlineLarge: baseTheme.headlineLarge?.copyWith(
        fontFamily: fonts.titleFontFamily,
        fontWeight: fonts.titleFontWeight,
      ),
      headlineMedium: baseTheme.headlineMedium?.copyWith(
        fontFamily: fonts.titleFontFamily,
        fontWeight: fonts.titleFontWeight,
      ),
      headlineSmall: baseTheme.headlineSmall?.copyWith(
        fontFamily: fonts.titleFontFamily,
        fontWeight: fonts.titleFontWeight,
      ),

      // Subtitle styles
      titleLarge: baseTheme.titleLarge?.copyWith(
        fontFamily: fonts.subtitleFontFamily,
        fontWeight: fonts.subtitleFontWeight,
      ),
      titleMedium: baseTheme.titleMedium?.copyWith(
        fontFamily: fonts.subtitleFontFamily,
        fontWeight: fonts.subtitleFontWeight,
      ),
      titleSmall: baseTheme.titleSmall?.copyWith(
        fontFamily: fonts.subtitleFontFamily,
        fontWeight: fonts.subtitleFontWeight,
      ),

      // Body text styles
      bodyLarge: baseTheme.bodyLarge?.copyWith(
        fontFamily: fonts.bodyFontFamily,
        fontWeight: fonts.bodyFontWeight,
      ),
      bodyMedium: baseTheme.bodyMedium?.copyWith(
        fontFamily: fonts.bodyFontFamily,
        fontWeight: fonts.bodyFontWeight,
      ),
      bodySmall: baseTheme.bodySmall?.copyWith(
        fontFamily: fonts.bodyFontFamily,
        fontWeight: fonts.bodyFontWeight,
      ),

      // Label styles (buttons, etc.)
      labelLarge: baseTheme.labelLarge?.copyWith(
        fontFamily: fonts.bodyFontFamily,
        fontWeight: fonts.bodyFontWeight,
      ),
      labelMedium: baseTheme.labelMedium?.copyWith(
        fontFamily: fonts.bodyFontFamily,
        fontWeight: fonts.bodyFontWeight,
      ),
      labelSmall: baseTheme.labelSmall?.copyWith(
        fontFamily: fonts.bodyFontFamily,
        fontWeight: fonts.bodyFontWeight,
      ),
    );
  }
}
