import 'package:flutter/material.dart';
import '../../../primitives/quanitya_palette.dart';
import '../../../primitives/zen_grid_constants.dart';

/// A performance-optimized dot grid background for lab notebook aesthetic.
///
/// Uses [RepaintBoundary] when static, but invalidates on scroll to create
/// a physical "moving paper" effect with continuous dot grid alignment.
class ZenPaperBackground extends StatefulWidget {
  final Widget child;
  final Color? baseColor;
  final double? scrollOffset;

  /// Horizontal position of this background in a multi-strip layout.
  /// Used to align the dot grid across adjacent strips so dots tile
  /// continuously at strip boundaries. Defaults to 0.0 (standalone use).
  final double stripOriginX;

  /// Total width of the combined multi-strip surface.
  /// The dot grid is centered across this total width rather than
  /// each individual strip. Defaults to 0.0 (use own width for centering).
  final double totalStripWidth;

  const ZenPaperBackground({
    super.key,
    required this.child,
    this.baseColor,
    this.scrollOffset,
    this.stripOriginX = 0.0,
    this.totalStripWidth = 0.0,
  });

  @override
  State<ZenPaperBackground> createState() => _ZenPaperBackgroundState();
}

class _ZenPaperBackgroundState extends State<ZenPaperBackground> {
  double _internalScrollOffset = 0.0;

  @override
  Widget build(BuildContext context) {
    // defaults to Quanitya's Washi White if no color provided
    final defaultWashi = QuanityaPalette.primary.colors['color1']!;
    final color = widget.baseColor ?? defaultWashi;

    // IF the color is NOT the default Washi White, render solid color (ignoring texture)
    if (color.toARGB32() != defaultWashi.toARGB32()) {
      return Container(
        color: color,
        child: widget.child,
      );
    }

    // Determine the scroll offset to use
    final effectiveOffset = widget.scrollOffset != null
        ? -widget.scrollOffset!
        : _internalScrollOffset;

    // Otherwise, render the dot grid pattern
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (widget.scrollOffset != null) {
          return false; // Ignore internal if external provided
        }

        if (notification is ScrollUpdateNotification &&
            notification.metrics.axis == Axis.vertical) {
          setState(() {
            _internalScrollOffset -= notification.scrollDelta ?? 0;
          });
          return false;
        }
        return false;
      },
      child: Stack(
        children: [
          // The background layers (Cached Chunks)
          ..._buildVisibleChunks(context, color, effectiveOffset),

          // The content
          widget.child,
        ],
      ),
    );
  }

  List<Widget> _buildVisibleChunks(
    BuildContext context,
    Color color,
    double currentOffset,
  ) {
    const chunkHeight = 1350.0;
    final screenSize = MediaQuery.sizeOf(context);
    final screenWidth = screenSize.width;
    final screenHeight = screenSize.height;

    final paperTopY = currentOffset;

    final minChunk = ((-paperTopY) / chunkHeight).floor();
    final maxChunk = ((screenHeight - paperTopY) / chunkHeight).floor();

    // Calculate horizontal offset for dot grid alignment.
    // In multi-strip mode, center the grid across the total strip width
    // and offset each strip so dots tile continuously at boundaries.
    final dotSpacing = ZenGridConstants.dotSpacing;
    final double horizontalOffset;
    if (widget.totalStripWidth > 0) {
      // Multi-strip: center grid across total width, then adjust for this strip's position
      final globalCenterOffset = (widget.totalStripWidth % dotSpacing) / 2;
      horizontalOffset = (globalCenterOffset - widget.stripOriginX) % dotSpacing;
    } else {
      // Standalone: center within own width
      horizontalOffset = (screenWidth % dotSpacing) / 2;
    }

    final widgets = <Widget>[];

    for (int i = minChunk - 1; i <= maxChunk + 1; i++) {
      final top = i * chunkHeight + paperTopY;

      widgets.add(
        Positioned(
          top: top,
          left: 0,
          right: 0,
          height: chunkHeight,
          child: RepaintBoundary(
            child: CustomPaint(
              painter: _StaticChunkPainter(
                color: color,
                chunkIndex: i,
                horizontalOffset: horizontalOffset,
              ),
            ),
          ),
        ),
      );
    }
    return widgets;
  }
}

/// Paints a single static chunk of dot grid pattern.
class _StaticChunkPainter extends CustomPainter {
  final Color color;
  final int chunkIndex;
  final double horizontalOffset;

  _StaticChunkPainter({
    required this.color,
    required this.chunkIndex,
    this.horizontalOffset = 0.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Fill base color
    final bgPaint = Paint()..color = color;
    canvas.drawRect(Offset.zero & size, bgPaint);

    // 2. Draw dot grid pattern - using shared zen grid constants
    final dotSpacing = ZenGridConstants.dotSpacing;
    final dotRadius = ZenGridConstants.dotRadius;
    
    final dotPaint = Paint()
      ..color = QuanityaPalette.primary.textSecondary.withValues(alpha: ZenGridConstants.dotOpacity)
      ..style = PaintingStyle.fill;

    // Calculate offset to ensure dots align across chunks
    final chunkOffsetY = chunkIndex * size.height;
    
    // Center the grid horizontally: calculate offset so grid is symmetric
    // horizontalOffset is the remainder when dividing screen width by dotSpacing
    final startX = horizontalOffset;
    final startY = (dotSpacing - (chunkOffsetY % dotSpacing)) % dotSpacing;

    // Draw dots in a regular grid
    for (double x = startX; x < size.width; x += dotSpacing) {
      for (double y = startY; y < size.height; y += dotSpacing) {
        canvas.drawCircle(
          Offset(x, y),
          dotRadius,
          dotPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _StaticChunkPainter oldDelegate) {
    return oldDelegate.color != color || 
           oldDelegate.chunkIndex != chunkIndex ||
           oldDelegate.horizontalOffset != horizontalOffset;
  }
}
