import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../primitives/app_sizes.dart';
import '../../../primitives/quanitya_palette.dart';
import '../../../primitives/quanitya_fonts.dart';

/// Consistent text button with interactable color styling and pen-circle effect.
///
/// Use for text-only actions like "View All", "Cancel", "Edit".
/// - Default: Teal (interactableColor) - "tap me" signal
/// - Destructive: Red (destructiveColor) - danger signal
/// - Pressed: Shows animated pen-circle around text
///
/// Follows the manuscript aesthetic: teal = pencil sketch (option),
/// black = inked in (when pressed/selected).
class QuanityaTextButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isDestructive;
  final TextStyle? style;

  const QuanityaTextButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isDestructive = false,
    this.style,
  });

  @override
  State<QuanityaTextButton> createState() => _QuanityaTextButtonState();
}

class _QuanityaTextButtonState extends State<QuanityaTextButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _isPressed = false;
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
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double _generateRandomAngle() {
    return math.Random().nextDouble() * 2 * math.pi;
  }

  void _handleTapDown(TapDownDetails details) {
    if (widget.onPressed == null) return;
    setState(() {
      _isPressed = true;
      _startAngle = _generateRandomAngle();
    });
    _controller.forward(from: 0.0);
  }

  void _handleTapUp(TapUpDetails details) {
    _resetPress();
  }

  void _handleTapCancel() {
    _resetPress();
  }

  void _resetPress() {
    setState(() => _isPressed = false);
    _controller.reset();
  }

  @override
  Widget build(BuildContext context) {
    final palette = QuanityaPalette.primary;
    final color = widget.onPressed == null
        ? palette.textSecondary // Disabled
        : widget.isDestructive
            ? palette.destructiveColor
            : _isPressed
                ? palette.textPrimary // Inked when pressed
                : palette.interactableColor;

    return Semantics(
      button: true,
      label: widget.text,
      enabled: widget.onPressed != null,
      child: GestureDetector(
        onTapDown: _handleTapDown,
        onTapUp: _handleTapUp,
        onTapCancel: _handleTapCancel,
        onTap: widget.onPressed,
        behavior: HitTestBehavior.opaque,
        child: AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            return CustomPaint(
              painter: _PenCirclePainter(
                progress: _animation.value,
                color: widget.isDestructive ? palette.destructiveColor : palette.textPrimary,
                borderRadius: AppSizes.size20,
                strokeWidth: 1.5,
                startAngle: _startAngle,
              ),
              child: child,
            );
          },
          child: Container(
            constraints: BoxConstraints(minHeight: AppSizes.buttonHeight),
            padding: EdgeInsets.symmetric(
              horizontal: AppSizes.space * 1.5,
              vertical: AppSizes.space,
            ),
            child: Center(
              child: Text(
                widget.text,
                style: widget.style ??
                    TextStyle(
                      fontFamily: QuanityaFonts.bodyFamily,
                      fontSize: AppSizes.fontStandard,
                      fontWeight: _isPressed ? FontWeight.w700 : FontWeight.w600,
                      color: color,
                    ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Custom painter that draws a rounded rect progressively (pen-circle effect)
class _PenCirclePainter extends CustomPainter {
  final double progress;
  final Color color;
  final double borderRadius;
  final double strokeWidth;
  final double startAngle;

  _PenCirclePainter({
    required this.progress,
    required this.color,
    this.borderRadius = 20,
    this.strokeWidth = 1.5,
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

  @override
  bool shouldRepaint(_PenCirclePainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.color != color ||
        oldDelegate.startAngle != startAngle;
  }
}
