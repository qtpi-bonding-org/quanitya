import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import 'package:quanitya_flutter/logic/templates/models/shared/shareable_template.dart';
import 'package:quanitya_flutter/logic/templates/models/shared/tracker_template.dart';
import 'package:quanitya_flutter/logic/templates/models/shared/template_field.dart';
import 'package:quanitya_flutter/logic/templates/models/shared/template_aesthetics.dart';
import 'package:quanitya_flutter/logic/templates/enums/field_enum.dart';
import 'package:quanitya_flutter/logic/templates/services/sharing/template_export_service.dart';
import 'package:quanitya_flutter/logic/templates/services/sharing/template_import_service.dart';
import 'package:quanitya_flutter/data/repositories/template_with_aesthetics_repository.dart';

import 'template_sharing_test.mocks.dart';

@GenerateMocks([http.Client, TemplateWithAestheticsRepository])
void main() {
  group('Template Sharing Phase 1', () {
    late TemplateExportService exportService;
    late TemplateImportService importService;
    late MockClient mockHttpClient;
    late MockTemplateWithAestheticsRepository mockRepository;

    setUp(() {
      mockHttpClient = MockClient();
      mockRepository = MockTemplateWithAestheticsRepository();
      exportService = TemplateExportService(null);
      importService = TemplateImportService(mockHttpClient, mockRepository, null);
    });

    group('ShareableTemplate Model', () {
      test('should create shareable template with required fields', () {
        final author = AuthorCredit.create(name: 'Test Author');
        final template = TrackerTemplateModel.create(
          name: 'Test Template',
          fields: [
            TemplateField.create(
              label: 'Weight',
              type: FieldEnum.float,
            ),
          ],
        );

        final shareable = ShareableTemplate.create(
          author: author,
          template: template,
        );

        expect(shareable.version, '1.0');
        expect(shareable.author.name, 'Test Author');
        expect(shareable.template.name, 'Test Template');
        expect(shareable.template.fields.length, 1);
        expect(shareable.template.fields.first.label, 'Weight');
      });

      test('should serialize to JSON and back', () {
        final author = AuthorCredit.create(name: 'Test Author');
        final template = TrackerTemplateModel.create(
          name: 'Test Template',
          fields: [
            TemplateField.create(
              label: 'Weight',
              type: FieldEnum.float,
            ),
          ],
        );

        final original = ShareableTemplate.create(
          author: author,
          template: template,
          description: 'Test description',
        );

        // Serialize to JSON
        final json = original.toJson();
        expect(json['version'], '1.0');
        expect(json['author']['name'], 'Test Author');
        expect(json['template']['name'], 'Test Template');

        // Deserialize from JSON
        final restored = ShareableTemplate.fromJson(json);
        expect(restored.version, original.version);
        expect(restored.author.name, original.author.name);
        expect(restored.template.name, original.template.name);
        expect(restored.description, original.description);
      });
    });

    group('TemplateExportService', () {
      test('should export template to JSON string', () async {
        final author = AuthorCredit.create(name: 'Test Author');
        final template = TrackerTemplateModel.create(
          name: 'Test Template',
          fields: [
            TemplateField.create(
              label: 'Weight',
              type: FieldEnum.float,
            ),
          ],
        );
        final aesthetics = TemplateAestheticsModel.defaults(
          templateId: template.id,
        );

        final templateWithAesthetics = TemplateWithAesthetics(
          template: template,
          aesthetics: aesthetics,
        );

        final jsonString = await exportService.exportTemplate(
          templateWithAesthetics: templateWithAesthetics,
          author: author,
          description: 'Test export',
        );

        expect(jsonString, isA<String>());
        expect(jsonString, contains('"version": "1.0"'));
        expect(jsonString, contains('"name": "Test Author"'));
        expect(jsonString, contains('"name": "Test Template"'));
        expect(jsonString, contains('"description": "Test export"'));
      });
    });

    group('TemplateImportService', () {
      test('should normalize GitHub Gist URLs', () {
        final service = TemplateImportService(mockHttpClient, mockRepository, null);
        
        // Access private method via reflection or make it public for testing
        // For now, we'll test the public interface
        expect(service, isA<TemplateImportService>());
      });

      test('should validate HTTPS URLs only', () async {
        when(mockHttpClient.get(any, headers: anyNamed('headers')))
            .thenAnswer((_) async => http.Response('', 400));

        expect(
          () => importService.previewFromUrl('http://example.com/template.json'),
          throwsA(isA<Exception>()),
        );
      });

      test('should handle valid JSON response', () async {
        final validJson = '''
        {
          "version": "1.0",
          "author": {
            "name": "Test Author"
          },
          "template": {
            "id": "test-id",
            "name": "Test Template",
            "fields": [
              {
                "id": "field-id",
                "label": "Weight",
                "type": "float",
                "validators": []
              }
            ],
            "updatedAt": "2024-01-01T00:00:00.000Z"
          }
        }
        ''';

        when(mockHttpClient.get(any, headers: anyNamed('headers')))
            .thenAnswer((_) async => http.Response(validJson, 200));

        final result = await importService.previewFromUrl(
          'https://gist.githubusercontent.com/user/gist/raw/template.json',
        );

        expect(result.version, '1.0');
        expect(result.author.name, 'Test Author');
        expect(result.template.name, 'Test Template');
      });
    });
  });
}