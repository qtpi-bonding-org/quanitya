import 'package:flutter/material.dart';

import '../../../design_system/primitives/app_sizes.dart';
import '../../../design_system/primitives/app_spacings.dart';
import '../../../design_system/primitives/quanitya_palette.dart';
import '../../../support/extensions/context_extensions.dart';

/// Data for a single folder tab.
class FolderTab {
  final IconData icon;
  final String label;

  /// Small arrow shown to the left of the icon (e.g. incoming indicator).
  final IconData? leftIndicator;

  /// Small arrow shown to the right of the icon (e.g. outgoing indicator).
  final IconData? rightIndicator;

  /// Optional key used by guided tour to target this tab.
  final GlobalKey? tourKey;

  const FolderTab({
    required this.icon,
    required this.label,
    this.leftIndicator,
    this.rightIndicator,
    this.tourKey,
  });
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
    return Container(
      color: QuanityaPalette.primary.backgroundPrimary,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: AppSizes.space,
          ),
          child: Row(
            children: List.generate(tabs.length, (index) {
              final tab = tabs[index];
              final isSelected = index == currentIndex;
              Widget tabWidget = Expanded(
                child: Semantics(
                  button: true,
                  selected: isSelected,
                  label: tab.label,
                  child: GestureDetector(
                    onTap: () => onTabSelected(index),
                    behavior: HitTestBehavior.opaque,
                    child: _FolderTabWidget(
                      tab: tab,
                      isSelected: isSelected,
                      position: index == 0
                          ? _TabPosition.first
                          : index == tabs.length - 1
                              ? _TabPosition.last
                              : _TabPosition.middle,
                    ),
                  ),
                ),
              );
              if (tab.tourKey != null) {
                tabWidget = KeyedSubtree(key: tab.tourKey, child: tabWidget);
              }
              return tabWidget;
            }),
          ),
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
              _IconWithIndicators(
                icon: tab.icon,
                iconSize: isSelected ? AppSizes.iconMedium : AppSizes.iconSmall + 2,
                iconColor: tabColor,
                leftIndicator: tab.leftIndicator,
                rightIndicator: tab.rightIndicator,
                indicatorSize: AppSizes.iconTiny + 2,
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

/// Icon with optional left/right indicator arrows positioned via a Stack
/// so they never shift the main icon off-center.
class _IconWithIndicators extends StatelessWidget {
  final IconData icon;
  final double iconSize;
  final Color iconColor;
  final IconData? leftIndicator;
  final IconData? rightIndicator;
  final double indicatorSize;

  const _IconWithIndicators({
    required this.icon,
    required this.iconSize,
    required this.iconColor,
    this.leftIndicator,
    this.rightIndicator,
    required this.indicatorSize,
  });

  @override
  Widget build(BuildContext context) {
    // Always reserve space for both arrows so the icon stays centered
    // regardless of which indicators are active.
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Opacity(
          opacity: leftIndicator != null ? 1.0 : 0.0,
          child: Padding(
            padding: EdgeInsets.only(right: AppSizes.space * 0.25),
            child: Icon(
              leftIndicator ?? Icons.south,
              size: indicatorSize,
              color: iconColor,
            ),
          ),
        ),
        Icon(icon, size: iconSize, color: iconColor),
        Opacity(
          opacity: rightIndicator != null ? 1.0 : 0.0,
          child: Padding(
            padding: EdgeInsets.only(left: AppSizes.space * 0.25),
            child: Icon(
              rightIndicator ?? Icons.north,
              size: indicatorSize,
              color: iconColor,
            ),
          ),
        ),
      ],
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
