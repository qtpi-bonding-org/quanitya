import 'package:flutter/material.dart';
import '../primitives/app_spacings.dart';

/// A Column widget that automatically spaces children according to the zen grid system.
/// 
/// Uses VSpace tokens for consistent vertical spacing that aligns with the grid.
class ZenGridColumn extends StatelessWidget {
  final List<Widget> children;
  final CrossAxisAlignment crossAxisAlignment;
  final MainAxisAlignment mainAxisAlignment;
  final MainAxisSize mainAxisSize;
  final VerticalSpacing spacing;
  
  const ZenGridColumn({
    super.key,
    required this.children,
    this.crossAxisAlignment = CrossAxisAlignment.start,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.mainAxisSize = MainAxisSize.max,
    this.spacing = VerticalSpacing.x1,
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
    
    return Column(
      crossAxisAlignment: crossAxisAlignment,
      mainAxisAlignment: mainAxisAlignment,
      mainAxisSize: mainAxisSize,
      children: spacedChildren,
    );
  }
  
  Widget _getSpacingWidget(VerticalSpacing spacing) {
    return switch (spacing) {
      VerticalSpacing.x025 => VSpace.x025,
      VerticalSpacing.x05 => VSpace.x05,
      VerticalSpacing.x1 => VSpace.x1,
      VerticalSpacing.x2 => VSpace.x2,
      VerticalSpacing.x3 => VSpace.x3,
    };
  }
}

/// Vertical spacing options for ZenGridColumn
enum VerticalSpacing {
  x025, // Optical correction
  x05,  // Text glue
  x1,   // Component breath
  x2,   // Standard margin
  x3,   // Narrative flow
}