import 'package:flutter/material.dart';
import 'app_sizes.dart';

/// Quanitya's monospace typography system - Data-focused design
///
/// Font Families (Both Monospace for Perfect Alignment):
/// - Heading: Atkinson Hyperlegible Mono (Accessible, distinctive, data-focused)
/// - Body: Noto Sans Mono (Universal language support, clean, functional)
///
/// Weight Classes (for visual hierarchy):
/// - Heavy (Bold/800): The Anchor - Primary Data Values, Section Headers
/// - Medium (Regular/400): The Narrative - Standard sentences, descriptions
/// - Light (Light/200 or Grey): The Whisper - Timestamps, units, metadata
class QuanityaFonts {
  /// Header font family - Atkinson Hyperlegible Mono with minimal fallbacks
  /// Role: Accessible, distinctive headers and data values with perfect alignment.
  /// Falls back to system defaults if unavailable (making it obvious).
  static const List<String> headerFontFallbacks = [
    'Atkinson Hyperlegible Mono',
  ];

  /// Body font family - Noto Sans Mono with minimal fallbacks
  /// Role: Universal language support, clean body text with consistent spacing.
  /// Falls back to system defaults if unavailable (making it obvious).
  static const List<String> bodyFontFallbacks = [
    'Noto Sans Mono',
  ];

  /// Header font family - Atkinson Hyperlegible Mono
  /// Role: Accessible, distinctive headers and data values with perfect alignment.
  static const String headerFamily = 'Atkinson Hyperlegible Mono';

  /// Body font family - Noto Sans Mono
  /// Role: Universal language support, clean body text with consistent spacing.
  static const String bodyFamily = 'Noto Sans Mono';

  // Weight Classes
  static const FontWeight heavy = FontWeight.w800; // The Anchor
  static const FontWeight medium = FontWeight.w400; // The Narrative
  static const FontWeight light = FontWeight.w200; // The Whisper

  /// Simplified text theme - Headers and Titles are the same (Atkinson Hyperlegible)
  static TextTheme get textTheme => TextTheme(
    // All Headers/Titles use Atkinson Hyperlegible (Heavy - The Anchor)
    displayLarge: TextStyle(
      fontFamilyFallback: headerFontFallbacks,
      fontSize: AppSizes.fontMassive, // 36 (was 56)
      fontWeight: heavy,
    ),
    displayMedium: TextStyle(
      fontFamilyFallback: headerFontFallbacks,
      fontSize: AppSizes.fontMassive, // 36 (was 48)
      fontWeight: heavy,
    ),
    displaySmall: TextStyle(
      fontFamilyFallback: headerFontFallbacks,
      fontSize: AppSizes.fontMassive, // 36 (was 36)
      fontWeight: heavy,
    ),
    headlineLarge: TextStyle(
      fontFamilyFallback: headerFontFallbacks,
      fontSize: AppSizes.fontMassive, // 36 (was 32)
      fontWeight: heavy,
    ),
    headlineMedium: TextStyle(
      fontFamilyFallback: headerFontFallbacks,
      fontSize: AppSizes.fontLarge, // 24 (was 28)
      fontWeight: heavy,
    ),
    headlineSmall: TextStyle(
      fontFamilyFallback: headerFontFallbacks,
      fontSize: AppSizes.fontLarge, // 24 (was 24)
      fontWeight: heavy,
    ),
    titleLarge: TextStyle(
      fontFamilyFallback: headerFontFallbacks,
      fontSize: AppSizes.fontLarge, // 24 (was 22)
      fontWeight: heavy,
    ),
    titleMedium: TextStyle(
      fontFamilyFallback: headerFontFallbacks,
      fontSize: AppSizes.fontStandard, // 16 (was 16)
      fontWeight: heavy,
    ),
    titleSmall: TextStyle(
      fontFamilyFallback: headerFontFallbacks,
      fontSize: AppSizes.fontSmall, // 14 (was 14)
      fontWeight: heavy,
    ),

    // All Body text uses Noto Sans (Medium - The Narrative)
    bodyLarge: TextStyle(
      fontFamilyFallback: bodyFontFallbacks,
      fontSize: AppSizes.fontStandard, // 16 (was 16)
      fontWeight: medium,
    ),
    bodyMedium: TextStyle(
      fontFamilyFallback: bodyFontFallbacks,
      fontSize: AppSizes.fontSmall, // 14 (was 14)
      fontWeight: medium,
    ),
    bodySmall: TextStyle(
      fontFamilyFallback: bodyFontFallbacks,
      fontSize: AppSizes.fontMini, // 12 (was 12)
      fontWeight: medium,
    ),

    // All Labels/Metadata use Noto Sans (Light - The Whisper)
    labelLarge: TextStyle(
      fontFamilyFallback: bodyFontFallbacks,
      fontSize: AppSizes.fontStandard, // 16 (was 16)
      fontWeight: medium,
    ),
    labelMedium: TextStyle(
      fontFamilyFallback: bodyFontFallbacks,
      fontSize: AppSizes.fontSmall, // 14 (was 14)
      fontWeight: medium,
    ),
    labelSmall: TextStyle(
      fontFamilyFallback: bodyFontFallbacks,
      fontSize: AppSizes.fontMini, // 12 (was 12)
      fontWeight: medium,
    ),
  );

  QuanityaFonts._();
}

/// Typography Quick Reference (use Flutter's native TextTheme names):
/// 
/// Headers (Atkinson Hyperlegible Mono, Heavy):
///   - headlineLarge: 36px - Major titles, hero text
///   - headlineMedium: 24px - Section headers, page titles
///   - headlineSmall: 24px - Subsection headers
///   - titleSmall: 14px - Small headers, labels
///
/// Body (Noto Sans Mono, Medium):
///   - bodyLarge: 16px - Primary body text
///   - bodyMedium: 14px - Secondary body text
///   - bodySmall: 12px - Fine print, captions
///
/// Labels (Noto Sans Mono, Medium):
///   - labelLarge: 16px - Button text, prominent labels
///   - labelMedium: 14px - Metadata, timestamps
///   - labelSmall: 12px - Tiny labels
