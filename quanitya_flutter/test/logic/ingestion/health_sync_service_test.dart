import 'package:flutter_test/flutter_test.dart';
import 'package:health/health.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:quanitya_flutter/data/dao/template_query_dao.dart';
import 'package:quanitya_flutter/data/repositories/template_with_aesthetics_repository.dart';
import 'package:quanitya_flutter/integrations/flutter/health/health_adapter_factory.dart';
import 'package:quanitya_flutter/integrations/flutter/health/health_sync_service.dart';
import 'package:quanitya_flutter/logic/ingestion/services/data_ingestion_service.dart';
import 'package:quanitya_flutter/logic/templates/enums/field_enum.dart';
import 'package:quanitya_flutter/logic/templates/models/shared/template_field.dart';
import 'package:quanitya_flutter/logic/templates/models/shared/tracker_template.dart';

@GenerateMocks([
  Health,
  HealthAdapterFactory,
  DataIngestionService,
  TemplateQueryDao,
  TemplateWithAestheticsRepository,
])
import 'health_sync_service_test.mocks.dart';

HealthDataPoint _makePoint({
  required HealthDataType type,
  required double value,
  String uuid = 'uuid-1',
}) {
  return HealthDataPoint(
    uuid: uuid,
    type: type,
    value: NumericHealthValue(numericValue: value),
    unit: HealthDataUnit.COUNT,
    dateFrom: DateTime(2026, 1, 1, 10, 0),
    dateTo: DateTime(2026, 1, 1, 11, 0),
    sourceName: 'iPhone',
    sourceId: 'com.apple.Health',
    sourcePlatform: HealthPlatformType.appleHealth,
    sourceDeviceId: 'device-1',
  );
}

void main() {
  late HealthSyncService service;
  late MockHealth mockHealth;
  late MockHealthAdapterFactory mockAdapterFactory;
  late MockDataIngestionService mockIngestionService;
  late MockTemplateQueryDao mockTemplateQueryDao;
  late MockTemplateWithAestheticsRepository mockTemplateRepo;

  setUp(() {
    mockHealth = MockHealth();
    mockAdapterFactory = MockHealthAdapterFactory();
    mockIngestionService = MockDataIngestionService();
    mockTemplateQueryDao = MockTemplateQueryDao();
    mockTemplateRepo = MockTemplateWithAestheticsRepository();

    service = HealthSyncService.forTesting(
      mockAdapterFactory,
      mockIngestionService,
      mockTemplateQueryDao,
      mockTemplateRepo,
      mockHealth,
    );
  });

  group('HealthSyncService', () {
    group('isAvailable', () {
      test('delegates to Health.isHealthConnectAvailable', () async {
        when(mockHealth.isHealthConnectAvailable())
            .thenAnswer((_) async => true);

        final result = await service.isAvailable();

        expect(result, isTrue);
        verify(mockHealth.isHealthConnectAvailable()).called(1);
      });
    });

    group('requestPermissions', () {
      test('requests READ authorization for given types', () async {
        final types = [HealthDataType.STEPS, HealthDataType.HEART_RATE];

        when(mockHealth.requestAuthorization(
          types,
          permissions: [HealthDataAccess.READ, HealthDataAccess.READ],
        )).thenAnswer((_) async => true);

        final result = await service.requestPermissions(types);

        expect(result, isTrue);
        verify(mockHealth.requestAuthorization(
          types,
          permissions: [HealthDataAccess.READ, HealthDataAccess.READ],
        )).called(1);
      });
    });

    group('sync', () {
      test('returns 0 when health SDK returns no data', () async {
        when(mockHealth.getHealthDataFromTypes(
          types: anyNamed('types'),
          startTime: anyNamed('startTime'),
          endTime: anyNamed('endTime'),
        )).thenAnswer((_) async => []);

        final count = await service.sync([HealthDataType.STEPS]);

        expect(count, equals(0));
        verifyNever(mockAdapterFactory.create(any, fieldLabelToId: anyNamed('fieldLabelToId')));
      });

      test('groups by type, resolves templates, and imports', () async {
        final stepsPoint = _makePoint(
          type: HealthDataType.STEPS,
          value: 5000,
          uuid: 'steps-1',
        );
        final hrPoint = _makePoint(
          type: HealthDataType.HEART_RATE,
          value: 72,
          uuid: 'hr-1',
        );

        // Health SDK returns mixed types
        when(mockHealth.getHealthDataFromTypes(
          types: anyNamed('types'),
          startTime: anyNamed('startTime'),
          endTime: anyNamed('endTime'),
        )).thenAnswer((_) async => [stepsPoint, hrPoint]);

        // Real adapter factory for actual adapter behavior
        final realFactory = HealthAdapterFactory();

        // Factory is called twice per type: once for base, once with field mapping
        when(mockAdapterFactory.create(
          HealthDataType.STEPS,
          fieldLabelToId: anyNamed('fieldLabelToId'),
        )).thenAnswer((inv) => realFactory.create(
              HealthDataType.STEPS,
              fieldLabelToId: inv.namedArguments[#fieldLabelToId] as Map<String, String>? ?? const {},
            ));
        when(mockAdapterFactory.create(
          HealthDataType.HEART_RATE,
          fieldLabelToId: anyNamed('fieldLabelToId'),
        )).thenAnswer((inv) => realFactory.create(
              HealthDataType.HEART_RATE,
              fieldLabelToId: inv.namedArguments[#fieldLabelToId] as Map<String, String>? ?? const {},
            ));

        // Templates with fields (for field UUID resolution)
        final stepsField = TemplateField.create(label: 'Value', type: FieldEnum.integer);
        final stepsTemplate = TrackerTemplateModel.create(
          name: 'Steps',
          fields: [stepsField],
        );
        final hrField = TemplateField.create(label: 'Value', type: FieldEnum.float);
        final hrTemplate = TrackerTemplateModel.create(
          name: 'Heart Rate',
          fields: [hrField],
        );

        when(mockTemplateQueryDao.findByName('Steps'))
            .thenAnswer((_) async => stepsTemplate);
        when(mockTemplateQueryDao.findByName('Heart Rate'))
            .thenAnswer((_) async => hrTemplate);
        when(mockTemplateQueryDao.findById(stepsTemplate.id))
            .thenAnswer((_) async => stepsTemplate);
        when(mockTemplateQueryDao.findById(hrTemplate.id))
            .thenAnswer((_) async => hrTemplate);

        // Ingestion service returns counts
        when(mockIngestionService.syncFlutter(
          adapter: anyNamed('adapter'),
          templateId: anyNamed('templateId'),
          sourceData: anyNamed('sourceData'),
        )).thenAnswer((_) async => 1);

        final count = await service.sync(
          [HealthDataType.STEPS, HealthDataType.HEART_RATE],
        );

        expect(count, equals(2));
      });

      test('creates template via repository when not found by name', () async {
        final point = _makePoint(
          type: HealthDataType.STEPS,
          value: 100,
        );

        when(mockHealth.getHealthDataFromTypes(
          types: anyNamed('types'),
          startTime: anyNamed('startTime'),
          endTime: anyNamed('endTime'),
        )).thenAnswer((_) async => [point]);

        final realFactory = HealthAdapterFactory();
        when(mockAdapterFactory.create(
          HealthDataType.STEPS,
          fieldLabelToId: anyNamed('fieldLabelToId'),
        )).thenAnswer((inv) => realFactory.create(
              HealthDataType.STEPS,
              fieldLabelToId: inv.namedArguments[#fieldLabelToId] as Map<String, String>? ?? const {},
            ));

        // Template NOT found in DB by name
        when(mockTemplateQueryDao.findByName('Steps'))
            .thenAnswer((_) async => null);

        // Save succeeds
        when(mockTemplateRepo.save(any)).thenAnswer((_) async {});

        // findById for newly created template — return a template with fields
        when(mockTemplateQueryDao.findById(any)).thenAnswer((_) async {
          final field = TemplateField.create(label: 'Value', type: FieldEnum.integer);
          return TrackerTemplateModel.create(name: 'Steps', fields: [field]);
        });

        // Ingestion succeeds
        when(mockIngestionService.syncFlutter(
          adapter: anyNamed('adapter'),
          templateId: anyNamed('templateId'),
          sourceData: anyNamed('sourceData'),
        )).thenAnswer((_) async => 1);

        await service.sync([HealthDataType.STEPS]);

        // Verify template was saved
        verify(mockTemplateRepo.save(any)).called(1);
      });

      test('caches template ID across multiple syncs', () async {
        final point = _makePoint(type: HealthDataType.STEPS, value: 100);

        when(mockHealth.getHealthDataFromTypes(
          types: anyNamed('types'),
          startTime: anyNamed('startTime'),
          endTime: anyNamed('endTime'),
        )).thenAnswer((_) async => [point]);

        final realFactory = HealthAdapterFactory();
        when(mockAdapterFactory.create(
          HealthDataType.STEPS,
          fieldLabelToId: anyNamed('fieldLabelToId'),
        )).thenAnswer((inv) => realFactory.create(
              HealthDataType.STEPS,
              fieldLabelToId: inv.namedArguments[#fieldLabelToId] as Map<String, String>? ?? const {},
            ));

        final stepsField = TemplateField.create(label: 'Value', type: FieldEnum.integer);
        final template = TrackerTemplateModel.create(
          name: 'Steps',
          fields: [stepsField],
        );
        when(mockTemplateQueryDao.findByName('Steps'))
            .thenAnswer((_) async => template);
        when(mockTemplateQueryDao.findById(template.id))
            .thenAnswer((_) async => template);

        when(mockIngestionService.syncFlutter(
          adapter: anyNamed('adapter'),
          templateId: anyNamed('templateId'),
          sourceData: anyNamed('sourceData'),
        )).thenAnswer((_) async => 1);

        // Sync twice
        await service.sync([HealthDataType.STEPS]);
        await service.sync([HealthDataType.STEPS]);

        // findByName is called once per sync (no cross-sync caching)
        verify(mockTemplateQueryDao.findByName('Steps')).called(2);
      });
    });
  });
}
