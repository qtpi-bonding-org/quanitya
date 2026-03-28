import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../../design_system/primitives/app_sizes.dart';
import '../../../design_system/primitives/app_spacings.dart';
import '../../../design_system/primitives/quanitya_palette.dart';
import '../../../support/extensions/context_extensions.dart';

/// A read-only gallery card for community template browsing.
///
/// Shows a TemplateIcon + name, with a pen-circled selection style.
/// When selected, animates a hand-drawn circle around the icon.
class GalleryCard extends StatefulWidget {
  final Widget icon;
  final String name;
  final bool isSelected;
  final VoidCallback? onTap;

  const GalleryCard({
    super.key,
    required this.icon,
    required this.name,
    this.isSelected = false,
    this.onTap,
  });

  @override
  State<GalleryCard> createState() => _GalleryCardState();
}

class _GalleryCardState extends State<GalleryCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _wasSelected = false;
  double _startAngle = 0.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 120),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );

    if (widget.isSelected) {
      _startAngle = math.Random().nextDouble() * 2 * math.pi;
      _controller.value = 1.0;
    }
    _wasSelected = widget.isSelected;
  }

  @override
  void didUpdateWidget(GalleryCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSelected != _wasSelected) {
      if (widget.isSelected) {
        _startAngle = math.Random().nextDouble() * 2 * math.pi;
        _controller.forward(from: 0.0);
      } else {
        _controller.reset();
      }
      _wasSelected = widget.isSelected;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = QuanityaPalette.primary;

    return Semantics(
      button: true,
      label: widget.name,
      selected: widget.isSelected,
      child: GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: AppSizes.buttonHeight),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Center(
                child: AnimatedBuilder(
                  animation: _animation,
                  builder: (context, child) {
                    return CustomPaint(
                      painter: _PenCirclePainter(
                        progress: _animation.value,
                        color: palette.textPrimary,
                        startAngle: _startAngle,
                      ),
                      child: child,
                    );
                  },
                  child: Padding(
                    padding: EdgeInsets.all(AppSizes.space * 0.5),
                    child: widget.icon,
                  ),
                ),
              ),

              VSpace.x05,

              Padding(
                padding: AppPadding.horizontalSingle,
                child: Text(
                  widget.name.toUpperCase(),
                  style: context.text.labelSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.1,
                    color: widget.isSelected
                        ? palette.textPrimary
                        : palette.interactableColor,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              VSpace.x1,
            ],
          ),
        ),
      ),
    );
  }
}

/// Draws an animated pen circle around the child.
class _PenCirclePainter extends CustomPainter {
  final double progress;
  final Color color;
  final double startAngle;

  _PenCirclePainter({
    required this.progress,
    required this.color,
    required this.startAngle,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final sweepAngle = 2 * math.pi * progress;
    canvas.drawArc(rect, startAngle, sweepAngle, false, paint);
  }

  @override
  bool shouldRepaint(_PenCirclePainter old) =>
      old.progress != progress || old.color != color;
}
