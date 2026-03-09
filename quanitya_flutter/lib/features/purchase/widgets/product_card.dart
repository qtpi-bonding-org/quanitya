import 'package:flutter/material.dart';

import '../../../design_system/primitives/app_sizes.dart';
import '../../../design_system/primitives/app_spacings.dart';
import '../../../design_system/primitives/quanitya_palette.dart';
import '../../../infrastructure/purchase/purchase_models.dart';
import '../../../support/extensions/context_extensions.dart';

/// Displays a single purchasable product with title, description, price, and buy button.
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

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: AppPadding.listItem,
      child: Padding(
        padding: AppPadding.allDouble,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(product.title, style: context.text.titleMedium),
            VSpace.x05,
            Text(
              product.description,
              style: context.text.bodyMedium?.copyWith(
                color: context.colors.textSecondary,
              ),
            ),
            VSpace.x2,
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  product.localizedPrice ?? '\$${product.priceUsd.toStringAsFixed(2)}',
                  style: context.text.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                FilledButton(
                  onPressed: isLoading ? null : onBuy,
                  child: isLoading
                      ? SizedBox(
                          width: AppSizes.iconSmall,
                          height: AppSizes.iconSmall,
                          child: const CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(_isSubscription
                          ? context.l10n.purchaseSubscribe
                          : context.l10n.purchaseBuy),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
