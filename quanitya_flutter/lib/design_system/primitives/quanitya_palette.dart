import 'package:flutter/material.dart';
import 'package:flutter_color_palette/flutter_color_palette.dart';

/// Quanitya's core color palette
/// 
/// Light mode colors:
/// - color1: #FAF7F0 (Warm white - background)
/// - color2: #2B2B2B (Soft black - text)
/// - color3: #006280 (Teal - accent/primary)
/// - neutral1: #4D5B60 (Blue-grey - secondary text)
/// 
/// Interactable colors:
/// - interactable: #006280 (Teal - "tap me" signal)
/// 
/// Semantic colors (pastel - for toast backgrounds):
/// - info: #B9D9ED (Soft blue)
/// - success: #CDE8C4 (Mint green)
/// - error: #F4C1C1 (Soft pink)
/// - warning: #F5E6A3 (Pale yellow)
/// 
/// Destructive color:
/// - destructive: #BC4B41 (Dark red - for delete icons/text)
class QuanityaPalette {
  static final IColorPalette primary = AppColorPalette(
    colors: {
      // Core palette (light mode)
      'color1': const Color(0xFFFAF7F0), // Washi White - background
      'color2': const Color(0xFF2B2B2B), // Sumi Black - text
      'color3': const Color(0xFF006280), // Teal - accent/primary
      'neutral1': const Color(0xFF4D5B60), // Blue-grey - secondary text
      
      // Interactable color - "tap me" signal (pencil sketch → inked in)
      'interactable': const Color(0xFF006280), // Teal
      
      // Semantic colors (pastel - for toast backgrounds)
      'info': const Color(0xFFB9D9ED),     // Soft blue
      'success': const Color(0xFFCDE8C4),  // Mint green
      'error': const Color(0xFFF4C1C1),    // Soft pink
      'warning': const Color(0xFFF5E6A3),  // Pale yellow
      
      // Destructive color (for delete icons/text)
      'destructive': const Color(0xFFBC4B41), // Dark red
    },
    name: 'Quanitya Primary',
  );
  
  /// Automatic dark mode via luminance inversion
  static IColorPalette get dark => primary.symmetricPalette;
  
  /// Zen Data Palette - 10 harmonious colors for charts and data visualization
  /// Inspired by traditional Japanese colors with good contrast
  static const List<Color> zenDataPalette = [
    Color(0xFF006280), // 1. Tetsu (Iron Teal) - Primary
    Color(0xFFBC4B41), // 2. Shu (Vermilion) - Destructive
    Color(0xFFD4A017), // 3. Karashi (Mustard) - Earthy Yellow
    Color(0xFF4A5D23), // 4. Matsu (Pine) - Deep Green
    Color(0xFF374F6B), // 5. Ai (Indigo) - Deep Blue
    Color(0xFFCC5D2B), // 6. Kaki (Persimmon) - Burnt Orange
    Color(0xFF7A6B8E), // 7. Fuji (Wisteria) - Dusty Purple
    Color(0xFF5C6F7C), // 8. Sora (Slate) - Storm Grey
    Color(0xFF8D5B4C), // 9. Kurumi (Walnut) - Red-Brown
    Color(0xFF7C9473), // 10. Take (Bamboo) - Soft Green
  ];

  /// D3 / Mathematica category10 — standard data visualization palette
  static const List<Color> category10 = [
    Color(0xFF1F77B4), // blue
    Color(0xFFFF7F0E), // orange
    Color(0xFF2CA02C), // green
    Color(0xFFD62728), // red
    Color(0xFF9467BD), // purple
    Color(0xFF8C564B), // brown
    Color(0xFFE377C2), // pink
    Color(0xFF7F7F7F), // gray
    Color(0xFFBCBD22), // olive
    Color(0xFF17BECF), // cyan
  ];
}

/// Extension for semantic color access
extension QuanityaColors on IColorPalette {
  // Background & Surface
  Color get backgroundPrimary => getColor('color1')!;
  
  // Text
  Color get textPrimary => getColor('color2')!;
  Color get textSecondary => getColor('neutral1')!;
  
  // Accent/Primary action color
  Color get primaryColor => getColor('color3')!;
  Color get accentColor => getColor('color3')!;
  Color get secondaryColor => getColor('neutral1')!;
  
  // Interactable - "tap me" signal
  Color get interactableColor => getColor('interactable')!;
  
  // Semantic colors (pastel - for toast backgrounds)
  Color get infoColor => getColor('info')!;
  Color get successColor => getColor('success')!;
  Color get errorColor => getColor('error')!;
  Color get warningColor => getColor('warning')!;
  
  // Destructive color (for delete icons/text)
  Color get destructiveColor => getColor('destructive')!;
}