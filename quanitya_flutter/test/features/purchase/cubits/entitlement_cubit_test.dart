import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:cubit_ui_flow/cubit_ui_flow.dart';
import 'package:anonaccred_client/anonaccred_client.dart'
    show AccountEntitlement;

import 'package:quanitya_flutter/infrastructure/purchase/i_entitlement_service.dart';
import 'package:quanitya_flutter/features/purchase/cubits/entitlement_cubit.dart';
import 'package:quanitya_flutter/features/purchase/cubits/entitlement_state.dart';

class MockEntitlementService extends Mock implements IEntitlementService {}

void main() {
  late MockEntitlementService mockService;

  setUp(() {
    mockService = MockEntitlementService();
  });

  group('EntitlementCubit', () {
    test('initial state is idle with no entitlements', () {
      final cubit = EntitlementCubit(mockService);
      expect(cubit.state.status, UiFlowStatus.idle);
      expect(cubit.state.entitlements, isEmpty);
      expect(cubit.state.hasSyncAccess, isFalse);
      cubit.close();
    });

    blocTest<EntitlementCubit, EntitlementState>(
      'loadEntitlements emits loading then success with entitlements',
      build: () {
        when(() => mockService.getEntitlements()).thenAnswer(
          (_) async => [
            AccountEntitlement(
              accountId: 1,
              entitlementId: 1,
              balance: 25.0,
            ),
          ],
        );
        return EntitlementCubit(mockService);
      },
      act: (cubit) => cubit.loadEntitlements(),
      expect: () => [
        predicate<EntitlementState>(
          (s) => s.status == UiFlowStatus.loading,
          'loading state',
        ),
        predicate<EntitlementState>(
          (s) =>
              s.status == UiFlowStatus.success &&
              s.lastOperation == EntitlementOperation.loadEntitlements &&
              s.entitlements.length == 1 &&
              s.entitlements.first.balance == 25.0,
          'success state with entitlements',
        ),
      ],
    );

    blocTest<EntitlementCubit, EntitlementState>(
      'checkSyncAccess emits true when service says yes',
      build: () {
        when(() => mockService.hasSyncAccess())
            .thenAnswer((_) async => true);
        return EntitlementCubit(mockService);
      },
      act: (cubit) => cubit.checkSyncAccess(),
      expect: () => [
        predicate<EntitlementState>(
          (s) => s.status == UiFlowStatus.loading,
          'loading state',
        ),
        predicate<EntitlementState>(
          (s) =>
              s.status == UiFlowStatus.success &&
              s.lastOperation == EntitlementOperation.checkSyncAccess &&
              s.hasSyncAccess == true,
          'success state with sync access',
        ),
      ],
    );

    blocTest<EntitlementCubit, EntitlementState>(
      'checkSyncAccess emits false when no credits',
      build: () {
        when(() => mockService.hasSyncAccess())
            .thenAnswer((_) async => false);
        return EntitlementCubit(mockService);
      },
      act: (cubit) => cubit.checkSyncAccess(),
      expect: () => [
        predicate<EntitlementState>(
          (s) => s.status == UiFlowStatus.loading,
          'loading state',
        ),
        predicate<EntitlementState>(
          (s) =>
              s.status == UiFlowStatus.success &&
              s.hasSyncAccess == false,
          'success state without sync access',
        ),
      ],
    );

    blocTest<EntitlementCubit, EntitlementState>(
      'checkSyncAccess emits failure when service throws',
      build: () {
        when(() => mockService.hasSyncAccess())
            .thenThrow(Exception('Network error'));
        return EntitlementCubit(mockService);
      },
      act: (cubit) => cubit.checkSyncAccess(),
      expect: () => [
        predicate<EntitlementState>(
          (s) => s.status == UiFlowStatus.loading,
          'loading state',
        ),
        predicate<EntitlementState>(
          (s) => s.status == UiFlowStatus.failure && s.error != null,
          'failure state with error',
        ),
      ],
    );
  });
}
