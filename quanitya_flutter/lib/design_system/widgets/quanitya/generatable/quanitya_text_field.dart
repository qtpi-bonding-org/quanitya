import 'package:flutter/material.dart';
import 'package:flutter_colorable/flutter_colorable.dart';

import '../../../primitives/app_sizes.dart';
import '../../../primitives/quanitya_fonts.dart';

/// Zen-styled text field - no outlines, just an underline that appears on focus.
///
/// Follows manuscript aesthetic:
/// - Transparent background (paper shows through)
/// - Subtle underline only (no box borders)
/// - Accent color on focus
/// - Clean, minimal appearance
// Note: @ColorableWidget annotation kept for documentation.
// Schema is defined in QuanityaWidgetRegistry instead of generated code.
@ColorableWidget('textField')
class QuanityaTextField extends StatelessWidget {
  @Colorable() final Color cursorColor;
  @Colorable() final Color fillColor; // Kept for API compatibility, but transparent by default
  @Colorable() final Color borderColor; // Used for underline
  @Colorable() final Color focusedBorderColor; // Accent color on focus
  @Colorable() final Color errorBorderColor;

  final TextEditingController? controller;
  final String? hintText;
  final int maxLines;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;
  final Color? textColor;
  final Color? hintColor;
  final TextStyle? style; // Custom text style (for aesthetic fonts)
  final TextStyle? hintStyle; // Custom hint style
  final String? semanticLabel;

  const QuanityaTextField({
    super.key,
    required this.cursorColor,
    required this.fillColor,
    required this.borderColor,
    required this.focusedBorderColor,
    required this.errorBorderColor,
    this.controller,
    this.hintText,
    this.maxLines = 1,
    this.keyboardType,
    this.onChanged,
    this.textColor,
    this.hintColor,
    this.style,
    this.hintStyle,
    this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    // Use provided style or fall back to default
    final baseStyle = style ?? TextStyle(
      fontFamily: QuanityaFonts.bodyFamily,
      fontSize: AppSizes.fontStandard,
    );
    final effectiveStyle = baseStyle.copyWith(
      color: textColor ?? baseStyle.color,
    );
    final effectiveHintStyle = hintStyle ?? baseStyle.copyWith(
      color: hintColor ?? borderColor.withValues(alpha: 0.6),
    );

    return Semantics(
      label: semanticLabel ?? hintText,
      textField: true,
      child: TextField(
      controller: controller,
      cursorColor: cursorColor,
      maxLines: maxLines,
      keyboardType: keyboardType,
      onChanged: onChanged,
      style: effectiveStyle,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: effectiveHintStyle,
        filled: false, // Transparent - let paper show through
        contentPadding: EdgeInsets.symmetric(
          horizontal: 0, // No horizontal padding - zen minimal
          vertical: AppSizes.space,
        ),
        // Zen style: underline only, no box borders
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(
            color: borderColor.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(
            color: focusedBorderColor,
            width: 2,
          ),
        ),
        errorBorder: UnderlineInputBorder(
          borderSide: BorderSide(
            color: errorBorderColor,
            width: 1,
          ),
        ),
        focusedErrorBorder: UnderlineInputBorder(
          borderSide: BorderSide(
            color: errorBorderColor,
            width: 2,
          ),
        ),
      ),
      ),
    );
  }
}
