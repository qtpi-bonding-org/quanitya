import 'package:flutter/material.dart';
import '../../../../design_system/primitives/quanitya_fonts.dart';
import '../../../../design_system/primitives/quanitya_palette.dart';
import '../../../../design_system/primitives/app_spacings.dart';
import '../../../../support/extensions/context_extensions.dart';
import '../../../../design_system/primitives/app_sizes.dart';

/// Navigation indicator for the Temporal Home Screen.
/// Displays [-t] [t] [+t] and animates opacity based on scroll position.
/// 
/// Color logic (manuscript aesthetic):
/// - Inactive: interactableColor (teal) - "pencil sketch" / tappable
/// - Active: textPrimary (black) + bold - "inked in" / selected
class TemporalIndicator extends StatelessWidget {
  final PageController controller;
  final Function(int) onTabSelected;

  const TemporalIndicator({
    super.key,
    required this.controller,
    required this.onTabSelected,
  });


  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        // Page 1 is Center (t).
        // Page 0 is Left (-t).
        // Page 2 is Right (+t).
        // Default to 1.0 if not attached yet.
        final page = controller.hasClients ? (controller.page ?? 1.0) : 1.0;

        return SizedBox(
          height: AppSizes.inputHeight, // Using 56 instead of 60
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildLabel(context, '-t', 0, page),
              HSpace.x4,
              _buildLabel(context, 't', 1, page),
              HSpace.x4,
              _buildLabel(context, '+t', 2, page),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLabel(BuildContext context, String text, int index, double currentPage) {
    final palette = QuanityaPalette.primary;
    
    // Calculate "activeness" (0.0 to 1.0)
    final distance = (currentPage - index).abs();
    final active = (1.0 - distance).clamp(0.0, 1.0);

    // Snap at 0.5 threshold for clean transition
    final isActive = active > 0.5;

    // Color logic: inactive = interactable (teal), active = textPrimary (black)
    final color = isActive 
        ? palette.textPrimary 
        : palette.interactableColor;

    return GestureDetector(
      onTap: () => onTabSelected(index),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: EdgeInsets.symmetric(
            horizontal: AppSizes.space * 1.5, 
            vertical: AppSizes.space
        ),
        child: Text(
          text,
          style: context.text.bodyLarge?.copyWith(
            fontWeight: isActive ? FontWeight.w900 : FontWeight.w500,
            color: color,
            fontFamily: QuanityaFonts.headerFamily,
            fontSize: AppSizes.fontLarge,
          ),
        ),
      ),
    );
  }
}
