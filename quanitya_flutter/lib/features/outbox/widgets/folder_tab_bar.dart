import 'package:flutter/material.dart';

import '../../../design_system/primitives/app_sizes.dart';
import '../../../design_system/primitives/app_spacings.dart';
import '../../../design_system/primitives/quanitya_palette.dart';
import '../../../support/extensions/context_extensions.dart';

/// Data for a single folder tab.
class FolderTab {
  final IconData icon;
  final String label;

  const FolderTab({required this.icon, required this.label});
}

/// A tab bar styled like physical file folder tabs.
///
/// Each tab looks like a folder divider with a rounded top edge that
/// "sticks up" when selected, visually connecting to the content above.
class FolderTabBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTabSelected;
  final List<FolderTab> tabs;

  const FolderTabBar({
    super.key,
    required this.currentIndex,
    required this.onTabSelected,
    required this.tabs,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: EdgeInsets.only(
          left: AppSizes.space,
          right: AppSizes.space,
          bottom: AppSizes.space,
        ),
        child: Row(
          children: List.generate(tabs.length, (index) {
            final isSelected = index == currentIndex;
            return Expanded(
              child: GestureDetector(
                onTap: () => onTabSelected(index),
                behavior: HitTestBehavior.opaque,
                child: _FolderTabWidget(
                  tab: tabs[index],
                  isSelected: isSelected,
                  position: index == 0
                      ? _TabPosition.first
                      : index == tabs.length - 1
                          ? _TabPosition.last
                          : _TabPosition.middle,
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

enum _TabPosition { first, middle, last }

class _FolderTabWidget extends StatelessWidget {
  final FolderTab tab;
  final bool isSelected;
  final _TabPosition position;

  const _FolderTabWidget({
    required this.tab,
    required this.isSelected,
    required this.position,
  });

  @override
  Widget build(BuildContext context) {
    final palette = QuanityaPalette.primary;
    final tabColor = isSelected ? palette.textPrimary : palette.interactableColor;
    final borderColor = (isSelected ? palette.textPrimary : palette.interactableColor).withValues(alpha: 0.3);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      margin: EdgeInsets.only(
        left: position == _TabPosition.first ? 0 : 2,
        right: position == _TabPosition.last ? 0 : 2,
      ),
      child: CustomPaint(
        painter: _FolderTabPainter(
          isSelected: isSelected,
          fillColor: Colors.transparent,
          borderColor: borderColor,
          backgroundColor: context.colors.backgroundPrimary,
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(
            vertical: isSelected ? AppSizes.space * 1.5 : AppSizes.space,
            horizontal: AppSizes.space,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                tab.icon,
                size: isSelected ? AppSizes.iconMedium : AppSizes.iconSmall + 2,
                color: tabColor,
              ),
              if (isSelected) ...[
                VSpace.x05,
                Text(
                  tab.label,
                  style: context.text.labelSmall?.copyWith(
                    color: tabColor,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Custom painter that draws a folder tab shape with rounded top corners
/// and a flat bottom that connects to the content area.
class _FolderTabPainter extends CustomPainter {
  final bool isSelected;
  final Color fillColor;
  final Color borderColor;
  final Color backgroundColor;

  _FolderTabPainter({
    required this.isSelected,
    required this.fillColor,
    required this.borderColor,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final radius = AppSizes.radiusMedium;
    final borderWidth = isSelected ? 1.5 : 1.0;

    // The folder tab shape: rounded top corners, flat bottom
    final path = Path()
      ..moveTo(0, size.height) // bottom-left
      ..lineTo(0, radius) // up the left side
      ..quadraticBezierTo(0, 0, radius, 0) // top-left curve
      ..lineTo(size.width - radius, 0) // across the top
      ..quadraticBezierTo(size.width, 0, size.width, radius) // top-right curve
      ..lineTo(size.width, size.height) // down the right side
      ..close();

    // Fill
    final fillPaint = Paint()
      ..color = fillColor
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, fillPaint);

    // Border (only top and sides, not bottom)
    final borderPath = Path()
      ..moveTo(0, size.height) // bottom-left
      ..lineTo(0, radius) // up the left side
      ..quadraticBezierTo(0, 0, radius, 0) // top-left curve
      ..lineTo(size.width - radius, 0) // across the top
      ..quadraticBezierTo(size.width, 0, size.width, radius) // top-right curve
      ..lineTo(size.width, size.height); // down the right side

    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;
    canvas.drawPath(borderPath, borderPaint);
  }

  @override
  bool shouldRepaint(_FolderTabPainter oldDelegate) {
    return isSelected != oldDelegate.isSelected ||
        fillColor != oldDelegate.fillColor ||
        borderColor != oldDelegate.borderColor;
  }
}
