import 'package:flutter/material.dart';
import '../primitives/app_sizes.dart';
import '../../support/extensions/context_extensions.dart';
import '../primitives/quanitya_palette.dart';

/// A custom text field with a "Ghost" fill style.
/// 
/// Features:
/// - Subtle background fill (no border)
/// - "Paper" feel rather than "box"
/// - Aggressive hint text styling
class QuanityaTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? hintText;
  final String? labelText;
  final ValueChanged<String>? onChanged;
  final TextInputType? keyboardType;
  final int? maxLines;
  final int? minLines;
  final bool autofocus;
  final TextStyle? style;
  final TextStyle? hintStyle;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final TextInputAction? textInputAction;
  final VoidCallback? onEditingComplete;
  final ValueChanged<String>? onSubmitted;
  final FocusNode? focusNode;
  final bool enabled;

  const QuanityaTextField({
    super.key,
    this.controller,
    this.hintText,
    this.labelText,
    this.onChanged,
    this.keyboardType,
    this.maxLines = 1,
    this.minLines,
    this.autofocus = false,
    this.style,
    this.hintStyle,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.textInputAction,
    this.onEditingComplete,
    this.onSubmitted,
    this.focusNode,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    // Determine the effective text style
    final effectiveStyle = style ?? context.text.bodyLarge;
    
    // Determine hint style (lighter grey)
    final effectiveHintStyle = hintStyle ?? context.text.bodyLarge?.copyWith(
      color: context.colors.textSecondary.withValues(alpha: 0.5),
    );

    return TextField(
      controller: controller,
      onChanged: onChanged,
      keyboardType: keyboardType,
      maxLines: maxLines,
      minLines: minLines,
      autofocus: autofocus,
      style: effectiveStyle,
      obscureText: obscureText,
      textInputAction: textInputAction,
      onEditingComplete: onEditingComplete,
      onSubmitted: onSubmitted,
      focusNode: focusNode,
      enabled: enabled,
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
        fillColor: context.colors.textSecondary.withValues(alpha: 0.05), // Ghost fill
        contentPadding: EdgeInsets.all(AppSizes.space * 1.5), // Comfortable padding
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
          borderSide: BorderSide.none, // No border
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
          borderSide: BorderSide.none, // Keep it ghost-like, maybe user wants highlight?
          // If we want a subtle highlight, we could add a very faint border, but "no outlines" was requested.
          // We can rely on the cursor and input content for focus indication.
        ),
        errorBorder: OutlineInputBorder(
           borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
           borderSide: BorderSide(color: context.colors.destructiveColor, width: 1),
        ),
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
      ),
    );
  }
}
