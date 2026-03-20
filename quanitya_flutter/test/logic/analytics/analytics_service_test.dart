import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:quanitya_cloud_client/quanitya_cloud_client.dart';
import 'package:quanitya_flutter/logic/analytics/analytics_service.dart';
import 'package:quanitya_flutter/data/repositories/analytics_inbox_repository.dart';
import 'package:quanitya_flutter/infrastructure/public_submission/public_submission_service.dart';

class _MockClient extends Mock implements Client {}

class _MockEndpointAnalyticsEvent extends Mock
    implements EndpointAnalyticsEvent {}

class _MockAnalyticsInboxRepository extends Mock
    implements AnalyticsInboxRepository {}

class _MockPublicSubmissionService extends Mock
    implements PublicSubmissionService {}

void main() {
  group('AnalyticsService', () {
    late AnalyticsService service;
    late _MockClient mockClient;
    late _MockEndpointAnalyticsEvent mockEndpoint;
    late _MockAnalyticsInboxRepository mockInbox;
    late _MockPublicSubmissionService mockSubmission;

    setUp(() {
      mockClient = _MockClient();
      mockEndpoint = _MockEndpointAnalyticsEvent();
      mockInbox = _MockAnalyticsInboxRepository();
      mockSubmission = _MockPublicSubmissionService();
      when(() => mockClient.analyticsEvent).thenReturn(mockEndpoint);
      when(() => mockInbox.saveEvent(
            eventName: any(named: 'eventName'),
            clientTimestamp: any(named: 'clientTimestamp'),
            platform: any(named: 'platform'),
            props: any(named: 'props'),
          )).thenAnswer((_) async {});

      service = AnalyticsService(mockClient, mockInbox, mockSubmission);
    });

    test('all typed methods save to inbox without throwing', () {
      service.trackTemplateCreated();
      service.trackTemplateDeleted();
      service.trackEntryLogged();
      service.trackTemplateExported();
      service.trackTemplateImported();
      service.trackAnalysisRun();
      service.trackScheduleCreated();
      service.trackHealthSynced();
      service.trackDataExported();
      service.trackAppOpened();
      service.trackPurchaseCompleted(productId: 'test_product');

      verify(() => mockInbox.saveEvent(
            eventName: any(named: 'eventName'),
            clientTimestamp: any(named: 'clientTimestamp'),
            platform: any(named: 'platform'),
            props: any(named: 'props'),
          )).called(11);
    });

    test('silently handles inbox failure', () {
      when(() => mockInbox.saveEvent(
            eventName: any(named: 'eventName'),
            clientTimestamp: any(named: 'clientTimestamp'),
            platform: any(named: 'platform'),
            props: any(named: 'props'),
          )).thenAnswer((_) async => throw Exception('DB error'));

      // Should not throw
      service.trackAppOpened();
    });
  });
}
