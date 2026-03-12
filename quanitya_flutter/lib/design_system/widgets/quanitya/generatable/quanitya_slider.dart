import 'package:flutter/material.dart';
import 'package:flutter_colorable/flutter_colorable.dart';

/// Zen-styled slider - minimal track, accent-colored thumb.
///
/// Follows manuscript aesthetic:
/// - Thin, subtle track
/// - Accent-colored thumb
/// - Clean, minimal appearance
// Note: @ColorableWidget annotation kept for documentation.
// Schema is defined in QuanityaWidgetRegistry instead of generated code.
@ColorableWidget('slider')
class QuanityaSlider extends StatelessWidget {
  @Colorable() final Color activeColor; // Accent color for active track + thumb
  @Colorable() final Color inactiveColor; // Subtle color for inactive track
  @Colorable() final Color thumbColor; // Thumb color (usually same as activeColor)

  final double value;
  final double min;
  final double max;
  final int? divisions;
  final ValueChanged<double>? onChanged;
  final bool showValue;
  final String? semanticLabel;

  const QuanityaSlider({
    super.key,
    required this.activeColor,
    required this.inactiveColor,
    required this.thumbColor,
    required this.value,
    this.min = 0,
    this.max = 100,
    this.divisions,
    this.onChanged,
    this.showValue = false,
    this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      value: '$value',
      child: SliderTheme(
        data: SliderThemeData(
          activeTrackColor: activeColor,
          inactiveTrackColor: inactiveColor.withValues(alpha: 0.3),
          thumbColor: thumbColor,
          overlayColor: thumbColor.withValues(alpha: 0.12),
          // Zen style: thin track, small thumb
          trackHeight: 2,
          thumbShape: const RoundSliderThumbShape(
            enabledThumbRadius: 8,
            elevation: 0, // No shadow - flat zen style
            pressedElevation: 0,
          ),
          overlayShape: const RoundSliderOverlayShape(
            overlayRadius: 20, // Touch feedback area
          ),
          // No tick marks for cleaner look
          tickMarkShape: SliderTickMarkShape.noTickMark,
        ),
        child: Slider(
          value: value.clamp(min, max),
          min: min,
          max: max,
          divisions: divisions,
          onChanged: onChanged,
          semanticFormatterCallback: semanticLabel != null
              ? (double val) => '$semanticLabel: $val'
              : null,
        ),
      ),
    );
  }
}
