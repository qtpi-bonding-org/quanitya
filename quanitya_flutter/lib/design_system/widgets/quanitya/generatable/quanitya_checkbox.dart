import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_colorable/flutter_colorable.dart';

import '../../../primitives/app_sizes.dart';

/// Zen-styled checkbox with pen-circle animation on selection.
///
/// Follows manuscript aesthetic:
/// - Teal when unchecked (pencil sketch / option)
/// - Black with pen-circle when checked (inked in / committed)
/// - Animated circle drawing effect
// Note: @ColorableWidget annotation kept for documentation.
// Schema is defined in QuanityaWidgetRegistry instead of generated code.
@ColorableWidget('checkbox')
class QuanityaCheckbox extends StatefulWidget {
  @Colorable() final Color activeColor; // Color when checked
  @Colorable() final Color checkColor; // Checkmark color
  @Colorable() final Color borderColor; // Border when unchecked

  final bool value;
  final ValueChanged<bool?>? onChanged;

  const QuanityaCheckbox({
    super.key,
    required this.activeColor,
    required this.checkColor,
    required this.borderColor,
    required this.value,
    this.onChanged,
  });

  @override
  State<QuanityaCheckbox> createState() => _QuanityaCheckboxState();
}

class _QuanityaCheckboxState extends State<QuanityaCheckbox>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _wasChecked = false;
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

    if (widget.value) {
      _startAngle = _generateRandomAngle();
      _controller.value = 1.0;
    }
    _wasChecked = widget.value;
  }

  double _generateRandomAngle() {
    return math.Random().nextDouble() * 2 * math.pi;
  }

  @override
  void didUpdateWidget(QuanityaCheckbox oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.value != _wasChecked) {
      if (widget.value) {
        _startAngle = _generateRandomAngle();
        _controller.forward(from: 0.0);
      } else {
        _controller.reset();
      }
      _wasChecked = widget.value;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.value ? widget.activeColor : widget.borderColor;

    return SizedBox(
      width: AppSizes.buttonHeight,
      height: AppSizes.buttonHeight,
      child: GestureDetector(
        onTap: widget.onChanged != null
            ? () => widget.onChanged!(!widget.value)
            : null,
        behavior: HitTestBehavior.opaque,
        child: AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            return CustomPaint(
              painter: _PenCirclePainter(
                progress: _animation.value,
                color: widget.activeColor,
                borderRadius: 4,
                strokeWidth: 1.5,
                startAngle: _startAngle,
              ),
              child: child,
            );
          },
          child: Center(
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: color,
                  width: 1.5,
                ),
              ),
              child: widget.value
                  ? Icon(
                      Icons.check,
                      size: 14,
                      color: widget.checkColor,
                    )
                  : null,
            ),
          ),
        ),
      ),
    );
  }
}

/// Custom painter for pen-circle effect
class _PenCirclePainter extends CustomPainter {
  final double progress;
  final Color color;
  final double borderRadius;
  final double strokeWidth;
  final double startAngle;

  _PenCirclePainter({
    required this.progress,
    required this.color,
    this.borderRadius = 4,
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

    // Draw around the checkbox area with some padding
    final padding = 8.0;
    final rect = Rect.fromLTWH(
      padding,
      padding,
      size.width - padding * 2,
      size.height - padding * 2,
    );
    final rrect = RRect.fromRectAndRadius(
      rect,
      Radius.circular(borderRadius + 4),
    );

    final path = Path()..addRRect(rrect);
    final pathMetrics = path.computeMetrics().first;

    final totalLength = pathMetrics.length;
    final startOffset = (startAngle / (2 * math.pi)) * totalLength;
    final drawLength = totalLength * progress;

    if (startOffset + drawLength <= totalLength) {
      final extractPath = pathMetrics.extractPath(
        startOffset,
        startOffset + drawLength,
      );
      canvas.drawPath(extractPath, paint);
    } else {
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
