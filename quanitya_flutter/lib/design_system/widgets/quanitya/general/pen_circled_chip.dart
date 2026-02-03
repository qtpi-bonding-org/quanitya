import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../../primitives/app_sizes.dart';
import '../../../primitives/app_spacings.dart';
import '../../../primitives/quanitya_palette.dart';
import '../../../../support/extensions/context_extensions.dart';

/// A chip with animated "pen-circled" selection style.
///
/// When selected, animates a hand-drawn circle being drawn around the content.
/// Follows ui-guide.md: no filled backgrounds, just a subtle border.
///
/// Color logic (manuscript aesthetic):
/// - Unselected: interactableColor (teal) - "pencil sketch" / option
/// - Selected: textPrimary (black) + bold + pen circle - "inked in" / committed
class PenCircledChip extends StatefulWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final IconData? icon;
  final double? borderRadius;

  /// Duration of the circle-drawing animation (default 120ms for snappy feel)
  final Duration animationDuration;

  const PenCircledChip({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.icon,
    this.borderRadius,
    this.animationDuration = const Duration(milliseconds: 120),
  });

  @override
  State<PenCircledChip> createState() => _PenCircledChipState();
}

class _PenCircledChipState extends State<PenCircledChip>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _wasSelected = false;
  double _startAngle = 0.0; // Random starting angle for hand-drawn feel

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );

    // If already selected on init, show full circle with random angle
    if (widget.isSelected) {
      _startAngle = _generateRandomAngle();
      _controller.value = 1.0;
    }
    _wasSelected = widget.isSelected;
  }

  double _generateRandomAngle() {
    return math.Random().nextDouble() * 2 * math.pi;
  }

  @override
  void didUpdateWidget(PenCircledChip oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.isSelected != _wasSelected) {
      if (widget.isSelected) {
        _startAngle = _generateRandomAngle(); // New random angle each selection
        _controller.forward(from: 0.0);
      } else {
        _controller.reset(); // Instant disappear
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
    final radius = widget.borderRadius ?? AppSizes.size20;
    final palette = QuanityaPalette.primary;

    // Color logic: teal when unselected (pencil), black when selected (inked)
    final textColor = widget.isSelected
        ? palette.textPrimary
        : palette.interactableColor;

    return GestureDetector(
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return CustomPaint(
            painter: _PenCirclePainter(
              progress: _animation.value,
              color: palette.textPrimary, // Circle always in black ink
              borderRadius: radius,
              strokeWidth: 1.5,
              startAngle: _startAngle,
            ),
            child: child,
          );
        },
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: AppSizes.space * 1.5,
            vertical: AppSizes.space,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.icon != null) ...[
                Icon(
                  widget.icon,
                  size: AppSizes.iconSmall,
                  color: textColor,
                ),
                HSpace.x05,
              ],
              Text(
                widget.label,
                style: context.text.bodyMedium?.copyWith(
                  color: textColor,
                  fontWeight: widget.isSelected
                      ? FontWeight.w600
                      : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A circular version with animated drawing effect.
class PenCircledDot extends StatefulWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final double size;
  final Duration animationDuration;

  const PenCircledDot({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.size = 36,
    this.animationDuration = const Duration(milliseconds: 120),
  });

  @override
  State<PenCircledDot> createState() => _PenCircledDotState();
}

class _PenCircledDotState extends State<PenCircledDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _wasSelected = false;
  double _startAngle = 0.0; // Random starting angle for hand-drawn feel

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );

    if (widget.isSelected) {
      _startAngle = _generateRandomAngle();
      _controller.value = 1.0;
    }
    _wasSelected = widget.isSelected;
  }

  double _generateRandomAngle() {
    return math.Random().nextDouble() * 2 * math.pi;
  }

  @override
  void didUpdateWidget(PenCircledDot oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.isSelected != _wasSelected) {
      if (widget.isSelected) {
        _startAngle = _generateRandomAngle(); // New random angle each selection
        _controller.forward(from: 0.0);
      } else {
        _controller.reset(); // Instant disappear
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

    // Color logic: teal when unselected (pencil), black when selected (inked)
    final textColor = widget.isSelected
        ? palette.textPrimary
        : palette.interactableColor;

    return GestureDetector(
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return CustomPaint(
            painter: _PenCirclePainter(
              progress: _animation.value,
              color: palette.textPrimary, // Circle always in black ink
              isCircle: true,
              strokeWidth: 1.5,
              startAngle: _startAngle,
            ),
            child: child,
          );
        },
        child: SizedBox(
          width: widget.size,
          height: widget.size,
          child: Center(
            child: Text(
              widget.label,
              style: context.text.bodyMedium?.copyWith(
                color: textColor,
                fontWeight: widget.isSelected
                    ? FontWeight.w600
                    : FontWeight.normal,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Custom painter that draws a circle/rounded rect progressively
class _PenCirclePainter extends CustomPainter {
  final double progress;
  final Color color;
  final double borderRadius;
  final double strokeWidth;
  final bool isCircle;
  final double startAngle; // Random starting angle for hand-drawn feel

  _PenCirclePainter({
    required this.progress,
    required this.color,
    this.borderRadius = 20,
    this.strokeWidth = 1.5,
    this.isCircle = false,
    this.startAngle = 0.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    if (isCircle) {
      // Draw circle arc from random starting angle
      final center = Offset(size.width / 2, size.height / 2);
      final radius = (math.min(size.width, size.height) / 2) - strokeWidth;

      final sweepAngle = 2 * math.pi * progress;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle, // Random starting angle instead of always top
        sweepAngle,
        false,
        paint,
      );
    } else {
      // Draw rounded rectangle progressively
      final rect = Rect.fromLTWH(
        strokeWidth / 2,
        strokeWidth / 2,
        size.width - strokeWidth,
        size.height - strokeWidth,
      );
      final rrect = RRect.fromRectAndRadius(
        rect,
        Radius.circular(borderRadius),
      );

      // Create path and measure it
      final path = Path()..addRRect(rrect);
      final pathMetrics = path.computeMetrics().first;

      // Start from random position along the path
      final totalLength = pathMetrics.length;
      final startOffset = (startAngle / (2 * math.pi)) * totalLength;
      final drawLength = totalLength * progress;

      // Handle wrap-around if needed
      if (startOffset + drawLength <= totalLength) {
        final extractPath = pathMetrics.extractPath(
          startOffset,
          startOffset + drawLength,
        );
        canvas.drawPath(extractPath, paint);
      } else {
        // Wrap around: draw from start to end, then from beginning
        final firstPart = pathMetrics.extractPath(startOffset, totalLength);
        final secondPart = pathMetrics.extractPath(
          0,
          (startOffset + drawLength) - totalLength,
        );
        canvas.drawPath(firstPart, paint);
        canvas.drawPath(secondPart, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_PenCirclePainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.color != color ||
        oldDelegate.startAngle != startAngle;
  }
}
