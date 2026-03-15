import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:cubit_ui_flow/cubit_ui_flow.dart';

import 'package:quanitya_flutter/features/app_syncing_mode/models/app_syncing_mode.dart';
import 'package:quanitya_flutter/features/app_syncing_mode/cubits/app_syncing_state.dart';
import 'package:quanitya_flutter/features/app_syncing_mode/cubits/app_syncing_cubit.dart';
import 'package:quanitya_flutter/features/app_syncing_mode/repositories/app_syncing_repository.dart';
import 'package:quanitya_flutter/features/app_syncing_mode/services/network_service.dart';

import 'app_syncing_mode_test.mocks.dart';

@GenerateMocks([AppSyncingRepository, INetworkService])
void main() {
  late AppSyncingCubit cubit;
  late MockAppSyncingRepository mockRepository;
  late MockINetworkService mockNetworkService;

  setUp(() {
    GetIt.instance.reset();
    mockRepository = MockAppSyncingRepository();
    mockNetworkService = MockINetworkService();
    cubit = AppSyncingCubit(mockRepository, mockNetworkService);
  });

  tearDown(() {
    cubit.close();
  });

  group('AppSyncingMode', () {
    test('should have correct default values', () {
      expect(AppSyncingMode.local.requiresServer, false);
      expect(AppSyncingMode.selfHosted.requiresServer, true);
      expect(AppSyncingMode.cloud.requiresServer, true);

      expect(AppSyncingMode.local.supportsSync, false);
      expect(AppSyncingMode.selfHosted.supportsSync, true);
      expect(AppSyncingMode.cloud.supportsSync, true);
    });

    test('should have correct display names', () {
      expect(AppSyncingMode.local.displayName, 'Local Only');
      expect(AppSyncingMode.selfHosted.displayName, 'Self-Hosted');
      expect(AppSyncingMode.cloud.displayName, 'Quanitya Cloud');
    });
  });

  group('AppSyncingState', () {
    test('should have correct initial state', () {
      const state = AppSyncingState();

      expect(state.status, UiFlowStatus.idle);
      expect(state.mode, AppSyncingMode.local);
      expect(state.isConnected, false);
      expect(state.hasTriedConnection, false);
      expect(state.serverpodUrl, 'http://localhost:8080/');
      expect(state.selfHostedUrl, null);
    });

    test('canCreateAccount should work correctly', () {
      // Local mode - always can create
      const localState = AppSyncingState(mode: AppSyncingMode.local);
      expect(localState.canCreateAccount, true);

      // Server modes - depends on connection
      const connectedSelfHosted = AppSyncingState(
        mode: AppSyncingMode.selfHosted,
        isConnected: true,
      );
      expect(connectedSelfHosted.canCreateAccount, true);

      const disconnectedSelfHosted = AppSyncingState(
        mode: AppSyncingMode.selfHosted,
        isConnected: false,
      );
      expect(disconnectedSelfHosted.canCreateAccount, false);
    });
  });

  group('AppSyncingCubit', () {
    test('should start with correct initial state', () {
      expect(cubit.state.mode, AppSyncingMode.local);
      expect(cubit.state.status, UiFlowStatus.idle);
    });

    test('should switch to local mode successfully', () async {
      // Arrange
      when(mockRepository.updateMode(AppSyncingMode.local))
          .thenAnswer((_) async {});

      // Act
      await cubit.switchToLocal();

      // Assert
      expect(cubit.state.mode, AppSyncingMode.local);
      expect(cubit.state.status, UiFlowStatus.success);
      expect(cubit.state.isConnected, false);
      expect(cubit.state.lastOperation, AppSyncingOperation.switchMode);

      verify(mockRepository.updateMode(AppSyncingMode.local)).called(1);
    });

    test('should test connection successfully', () async {
      // Arrange
      const testUrl = 'https://test.example.com';
      when(mockNetworkService.testConnection(testUrl))
          .thenAnswer((_) async => true);
      when(mockRepository.updateConnectionStatus(true))
          .thenAnswer((_) async {});

      // Act
      await cubit.testConnection(testUrl);

      // Assert
      expect(cubit.state.status, UiFlowStatus.success);
      expect(cubit.state.isConnected, true);
      expect(cubit.state.hasTriedConnection, true);
      expect(cubit.state.lastTestedUrl, testUrl);
      expect(cubit.state.lastOperation, AppSyncingOperation.testConnection);

      verify(mockNetworkService.testConnection(testUrl)).called(1);
      verify(mockRepository.updateConnectionStatus(true)).called(1);
    });

    test('should handle connection failure', () async {
      // Arrange
      const testUrl = 'https://test.example.com';
      when(mockNetworkService.testConnection(testUrl))
          .thenAnswer((_) async => false);
      when(mockRepository.updateConnectionStatus(false))
          .thenAnswer((_) async {});

      // Act
      await cubit.testConnection(testUrl);

      // Assert
      expect(cubit.state.status, UiFlowStatus.success);
      expect(cubit.state.isConnected, false);
      expect(cubit.state.hasTriedConnection, true);
      expect(cubit.state.lastTestedUrl, testUrl);

      verify(mockNetworkService.testConnection(testUrl)).called(1);
      verify(mockRepository.updateConnectionStatus(false)).called(1);
    });
  });
}
