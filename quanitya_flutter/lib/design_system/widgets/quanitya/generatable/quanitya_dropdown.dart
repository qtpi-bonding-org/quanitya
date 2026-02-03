import 'package:flutter/material.dart';
import 'package:flutter_colorable/flutter_colorable.dart';

import '../../../primitives/app_sizes.dart';
import '../../../primitives/quanitya_fonts.dart';

/// Zen-styled dropdown - no outlines, just an underline and clean appearance.
///
/// Follows manuscript aesthetic:
/// - Transparent background (paper shows through)
/// - Subtle underline only (no box borders)
/// - Accent color icon
/// - Clean, minimal appearance
// Note: @ColorableWidget annotation kept for documentation.
// Schema is defined in QuanityaWidgetRegistry instead of generated code.
@ColorableWidget('dropdown')
class QuanityaDropdown<T> extends StatelessWidget {
  @Colorable() final Color dropdownColor;
  @Colorable() final Color fillColor; // Kept for API compatibility
  @Colorable() final Color borderColor; // Used for underline
  @Colorable() final Color iconColor; // Accent color for icon

  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final String? hintText;
  final Color? textColor;
  final TextStyle? style; // Custom text style (for aesthetic fonts)

  const QuanityaDropdown({
    super.key,
    required this.dropdownColor,
    required this.fillColor,
    required this.borderColor,
    required this.iconColor,
    this.value,
    required this.items,
    this.onChanged,
    this.hintText,
    this.textColor,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    // Use provided style or fall back to default
    final baseStyle = style ?? TextStyle(
      fontFamily: QuanityaFonts.bodyFamily,
      fontSize: AppSizes.fontStandard,
    );
    final effectiveStyle = baseStyle.copyWith(
      color: textColor ?? baseStyle.color ?? Colors.black87,
    );
    final hintStyle = baseStyle.copyWith(
      color: borderColor.withValues(alpha: 0.6),
    );

    return DropdownButtonFormField<T>(
      initialValue: value,
      items: items,
      onChanged: onChanged,
      dropdownColor: dropdownColor,
      iconEnabledColor: iconColor,
      icon: Icon(
        Icons.keyboard_arrow_down,
        color: iconColor,
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
            color: borderColor.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(
            color: iconColor,
            width: 2,
          ),
        ),
      ),
    );
  }
}
