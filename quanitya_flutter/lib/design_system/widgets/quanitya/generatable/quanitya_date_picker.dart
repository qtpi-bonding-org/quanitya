import 'package:flutter/material.dart';
import 'package:flutter_colorable/flutter_colorable.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../primitives/app_sizes.dart';
import '../../../primitives/quanitya_fonts.dart';
import '../../../primitives/quanitya_palette.dart';

/// Zen-styled date picker - no outlines, just an underline and clean appearance.
///
/// Follows manuscript aesthetic:
/// - Transparent background (paper shows through)
/// - Subtle underline only (no box borders)
/// - Accent color icon
/// - Clean, minimal appearance
// Note: @ColorableWidget annotation kept for documentation.
// Schema is defined in QuanityaWidgetRegistry instead of generated code.
@ColorableWidget('datePicker')
class QuanityaDatePicker extends StatelessWidget {
  @Colorable() final Color primaryColor; // Accent color
  @Colorable() final Color backgroundColor; // Dialog background
  @Colorable() final Color borderColor; // Underline color
  @Colorable() final Color fillColor; // Kept for API compatibility

  final DateTime? value;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final ValueChanged<DateTime>? onChanged;
  final String? hintText;
  final Color? textColor;
  final TextStyle? textStyle; // Custom text style (for aesthetic fonts)

  const QuanityaDatePicker({
    super.key,
    required this.primaryColor,
    required this.backgroundColor,
    required this.borderColor,
    required this.fillColor,
    this.value,
    this.firstDate,
    this.lastDate,
    this.onChanged,
    this.hintText,
    this.textColor,
    this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    final hasValue = value != null;
    final displayText = hasValue
        ? _formatDate(value!)
        : (hintText ?? AppLocalizations.of(context)?.selectDate ?? 'Select date');

    // Use provided style or fall back to default
    final baseStyle = textStyle ?? TextStyle(
      fontFamily: QuanityaFonts.bodyFamily,
      fontSize: AppSizes.fontStandard,
    );

    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: onChanged != null ? () => _showPicker(context) : null,
        child: Container(
          constraints: BoxConstraints(minHeight: AppSizes.buttonHeight),
          decoration: BoxDecoration(
            // Zen style: underline only, no box
            border: Border(
              bottom: BorderSide(
                color: borderColor.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  displayText,
                  style: baseStyle.copyWith(
                    color: hasValue
                        ? (textColor ?? baseStyle.color ?? QuanityaPalette.primary.textPrimary)
                        : borderColor.withValues(alpha: 0.6),
                  ),
                ),
              ),
              Icon(
                Icons.calendar_today_outlined,
                color: primaryColor,
                size: AppSizes.iconSmall,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    // Simple format: Jan 15, 2024
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  Future<void> _showPicker(BuildContext context) async {
    final result = await showDatePicker(
      context: context,
      initialDate: value ?? DateTime.now(),
      firstDate: firstDate ?? DateTime(1900),
      lastDate: lastDate ?? DateTime(2100),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.light(
            primary: primaryColor,
            surface: backgroundColor,
          ),
        ),
        child: child!,
      ),
    );
    if (result != null) onChanged?.call(result);
  }
}
