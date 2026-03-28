import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:quanitya_flutter/logic/import/models/import_item.dart';
import 'package:quanitya_flutter/logic/import/services/import_executor.dart';
import 'package:quanitya_flutter/logic/ingestion/adapters/json_data_source_adapter.dart';
import 'package:quanitya_flutter/logic/ingestion/services/data_ingestion_service.dart';
import 'package:quanitya_flutter/logic/llm/models/gbnf_field.dart';
import 'package:quanitya_flutter/logic/ocr/models/extraction_field.dart';
import 'package:quanitya_flutter/logic/templates/enums/field_enum.dart';
import 'package:quanitya_flutter/logic/templates/models/shared/template_field.dart';
import 'package:quanitya_flutter/logic/templates/models/shared/tracker_template.dart';

@GenerateMocks([DataIngestionService])
import 'import_executor_test.mocks.dart';

void main() {
  late MockDataIngestionService mockIngestion;
  late ImportExecutor executor;
  late TrackerTemplateModel template;
  late List<ExtractionField> fields;

  setUp(() {
    mockIngestion = MockDataIngestionService();
    executor = ImportExecutor(mockIngestion);

    template = TrackerTemplateModel(
      id: 'template-1',
      name: 'Test',
      fields: [
        TemplateField(id: 'f-name', label: 'Name', type: FieldEnum.text),
        TemplateField(id: 'f-price', label: 'Price', type: FieldEnum.float),
      ],
      updatedAt: DateTime(2026, 3, 26),
    );

    fields = [
      ExtractionField(fieldId: 'f-name', label: 'Name', type: GbnfFieldType.string),
      ExtractionField(fieldId: 'f-price', label: 'Price', type: GbnfFieldType.number),
    ];
  });

  group('ImportExecutor', () {
    test('passes items with _occurredAt to DataIngestionService', () async {
      final items = [
        ImportItem(
          data: {'f-name': 'Coffee', 'f-price': 4.5},
          occurredAt: DateTime(2026, 3, 15),
        ),
        ImportItem(
          data: {'f-name': 'Bagel', 'f-price': 3.25},
          occurredAt: DateTime(2026, 3, 16),
        ),
      ];

      when(mockIngestion.syncJson(
        adapter: anyNamed('adapter'),
        templateId: anyNamed('templateId'),
        sourceData: anyNamed('sourceData'),
      )).thenAnswer((_) async => 2);

      final count = await executor.execute(
        templateId: 'template-1',
        template: template,
        items: items,
        extractionFields: fields,
      );

      expect(count, 2);

      final captured = verify(mockIngestion.syncJson(
        adapter: captureAnyNamed('adapter'),
        templateId: captureAnyNamed('templateId'),
        sourceData: captureAnyNamed('sourceData'),
      )).captured;

      final sourceData = captured[2] as List<Map<String, dynamic>>;
      expect(sourceData, hasLength(2));
      expect(sourceData[0]['_occurredAt'], DateTime(2026, 3, 15).toIso8601String());
      expect(sourceData[1]['_occurredAt'], DateTime(2026, 3, 16).toIso8601String());
      expect(sourceData[0]['f-name'], 'Coffee');
    });

    test('returns 0 for empty items', () async {
      final count = await executor.execute(
        templateId: 'template-1',
        template: template,
        items: [],
        extractionFields: fields,
      );

      expect(count, 0);
      verifyNever(mockIngestion.syncJson(
        adapter: anyNamed('adapter'),
        templateId: anyNamed('templateId'),
        sourceData: anyNamed('sourceData'),
      ));
    });

  });
}
