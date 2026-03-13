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
    test('initial state is idle', () {
      final cubit = HealthSyncCubit(mockService, mockPermissionService);
      addTearDown(cubit.close);

      expect(cubit.state.status, UiFlowStatus.idle);
      expect(cubit.state.permissionsGranted, isFalse);
      expect(cubit.state.lastImportCount, equals(0));
      expect(cubit.state.lastOperation, isNull);
      expect(cubit.state.error, isNull);
    });

    group('requestPermissions', () {
      final types = [HealthDataType.STEPS, HealthDataType.HEART_RATE];

      blocTest<HealthSyncCubit, HealthSyncState>(
        'emits loading then success with permissionsGranted=true',
        build: () {
          when(mockPermissionService.ensureHealth(types))
              .thenAnswer((_) async => true);
          return HealthSyncCubit(mockService, mockPermissionService);
        },
        act: (cubit) => cubit.requestPermissions(types),
        expect: () => [
          const HealthSyncState(status: UiFlowStatus.loading),
          const HealthSyncState(
            status: UiFlowStatus.success,
            lastOperation: HealthSyncOperation.requestPermissions,
            permissionsGranted: true,
          ),
        ],
        verify: (_) {
          verify(mockPermissionService.ensureHealth(types)).called(1);
        },
      );

      blocTest<HealthSyncCubit, HealthSyncState>(
        'emits loading then success with permissionsGranted=false when denied',
        build: () {
          when(mockPermissionService.ensureHealth(types))
              .thenAnswer((_) async => false);
          return HealthSyncCubit(mockService, mockPermissionService);
        },
        act: (cubit) => cubit.requestPermissions(types),
        expect: () => [
          const HealthSyncState(status: UiFlowStatus.loading),
          const HealthSyncState(
            status: UiFlowStatus.success,
            lastOperation: HealthSyncOperation.requestPermissions,
            permissionsGranted: false,
          ),
        ],
      );

      blocTest<HealthSyncCubit, HealthSyncState>(
        'emits loading then failure on error',
        build: () {
          when(mockPermissionService.ensureHealth(types))
              .thenThrow(Exception('platform error'));
          return HealthSyncCubit(mockService, mockPermissionService);
        },
        act: (cubit) => cubit.requestPermissions(types),
        expect: () => [
          const HealthSyncState(status: UiFlowStatus.loading),
          predicate<HealthSyncState>(
            (s) => s.status == UiFlowStatus.failure && s.error != null,
          ),
        ],
      );
    });

    group('sync', () {
      final types = [HealthDataType.STEPS];

      blocTest<HealthSyncCubit, HealthSyncState>(
        'emits loading then success with import count',
        build: () {
          when(mockService.sync(types, since: null))
              .thenAnswer((_) async => 42);
          return HealthSyncCubit(mockService, mockPermissionService);
        },
        act: (cubit) => cubit.sync(types),
        expect: () => [
          const HealthSyncState(status: UiFlowStatus.loading),
          const HealthSyncState(
            status: UiFlowStatus.success,
            lastOperation: HealthSyncOperation.sync,
            lastImportCount: 42,
          ),
        ],
        verify: (_) {
          verify(mockService.sync(types, since: null)).called(1);
        },
      );

      blocTest<HealthSyncCubit, HealthSyncState>(
        'emits loading then success with 0 when nothing new',
        build: () {
          when(mockService.sync(types, since: null))
              .thenAnswer((_) async => 0);
          return HealthSyncCubit(mockService, mockPermissionService);
        },
        act: (cubit) => cubit.sync(types),
        expect: () => [
          const HealthSyncState(status: UiFlowStatus.loading),
          const HealthSyncState(
            status: UiFlowStatus.success,
            lastOperation: HealthSyncOperation.sync,
            lastImportCount: 0,
          ),
        ],
      );

      blocTest<HealthSyncCubit, HealthSyncState>(
        'passes since parameter through to service',
        build: () {
          final since = DateTime(2026, 1, 1);
          when(mockService.sync(types, since: since))
              .thenAnswer((_) async => 10);
          return HealthSyncCubit(mockService, mockPermissionService);
        },
        act: (cubit) => cubit.sync(types, since: DateTime(2026, 1, 1)),
        expect: () => [
          const HealthSyncState(status: UiFlowStatus.loading),
          const HealthSyncState(
            status: UiFlowStatus.success,
            lastOperation: HealthSyncOperation.sync,
            lastImportCount: 10,
          ),
        ],
      );

      blocTest<HealthSyncCubit, HealthSyncState>(
        'emits loading then failure on error',
        build: () {
          when(mockService.sync(types, since: null))
              .thenThrow(Exception('sync failed'));
          return HealthSyncCubit(mockService, mockPermissionService);
        },
        act: (cubit) => cubit.sync(types),
        expect: () => [
          const HealthSyncState(status: UiFlowStatus.loading),
          predicate<HealthSyncState>(
            (s) => s.status == UiFlowStatus.failure && s.error != null,
          ),
        ],
      );
    });
  });
}
