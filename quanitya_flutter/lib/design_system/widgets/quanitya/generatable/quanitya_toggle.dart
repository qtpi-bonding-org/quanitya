import 'package:flutter/material.dart';
import 'package:flutter_colorable/flutter_colorable.dart';

import '../../../primitives/app_sizes.dart';

/// Zen-styled toggle switch - clean, minimal appearance.
///
/// Follows manuscript aesthetic:
/// - No outline on track
/// - Accent color when active
/// - Subtle inactive state
// Note: @ColorableWidget annotation kept for documentation.
// Schema is defined in QuanityaWidgetRegistry instead of generated code.
@ColorableWidget('toggle')
class QuanityaToggle extends StatelessWidget {
  @Colorable() final Color activeThumbColor;
  @Colorable() final Color activeTrackColor;
  @Colorable() final Color inactiveThumbColor;
  @Colorable() final Color inactiveTrackColor;

  final bool value;
  final ValueChanged<bool>? onChanged;

  const QuanityaToggle({
    super.key,
    required this.activeThumbColor,
    required this.activeTrackColor,
    required this.inactiveThumbColor,
    required this.inactiveTrackColor,
    required this.value,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    // Wrap in SizedBox to ensure consistent touch target
    return SizedBox(
      height: AppSizes.buttonHeight,
      child: Align(
        alignment: Alignment.centerLeft,
        child: Switch(
          value: value,
          onChanged: onChanged,
          thumbColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return activeThumbColor;
            }
            return inactiveThumbColor;
          }),
          trackColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return activeTrackColor;
            }
            return inactiveTrackColor.withValues(alpha: 0.3);
          }),
          // Zen style: no outline
          trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
          trackOutlineWidth: WidgetStateProperty.all(0),
        ),
      ),
    );
  }
}
