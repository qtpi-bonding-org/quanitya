import 'dart:ui';

import 'package:flutter/material.dart';

import '../../logic/templates/enums/ai/template_preset.dart';
import '../primitives/app_spacings.dart';

/// Container that applies preset geometry to its child.
///
/// Used to wrap template field labels and inputs with the selected
/// container style (borders, radius, fill, dashed lines).
///
/// Philosophy: "Stationery, not software" - the preset is the paper shape,
/// decoupled from font and color.
class StyledFieldContainer extends StatelessWidget {
  final Widget child;
  final TemplateContainerStyle? preset;
  final Color accentColor;
  final EdgeInsets? padding;

  const StyledFieldContainer({
    super.key,
    required this.child,
    required this.preset,
    required this.accentColor,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    // Null preset or zen = no styling
    if (preset == null || preset == TemplateContainerStyle.zen) {
      return Padding(
        padding: padding ?? AppPadding.allSingle,
        child: child,
      );
    }

    final recipe = StyleRecipe.fromContainerStyle(preset!);
    final effectivePadding = padding ?? AppPadding.allDouble;

    // Dashed borders need CustomPaint — painter is purely decorative
    if (recipe.isDashed) {
      return Stack(
        children: [
          Positioned.fill(
            child: ExcludeSemantics(
              child: CustomPaint(
                painter: _DashedBoxPainter(
                  color: accentColor,
                  width: recipe.borderWidth,
                ),
              ),
            ),
          ),
          Container(
            padding: effectivePadding,
            child: child,
          ),
        ],
      );
    }

    // Standard borders use BoxDecoration
    return Container(
      padding: effectivePadding,
      decoration: BoxDecoration(
        color: recipe.hasFill
            ? accentColor.withValues(alpha: recipe.fillOpacity)
            : null,
        borderRadius: recipe.borderRadius > 0
            ? BorderRadius.circular(recipe.borderRadius)
            : null,
        border: recipe.hasBorder
            ? Border(
                top: _side(recipe.top, recipe.borderWidth),
                bottom: _side(recipe.bottom, recipe.borderWidth),
                left: _side(recipe.left, recipe.borderWidth),
                right: _side(recipe.right, recipe.borderWidth),
              )
            : null,
      ),
      child: child,
    );
  }

  BorderSide _side(bool show, double width) {
    return show
        ? BorderSide(color: accentColor, width: width)
        : BorderSide.none;
  }
}

/// Custom painter for dashed rectangle borders.
class _DashedBoxPainter extends CustomPainter {
  final Color color;
  final double width;

  _DashedBoxPainter({required this.color, required this.width});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = width
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));

    // Create dashes (6px line, 4px gap)
    final dashedPath = Path();
    for (final PathMetric metric in path.computeMetrics()) {
      double distance = 0.0;
      const dashLength = 6.0;
      const gapLength = 4.0;
      while (distance < metric.length) {
        dashedPath.addPath(
          metric.extractPath(distance, distance + dashLength),
          Offset.zero,
        );
        distance += dashLength + gapLength;
      }
    }
    canvas.drawPath(dashedPath, paint);
  }

  @override
  bool shouldRepaint(covariant _DashedBoxPainter old) =>
      color != old.color || width != old.width;
}
