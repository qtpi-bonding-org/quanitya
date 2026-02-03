import 'package:flutter/material.dart';
import '../primitives/app_sizes.dart';
import '../../support/extensions/context_extensions.dart';
import '../primitives/quanitya_palette.dart';

/// A custom text form field with a "Ghost" fill style and validation support.
/// 
/// Features:
/// - Subtle background fill (no border)
/// - "Paper" feel rather than "box"
/// - Form validation support via [validator]
/// - Error styling with subtle border on validation failure
class QuanityaTextFormField extends StatelessWidget {
  final TextEditingController? controller;
  final String? hintText;
  final String? labelText;
  final ValueChanged<String>? onChanged;
  final TextInputType? keyboardType;
  final int? maxLines;
  final bool autofocus;
  final TextStyle? style;
  final TextStyle? hintStyle;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final TextInputAction? textInputAction;
  final VoidCallback? onEditingComplete;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onFieldSubmitted;
  final AutovalidateMode? autovalidateMode;

  const QuanityaTextFormField({
    super.key,
    this.controller,
    this.hintText,
    this.labelText,
    this.onChanged,
    this.keyboardType,
    this.maxLines = 1,
    this.autofocus = false,
    this.style,
    this.hintStyle,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.textInputAction,
    this.onEditingComplete,
    this.validator,
    this.onFieldSubmitted,
    this.autovalidateMode,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveStyle = style ?? context.text.bodyLarge;
    
    final effectiveHintStyle = hintStyle ?? context.text.bodyLarge?.copyWith(
      color: context.colors.textSecondary.withValues(alpha: 0.5),
    );

    return TextFormField(
      controller: controller,
      onChanged: onChanged,
      keyboardType: keyboardType,
      maxLines: maxLines,
      autofocus: autofocus,
      style: effectiveStyle,
      obscureText: obscureText,
      textInputAction: textInputAction,
      onEditingComplete: onEditingComplete,
      validator: validator,
      onFieldSubmitted: onFieldSubmitted,
      autovalidateMode: autovalidateMode,
      cursorColor: context.colors.primaryColor,
      decoration: InputDecoration(
        labelText: labelText,
        labelStyle: context.text.bodySmall?.copyWith(
          color: context.colors.textSecondary,
          fontWeight: FontWeight.bold,
        ),
        hintText: hintText,
        hintStyle: effectiveHintStyle,
        filled: true,
        fillColor: context.colors.textSecondary.withValues(alpha: 0.05),
        contentPadding: EdgeInsets.all(AppSizes.space * 1.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
          borderSide: BorderSide.none,
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
          borderSide: BorderSide(
            color: context.colors.errorColor,
            width: AppSizes.borderWidth,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
          borderSide: BorderSide(
            color: context.colors.errorColor,
            width: AppSizes.borderWidth,
          ),
        ),
        errorStyle: context.text.bodySmall?.copyWith(
          color: context.colors.errorColor,
        ),
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
      ),
    );
  }
}
