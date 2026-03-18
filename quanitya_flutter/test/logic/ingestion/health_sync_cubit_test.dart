import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:health/health.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:cubit_ui_flow/cubit_ui_flow.dart';

import 'package:quanitya_flutter/infrastructure/permissions/permission_service.dart';
import 'package:quanitya_flutter/integrations/flutter/health/health_sync_cubit.dart';
import 'package:quanitya_flutter/integrations/flutter/health/health_sync_service.dart';
import 'package:quanitya_flutter/integrations/flutter/health/health_sync_state.dart';

@GenerateMocks([HealthSyncService, PermissionService])
import 'health_sync_cubit_test.mocks.dart';

void main() {
  late MockHealthSyncService mockService;
  late MockPermissionService mockPermissionService;

  setUp(() {
    mockService = MockHealthSyncService();
    mockPermissionService = MockPermissionService();
  });

  group('HealthSyncCubit', () {
    test('initial state is idle and disabled', () {
      final cubit = HealthSyncCubit(mockService, mockPermissionService);
      addTearDown(cubit.close);

      expect(cubit.state.status, UiFlowStatus.idle);
      expect(cubit.state.enabled, isFalse);
      expect(cubit.state.lastImportCount, equals(0));
      expect(cubit.state.lastOperation, isNull);
      expect(cubit.state.error, isNull);
    });

    group('loadEnabled', () {
      blocTest<HealthSyncCubit, HealthSyncState>(
        'emits enabled=true when previously enabled',
        build: () {
          when(mockService.isEnabled()).thenAnswer((_) async => true);
          return HealthSyncCubit(mockService, mockPermissionService);
        },
        act: (cubit) => cubit.loadEnabled(),
        expect: () => [
          const HealthSyncState(enabled: true),
        ],
      );

      blocTest<HealthSyncCubit, HealthSyncState>(
        'emits nothing when disabled (already default)',
        build: () {
          when(mockService.isEnabled()).thenAnswer((_) async => false);
          return HealthSyncCubit(mockService, mockPermissionService);
        },
        act: (cubit) => cubit.loadEnabled(),
        expect: () => <HealthSyncState>[],
      );
    });

    group('toggle on', () {
      final types = [HealthDataType.STEPS, HealthDataType.HEART_RATE];

      blocTest<HealthSyncCubit, HealthSyncState>(
        'requests permissions, syncs, persists enabled',
        build: () {
          when(mockPermissionService.ensureHealth(types))
              .thenAnswer((_) async => true);
          when(mockService.sync(types)).thenAnswer((_) async => 42);
          when(mockService.setEnabled(true)).thenAnswer((_) async {});
          return HealthSyncCubit(mockService, mockPermissionService);
        },
        act: (cubit) => cubit.toggle(true, types),
        expect: () => [
          const HealthSyncState(status: UiFlowStatus.loading),
          const HealthSyncState(
            status: UiFlowStatus.success,
            enabled: true,
            lastOperation: HealthSyncOperation.toggle,
            lastImportCount: 42,
          ),
        ],
        verify: (_) {
          verify(mockPermissionService.ensureHealth(types)).called(1);
          verify(mockService.sync(types)).called(1);
          verify(mockService.setEnabled(true)).called(1);
        },
      );

      blocTest<HealthSyncCubit, HealthSyncState>(
        'emits failure on sync error',
        build: () {
          when(mockPermissionService.ensureHealth(types))
              .thenAnswer((_) async => true);
          when(mockService.sync(types)).thenThrow(Exception('sync failed'));
          return HealthSyncCubit(mockService, mockPermissionService);
        },
        act: (cubit) => cubit.toggle(true, types),
        expect: () => [
          const HealthSyncState(status: UiFlowStatus.loading),
          predicate<HealthSyncState>(
            (s) => s.status == UiFlowStatus.failure && s.error != null,
          ),
        ],
        verify: (_) {
          verifyNever(mockService.setEnabled(any));
        },
      );
    });

    group('toggle off', () {
      final types = [HealthDataType.STEPS];

      blocTest<HealthSyncCubit, HealthSyncState>(
        'persists disabled and emits enabled=false',
        build: () {
          when(mockService.setEnabled(false)).thenAnswer((_) async {});
          return HealthSyncCubit(mockService, mockPermissionService);
        },
        act: (cubit) => cubit.toggle(false, types),
        expect: () => [
          const HealthSyncState(
            enabled: false,
            status: UiFlowStatus.success,
            lastOperation: HealthSyncOperation.toggle,
          ),
        ],
        verify: (_) {
          verify(mockService.setEnabled(false)).called(1);
          verifyNever(mockPermissionService.ensureHealth(any));
          verifyNever(mockService.sync(any));
        },
      );
    });
  });
}
