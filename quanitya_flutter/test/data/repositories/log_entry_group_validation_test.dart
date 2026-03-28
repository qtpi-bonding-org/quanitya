import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:quanitya_flutter/data/dao/log_entry_dual_dao.dart';
import 'package:quanitya_flutter/data/dao/log_entry_query_dao.dart';
import 'package:quanitya_flutter/data/dao/template_query_dao.dart';
import 'package:quanitya_flutter/data/db/app_database.dart';
import 'package:quanitya_flutter/data/repositories/log_entry_repository.dart';
import 'package:quanitya_flutter/logic/templates/enums/field_enum.dart';
import 'package:quanitya_flutter/logic/templates/models/shared/field_validator.dart';
import 'package:quanitya_flutter/logic/templates/models/shared/template_field.dart';

class MockLogEntryDualDao extends Mock implements LogEntryDualDao {}

class MockLogEntryQueryDao extends Mock implements LogEntryQueryDao {}

class MockTemplateQueryDao extends Mock implements TemplateQueryDao {}

class MockAppDatabase extends Mock implements AppDatabase {}

void main() {
  late LogEntryRepository repository;

  setUp(() {
    repository = LogEntryRepository(
      MockLogEntryDualDao(),
      MockLogEntryQueryDao(),
      MockTemplateQueryDao(),
      MockAppDatabase(),
    );
  });

  // Helper to create a group field with sub-fields
  TemplateField makeGroupField({
    String label = 'Vitals',
    bool isList = false,
    List<TemplateField>? subFields,
  }) {
    return TemplateField.create(
      label: label,
      type: FieldEnum.group,
      isList: isList,
      subFields: subFields ??
          [
            TemplateField.create(
              label: 'Systolic',
              type: FieldEnum.integer,
            ),
            TemplateField.create(
              label: 'Diastolic',
              type: FieldEnum.integer,
            ),
          ],
    );
  }

  group('Group field validation', () {
    test('valid group object passes validation', () {
      final field = makeGroupField();
      final value = <String, dynamic>{
        field.subFields![0].id: 120,
        field.subFields![1].id: 80,
      };

      final error = repository.validateFieldTypeForTest(field, value);
      expect(error, isNull);
    });

    test('non-map value fails with "must be an object"', () {
      final field = makeGroupField();

      final error = repository.validateFieldTypeForTest(field, 'not a map');
      expect(error, contains('must be an object'));
    });

    test('missing required sub-field fails', () {
      final field = makeGroupField();
      // Only provide one of the two required sub-fields
      final value = <String, dynamic>{
        field.subFields![0].id: 120,
      };

      final error = repository.validateFieldTypeForTest(field, value);
      expect(error, contains('is required'));
    });

    test('wrong sub-field type fails', () {
      final field = makeGroupField();
      final value = <String, dynamic>{
        field.subFields![0].id: 'not an integer',
        field.subFields![1].id: 80,
      };

      final error = repository.validateFieldTypeForTest(field, value);
      expect(error, contains('must be an integer'));
    });

    test('unknown key in group object fails', () {
      final field = makeGroupField();
      final value = <String, dynamic>{
        field.subFields![0].id: 120,
        field.subFields![1].id: 80,
        'bogus_key': 42,
      };

      final error = repository.validateFieldTypeForTest(field, value);
      expect(error, contains('unknown sub-field key'));
    });

    test('optional sub-field may be absent', () {
      final optionalSubField = TemplateField.create(
        label: 'Notes',
        type: FieldEnum.text,
        validators: [
          const FieldValidator(
            validatorType: ValidatorType.optional,
            validatorData: {},
          ),
        ],
      );
      final field = makeGroupField(
        subFields: [
          TemplateField.create(label: 'Weight', type: FieldEnum.float),
          optionalSubField,
        ],
      );
      final value = <String, dynamic>{
        field.subFields![0].id: 72.5,
        // Notes sub-field intentionally omitted
      };

      final error = repository.validateFieldTypeForTest(field, value);
      expect(error, isNull);
    });

    test('deleted sub-field is ignored', () {
      final field = makeGroupField(
        subFields: [
          TemplateField.create(label: 'Active', type: FieldEnum.integer),
          TemplateField.create(
            label: 'Removed',
            type: FieldEnum.text,
            isDeleted: true,
          ),
        ],
      );
      final value = <String, dynamic>{
        field.subFields![0].id: 42,
      };

      final error = repository.validateFieldTypeForTest(field, value);
      expect(error, isNull);
    });

    test('group with no sub-fields defined fails', () {
      final field = makeGroupField(subFields: []);

      final value = <String, dynamic>{'anything': 1};
      final error = repository.validateFieldTypeForTest(field, value);
      expect(error, contains('has no sub-fields defined'));
    });
  });

  group('isList group validation', () {
    test('validates list of group objects', () {
      final field = makeGroupField(isList: true);
      final value = [
        <String, dynamic>{
          field.subFields![0].id: 120,
          field.subFields![1].id: 80,
        },
        <String, dynamic>{
          field.subFields![0].id: 130,
          field.subFields![1].id: 85,
        },
      ];

      final error = repository.validateFieldTypeForTest(field, value);
      expect(error, isNull);
    });

    test('rejects non-list value for isList group', () {
      final field = makeGroupField(isList: true);

      final error = repository.validateFieldTypeForTest(field, 'not a list');
      expect(error, contains('must be a list'));
    });

    test('catches invalid item in list of groups', () {
      final field = makeGroupField(isList: true);
      final value = [
        <String, dynamic>{
          field.subFields![0].id: 120,
          field.subFields![1].id: 80,
        },
        'not a map', // invalid item
      ];

      final error = repository.validateFieldTypeForTest(field, value);
      expect(error, contains('must be an object'));
      expect(error, contains('item 2'));
    });
  });

  group('Group field JSON round-trip', () {
    test('TemplateField with subFields serializes to JSON', () {
      final field = makeGroupField();
      final json = field.toJson();

      expect(json['type'], 'group');
      expect(json['subFields'], isA<List>());
      expect((json['subFields'] as List).length, 2);
    });

    test('TemplateField with subFields deserializes from JSON', () {
      final field = makeGroupField();
      final json = field.toJson();
      final restored = TemplateField.fromJson(json);

      expect(restored.type, FieldEnum.group);
      expect(restored.subFields, isNotNull);
      expect(restored.subFields!.length, 2);
      expect(restored.subFields![0].label, 'Systolic');
      expect(restored.subFields![1].label, 'Diastolic');
    });

    test('subField types are preserved through round-trip', () {
      final field = makeGroupField();
      final restored = TemplateField.fromJson(field.toJson());

      expect(restored.subFields![0].type, FieldEnum.integer);
      expect(restored.subFields![1].type, FieldEnum.integer);
    });

    test('null subFields round-trips correctly', () {
      final field = TemplateField.create(
        label: 'Plain text',
        type: FieldEnum.text,
      );
      final restored = TemplateField.fromJson(field.toJson());

      expect(restored.subFields, isNull);
    });
  });
}
