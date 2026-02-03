import 'package:flutter/material.dart';
import 'package:flutter_color_palette/flutter_color_palette.dart';
import '../primitives/quanitya_palette.dart';
import '../primitives/quanitya_fonts.dart';
import '../primitives/app_sizes.dart';

/// Minimal theme implementation using Quanitya color palette and fonts
class AppTheme {
  /// Light theme
  static ThemeData get lightTheme => _buildTheme(QuanityaPalette.primary);

  /// Dark theme
  static ThemeData get darkTheme => _buildTheme(QuanityaPalette.dark);

  static ThemeData _buildTheme(IColorPalette palette) {
    final isDark = palette == QuanityaPalette.dark;

    return ThemeData(
      useMaterial3: true,
      brightness: isDark ? Brightness.dark : Brightness.light,

      // Apply Quanitya fonts
      textTheme: QuanityaFonts.textTheme.apply(
        bodyColor: palette.textPrimary,
        displayColor: palette.textPrimary,
      ),

      colorScheme: ColorScheme(
        brightness: isDark ? Brightness.dark : Brightness.light,
        primary: palette.primaryColor,
        onPrimary: palette.backgroundPrimary,
        secondary: palette.textSecondary,
        onSecondary: palette.backgroundPrimary,
        error: palette.destructiveColor,
        onError: palette.backgroundPrimary,
        surface: palette.backgroundPrimary,
        onSurface: palette.textPrimary,
      ),

      scaffoldBackgroundColor: Colors.transparent, // Transparent to show Zen Paper

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: palette.primaryColor,
          foregroundColor: palette.backgroundPrimary,
          minimumSize: Size.fromHeight(AppSizes.buttonHeight),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
          ),
          textStyle: TextStyle(
            fontFamily: QuanityaFonts.bodyFamily,
            fontSize: AppSizes.size16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: Size.fromHeight(AppSizes.buttonHeight),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
          ),
          textStyle: TextStyle(
            fontFamily: QuanityaFonts.bodyFamily,
            fontSize: AppSizes.size16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),

      cardTheme: CardThemeData(
        color: palette.backgroundPrimary,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
        ),
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: palette.backgroundPrimary,
        foregroundColor: palette.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0, // Disable color change on scroll
        toolbarHeight: AppSizes.appBarHeight,
        titleTextStyle: TextStyle(
          fontFamily: QuanityaFonts.headerFamily,
          fontSize: AppSizes.size20,
          fontWeight: FontWeight.w600,
          color: palette.textPrimary,
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
          borderSide: BorderSide(color: palette.textSecondary),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
          borderSide: BorderSide(
            color: palette.primaryColor,
            width: AppSizes.borderWidthThick,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
          borderSide: BorderSide(color: palette.destructiveColor),
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: AppSizes.space * 2,
          vertical: AppSizes.space * 1.5,
        ),
        labelStyle: TextStyle(
          fontFamily: QuanityaFonts.bodyFamily,
          fontSize: AppSizes.size14,
          color: palette.textSecondary,
        ),
      ),

      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: palette.primaryColor,
        foregroundColor: palette.backgroundPrimary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
        ),
      ),

      listTileTheme: ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(
          horizontal: AppSizes.space * 2,
          vertical: AppSizes.space,
        ),
      ),
    );
  }
}

/// Extension for easy palette access
extension AppThemeExtension on BuildContext {
  ThemeData get theme => Theme.of(this);
  ColorScheme get colorScheme => theme.colorScheme;
  TextTheme get textTheme => theme.textTheme;
}
