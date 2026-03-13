import 'package:flutter/material.dart';
import 'package:flutter_colorable/flutter_colorable.dart';

import '../../../primitives/app_sizes.dart';
import '../../../primitives/quanitya_palette.dart';

/// Zen-styled toggle switch - clean, minimal appearance.
///
/// Follows manuscript aesthetic:
/// - No outline on track
/// - Accent color when active
/// - Subtle inactive state
///
/// Defaults to palette state colors (sage green on, stone grey off)
/// with washi white thumb.
// Note: @ColorableWidget annotation kept for documentation.
// Schema is defined in QuanityaWidgetRegistry instead of generated code.
@ColorableWidget('toggle')
class QuanityaToggle extends StatelessWidget {
  @Colorable() final Color? activeThumbColor;
  @Colorable() final Color? activeTrackColor;
  @Colorable() final Color? inactiveThumbColor;
  @Colorable() final Color? inactiveTrackColor;

  final bool value;
  final ValueChanged<bool>? onChanged;
  final String? semanticLabel;

  const QuanityaToggle({
    super.key,
    this.activeThumbColor,
    this.activeTrackColor,
    this.inactiveThumbColor,
    this.inactiveTrackColor,
    required this.value,
    this.onChanged,
    this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    final palette = QuanityaPalette.primary;
    final thumbOn = activeThumbColor ?? palette.backgroundPrimary;
    final thumbOff = inactiveThumbColor ?? palette.backgroundPrimary;
    final trackOn = activeTrackColor ?? palette.stateOnColor;
    final trackOff = inactiveTrackColor ?? palette.stateOffColor;

    // Wrap in SizedBox to ensure consistent touch target
    return Semantics(
      toggled: value,
      label: semanticLabel,
      child: SizedBox(
        height: AppSizes.buttonHeight,
        child: Align(
          alignment: Alignment.centerLeft,
          child: Switch(
            value: value,
            onChanged: onChanged,
            thumbColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return thumbOn;
              }
              return thumbOff;
            }),
            trackColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return trackOn;
              }
              return trackOff.withValues(alpha: 0.3);
            }),
            // Zen style: no outline
            trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
            trackOutlineWidth: WidgetStateProperty.all(0),
          ),
        ),
      ),
    );
  }
}
