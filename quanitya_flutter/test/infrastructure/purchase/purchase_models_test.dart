import 'package:flutter_test/flutter_test.dart';

import 'package:quanitya_flutter/infrastructure/purchase/purchase_models.dart';

void main() {
  group('PurchaseProduct', () {
    test('creates with required fields', () {
      const product = PurchaseProduct(
        productId: 'sync_days_30',
        title: '30 Sync Days',
        description: '30 days of cloud sync',
        priceUsd: 2.99,
        rail: PurchaseRail.appleIap,
      );

      expect(product.productId, 'sync_days_30');
      expect(product.priceUsd, 2.99);
      expect(product.localizedPrice, isNull);
      expect(product.currencyCode, isNull);
    });

    test('copyWith preserves unchanged fields', () {
      const product = PurchaseProduct(
        productId: 'sync_days_30',
        title: '30 Sync Days',
        description: '30 days',
        priceUsd: 2.99,
        rail: PurchaseRail.appleIap,
      );

      final updated = product.copyWith(localizedPrice: '\$2.99');
      expect(updated.productId, 'sync_days_30');
      expect(updated.localizedPrice, '\$2.99');
    });

    test('equality works correctly', () {
      const a = PurchaseProduct(
        productId: 'sync_days_30',
        title: '30 Sync Days',
        description: '30 days',
        priceUsd: 2.99,
        rail: PurchaseRail.appleIap,
      );
      const b = PurchaseProduct(
        productId: 'sync_days_30',
        title: '30 Sync Days',
        description: '30 days',
        priceUsd: 2.99,
        rail: PurchaseRail.appleIap,
      );

      expect(a, equals(b));
    });
  });

  group('PurchaseResult', () {
    test('maps all status values', () {
      for (final status in PurchaseStatus.values) {
        final result = PurchaseResult(
          status: status,
          rail: PurchaseRail.appleIap,
          productId: 'test',
        );
        expect(result.status, status);
      }
    });
  });

  group('PurchaseValidationResult', () {
    test('success result contains tag and amount', () {
      const result = PurchaseValidationResult(
        success: true,
        tag: 'sync_days',
        amount: 30,
        internalTransactionId: 'txn_abc',
      );

      expect(result.success, isTrue);
      expect(result.tag, 'sync_days');
      expect(result.amount, 30);
      expect(result.errorMessage, isNull);
    });

    test('failure result contains error message', () {
      const result = PurchaseValidationResult(
        success: false,
        errorMessage: 'Invalid receipt',
      );

      expect(result.success, isFalse);
      expect(result.errorMessage, 'Invalid receipt');
    });
  });
}
