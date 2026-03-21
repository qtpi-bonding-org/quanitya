import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:quanitya_flutter/logic/templates/models/shared/shareable_template.dart';
import 'package:quanitya_flutter/logic/templates/models/shared/tracker_template.dart';
import 'package:quanitya_flutter/logic/templates/models/shared/template_field.dart';
import 'package:quanitya_flutter/logic/templates/models/shared/template_aesthetics.dart';
import 'package:quanitya_flutter/logic/templates/models/shared/field_validator.dart';
import 'package:quanitya_flutter/logic/templates/enums/field_enum.dart';
import 'package:quanitya_flutter/logic/templates/enums/ui_element_enum.dart';
import 'package:quanitya_flutter/logic/analysis/models/analysis_script.dart';
import 'package:quanitya_flutter/logic/analysis/enums/analysis_output_mode.dart';
import 'package:quanitya_flutter/logic/analysis/models/analysis_enums.dart';
import 'package:quanitya_flutter/logic/templates/services/sharing/template_export_service.dart';
import 'package:quanitya_flutter/data/repositories/template_with_aesthetics_repository.dart';

void main() {
  group('Export → Import Round Trip', () {
    late TemplateExportService exportService;

    setUp(() {
      exportService = TemplateExportService(null);
    });

    group('sanitizeForExport', () {
      test('replaces field IDs with sequential clean IDs', () {
        final template = _buildSimpleTemplate();
        final shareable = ShareableTemplate.create(
          author: AuthorCredit.create(name: 'Test'),
          template: template,
          category: 'test',
        );

        final sanitized = shareable.sanitizeForExport();

        expect(sanitized.template.id, 'template');
        expect(sanitized.template.fields[0].id, 'field-1');
        expect(sanitized.template.fields[1].id, 'field-2');
        expect(sanitized.template.fields[2].id, 'field-3');
      });

      test('replaces group sub-field IDs with nested clean IDs', () {
        final template = _buildLiftingTemplate();
        final shareable = ShareableTemplate.create(
          author: AuthorCredit.create(name: 'Test'),
          template: template,
          category: 'fitness',
        );

        final sanitized = shareable.sanitizeForExport();

        // Exercise is field-1, Sets group is field-2, Notes is field-3
        final setsField = sanitized.template.fields[1];
        expect(setsField.id, 'field-2');
        expect(setsField.subFields, isNotNull);
        expect(setsField.subFields![0].id, 'field-2-sub-1'); // Weight
        expect(setsField.subFields![1].id, 'field-2-sub-2'); // Reps
        expect(setsField.subFields![2].id, 'field-2-sub-3'); // RPE
      });

      test('remaps analysis script fieldId to clean ID', () {
        final template = _buildLiftingTemplate();
        final setsFieldId = template.fields[1].id; // the group field

        final script = AnalysisScriptModel(
          id: 'original-script-id',
          name: 'Volume Over Time',
          fieldId: setsFieldId,
          outputMode: AnalysisOutputMode.matrix,
          snippetLanguage: AnalysisSnippetLanguage.js,
          snippet: 'return [{label: "Volume", values: data.values.map(s => s.Weight * s.Reps)}];',
          updatedAt: DateTime.now(),
        );

        final shareable = ShareableTemplate.create(
          author: AuthorCredit.create(name: 'Test'),
          template: template,
          category: 'fitness',
          analysisScripts: [script],
        );

        final sanitized = shareable.sanitizeForExport();

        expect(sanitized.analysisScripts, isNotNull);
        expect(sanitized.analysisScripts!.length, 1);
        expect(sanitized.analysisScripts![0].id, 'script-1');
        expect(sanitized.analysisScripts![0].fieldId, 'field-2'); // remapped
      });

      test('remaps aesthetics IDs', () {
        final template = _buildSimpleTemplate();
        final aesthetics = TemplateAestheticsModel.defaults(
          templateId: template.id,
        );

        final shareable = ShareableTemplate.create(
          author: AuthorCredit.create(name: 'Test'),
          template: template,
          category: 'test',
          aesthetics: aesthetics,
        );

        final sanitized = shareable.sanitizeForExport();

        expect(sanitized.aesthetics, isNotNull);
        expect(sanitized.aesthetics!.id, 'aesthetics');
        expect(sanitized.aesthetics!.templateId, 'template');
      });

      test('preserves all non-ID data through sanitization', () {
        final template = _buildSimpleTemplate();
        final shareable = ShareableTemplate.create(
          author: AuthorCredit.create(name: 'Author', url: 'https://example.com'),
          template: template,
          category: 'health',
          description: 'A test template',
          tags: ['tag1', 'tag2'],
        );

        final sanitized = shareable.sanitizeForExport();

        expect(sanitized.version, '1.0');
        expect(sanitized.author.name, 'Author');
        expect(sanitized.author.url, 'https://example.com');
        expect(sanitized.template.name, 'Simple');
        expect(sanitized.template.fields[0].label, 'Mood');
        expect(sanitized.template.fields[0].type, FieldEnum.integer);
        expect(sanitized.description, 'A test template');
        expect(sanitized.category, 'health');
        expect(sanitized.tags, ['tag1', 'tag2']);
      });
    });

    group('Full export → JSON → import round trip', () {
      test('simple template survives export → parse → round trip', () async {
        final template = _buildSimpleTemplate();
        final templateWithAesthetics = TemplateWithAesthetics(
          template: template,
          aesthetics: TemplateAestheticsModel.defaults(templateId: template.id),
        );

        // Export to JSON string
        final jsonString = await exportService.exportTemplate(
          templateWithAesthetics: templateWithAesthetics,
          author: AuthorCredit.create(name: 'Exporter'),
          description: 'Exported template',
        );

        // Parse JSON back
        final jsonMap = jsonDecode(jsonString) as Map<String, dynamic>;
        final imported = ShareableTemplate.fromJson(jsonMap);

        // Verify clean IDs
        expect(imported.template.id, 'template');
        expect(imported.template.fields[0].id, 'field-1');

        // Verify data preserved
        expect(imported.template.name, 'Simple');
        expect(imported.template.fields.length, 3);
        expect(imported.template.fields[0].label, 'Mood');
        expect(imported.author.name, 'Exporter');
        expect(imported.description, 'Exported template');
        expect(imported.category, 'uncategorized');
      });

      test('group field template survives export → parse', () async {
        final template = _buildLiftingTemplate();
        final templateWithAesthetics = TemplateWithAesthetics(
          template: template,
          aesthetics: TemplateAestheticsModel.defaults(templateId: template.id),
        );

        final jsonString = await exportService.exportTemplate(
          templateWithAesthetics: templateWithAesthetics,
          author: AuthorCredit.create(name: 'Lifter'),
        );

        final jsonMap = jsonDecode(jsonString) as Map<String, dynamic>;
        final imported = ShareableTemplate.fromJson(jsonMap);

        // Find the group field
        final setsField = imported.template.fields
            .firstWhere((f) => f.label == 'Sets');
        expect(setsField.type, FieldEnum.group);
        expect(setsField.isList, isTrue);
        expect(setsField.subFields, isNotNull);
        expect(setsField.subFields!.length, 3);
        expect(setsField.subFields![0].label, 'Weight');
        expect(setsField.subFields![1].label, 'Reps');
        expect(setsField.subFields![2].label, 'RPE');

        // Verify clean IDs
        expect(setsField.id, 'field-2');
        expect(setsField.subFields![0].id, 'field-2-sub-1');
      });

      test('multiEnum field survives export → parse', () async {
        final template = _buildEmotionTemplate();
        final templateWithAesthetics = TemplateWithAesthetics(
          template: template,
          aesthetics: TemplateAestheticsModel.defaults(templateId: template.id),
        );

        final jsonString = await exportService.exportTemplate(
          templateWithAesthetics: templateWithAesthetics,
          author: AuthorCredit.create(name: 'Feeler'),
        );

        final jsonMap = jsonDecode(jsonString) as Map<String, dynamic>;
        final imported = ShareableTemplate.fromJson(jsonMap);

        final emotionField = imported.template.fields.first;
        expect(emotionField.type, FieldEnum.multiEnum);
        expect(emotionField.uiElement, UiElementEnum.chips);
        expect(emotionField.options, contains('Happy'));
        expect(emotionField.options, contains('Sad'));
        expect(emotionField.options!.length, 4);
      });

      test('analysis scripts survive export → parse with remapped fieldId', () {
        final template = _buildLiftingTemplate();
        final setsFieldId = template.fields[1].id;

        final script = AnalysisScriptModel(
          id: 'real-uuid-123',
          name: 'Volume',
          fieldId: setsFieldId,
          outputMode: AnalysisOutputMode.scalar,
          snippetLanguage: AnalysisSnippetLanguage.js,
          snippet: 'return [{label: "Vol", value: 42}];',
          updatedAt: DateTime.now(),
        );

        final shareable = ShareableTemplate.create(
          author: AuthorCredit.create(name: 'Test'),
          template: template,
          category: 'fitness',
          analysisScripts: [script],
        );

        // Export (sanitize) → serialize → parse
        final sanitized = shareable.sanitizeForExport();
        final json = sanitized.toJson();
        final imported = ShareableTemplate.fromJson(json);

        // Script fieldId should point to clean field ID
        expect(imported.analysisScripts![0].fieldId, 'field-2');
        expect(imported.analysisScripts![0].name, 'Volume');
        expect(imported.analysisScripts![0].snippet, contains('Vol'));

        // And field-2 should be the Sets group
        final field2 = imported.template.fields
            .firstWhere((f) => f.id == 'field-2');
        expect(field2.label, 'Sets');
        expect(field2.type, FieldEnum.group);
      });

      test('validators survive round trip', () {
        final template = _buildSimpleTemplate();
        final shareable = ShareableTemplate.create(
          author: AuthorCredit.create(name: 'Test'),
          template: template,
          category: 'test',
        );

        final sanitized = shareable.sanitizeForExport();
        final json = sanitized.toJson();
        final imported = ShareableTemplate.fromJson(json);

        // Mood field should have numeric validator
        final moodField = imported.template.fields
            .firstWhere((f) => f.label == 'Mood');
        expect(moodField.validators.length, 1);
        expect(moodField.validators[0].validatorType, ValidatorType.numeric);
        expect(moodField.validators[0].validatorData['min'], 1);
        expect(moodField.validators[0].validatorData['max'], 10);

        // Notes field should have optional validator
        final notesField = imported.template.fields
            .firstWhere((f) => f.label == 'Notes');
        expect(notesField.validators.length, 1);
        expect(notesField.validators[0].validatorType, ValidatorType.optional);
      });
    });
  });
}

// ─────────────────────────────────────────────────────────────────────────
// Test Helpers
// ─────────────────────────────────────────────────────────────────────────

TrackerTemplateModel _buildSimpleTemplate() {
  return TrackerTemplateModel.create(
    name: 'Simple',
    fields: [
      TemplateField.create(
        label: 'Mood',
        type: FieldEnum.integer,
        uiElement: UiElementEnum.slider,
        validators: [
          FieldValidator.create(
            validatorType: ValidatorType.numeric,
            validatorData: {'min': 1, 'max': 10},
          ),
        ],
        defaultValue: 5,
      ),
      TemplateField.create(
        label: 'Energy',
        type: FieldEnum.integer,
        uiElement: UiElementEnum.slider,
        validators: [
          FieldValidator.create(
            validatorType: ValidatorType.numeric,
            validatorData: {'min': 1, 'max': 10},
          ),
        ],
        defaultValue: 5,
      ),
      TemplateField.create(
        label: 'Notes',
        type: FieldEnum.text,
        uiElement: UiElementEnum.textArea,
        validators: [
          FieldValidator.create(
            validatorType: ValidatorType.optional,
            validatorData: {},
          ),
        ],
      ),
    ],
  );
}

TrackerTemplateModel _buildLiftingTemplate() {
  return TrackerTemplateModel.create(
    name: 'Lifting',
    fields: [
      TemplateField.create(
        label: 'Exercise',
        type: FieldEnum.text,
        uiElement: UiElementEnum.textField,
      ),
      TemplateField.create(
        label: 'Sets',
        type: FieldEnum.group,
        isList: true,
        subFields: [
          TemplateField.create(
            label: 'Weight',
            type: FieldEnum.float,
            uiElement: UiElementEnum.textField,
          ),
          TemplateField.create(
            label: 'Reps',
            type: FieldEnum.integer,
            uiElement: UiElementEnum.stepper,
          ),
          TemplateField.create(
            label: 'RPE',
            type: FieldEnum.integer,
            uiElement: UiElementEnum.slider,
          ),
        ],
      ),
      TemplateField.create(
        label: 'Notes',
        type: FieldEnum.text,
        uiElement: UiElementEnum.textArea,
        validators: [
          FieldValidator.create(
            validatorType: ValidatorType.optional,
            validatorData: {},
          ),
        ],
      ),
    ],
  );
}

TrackerTemplateModel _buildEmotionTemplate() {
  return TrackerTemplateModel.create(
    name: 'Emotion',
    fields: [
      TemplateField.create(
        label: 'Emotions',
        type: FieldEnum.multiEnum,
        uiElement: UiElementEnum.chips,
        options: ['Happy', 'Calm', 'Anxious', 'Sad'],
      ),
    ],
  );
}
