import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:flutter_error_privserver/flutter_error_privserver.dart';

import 'package:quanitya_flutter/infrastructure/error_reporting/error_reporter_service.dart';
import 'package:quanitya_flutter/infrastructure/public_submission/public_submission_service.dart';
import 'package:quanitya_cloud_client/quanitya_cloud_client.dart';

@GenerateMocks([Client, PublicSubmissionService])
import 'error_reporter_service_test.mocks.dart';

void main() {
  group('ErrorReporterService', () {
    late ErrorReporterService service;
    late MockClient mockClient;
    late MockPublicSubmissionService mockSubmissionService;

    setUp(() {
      mockClient = MockClient();
      mockSubmissionService = MockPublicSubmissionService();

      service = ErrorReporterService(mockClient, mockSubmissionService);
    });

    test('sendErrorReport succeeds with valid error entry', () async {
      // Arrange
      final errorEntry = ErrorEntry(
        source: 'TestCubit',
        errorType: 'TestException',
        errorCode: 'TEST_001',
        stackTrace: 'Test stack trace',
        timestamp: DateTime.now(),
        userMessage: 'Test error message',
      );

      when(mockSubmissionService.submitWithVerification(
        endpoint: anyNamed('endpoint'),
        payload: anyNamed('payload'),
        submitCallback: anyNamed('submitCallback'),
      )).thenAnswer((_) async {});

      // Act
      final result = await service.sendErrorReport(errorEntry);

      // Assert
      expect(result, true);

      verify(mockSubmissionService.submitWithVerification(
        endpoint: 'errorReport',
        payload: anyNamed('payload'),
        submitCallback: anyNamed('submitCallback'),
      )).called(1);
    });

    test('returns false on failure (exception caught)', () async {
      // Arrange
      final errorEntry = ErrorEntry(
        source: 'FailCubit',
        errorType: 'FailException',
        errorCode: 'FAIL_001',
        stackTrace: 'Fail stack trace',
        timestamp: DateTime.now(),
      );

      when(mockSubmissionService.submitWithVerification(
        endpoint: anyNamed('endpoint'),
        payload: anyNamed('payload'),
        submitCallback: anyNamed('submitCallback'),
      )).thenThrow(Exception('Server error'));

      // Act
      final result = await service.sendErrorReport(errorEntry);

      // Assert
      expect(result, false);

      verify(mockSubmissionService.submitWithVerification(
        endpoint: 'errorReport',
        payload: anyNamed('payload'),
        submitCallback: anyNamed('submitCallback'),
      )).called(1);
    });

    test('handles network errors gracefully', () async {
      // Arrange
      final errorEntry = ErrorEntry(
        source: 'NetworkCubit',
        errorType: 'NetworkException',
        errorCode: 'NET_001',
        stackTrace: 'Network stack trace',
        timestamp: DateTime.now(),
      );

      when(mockSubmissionService.submitWithVerification(
        endpoint: anyNamed('endpoint'),
        payload: anyNamed('payload'),
        submitCallback: anyNamed('submitCallback'),
      )).thenThrow(Exception('Network error'));

      // Act
      final result = await service.sendErrorReport(errorEntry);

      // Assert
      expect(result, false);

      verify(mockSubmissionService.submitWithVerification(
        endpoint: 'errorReport',
        payload: anyNamed('payload'),
        submitCallback: anyNamed('submitCallback'),
      )).called(1);
    });

    test('integrates with PublicSubmissionService correctly', () async {
      // Arrange
      final timestamp = DateTime.now();
      final errorEntry = ErrorEntry(
        source: 'IntegrationCubit',
        errorType: 'IntegrationException',
        errorCode: 'INT_001',
        stackTrace: 'Integration stack trace',
        timestamp: timestamp,
        userMessage: 'Integration test message',
      );

      // Capture the payload to verify format
      String? capturedPayload;
      when(mockSubmissionService.submitWithVerification(
        endpoint: anyNamed('endpoint'),
        payload: anyNamed('payload'),
        submitCallback: anyNamed('submitCallback'),
      )).thenAnswer((invocation) async {
        capturedPayload = invocation.namedArguments[const Symbol('payload')] as String;
      });

      // Act
      final result = await service.sendErrorReport(errorEntry);

      // Assert
      expect(result, true);
      expect(capturedPayload, isNotNull);
      // Payload is the signing payload: 'errorReports:N' (report data sent separately as reportsJson)
      expect(capturedPayload, equals('errorReports:1'));

      verify(mockSubmissionService.submitWithVerification(
        endpoint: 'errorReport',
        payload: anyNamed('payload'),
        submitCallback: anyNamed('submitCallback'),
      )).called(1);
    });

    test('builds correct payload format', () async {
      // Arrange
      final timestamp = DateTime(2024, 1, 15, 10, 30, 0);
      final errorEntry = ErrorEntry(
        source: 'PayloadCubit',
        errorType: 'PayloadException',
        errorCode: 'PAY_001',
        stackTrace: 'Payload stack trace',
        timestamp: timestamp,
      );

      String? capturedPayload;
      when(mockSubmissionService.submitWithVerification(
        endpoint: anyNamed('endpoint'),
        payload: anyNamed('payload'),
        submitCallback: anyNamed('submitCallback'),
      )).thenAnswer((invocation) async {
        capturedPayload = invocation.namedArguments[const Symbol('payload')] as String;
      });

      // Act
      await service.sendErrorReport(errorEntry);

      // Assert
      expect(capturedPayload, isNotNull);

      // Payload is the signing payload: 'errorReports:N' (report data sent separately as reportsJson)
      expect(capturedPayload, equals('errorReports:1'));
    });

    test('handles error entry with null userMessage', () async {
      // Arrange
      final errorEntry = ErrorEntry(
        source: 'NullMessageCubit',
        errorType: 'NullMessageException',
        errorCode: 'NULL_001',
        stackTrace: 'Null message stack trace',
        timestamp: DateTime.now(),
        userMessage: null, // Null user message
      );

      when(mockSubmissionService.submitWithVerification(
        endpoint: anyNamed('endpoint'),
        payload: anyNamed('payload'),
        submitCallback: anyNamed('submitCallback'),
      )).thenAnswer((_) async {});

      // Act
      final result = await service.sendErrorReport(errorEntry);

      // Assert
      expect(result, true);
    });

    test('handles multiple error reports sequentially', () async {
      // Arrange
      final errors = List.generate(3, (i) => ErrorEntry(
        source: 'MultiCubit',
        errorType: 'MultiException',
        errorCode: 'MULTI_00$i',
        stackTrace: 'Multi stack trace $i',
        timestamp: DateTime.now(),
      ));

      when(mockSubmissionService.submitWithVerification(
        endpoint: anyNamed('endpoint'),
        payload: anyNamed('payload'),
        submitCallback: anyNamed('submitCallback'),
      )).thenAnswer((_) async {});

      // Act
      final results = <bool>[];
      for (final error in errors) {
        results.add(await service.sendErrorReport(error));
      }

      // Assert
      expect(results, [true, true, true]);

      verify(mockSubmissionService.submitWithVerification(
        endpoint: 'errorReport',
        payload: anyNamed('payload'),
        submitCallback: anyNamed('submitCallback'),
      )).called(3);
    });

    test('never throws even on unexpected errors', () async {
      // Arrange
      final errorEntry = ErrorEntry(
        source: 'UnexpectedCubit',
        errorType: 'UnexpectedException',
        errorCode: 'UNEXP_001',
        stackTrace: 'Unexpected stack trace',
        timestamp: DateTime.now(),
      );

      when(mockSubmissionService.submitWithVerification(
        endpoint: anyNamed('endpoint'),
        payload: anyNamed('payload'),
        submitCallback: anyNamed('submitCallback'),
      )).thenThrow(StateError('Unexpected state error'));

      // Act
      final result = await service.sendErrorReport(errorEntry);

      // Assert
      expect(result, false);
    });
  });
}
