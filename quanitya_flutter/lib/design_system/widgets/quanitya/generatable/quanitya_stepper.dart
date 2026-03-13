import 'package:flutter/material.dart';
import 'package:flutter_colorable/flutter_colorable.dart';

import '../../../primitives/app_sizes.dart';
import '../../../primitives/app_spacings.dart';
import '../../../primitives/quanitya_fonts.dart';

/// Zen-styled stepper - minimal buttons with accent color, no heavy backgrounds.
///
/// Follows manuscript aesthetic:
/// - Transparent button backgrounds (just icons)
/// - Accent color for icons
/// - Clean, minimal appearance
/// - Value displayed prominently
// Note: @ColorableWidget annotation kept for documentation.
// Schema is defined in QuanityaWidgetRegistry instead of generated code.
@ColorableWidget('stepper')
class QuanityaStepper extends StatelessWidget {
  @Colorable() final Color buttonColor; // Accent color for icons
  @Colorable() final Color iconColor; // Kept for API compatibility (same as buttonColor)
  @Colorable() final Color valueColor; // Text color for value

  final num value;
  final num min;
  final num max;
  final num step;
  final ValueChanged<num>? onChanged;

  const QuanityaStepper({
    super.key,
    required this.buttonColor,
    required this.iconColor,
    required this.valueColor,
    required this.value,
    this.min = 0,
    this.max = 100,
    this.step = 1,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final canDecrement = value > min && onChanged != null;
    final canIncrement = value < max && onChanged != null;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Decrement button - zen style: just icon, no background
        Semantics(
          button: true,
          label: 'Decrease',
          child: _ZenStepperButton(
            icon: Icons.remove,
            color: buttonColor,
            enabled: canDecrement,
            onTap: canDecrement ? () => onChanged?.call(value - step) : null,
          ),
        ),
        HSpace.x3, // Generous spacing
        // Value display - prominent
        Semantics(
          value: _formatValue(value),
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: AppSizes.buttonHeight * 1.5),
            child: Text(
              _formatValue(value),
              style: TextStyle(
                fontFamily: QuanityaFonts.headerFamily,
                color: valueColor,
                fontSize: AppSizes.fontBig,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        HSpace.x3,
        // Increment button
        Semantics(
          button: true,
          label: 'Increase',
          child: _ZenStepperButton(
            icon: Icons.add,
            color: buttonColor,
            enabled: canIncrement,
            onTap: canIncrement ? () => onChanged?.call(value + step) : null,
          ),
        ),
      ],
    );
  }

  String _formatValue(num val) {
    if (val is int || val == val.toInt()) {
      return val.toInt().toString();
    }
    return val.toStringAsFixed(1);
  }
}

/// Zen-styled stepper button - just an icon with touch feedback.
class _ZenStepperButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final bool enabled;
  final VoidCallback? onTap;

  const _ZenStepperButton({
    required this.icon,
    required this.color,
    required this.enabled,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = enabled ? color : color.withValues(alpha: 0.3);

    return SizedBox(
      width: AppSizes.buttonHeight,
      height: AppSizes.buttonHeight,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppSizes.buttonHeight / 2),
          child: Center(
            child: Icon(
              icon,
              color: effectiveColor,
              size: AppSizes.iconMedium,
            ),
          ),
        ),
      ),
    );
  }
}
