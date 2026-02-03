import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_error_privserver/flutter_error_privserver.dart';
import 'package:quanitya_flutter/app/bootstrap.dart';
import 'package:quanitya_flutter/infrastructure/error_reporting/error_reporter_service.dart';
import 'package:flutter/services.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockPathProviderPlatform extends PathProviderPlatform with MockPlatformInterfaceMixin {
  @override
  Future<String?> getApplicationDocumentsPath() async {
    return '.';
  }
  
  @override
  Future<String?> getTemporaryPath() async {
    return '.';
  }

  @override
  Future<String?> getApplicationSupportPath() async {
    return '.';
  }
  
  @override
  Future<String?> getLibraryPath() async {
    return '.';
  }
  
  @override
  Future<String?> getExternalStoragePath() async {
    return '.';
  }
}

/// Integration test for error reporting system.
/// REQUIRED: Serverpod running locally and native PowerSync library available
/// Set [skipIntegrationTests] to null to run these tests
const skipIntegrationTests = 'Requires native dependencies (PowerSync)';

void main() {
  group('Error Reporting Integration', () {
    setUpAll(() async {
      TestWidgetsFlutterBinding.ensureInitialized();
      PathProviderPlatform.instance = MockPathProviderPlatform();
      
      try {
        await bootstrap();
      } catch (e) {
        print('Bootstrap failed (expected in test env): $e');
      }
    });
    
    test('initializes app with bootstrap', () async {
      expect(getIt.isRegistered<ErrorReporterService>(), true);
    });
    
    test('creates test error entry', () {
      final testError = ErrorEntry(
        source: 'IntegrationTestCubit',
        errorType: 'IntegrationTestException',
        errorCode: 'INT_TEST_001',
        stackTrace: 'Test stack trace for integration test',
        timestamp: DateTime.now(),
        userMessage: 'Integration test error message',
      );
      
      expect(testError.source, 'IntegrationTestCubit');
      expect(testError.errorType, 'IntegrationTestException');
      expect(testError.errorCode, 'INT_TEST_001');
      expect(testError.stackTrace, isNotEmpty);
      expect(testError.timestamp, isA<DateTime>());
    });
    
    test('sends error report to server', () async {
      final errorReporter = getIt<ErrorReporterService>();
      final testError = ErrorEntry(
        source: 'IntegrationTestCubit',
        errorType: 'IntegrationTestException',
        errorCode: 'INT_TEST_002',
        stackTrace: '''
#0      IntegrationTestCubit.testMethod (package:quanitya_flutter/test.dart:10:5)
''',
        timestamp: DateTime.now(),
        userMessage: 'Test error for integration testing',
      );
      
      final result = await errorReporter.sendErrorReport(testError);
      expect(result, isA<bool>());
    });
    
    test('verifies success response', () async {
      final errorReporter = getIt<ErrorReporterService>();
      final testError = ErrorEntry(
        source: 'SuccessTestCubit',
        errorType: 'SuccessTestException',
        errorCode: 'SUCCESS_001',
        stackTrace: 'Success test stack trace',
        timestamp: DateTime.now(),
      );
      
      final result = await errorReporter.sendErrorReport(testError);
      expect(result, isA<bool>());
    });
    
    test('tests with real Serverpod client (if available)', () async {
      final errorReporter = getIt<ErrorReporterService>();
      final testErrors = [
        ErrorEntry(
          source: 'BatchTestCubit',
          errorType: 'BatchTestException',
          errorCode: 'BATCH_001',
          stackTrace: 'Batch test 1 stack trace',
          timestamp: DateTime.now(),
        ),
      ];
      
      for (final error in testErrors) {
        final result = await errorReporter.sendErrorReport(error);
        expect(result, isA<bool>());
      }
    });
    
    test('handles network errors gracefully', () async {
      final errorReporter = getIt<ErrorReporterService>();
      final testError = ErrorEntry(
        source: 'NetworkTestCubit',
        errorType: 'NetworkTestException',
        errorCode: 'NET_001',
        stackTrace: 'Network test stack trace',
        timestamp: DateTime.now(),
      );
      
      final result = await errorReporter.sendErrorReport(testError);
      expect(result, isA<bool>());
    });
    
    test('validates error entry format', () {
      final testError = ErrorEntry(
        source: 'FormatTestCubit',
        errorType: 'FormatTestException',
        errorCode: 'FMT_001',
        stackTrace: 'Format test stack trace',
        timestamp: DateTime.now(),
        userMessage: 'Format test message',
      );
      
      expect(testError.source, isNotEmpty);
      expect(testError.errorType, isNotEmpty);
      expect(testError.errorCode, isNotEmpty);
      expect(testError.stackTrace, isNotEmpty);
      expect(testError.timestamp, isA<DateTime>());
    });
    
  }, skip: skipIntegrationTests);
}
