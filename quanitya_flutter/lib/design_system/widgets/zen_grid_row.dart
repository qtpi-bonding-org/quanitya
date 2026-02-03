import 'package:flutter/material.dart';
import '../primitives/app_spacings.dart';

/// A Row widget that automatically spaces children according to the zen grid system.
/// 
/// Uses HSpace tokens for consistent horizontal spacing.
class ZenGridRow extends StatelessWidget {
  final List<Widget> children;
  final CrossAxisAlignment crossAxisAlignment;
  final MainAxisAlignment mainAxisAlignment;
  final MainAxisSize mainAxisSize;
  final HorizontalSpacing spacing;
  
  const ZenGridRow({
    super.key,
    required this.children,
    this.crossAxisAlignment = CrossAxisAlignment.center,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.mainAxisSize = MainAxisSize.max,
    this.spacing = HorizontalSpacing.x1,
  });
  
  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) return const SizedBox.shrink();
    
    final spacedChildren = <Widget>[];
    
    for (int i = 0; i < children.length; i++) {
      spacedChildren.add(children[i]);
      
      // Add spacing between children (but not after the last one)
      if (i < children.length - 1) {
        spacedChildren.add(_getSpacingWidget(spacing));
      }
    }
    
    return Row(
      crossAxisAlignment: crossAxisAlignment,
      mainAxisAlignment: mainAxisAlignment,
      mainAxisSize: mainAxisSize,
      children: spacedChildren,
    );
  }
  
  Widget _getSpacingWidget(HorizontalSpacing spacing) {
    return switch (spacing) {
      HorizontalSpacing.x05 => HSpace.x05,
      HorizontalSpacing.x1 => HSpace.x1,
      HorizontalSpacing.x2 => HSpace.x2,
    };
  }
}

/// Horizontal spacing options for ZenGridRow
enum HorizontalSpacing {
  x05,  // Tight spacing
  x1,   // Standard spacing
  x2,   // Loose spacing
}