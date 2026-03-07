import 'package:flutter/material.dart';

import '../../../infrastructure/purchase/purchase_models.dart';

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
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(product.title, style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              product.description,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  product.localizedPrice ?? '\$${product.priceUsd.toStringAsFixed(2)}',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                FilledButton(
                  onPressed: isLoading ? null : onBuy,
                  child: isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(_isSubscription ? 'Subscribe' : 'Buy'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
