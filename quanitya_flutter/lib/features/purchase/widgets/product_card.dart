import 'package:flutter/material.dart';

import '../../../design_system/primitives/app_sizes.dart';
import '../../../design_system/primitives/app_spacings.dart';
import '../../../design_system/primitives/quanitya_palette.dart';
import '../../../design_system/widgets/quanitya/general/quanitya_text_button.dart';
import '../../../infrastructure/purchase/purchase_models.dart';
import '../../../support/extensions/context_extensions.dart';

/// Displays a purchasable product as a solid washi-white price tag.
///
/// Manuscript aesthetic: solid fill with subtle shadow (the only
/// place in the app that uses elevation/shadow), string hole detail,
/// capacity prominently displayed above the plan name.
class ProductCard extends StatelessWidget {
  const ProductCard({
    super.key,
    required this.product,
    required this.onBuy,
  });

  final PurchaseProduct product;
  final VoidCallback onBuy;

  bool get _isSubscription =>
      product.productType == StoreProductType.subscription;

  /// Extracts capacity (e.g. "500 MB", "1 GB") from the title.
  /// Returns (capacity, planName, entryEstimate).
  /// If no capacity found, (null, fullTitle, null).
  ({String? capacity, String planName, _EntryEstimate? entryEstimate}) _parseTitle() {
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
            .replaceAll(
              RegExp(r'\b(monthly|yearly|annual)\b', caseSensitive: false),
              '',
            )
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
  ///
  /// Returns a structured [_EntryEstimate] to be resolved to a localized
  /// string in [build] via [_resolveEstimate].
  static _EntryEstimate? _estimateEntries(double? value, String unit) {
    if (value == null) return null;

    final bytesPerEntry = 4096; // ~4 KB server-side
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
      return _EntryEstimate.millions(rounded ~/ 1000000);
    }
    if (rounded >= 1000) {
      return _EntryEstimate.thousands(rounded ~/ 1000);
    }
    return _EntryEstimate.exact(entries);
  }

  /// Resolves a structured [_EntryEstimate] to a localized display string.
  static String _resolveEstimate(BuildContext context, _EntryEstimate estimate) {
    return switch (estimate) {
      _EntryEstimate(:final millions?) =>
        context.l10n.estimatedEntriesMillions(millions),
      _EntryEstimate(:final thousands?) =>
        context.l10n.estimatedEntriesThousands(thousands),
      _EntryEstimate(:final exact?) =>
        context.l10n.estimatedEntries(exact),
      _ => '',
    };
  }

  @override
  Widget build(BuildContext context) {
    final palette = QuanityaPalette.primary;
    final parsed = _parseTitle();
    final price =
        product.localizedPrice ?? '\$${product.priceUsd.toStringAsFixed(2)}';

    final holeRadius = AppSizes.space * 0.75;

    final buttonLabel = _isSubscription
        ? context.l10n.purchaseSubscribe
        : context.l10n.purchaseBuy;

    final entryEstimateLabel = parsed.entryEstimate != null
        ? _resolveEstimate(context, parsed.entryEstimate!)
        : null;

    // Build a full semantic description for screen readers
    final semanticParts = <String>[
      parsed.planName,
      if (parsed.capacity != null) parsed.capacity ?? '',
      if (entryEstimateLabel != null) entryEstimateLabel,
      price,
      if (_isSubscription &&
          product.subscriptionPeriod == SubscriptionPeriod.monthly)
        context.l10n.purchasePeriodMonthly,
      if (_isSubscription &&
          product.subscriptionPeriod == SubscriptionPeriod.yearly)
        context.l10n.purchasePeriodYearly,
      buttonLabel,
    ];

    return Semantics(
      button: true,
      enabled: true,
      label: semanticParts.join(', '),
      excludeSemantics: true,
      child: Container(
        decoration: BoxDecoration(
          color: palette.backgroundPrimary,
          borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
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
          painter: _StringHolePainter(
            color: palette.textPrimary.withValues(alpha: 0.12),
            holeRadius: holeRadius,
            borderRadius: AppSizes.radiusSmall,
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
                    style: context.text.titleMedium?.copyWith(
                      color: palette.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (entryEstimateLabel != null) ...[
                    VSpace.x025,
                    Text(
                      entryEstimateLabel,
                      style: context.text.bodySmall?.copyWith(
                        color: palette.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  VSpace.x05,
                ],

                // Plan name
                Text(
                  parsed.planName,
                  style: context.text.headlineMedium?.copyWith(
                    color: palette.textPrimary,
                    fontWeight: FontWeight.w700,
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

                // Action — page-level overlay handles loading
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

/// Painter that draws a filled string hole at the top of the price tag.
///
/// The hole is a solid dark circle — same tone as the card shadow —
/// suggesting a punched-out hole in the tag.
class _StringHolePainter extends CustomPainter {
  final Color color;
  final double holeRadius;
  final double borderRadius;

  _StringHolePainter({
    required this.color,
    required this.holeRadius,
    required this.borderRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final holeCenter = Offset(
      size.width / 2,
      borderRadius + holeRadius + 4,
    );

    final fill = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawCircle(holeCenter, holeRadius, fill);

    final stroke = Paint()
      ..color = color.withValues(alpha: 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = AppSizes.borderWidth;
    canvas.drawCircle(holeCenter, holeRadius, stroke);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    if (oldDelegate is! _StringHolePainter) return true;
    return oldDelegate.color != color ||
        oldDelegate.holeRadius != holeRadius;
  }
}

/// Structured entry-count estimate returned by [ProductCard._estimateEntries].
///
/// Exactly one of the three fields is non-null, representing the magnitude
/// of the estimate. Resolved to a localized string via
/// [ProductCard._resolveEstimate].
class _EntryEstimate {
  final int? millions;
  final int? thousands;
  final int? exact;

  const _EntryEstimate._({this.millions, this.thousands, this.exact});

  factory _EntryEstimate.millions(int value) =>
      _EntryEstimate._(millions: value);
  factory _EntryEstimate.thousands(int value) =>
      _EntryEstimate._(thousands: value);
  factory _EntryEstimate.exact(int value) => _EntryEstimate._(exact: value);
}
