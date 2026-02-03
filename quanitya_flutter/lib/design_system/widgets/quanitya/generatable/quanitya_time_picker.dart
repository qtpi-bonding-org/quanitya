import 'package:flutter/material.dart';
import 'package:flutter_colorable/flutter_colorable.dart';

import '../../../primitives/app_sizes.dart';
import '../../../primitives/quanitya_fonts.dart';

/// Zen-styled time picker - no outlines, just an underline and clean appearance.
///
/// Follows manuscript aesthetic:
/// - Transparent background (paper shows through)
/// - Subtle underline only (no box borders)
/// - Accent color icon
/// - Clean, minimal appearance
// Note: @ColorableWidget annotation kept for documentation.
// Schema is defined in QuanityaWidgetRegistry instead of generated code.
@ColorableWidget('timePicker')
class QuanityaTimePicker extends StatelessWidget {
  @Colorable() final Color primaryColor; // Accent color
  @Colorable() final Color backgroundColor; // Dialog background
  @Colorable() final Color borderColor; // Underline color
  @Colorable() final Color fillColor; // Kept for API compatibility

  final TimeOfDay? value;
  final ValueChanged<TimeOfDay>? onChanged;
  final String? hintText;
  final Color? textColor;

  const QuanityaTimePicker({
    super.key,
    required this.primaryColor,
    required this.backgroundColor,
    required this.borderColor,
    required this.fillColor,
    this.value,
    this.onChanged,
    this.hintText,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final hasValue = value != null;
    final displayText = hasValue
        ? _formatTime(value!)
        : (hintText ?? 'Select time');

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
                  style: TextStyle(
                    fontFamily: QuanityaFonts.bodyFamily,
                    fontSize: AppSizes.fontStandard,
                    color: hasValue
                        ? (textColor ?? Colors.black87)
                        : borderColor.withValues(alpha: 0.6),
                  ),
                ),
              ),
              Icon(
                Icons.access_time_outlined,
                color: primaryColor,
                size: AppSizes.iconSmall,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  Future<void> _showPicker(BuildContext context) async {
    final result = await showTimePicker(
      context: context,
      initialTime: value ?? TimeOfDay.now(),
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
