import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:injectable/injectable.dart';
import '../config/debug_log.dart';

import '../../logic/templates/enums/ai/allowed_font.dart';

const _tag = 'infrastructure/fonts/font_preloader_service';

/// Service to preload Google Fonts for offline use.
/// 
/// Bundled fonts (Atkinson Hyperlegible Mono, Noto Sans Mono) are always available.
/// This service only preloads Google Fonts that need downloading.
@singleton
class FontPreloaderService {
  bool _isPreloaded = false;
  final Set<String> _bundledFonts = {
    'Atkinson Hyperlegible Mono',
    'Noto Sans Mono',
  };
  
  /// Whether Google Fonts have been preloaded
  bool get isPreloaded => _isPreloaded;
  
  /// Preload Google Fonts (not bundled fonts) for offline use.
  /// 
  /// Runs in background - doesn't block app startup.
  /// Bundled fonts are always available immediately.
  Future<void> preloadAllFonts() async {
    if (_isPreloaded) return;
    
    Log.d(_tag, 'Preloading Google Fonts in background...');
    
    final futures = <Future<void>>[];
    
    // Only preload Google Fonts (skip bundled fonts)
    for (final font in AllowedFont.values) {
      if (!_bundledFonts.contains(font.googleFontName)) {
        futures.add(_preloadFont(font.googleFontName));
      }
    }
    
    if (futures.isEmpty) {
      Log.d(_tag, 'No Google Fonts to preload (all fonts are bundled)');
      _isPreloaded = true;
      return;
    }
    
    try {
      await Future.wait(futures);
      _isPreloaded = true;
      Log.d(_tag, 'Google Fonts preloaded successfully');
    } catch (e) {
      Log.d(_tag, 'Some Google Fonts failed to preload: $e');
      // Don't throw - app should still work with system fonts
      _isPreloaded = true; // Mark as done to avoid retries
    }
  }
  
  /// Preload a specific Google Font by name.
  Future<void> _preloadFont(String fontName) async {
    try {
      // Preload regular and bold weights
      final regularFont = GoogleFonts.getFont(fontName, fontWeight: FontWeight.w400);
      final boldFont = GoogleFonts.getFont(fontName, fontWeight: FontWeight.w700);
      
      await Future.wait([
        Future.value(regularFont.fontFamily),
        Future.value(boldFont.fontFamily),
      ]);
      
      Log.d(_tag, 'Preloaded Google Font: $fontName');
    } catch (e) {
      Log.d(_tag, 'Failed to preload Google Font: $fontName: $e');
    }
  }
  
  /// Get a TextStyle with the specified font, with proper fallback handling.
  /// 
  /// Bundled fonts are used directly, Google Fonts go through GoogleFonts.getFont().
  TextStyle getTextStyle(String fontName, {
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
  }) {
    // Bundled fonts - use directly (no GoogleFonts wrapper needed)
    if (_bundledFonts.contains(fontName)) {
      return TextStyle(
        fontFamily: fontName,
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
      );
    }
    
    // Google Fonts - use GoogleFonts.getFont()
    try {
      return GoogleFonts.getFont(
        fontName,
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
      );
    } catch (e) {
      Log.d(_tag, 'Google Font $fontName not available, using system default');
      return TextStyle(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
      );
    }
  }
  
  /// Check if a specific font is available.
  /// Bundled fonts are always available, Google Fonts depend on preloading.
  bool isFontAvailable(String fontName) {
    // Bundled fonts are always available
    if (_bundledFonts.contains(fontName)) {
      return true;
    }
    
    // Google Fonts - check if preloaded
    return _isPreloaded;
  }
}