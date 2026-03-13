import 'package:flutter/material.dart';
import 'package:flutter_colorable/flutter_colorable.dart';

import '../../../primitives/app_sizes.dart';
import '../../../primitives/quanitya_fonts.dart';
import '../../../primitives/quanitya_palette.dart';

/// Zen-styled dropdown - no outlines, just an underline and clean appearance.
///
/// Follows manuscript aesthetic:
/// - Transparent background (paper shows through)
/// - Subtle underline only (no box borders)
/// - Interactable color icon (teal - "tap me")
/// - Clean, minimal appearance
///
/// Defaults to palette colors so callers can omit color params.
// Note: @ColorableWidget annotation kept for documentation.
// Schema is defined in QuanityaWidgetRegistry instead of generated code.
@ColorableWidget('dropdown')
class QuanityaDropdown<T> extends StatelessWidget {
  @Colorable() final Color? dropdownColor;
  @Colorable() final Color? fillColor; // Kept for API compatibility
  @Colorable() final Color? borderColor; // Used for underline
  @Colorable() final Color? iconColor; // Accent color for icon

  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final String? hintText;
  final Color? textColor;
  final TextStyle? style; // Custom text style (for aesthetic fonts)
  final FormFieldValidator<T>? validator;

  const QuanityaDropdown({
    super.key,
    this.dropdownColor,
    this.fillColor,
    this.borderColor,
    this.iconColor,
    this.value,
    required this.items,
    this.onChanged,
    this.hintText,
    this.textColor,
    this.style,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    final palette = QuanityaPalette.primary;
    final effectiveDropdownColor = dropdownColor ?? palette.backgroundPrimary;
    final effectiveBorderColor = borderColor ?? palette.textSecondary;
    final effectiveIconColor = iconColor ?? palette.interactableColor;

    // Use provided style or fall back to default
    final baseStyle = style ?? TextStyle(
      fontFamily: QuanityaFonts.bodyFamily,
      fontSize: AppSizes.fontStandard,
    );
    final effectiveStyle = baseStyle.copyWith(
      color: textColor ?? baseStyle.color ?? QuanityaPalette.primary.textPrimary,
    );
    final hintStyle = baseStyle.copyWith(
      color: effectiveBorderColor.withValues(alpha: 0.6),
    );

    return DropdownButtonFormField<T>(
      initialValue: value,
      items: items,
      onChanged: onChanged,
      validator: validator,
      dropdownColor: effectiveDropdownColor,
      iconEnabledColor: effectiveIconColor,
      icon: Icon(
        Icons.keyboard_arrow_down,
        color: effectiveIconColor,
        size: AppSizes.iconMedium,
      ),
      style: effectiveStyle,
      borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: hintStyle,
        filled: false, // Transparent - let paper show through
        contentPadding: EdgeInsets.symmetric(
          horizontal: 0,
          vertical: AppSizes.space,
        ),
        // Zen style: underline only
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(
            color: effectiveBorderColor.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(
            color: effectiveIconColor,
            width: 2,
          ),
        ),
      ),
    );
  }
}
