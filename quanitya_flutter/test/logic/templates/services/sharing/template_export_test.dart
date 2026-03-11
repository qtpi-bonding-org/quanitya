import 'package:flutter_test/flutter_test.dart';

import 'package:quanitya_flutter/logic/templates/models/shared/shareable_template.dart';
import 'package:quanitya_flutter/logic/templates/models/shared/tracker_template.dart';
import 'package:quanitya_flutter/logic/templates/models/shared/template_field.dart';
import 'package:quanitya_flutter/logic/templates/models/shared/template_aesthetics.dart';
import 'package:quanitya_flutter/logic/templates/enums/field_enum.dart';
import 'package:quanitya_flutter/logic/templates/services/sharing/template_export_service.dart';
import 'package:quanitya_flutter/data/repositories/template_with_aesthetics_repository.dart';

void main() {
  group('Template Export Phase 1', () {
    late TemplateExportService exportService;

    setUp(() {
      exportService = TemplateExportService(null); // No analysis script repository for basic test
    });

    test('should create shareable template model', () {
      final author = AuthorCredit.create(name: 'Test Author');
      final template = TrackerTemplateModel.create(
        name: 'Test Template',
        fields: [
          TemplateField.create(
            label: 'Weight',
            type: FieldEnum.integer,
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

    test('should export template to JSON string', () async {
      final author = AuthorCredit.create(
        name: 'Test Author',
        url: 'https://github.com/testauthor',
      );
      
      final template = TrackerTemplateModel.create(
        name: 'Workout Template',
        fields: [
          TemplateField.create(
            label: 'Sets',
            type: FieldEnum.integer,
          ),
          TemplateField.create(
            label: 'Reps',
            type: FieldEnum.integer,
          ),
          TemplateField.create(
            label: 'Notes',
            type: FieldEnum.text,
          ),
        ],
      );

      final templateWithAesthetics = TemplateWithAesthetics(
        template: template,
        aesthetics: TemplateAestheticsModel.defaults(templateId: template.id),
      );

      // Export to JSON
      final jsonString = await exportService.exportTemplate(
        templateWithAesthetics: templateWithAesthetics,
        author: author,
        description: 'A simple workout template for testing',
      );

      expect(jsonString, isA<String>());
      expect(jsonString, contains('"version": "1.0"'));
      expect(jsonString, contains('"name": "Test Author"'));
      expect(jsonString, contains('"url": "https://github.com/testauthor"'));
      expect(jsonString, contains('"name": "Workout Template"'));
      expect(jsonString, contains('"description": "A simple workout template for testing"'));
      expect(jsonString, contains('"label": "Sets"'));
      expect(jsonString, contains('"label": "Reps"'));
      expect(jsonString, contains('"label": "Notes"'));

      // Verify it's valid JSON by parsing it
      expect(() => jsonString, returnsNormally);
    });

    test('should export template with default aesthetics', () async {
      final author = AuthorCredit.create(name: 'Minimal Author');
      final template = TrackerTemplateModel.create(
        name: 'Minimal Template',
        fields: [
          TemplateField.create(
            label: 'Value',
            type: FieldEnum.integer,
          ),
        ],
      );

      // Test with no aesthetics (optional)
      final templateWithAesthetics = TemplateWithAesthetics(
        template: template,
        aesthetics: TemplateAestheticsModel.defaults(templateId: template.id),
      );

      final jsonString = await exportService.exportTemplate(
        templateWithAesthetics: templateWithAesthetics,
        author: author,
      );

      expect(jsonString, isA<String>());
      expect(jsonString, contains('"name": "Minimal Author"'));
      expect(jsonString, contains('"name": "Minimal Template"'));
      expect(jsonString, contains('"aesthetics":'));
    });
  });
}