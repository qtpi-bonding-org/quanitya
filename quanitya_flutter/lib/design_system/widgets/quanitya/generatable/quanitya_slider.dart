import 'package:flutter/material.dart';
import 'package:flutter_colorable/flutter_colorable.dart';

import '../../../primitives/quanitya_fonts.dart';
import '../../../primitives/app_sizes.dart';

/// Zen-styled slider - minimal track, accent-colored thumb.
///
/// Shows current value above the slider and min/max labels at the ends.
/// Follows manuscript aesthetic:
/// - Thin, subtle track
/// - Accent-colored thumb
/// - Current value displayed prominently
/// - Min/max range labels
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
    this.semanticLabel,
  });

  String _formatNum(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(1);

  @override
  Widget build(BuildContext context) {
    final labelStyle = TextStyle(
      fontFamily: QuanityaFonts.bodyFamily,
      fontSize: AppSizes.fontSmall,
      color: inactiveColor,
    );

    return Semantics(
      label: semanticLabel,
      value: _formatNum(value),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Current value display
          Text(
            _formatNum(value),
            style: TextStyle(
              fontFamily: QuanityaFonts.headerFamily,
              fontSize: AppSizes.fontBig,
              fontWeight: FontWeight.w600,
              color: activeColor,
            ),
          ),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: activeColor,
              inactiveTrackColor: inactiveColor.withValues(alpha: 0.3),
              thumbColor: thumbColor,
              overlayColor: thumbColor.withValues(alpha: 0.12),
              trackHeight: 2,
              thumbShape: const RoundSliderThumbShape(
                enabledThumbRadius: 8,
                elevation: 0,
                pressedElevation: 0,
              ),
              overlayShape: const RoundSliderOverlayShape(
                overlayRadius: 20,
              ),
              tickMarkShape: SliderTickMarkShape.noTickMark,
            ),
            child: Slider(
              value: value.clamp(min, max),
              min: min,
              max: max,
              divisions: divisions,
              onChanged: onChanged,
              semanticFormatterCallback: semanticLabel != null
                  ? (double val) => '$semanticLabel: ${_formatNum(val)}'
                  : null,
            ),
          ),
          // Min/max labels
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(_formatNum(min), style: labelStyle),
                Text(_formatNum(max), style: labelStyle),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
