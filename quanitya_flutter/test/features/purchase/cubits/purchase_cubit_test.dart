import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:cubit_ui_flow/cubit_ui_flow.dart';

import 'package:quanitya_flutter/infrastructure/auth/auth_service.dart';
import 'package:quanitya_flutter/infrastructure/device/device_info_service.dart';
import 'package:quanitya_flutter/infrastructure/purchase/i_purchase_service.dart';
import 'package:quanitya_flutter/infrastructure/purchase/purchase_models.dart';
import 'package:quanitya_flutter/features/app_syncing_mode/models/app_syncing_mode.dart';
import 'package:quanitya_flutter/features/purchase/cubits/purchase_cubit.dart';
import 'package:quanitya_flutter/features/purchase/cubits/purchase_state.dart';

class MockPurchaseService extends Mock implements IPurchaseService {}

class MockAuthService extends Mock implements AuthService {}

class MockDeviceInfoService extends Mock implements DeviceInfoService {}

class FakePurchaseRequest extends Fake implements PurchaseRequest {}

void main() {
  late MockPurchaseService mockService;
  late MockAuthService mockAuthService;
  late MockDeviceInfoService mockDeviceInfoService;

  setUpAll(() {
    registerFallbackValue(FakePurchaseRequest());
    registerFallbackValue(AppSyncingMode.cloud);
  });

  setUp(() {
    mockService = MockPurchaseService();
    mockAuthService = MockAuthService();
    mockDeviceInfoService = MockDeviceInfoService();
    when(() => mockAuthService.isRegisteredWithServer).thenAnswer((_) async => true);
    when(() => mockDeviceInfoService.getDeviceName()).thenAnswer((_) async => 'iPhone 15 Pro');
  });

  group('PurchaseCubit', () {
    test('initial state is idle with empty products', () {
      final cubit = PurchaseCubit(mockService);
      expect(cubit.state.status, UiFlowStatus.idle);
      expect(cubit.state.products, isEmpty);
      expect(cubit.state.lastOperation, isNull);
      cubit.close();
    });

    blocTest<PurchaseCubit, PurchaseState>(
      'loadProducts emits loading then success with products',
      build: () {
        when(() => mockService.getProducts()).thenAnswer(
          (_) async => [
            const PurchaseProduct(
              productId: 'sync_1gb_month',
              title: 'Monthly Sync (1 GB)',
              description: '1 month of cloud sync (1 GB)',
              priceUsd: 3.99,
              rail: PurchaseRail.appleIap,
            ),
            const PurchaseProduct(
              productId: 'sync_1gb_year',
              title: 'Yearly Sync (1 GB)',
              description: '1 year of cloud sync (1 GB)',
              priceUsd: 39.99,
              rail: PurchaseRail.appleIap,
            ),
          ],
        );
        return PurchaseCubit(mockService);
      },
      act: (cubit) => cubit.loadProducts(),
      expect: () => [
        predicate<PurchaseState>(
          (s) =>
              s.status == UiFlowStatus.idle &&
              s.lastOperation == PurchaseOperation.loadProducts,
          'idle state with operation set',
        ),
        predicate<PurchaseState>(
          (s) => s.status == UiFlowStatus.loading,
          'loading state',
        ),
        predicate<PurchaseState>(
          (s) =>
              s.status == UiFlowStatus.success &&
              s.lastOperation == PurchaseOperation.loadProducts &&
              s.products.length == 2,
          'success state with products',
        ),
      ],
    );

    blocTest<PurchaseCubit, PurchaseState>(
      'purchase emits loading then success',
      build: () {
        when(() => mockService.purchase(any(), mode: any(named: 'mode'))).thenAnswer(
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
          productId: 'sync_1gb_month',
          rail: PurchaseRail.appleIap,
        ),
        mode: AppSyncingMode.cloud,
      ),
      expect: () => [
        predicate<PurchaseState>(
          (s) => s.status == UiFlowStatus.loading,
          'loading state',
        ),
        predicate<PurchaseState>(
          (s) =>
              s.status == UiFlowStatus.success &&
              s.lastOperation == PurchaseOperation.purchase,
          'success state',
        ),
      ],
    );

    blocTest<PurchaseCubit, PurchaseState>(
      'purchase emits failure when service throws',
      build: () {
        when(() => mockService.purchase(any(), mode: any(named: 'mode')))
            .thenThrow(Exception('Network error'));
        return PurchaseCubit(mockService);
      },
      act: (cubit) => cubit.purchase(
        const PurchaseRequest(
          productId: 'sync_1gb_month',
          rail: PurchaseRail.appleIap,
        ),
        mode: AppSyncingMode.cloud,
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
