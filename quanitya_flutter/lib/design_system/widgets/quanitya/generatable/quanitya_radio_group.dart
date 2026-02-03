import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_colorable/flutter_colorable.dart';

import '../../../primitives/app_sizes.dart';
import '../../../primitives/app_spacings.dart';
import '../../../primitives/quanitya_fonts.dart';

/// Zen-styled radio group with pen-circle animation on selection.
///
/// Follows manuscript aesthetic:
/// - Teal when unselected (pencil sketch / option)
/// - Black with pen-circle when selected (inked in / committed)
/// - Animated circle drawing effect
// Note: @ColorableWidget annotation kept for documentation.
// Schema is defined in QuanityaWidgetRegistry instead of generated code.
@ColorableWidget('radioGroup')
class QuanityaRadioGroup<T> extends StatelessWidget {
  @Colorable() final Color activeColor; // Color when selected
  @Colorable() final Color inactiveColor; // Color when unselected

  final T? value;
  final List<T> options;
  final String Function(T) labelBuilder;
  final ValueChanged<T?>? onChanged;
  final Color? textColor;

  const QuanityaRadioGroup({
    super.key,
    required this.activeColor,
    required this.inactiveColor,
    this.value,
    required this.options,
    required this.labelBuilder,
    this.onChanged,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: options.asMap().entries.map((entry) {
        final index = entry.key;
        final option = entry.value;
        final isSelected = option == value;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (index > 0) VSpace.x1,
            _ZenRadioOption<T>(
              option: option,
              isSelected: isSelected,
              activeColor: activeColor,
              inactiveColor: inactiveColor,
              labelBuilder: labelBuilder,
              onChanged: onChanged,
              textColor: textColor,
            ),
          ],
        );
      }).toList(),
    );
  }
}

class _ZenRadioOption<T> extends StatefulWidget {
  final T option;
  final bool isSelected;
  final Color activeColor;
  final Color inactiveColor;
  final String Function(T) labelBuilder;
  final ValueChanged<T?>? onChanged;
  final Color? textColor;

  const _ZenRadioOption({
    required this.option,
    required this.isSelected,
    required this.activeColor,
    required this.inactiveColor,
    required this.labelBuilder,
    this.onChanged,
    this.textColor,
  });

  @override
  State<_ZenRadioOption<T>> createState() => _ZenRadioOptionState<T>();
}

class _ZenRadioOptionState<T> extends State<_ZenRadioOption<T>>
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
      _startAngle = _generateRandomAngle();
      _controller.value = 1.0;
    }
    _wasSelected = widget.isSelected;
  }

  double _generateRandomAngle() {
    return math.Random().nextDouble() * 2 * math.pi;
  }

  @override
  void didUpdateWidget(_ZenRadioOption<T> oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.isSelected != _wasSelected) {
      if (widget.isSelected) {
        _startAngle = _generateRandomAngle();
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
    final color = widget.isSelected ? widget.activeColor : widget.inactiveColor;
    final labelColor = widget.isSelected
        ? widget.activeColor
        : (widget.textColor ?? widget.inactiveColor);

    return GestureDetector(
      onTap: widget.onChanged != null ? () => widget.onChanged!(widget.option) : null,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: AppSizes.space * 0.5),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Radio circle with pen-circle animation
            AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                return CustomPaint(
                  painter: _PenCirclePainter(
                    progress: _animation.value,
                    color: widget.activeColor,
                    startAngle: _startAngle,
                  ),
                  child: child,
                );
              },
              child: SizedBox(
                width: 32,
                height: 32,
                child: Center(
                  child: Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: color,
                        width: 1.5,
                      ),
                    ),
                    child: widget.isSelected
                        ? Center(
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: widget.activeColor,
                              ),
                            ),
                          )
                        : null,
                  ),
                ),
              ),
            ),
            HSpace.x1,
            Flexible(
              child: Text(
                widget.labelBuilder(widget.option),
                style: TextStyle(
                  fontFamily: QuanityaFonts.bodyFamily,
                  fontSize: AppSizes.fontStandard,
                  color: labelColor,
                  fontWeight: widget.isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Custom painter for pen-circle effect
class _PenCirclePainter extends CustomPainter {
  final double progress;
  final Color color;
  final double startAngle;

  _PenCirclePainter({
    required this.progress,
    required this.color,
    this.startAngle = 0.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = (math.min(size.width, size.height) / 2) - 2;

    final sweepAngle = 2 * math.pi * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(_PenCirclePainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.color != color ||
        oldDelegate.startAngle != startAngle;
  }
}
