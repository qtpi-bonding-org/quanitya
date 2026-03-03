import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:quanitya_cloud_client/quanitya_cloud_client.dart';
import 'package:quanitya_flutter/logic/analytics/analytics_service.dart';

class _MockClient extends Mock implements Client {}

class _MockEndpointAnalyticsEvent extends Mock
    implements EndpointAnalyticsEvent {}

void main() {
  group('AnalyticsService', () {
    late AnalyticsService service;
    late _MockClient mockClient;
    late _MockEndpointAnalyticsEvent mockEndpoint;

    setUp(() {
      mockClient = _MockClient();
      mockEndpoint = _MockEndpointAnalyticsEvent();
      when(() => mockClient.analyticsEvent).thenReturn(mockEndpoint);
      when(() => mockEndpoint.submitEvent(
            eventName: any(named: 'eventName'),
            clientTimestamp: any(named: 'clientTimestamp'),
            platform: any(named: 'platform'),
            props: any(named: 'props'),
          )).thenAnswer((_) async {});

      service = AnalyticsService(mockClient);
    });

    test('all typed methods call endpoint without throwing', () {
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

      verify(() => mockEndpoint.submitEvent(
            eventName: any(named: 'eventName'),
            clientTimestamp: any(named: 'clientTimestamp'),
            platform: any(named: 'platform'),
            props: any(named: 'props'),
          )).called(11);
    });

    test('trackPurchaseCompleted sends product_id in props', () {
      service.trackPurchaseCompleted(productId: 'premium_monthly');

      verify(() => mockEndpoint.submitEvent(
            eventName: 'purchase_completed',
            clientTimestamp: any(named: 'clientTimestamp'),
            platform: any(named: 'platform'),
            props: any(
              named: 'props',
              that: contains('premium_monthly'),
            ),
          )).called(1);
    });

    test('silently handles endpoint failure', () {
      when(() => mockEndpoint.submitEvent(
            eventName: any(named: 'eventName'),
            clientTimestamp: any(named: 'clientTimestamp'),
            platform: any(named: 'platform'),
            props: any(named: 'props'),
          )).thenThrow(Exception('Server unreachable'));

      // Should not throw
      service.trackAppOpened();
    });
  });
}
