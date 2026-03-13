import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_colorable/flutter_colorable.dart';

import '../../../primitives/app_sizes.dart';
import '../../../primitives/quanitya_fonts.dart';

/// Zen-styled chip group with pen-circle animation on selection.
///
/// Follows manuscript aesthetic:
/// - Teal when unselected (pencil sketch / option)
/// - Black with pen-circle when selected (inked in / committed)
/// - No filled backgrounds, just text with animated border
// Note: @ColorableWidget annotation kept for documentation.
// Schema is defined in QuanityaWidgetRegistry instead of generated code.
@ColorableWidget('chipGroup')
class QuanityaChipGroup<T> extends StatelessWidget {
  @Colorable() final Color selectedColor; // Color when selected
  @Colorable() final Color unselectedColor; // Color when unselected
  @Colorable() final Color labelColor; // Text color (kept for API compatibility)

  final T? value;
  final List<T> options;
  final String Function(T) labelBuilder;
  final ValueChanged<T>? onChanged;

  const QuanityaChipGroup({
    super.key,
    required this.selectedColor,
    required this.unselectedColor,
    required this.labelColor,
    this.value,
    required this.options,
    required this.labelBuilder,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSizes.space,
      runSpacing: AppSizes.space,
      children: options.map((option) {
        final isSelected = option == value;
        return _ZenChip<T>(
          option: option,
          isSelected: isSelected,
          selectedColor: selectedColor,
          unselectedColor: unselectedColor,
          labelBuilder: labelBuilder,
          onChanged: onChanged,
        );
      }).toList(),
    );
  }
}

class _ZenChip<T> extends StatefulWidget {
  final T option;
  final bool isSelected;
  final Color selectedColor;
  final Color unselectedColor;
  final String Function(T) labelBuilder;
  final ValueChanged<T>? onChanged;

  const _ZenChip({
    required this.option,
    required this.isSelected,
    required this.selectedColor,
    required this.unselectedColor,
    required this.labelBuilder,
    this.onChanged,
  });

  @override
  State<_ZenChip<T>> createState() => _ZenChipState<T>();
}

class _ZenChipState<T> extends State<_ZenChip<T>>
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
  void didUpdateWidget(_ZenChip<T> oldWidget) {
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
    final color = widget.isSelected ? widget.selectedColor : widget.unselectedColor;

    return Semantics(
      button: true,
      toggled: widget.isSelected,
      label: widget.labelBuilder(widget.option),
      child: GestureDetector(
        onTap: widget.onChanged != null ? () => widget.onChanged!(widget.option) : null,
        behavior: HitTestBehavior.opaque,
        child: AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            return CustomPaint(
              painter: _PenCirclePainter(
                progress: _animation.value,
                color: widget.selectedColor,
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
            child: Text(
              widget.labelBuilder(widget.option),
              style: TextStyle(
                fontFamily: QuanityaFonts.bodyFamily,
                fontSize: AppSizes.fontStandard,
                color: color,
                fontWeight: widget.isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Custom painter for pen-circle effect (rounded rect)
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
