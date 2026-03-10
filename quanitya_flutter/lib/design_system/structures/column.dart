import 'package:flutter/material.dart';
import '../primitives/app_spacings.dart';

class QuanityaColumn extends StatelessWidget {
  final List<Widget> children;
  final CrossAxisAlignment crossAlignment;
  final MainAxisAlignment mainAlignment;
  final MainAxisSize mainAxisSize;
  final Widget? spacing; // The "Gap" token (e.g., VSpace.x1)

  const QuanityaColumn({
    super.key,
    required this.children,
    // Default to Hard Left Align (as per Design Guide)
    this.crossAlignment = CrossAxisAlignment.start,
    this.mainAlignment = MainAxisAlignment.start,
    this.mainAxisSize = MainAxisSize.max,
    // Default to "Component Breath" (8px) if not specified
    this.spacing,
  });

  Widget get _defaultSpacing => VSpace.x1;

  @override
  Widget build(BuildContext context) {
    // Optimization: Don't add spacing if there's only 1 item
    if (children.length <= 1) {
      return Column(
        crossAxisAlignment: crossAlignment,
        mainAxisAlignment: mainAlignment,
        mainAxisSize: mainAxisSize,
        children: children,
      );
    }

    // Interleave the children with the spacing token
    final spacedChildren = <Widget>[];
    final actualSpacing = spacing ?? _defaultSpacing;
    for (var i = 0; i < children.length; i++) {
      spacedChildren.add(children[i]);
      if (i != children.length - 1) {
        spacedChildren.add(actualSpacing);
      }
    }

    return Column(
      crossAxisAlignment: crossAlignment,
      mainAxisAlignment: mainAlignment,
      mainAxisSize: mainAxisSize,
      children: spacedChildren,
    );
  }
}
