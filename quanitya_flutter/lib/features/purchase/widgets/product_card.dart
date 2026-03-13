import 'package:flutter/material.dart';

import '../../../design_system/primitives/app_sizes.dart';
import '../../../design_system/primitives/app_spacings.dart';
import '../../../design_system/primitives/quanitya_palette.dart';
import '../../../design_system/widgets/quanitya/general/quanitya_text_button.dart';
import '../../../infrastructure/purchase/purchase_models.dart';
import '../../../support/extensions/context_extensions.dart';

/// Displays a purchasable product as a vertical price tag.
///
/// Manuscript aesthetic: pen-drawn border with string hole,
/// capacity prominently displayed above the plan name.
class ProductCard extends StatelessWidget {
  const ProductCard({
    super.key,
    required this.product,
    required this.onBuy,
    this.isLoading = false,
  });

  final PurchaseProduct product;
  final VoidCallback onBuy;
  final bool isLoading;

  bool get _isSubscription =>
      product.productType == StoreProductType.subscription;

  /// Extracts capacity (e.g. "500 MB", "1 GB") from the title.
  /// Returns (capacity, planName). If no capacity found, (null, fullTitle).
  ({String? capacity, String planName}) _parseTitle() {
    final capacityPattern = RegExp(
      r'(\d+(?:\.\d+)?\s*(?:KB|MB|GB|TB))',
      caseSensitive: false,
    );
    final match = capacityPattern.firstMatch(product.title);
    if (match != null) {
      final capacity = match.group(1);
      if (capacity != null) {
        final remainder = product.title
            .replaceFirst(capacity, '')
            .replaceAll(
              RegExp(r'\b(monthly|yearly|annual)\b', caseSensitive: false),
              '',
            )
            .trim();
        return (
          capacity: capacity,
          planName: remainder.isNotEmpty ? remainder : product.title,
        );
      }
    }
    return (capacity: null, planName: product.title);
  }

  @override
  Widget build(BuildContext context) {
    final palette = QuanityaPalette.primary;
    final parsed = _parseTitle();
    final price =
        product.localizedPrice ?? '\$${product.priceUsd.toStringAsFixed(2)}';

    return CustomPaint(
      painter: _PriceTagPainter(
        color: palette.interactableColor,
        strokeWidth: AppSizes.borderWidth * 1.5,
        borderRadius: AppSizes.radiusSmall,
        holeRadius: AppSizes.space * 0.75,
      ),
      child: Padding(
        padding: EdgeInsets.only(
          left: AppSizes.space * 2,
          right: AppSizes.space * 2,
          top: AppSizes.space * 3.5,
          bottom: AppSizes.space * 2,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Capacity (prominent, if extractable)
            if (parsed.capacity != null) ...[
              Text(
                parsed.capacity ?? '',
                style: context.text.headlineMedium?.copyWith(
                  color: palette.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
              VSpace.x05,
            ],

            // Plan name
            Text(
              parsed.planName,
              style: context.text.titleMedium?.copyWith(
                color: palette.textSecondary,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

            VSpace.x2,

            // Price
            Text(
              price,
              style: context.text.titleLarge?.copyWith(
                color: palette.textPrimary,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),

            VSpace.x2,

            // Action
            if (isLoading)
              SizedBox(
                width: AppSizes.iconSmall,
                height: AppSizes.iconSmall,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: palette.interactableColor,
                ),
              )
            else
              QuanityaTextButton(
                text: _isSubscription
                    ? context.l10n.purchaseSubscribe
                    : context.l10n.purchaseBuy,
                onPressed: onBuy,
              ),
          ],
        ),
      ),
    );
  }
}

/// Painter that draws a price tag silhouette: rounded rect + string hole.
class _PriceTagPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double borderRadius;
  final double holeRadius;

  _PriceTagPainter({
    required this.color,
    this.strokeWidth = 1.5,
    this.borderRadius = 8,
    this.holeRadius = 6,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    // Tag body
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
    canvas.drawRRect(rrect, paint);

    // String hole at top center
    final holeCenterY = borderRadius + holeRadius + strokeWidth + 4;
    canvas.drawCircle(
      Offset(size.width / 2, holeCenterY),
      holeRadius,
      paint,
    );

    // Short string line from hole upward
    final stringPaint = Paint()
      ..color = color.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth * 0.8
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(size.width / 2, holeCenterY - holeRadius),
      Offset(size.width / 2, strokeWidth / 2),
      stringPaint,
    );
  }

  @override
  bool shouldRepaint(_PriceTagPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
