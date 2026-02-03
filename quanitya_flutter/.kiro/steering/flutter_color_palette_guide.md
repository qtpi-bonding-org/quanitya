# Flutter Color Palette Guide

## How It Works

Uses enumerated colors (`color1`, `color2`) instead of semantic names (`primary`, `secondary`). Automatic dark mode via mathematical luminance inversion.

## Basic Usage

### Define Palette
```dart
final palette = AppColorPalette.enumerated(
  colors: [
    Color(0xFF1976D2), // color1 - Blue
    Color(0xFF388E3C), // color2 - Green
    Color(0xFFF57C00), // color3 - Orange
  ],
  neutrals: [
    Color(0xFF212121), // neutral1 - Dark
    Color(0xFFF5F5F5), // neutral2 - Light
  ],
);
```

### Get Colors
```dart
final blue = palette.getColor('color1');
final darkPalette = palette.symmetricPalette; // Automatic dark mode
```

### Map to UI Semantics
```dart
extension QuanityaColors on IColorPalette {
  Color get primaryColor => getColor('color1')!;
  Color get successColor => getColor('color2')!;
  Color get warningColor => getColor('color3')!;
  Color get textPrimary => getColor('neutral1')!;
  Color get backgroundPrimary => getColor('neutral2')!;
}
```

### Use in Widgets
```dart
Container(
  color: palette.primaryColor,
  child: Text(
    'Hello',
    style: TextStyle(color: palette.textPrimary),
  ),
)
```

## Accessibility Testing

```dart
// Check contrast
final grade = ContrastCalculator.getAccessibilityGrade(fg, bg); // AAA, AA, A, FAIL

// Visual testing widget
ContrastMatrixWidget(
  lightPalette: palette,
  showColorblindModes: true,
  showAccessibilityGrades: true,
)
```

## Integration Status

- ✅ **Available**: Library added, demo at `color_palette_demo.dart`
- 🔄 **Partial**: Theme structure exists in `app_theme.dart` but not implemented (all TODOs)
- ❌ **Missing**: Not used in actual UI components yet