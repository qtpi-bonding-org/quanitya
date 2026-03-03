import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:cubit_ui_flow/cubit_ui_flow.dart';

import 'package:quanitya_flutter/infrastructure/purchase/i_purchase_service.dart';
import 'package:quanitya_flutter/infrastructure/purchase/purchase_models.dart';
import 'package:quanitya_flutter/features/purchase/cubits/purchase_cubit.dart';
import 'package:quanitya_flutter/features/purchase/cubits/purchase_state.dart';

class MockPurchaseService extends Mock implements IPurchaseService {}

class FakePurchaseRequest extends Fake implements PurchaseRequest {}

void main() {
  late MockPurchaseService mockService;

  setUpAll(() {
    registerFallbackValue(FakePurchaseRequest());
  });

  setUp(() {
    mockService = MockPurchaseService();
  });

  group('PurchaseCubit', () {
    test('initial state is idle with empty products', () {
      final cubit = PurchaseCubit(mockService);
      expect(cubit.state.status, UiFlowStatus.idle);
      expect(cubit.state.products, isEmpty);
      expect(cubit.state.lastOperation, isNull);
      expect(cubit.state.lastValidation, isNull);
      cubit.close();
    });

    blocTest<PurchaseCubit, PurchaseState>(
      'loadProducts emits loading then success with products',
      build: () {
        when(() => mockService.getProducts(rail: any(named: 'rail')))
            .thenAnswer(
          (_) async => [
            const PurchaseProduct(
              productId: 'sync_days_30',
              title: '30 Sync Days',
              description: '30 days of cloud sync',
              priceUsd: 2.99,
              rail: PurchaseRail.appleIap,
            ),
            const PurchaseProduct(
              productId: 'sync_days_90',
              title: '90 Sync Days',
              description: '90 days of cloud sync',
              priceUsd: 6.99,
              rail: PurchaseRail.appleIap,
            ),
          ],
        );
        return PurchaseCubit(mockService);
      },
      act: (cubit) => cubit.loadProducts(),
      expect: () => [
        predicate<PurchaseState>(
          (s) => s.status == UiFlowStatus.loading,
          'loading state',
        ),
        predicate<PurchaseState>(
          (s) =>
              s.status == UiFlowStatus.success &&
              s.lastOperation == PurchaseOperation.loadProducts &&
              s.products.length == 2,
          'success state with 2 products',
        ),
      ],
    );

    blocTest<PurchaseCubit, PurchaseState>(
      'purchase emits loading then success with validation result',
      build: () {
        when(() => mockService.purchase(any())).thenAnswer(
          (_) async => const PurchaseValidationResult(
            success: true,
            tag: 'sync_days',
            amount: 30,
          ),
        );
        return PurchaseCubit(mockService);
      },
      act: (cubit) => cubit.purchase(
        const PurchaseRequest(
          productId: 'sync_days_30',
          rail: PurchaseRail.appleIap,
          accountId: 1,
        ),
      ),
      expect: () => [
        predicate<PurchaseState>(
          (s) => s.status == UiFlowStatus.loading,
          'loading state',
        ),
        predicate<PurchaseState>(
          (s) =>
              s.status == UiFlowStatus.success &&
              s.lastOperation == PurchaseOperation.purchase &&
              s.lastValidation != null &&
              s.lastValidation!.success == true,
          'success state with validation',
        ),
      ],
    );

    blocTest<PurchaseCubit, PurchaseState>(
      'purchase emits failure when service throws',
      build: () {
        when(() => mockService.purchase(any()))
            .thenThrow(Exception('Network error'));
        return PurchaseCubit(mockService);
      },
      act: (cubit) => cubit.purchase(
        const PurchaseRequest(
          productId: 'sync_days_30',
          rail: PurchaseRail.appleIap,
          accountId: 1,
        ),
      ),
      expect: () => [
        predicate<PurchaseState>(
          (s) => s.status == UiFlowStatus.loading,
          'loading state',
        ),
        predicate<PurchaseState>(
          (s) => s.status == UiFlowStatus.failure && s.error != null,
          'failure state with error',
        ),
      ],
    );

    blocTest<PurchaseCubit, PurchaseState>(
      'recoverPurchases emits loading then success',
      build: () {
        when(() => mockService.recoverPendingPurchases())
            .thenAnswer((_) async {});
        return PurchaseCubit(mockService);
      },
      act: (cubit) => cubit.recoverPurchases(),
      expect: () => [
        predicate<PurchaseState>(
          (s) => s.status == UiFlowStatus.loading,
          'loading state',
        ),
        predicate<PurchaseState>(
          (s) =>
              s.status == UiFlowStatus.success &&
              s.lastOperation == PurchaseOperation.recoverPurchases,
          'success state',
        ),
      ],
    );
  });
}
