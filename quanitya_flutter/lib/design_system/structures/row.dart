import 'package:flutter/material.dart';
import '../primitives/app_spacings.dart';

class QuanityaRow extends StatelessWidget {
  final Widget? start; // Slot 1: Fixed (Icon, Time, Label)
  final Widget? middle; // Slot 2: Flexible (Title, Description) - Auto Expanded
  final Widget? end; // Slot 3: Fixed (Button, Checkbox, Status)

  final CrossAxisAlignment alignment;
  final Widget? spacing; // The gap between slots

  const QuanityaRow({
    super.key,
    this.start,
    this.middle,
    this.end,
    // Default to Top Align (as per Design Guide)
    this.alignment = CrossAxisAlignment.start,
    // Default to "Standard Breath" (16px)
    this.spacing,
  });

  Widget get _defaultSpacing => HSpace.x2;

  @override
  Widget build(BuildContext context) {
    final actualSpacing = spacing ?? _defaultSpacing;

    return Row(
      crossAxisAlignment: alignment,
      children: [
        if (start != null) ...[
          start!,
          actualSpacing,
        ],

        // AUTOMATION: The middle slot is always Expanded
        if (middle != null)
          Expanded(child: middle!)
        else
          const Spacer(), // If no middle, push end to the right

        if (end != null) ...[
          actualSpacing,
          end!,
        ],
      ],
    );
  }
}
