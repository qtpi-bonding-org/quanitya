import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:cubit_ui_flow/cubit_ui_flow.dart';

import 'package:quanitya_flutter/features/app_operating_mode/models/app_operating_mode.dart';
import 'package:quanitya_flutter/features/app_operating_mode/cubits/app_operating_state.dart';
import 'package:quanitya_flutter/features/app_operating_mode/cubits/app_operating_cubit.dart';
import 'package:quanitya_flutter/features/app_operating_mode/repositories/app_operating_repository.dart';
import 'package:quanitya_flutter/features/app_operating_mode/services/network_service.dart';

import 'app_operating_mode_test.mocks.dart';

@GenerateMocks([AppOperatingRepository, INetworkService])
void main() {
  late AppOperatingCubit cubit;
  late MockAppOperatingRepository mockRepository;
  late MockINetworkService mockNetworkService;

  setUp(() {
    GetIt.instance.reset();
    mockRepository = MockAppOperatingRepository();
    mockNetworkService = MockINetworkService();
    cubit = AppOperatingCubit(mockRepository, mockNetworkService);
  });

  tearDown(() {
    cubit.close();
  });

  group('AppOperatingMode', () {
    test('should have correct default values', () {
      expect(AppOperatingMode.local.requiresServer, false);
      expect(AppOperatingMode.selfHosted.requiresServer, true);
      expect(AppOperatingMode.cloud.requiresServer, true);
      
      expect(AppOperatingMode.local.supportsSync, false);
      expect(AppOperatingMode.selfHosted.supportsSync, true);
      expect(AppOperatingMode.cloud.supportsSync, true);
    });

    test('should have correct display names', () {
      expect(AppOperatingMode.local.displayName, 'Local Only');
      expect(AppOperatingMode.selfHosted.displayName, 'Self-Hosted');
      expect(AppOperatingMode.cloud.displayName, 'Quanitya Cloud');
    });
  });

  group('AppOperatingState', () {
    test('should have correct initial state', () {
      const state = AppOperatingState();
      
      expect(state.status, UiFlowStatus.idle);
      expect(state.mode, AppOperatingMode.local);
      expect(state.isConnected, false);
      expect(state.hasTriedConnection, false);
      expect(state.serverpodUrl, 'http://localhost:8080/');
      expect(state.selfHostedUrl, null);
    });

    test('canCreateAccount should work correctly', () {
      // Local mode - always can create
      const localState = AppOperatingState(mode: AppOperatingMode.local);
      expect(localState.canCreateAccount, true);
      
      // Server modes - depends on connection
      const connectedSelfHosted = AppOperatingState(
        mode: AppOperatingMode.selfHosted,
        isConnected: true,
      );
      expect(connectedSelfHosted.canCreateAccount, true);
      
      const disconnectedSelfHosted = AppOperatingState(
        mode: AppOperatingMode.selfHosted,
        isConnected: false,
      );
      expect(disconnectedSelfHosted.canCreateAccount, false);
    });
  });

  group('AppOperatingCubit', () {
    test('should start with correct initial state', () {
      expect(cubit.state.mode, AppOperatingMode.local);
      expect(cubit.state.status, UiFlowStatus.idle);
    });

    test('should switch to local mode successfully', () async {
      // Arrange
      when(mockRepository.updateMode(AppOperatingMode.local))
          .thenAnswer((_) async {});

      // Act
      await cubit.switchToLocal();

      // Assert
      expect(cubit.state.mode, AppOperatingMode.local);
      expect(cubit.state.status, UiFlowStatus.success);
      expect(cubit.state.isConnected, false);
      expect(cubit.state.lastOperation, AppOperatingOperation.switchMode);
      
      verify(mockRepository.updateMode(AppOperatingMode.local)).called(1);
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
      expect(cubit.state.lastOperation, AppOperatingOperation.testConnection);
      
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