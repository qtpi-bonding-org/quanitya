import 'package:flutter/material.dart';

import '../../../design_system/primitives/app_sizes.dart';
import '../../../design_system/primitives/app_spacings.dart';
import '../../../design_system/primitives/quanitya_palette.dart';
import '../../../design_system/widgets/quanitya/general/quanitya_text_button.dart';
import '../../../infrastructure/purchase/purchase_models.dart';
import '../../../support/extensions/context_extensions.dart';

/// Displays a consumable product as a gift-card-style widget.
///
/// Manuscript aesthetic: solid washi-white card with a rounded rectangular
/// hang-tab slot at the top center (like a store gift card), price
/// denomination in the upper-right corner, and capacity prominently
/// centered.
class ConsumableCard extends StatelessWidget {
  const ConsumableCard({
    super.key,
    required this.product,
    required this.onBuy,
    this.isLoading = false,
  });

  final PurchaseProduct product;
  final VoidCallback onBuy;
  final bool isLoading;

  /// Formats price as a clean denomination — sub-dollar amounts use
  /// the cent symbol (e.g. "49¢") for a gift-card feel.
  static String _formatPrice(String? localizedPrice, double priceUsd) {
    if (localizedPrice != null) {
      // Check for sub-dollar localized price like "$0.49"
      final subDollar = RegExp(r'^\$0\.(\d{2})$').firstMatch(localizedPrice);
      if (subDollar != null) {
        final cents = int.tryParse(subDollar.group(1) ?? '');
        if (cents != null) return '$cents¢';
      }
      return localizedPrice;
    }
    if (priceUsd < 1.0) {
      final cents = (priceUsd * 100).round();
      return '$cents¢';
    }
    return '\$${priceUsd.toStringAsFixed(2)}';
  }

  /// Splits a plan name like "20 AI Calls" into ["20", "AI Calls"].
  /// If no leading number found, returns the name as a single element.
  static List<String> _splitPlanName(String name) {
    final match = RegExp(r'^(\d+)\s+(.+)$').firstMatch(name);
    if (match != null) {
      return [match.group(1) ?? name, match.group(2) ?? ''];
    }
    return [name];
  }

  /// Extracts capacity (e.g. "500 MB", "1 GB") from the title.
  ({String? capacity, String planName, String? entryEstimate}) _parseTitle() {
    final capacityPattern = RegExp(
      r'(\d+(?:\.\d+)?)\s*(KB|MB|GB|TB)',
      caseSensitive: false,
    );
    final match = capacityPattern.firstMatch(product.title);
    if (match != null) {
      final number = match.group(1);
      final unit = match.group(2);
      if (number != null && unit != null) {
        final capacityStr = '${match.group(0)}';
        final remainder = product.title
            .replaceFirst(capacityStr, '')
            .trim();
        return (
          capacity: capacityStr,
          planName: remainder.isNotEmpty ? remainder : product.title,
          entryEstimate: _estimateEntries(double.tryParse(number), unit),
        );
      }
    }
    return (capacity: null, planName: product.title, entryEstimate: null);
  }

  /// Estimates how many log entries fit in the given capacity.
  ///
  /// Assumes ~4 KB per entry on the server: encrypted blob (~1 KB in
  /// SQLite) × 4 for PostgreSQL with PowerSync (oplog, indexes,
  /// row overhead, WAL).
  static String? _estimateEntries(double? value, String unit) {
    if (value == null) return null;

    const bytesPerEntry = 4096; // ~4 KB server-side
    final bytes = switch (unit.toUpperCase()) {
      'KB' => value * 1024,
      'MB' => value * 1024 * 1024,
      'GB' => value * 1024 * 1024 * 1024,
      'TB' => value * 1024 * 1024 * 1024 * 1024,
      _ => null,
    };
    if (bytes == null) return null;

    final entries = (bytes / bytesPerEntry).round();
    final rounded = (entries / 1000).round() * 1000;
    if (rounded >= 1000000) {
      final millions = rounded / 1000000;
      return '~${millions.toStringAsFixed(millions.truncateToDouble() == millions ? 0 : 1)}M entries';
    }
    if (rounded >= 1000) {
      return '~${rounded ~/ 1000}K entries';
    }
    return '~$entries entries';
  }

  @override
  Widget build(BuildContext context) {
    final palette = QuanityaPalette.primary;
    final parsed = _parseTitle();
    final price = _formatPrice(
      product.localizedPrice,
      product.priceUsd,
    );

    final buttonLabel = context.l10n.purchaseBuy;

    // Hang-tab dimensions
    final tabWidth = AppSizes.space * 5;
    final tabHeight = AppSizes.space * 1.5;
    final tabRadius = tabHeight / 2;

    final semanticParts = <String>[
      parsed.planName,
      if (parsed.capacity != null) parsed.capacity ?? '',
      if (parsed.entryEstimate != null) parsed.entryEstimate ?? '',
      price,
      buttonLabel,
    ];

    return Semantics(
      button: true,
      enabled: !isLoading,
      label: semanticParts.join(', '),
      excludeSemantics: true,
      child: Container(
        decoration: BoxDecoration(
          color: palette.backgroundPrimary,
          borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
          border: Border.all(
            color: palette.textPrimary.withValues(alpha: 0.25),
            width: AppSizes.borderWidth,
          ),
          boxShadow: [
            BoxShadow(
              color: palette.textPrimary.withValues(alpha: 0.12),
              blurRadius: AppSizes.space * 2,
              offset: Offset(0, AppSizes.space * 0.5),
            ),
            BoxShadow(
              color: palette.textPrimary.withValues(alpha: 0.06),
              blurRadius: AppSizes.space * 0.5,
              offset: Offset(0, AppSizes.space * 0.25),
            ),
          ],
        ),
        child: CustomPaint(
          painter: _HangTabSlotPainter(
            color: palette.textPrimary.withValues(alpha: 0.10),
            tabWidth: tabWidth,
            tabHeight: tabHeight,
            tabRadius: tabRadius,
            cardBorderRadius: AppSizes.radiusMedium,
          ),
          child: Padding(
            padding: EdgeInsets.only(
              left: AppSizes.space * 2,
              right: AppSizes.space * 2,
              top: AppSizes.space * 3,
              bottom: AppSizes.space * 2,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Price denomination — upper-right, like a gift card
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    price,
                    style: context.text.headlineMedium?.copyWith(
                      color: palette.textSecondary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),

                VSpace.x2,

                // Capacity — smaller, like old plan name style
                if (parsed.capacity != null) ...[
                  Text(
                    parsed.capacity ?? '',
                    style: context.text.titleMedium?.copyWith(
                      color: palette.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (parsed.entryEstimate != null) ...[
                    VSpace.x025,
                    Text(
                      parsed.entryEstimate ?? '',
                      style: context.text.bodySmall?.copyWith(
                        color: palette.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  VSpace.x05,
                ],

                // Plan name — number on its own line, label below
                ..._splitPlanName(parsed.planName).map(
                  (line) => Text(
                    line,
                    style: context.text.headlineMedium?.copyWith(
                      color: palette.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

                VSpace.x3,

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
                    text: buttonLabel,
                    onPressed: onBuy,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Painter that draws a rounded rectangular hang-tab slot at the top center
/// of the card — like the punch-out tab on a physical gift card.
class _HangTabSlotPainter extends CustomPainter {
  final Color color;
  final double tabWidth;
  final double tabHeight;
  final double tabRadius;
  final double cardBorderRadius;

  _HangTabSlotPainter({
    required this.color,
    required this.tabWidth,
    required this.tabHeight,
    required this.tabRadius,
    required this.cardBorderRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final halfWidth = tabWidth / 2;

    // Rounded rectangle (pill) body
    final pillTop = cardBorderRadius;
    final pillBottom = pillTop + tabHeight;

    // Semicircle arch that bulges up from the pill's top edge
    final archRadius = halfWidth * 0.375; // 0.75 diameter = 0.375 radius

    final path = Path()
      // Start at top-left of pill
      ..moveTo(centerX - halfWidth, pillTop + tabRadius)
      // Top-left rounded corner
      ..arcToPoint(
        Offset(centerX - halfWidth + tabRadius, pillTop),
        radius: Radius.circular(tabRadius),
        clockwise: true,
      )
      // Straight to where the arch begins
      ..lineTo(centerX - archRadius, pillTop)
      // Semicircle arch bulging upward (clockwise = arches above the line)
      ..arcToPoint(
        Offset(centerX + archRadius, pillTop),
        radius: Radius.circular(archRadius),
        clockwise: true,
      )
      // Straight to top-right corner
      ..lineTo(centerX + halfWidth - tabRadius, pillTop)
      // Top-right rounded corner
      ..arcToPoint(
        Offset(centerX + halfWidth, pillTop + tabRadius),
        radius: Radius.circular(tabRadius),
        clockwise: true,
      )
      // Right side down
      ..lineTo(centerX + halfWidth, pillBottom - tabRadius)
      // Bottom-right rounded corner
      ..arcToPoint(
        Offset(centerX + halfWidth - tabRadius, pillBottom),
        radius: Radius.circular(tabRadius),
        clockwise: true,
      )
      // Bottom straight
      ..lineTo(centerX - halfWidth + tabRadius, pillBottom)
      // Bottom-left rounded corner
      ..arcToPoint(
        Offset(centerX - halfWidth, pillBottom - tabRadius),
        radius: Radius.circular(tabRadius),
        clockwise: true,
      )
      ..close();

    final fill = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, fill);

    final stroke = Paint()
      ..color = color.withValues(alpha: 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawPath(path, stroke);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    if (oldDelegate is! _HangTabSlotPainter) return true;
    return oldDelegate.color != color ||
        oldDelegate.tabWidth != tabWidth ||
        oldDelegate.tabHeight != tabHeight;
  }
}
