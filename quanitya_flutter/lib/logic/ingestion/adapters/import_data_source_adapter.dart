import 'dart:convert';
import 'package:crypto/crypto.dart';
import '../../llm/models/gbnf_field.dart';
import '../../log_entries/models/log_entry.dart';
import '../../ocr/models/extraction_field.dart';
import '../../templates/models/shared/tracker_template.dart';
import 'json_data_source_adapter.dart';

/// Data source adapter for bulk import with per-item timestamps.
///
/// Extends [JsonDataSourceAdapter] to plug into the existing
/// [DataIngestionService.syncJson] pipeline. Constructed per-import
/// with the target template and extraction fields.
///
/// Per-item timestamps are passed via a `_occurredAt` metadata key in the
/// data map. The adapter reads it, parses it as ISO 8601, uses it for
/// `occurredAt`, and strips it before creating the entry.
///
/// Dedup key is a SHA1 hash of sorted field values, so re-importing
/// the same data won't create duplicate entries.
class ImportDataSourceAdapter extends JsonDataSourceAdapter {
  final TrackerTemplateModel _template;
  final List<ExtractionField> _extractionFields;

  ImportDataSourceAdapter(this._template, this._extractionFields);

  @override
  String get adapterId => 'import.bulk';

  @override
  String get displayName => 'Bulk Import';

  @override
  Map<String, dynamic> get inputSchema {
    final properties = <String, dynamic>{};
    final required = <String>[];
    for (final field in _extractionFields) {
      required.add(field.fieldId);
      properties[field.fieldId] = {
        'type': switch (field.type) {
          GbnfFieldType.string => 'string',
          GbnfFieldType.integer => 'integer',
          GbnfFieldType.number => 'number',
          GbnfFieldType.boolean => 'boolean',
          GbnfFieldType.enumerated => 'string',
        },
      };
    }
    return {'type': 'object', 'required': required, 'properties': properties};
  }

  @override
  List<String> validate(Map<String, dynamic> json) {
    final errors = <String>[];
    for (final field in _extractionFields) {
      final value = json[field.fieldId];
      if (value == null) {
        errors.add('Missing required field: ${field.fieldId}');
        continue;
      }
      if (value is String && value.trim().isEmpty) continue;
      final valid = switch (field.type) {
        GbnfFieldType.string => value is String,
        GbnfFieldType.integer => value is int,
        GbnfFieldType.number => value is num,
        GbnfFieldType.boolean => value is bool,
        GbnfFieldType.enumerated =>
          value is String && (field.enumValues?.contains(value) ?? true),
      };
      if (!valid) {
        errors.add(
          'Invalid type for field ${field.fieldId}: '
          'expected ${field.type.name}, got ${value.runtimeType} ($value)',
        );
      }
    }
    return errors;
  }

  @override
  LogEntryModel mapToEntry(Map<String, dynamic> sourceData, String templateId) {
    final occurredAtStr = sourceData['_occurredAt']?.toString();
    final occurredAt = occurredAtStr != null
        ? DateTime.tryParse(occurredAtStr) ?? DateTime.now()
        : DateTime.now();
    final cleanData = Map<String, dynamic>.of(sourceData)..remove('_occurredAt');

    return LogEntryModel.logNow(
      templateId: templateId,
      occurredAt: occurredAt,
      data: {
        ...cleanData,
        '_sourceAdapter': adapterId,
        '_dedupKey': extractDedupKey(sourceData),
      },
    );
  }

  @override
  String extractDedupKey(Map<String, dynamic> sourceData) {
    final parts = <String>[];
    final fieldIds = _extractionFields.map((f) => f.fieldId).toList()..sort();
    for (final id in fieldIds) {
      parts.add('$id:${sourceData[id]}');
    }
    return sha1.convert(utf8.encode(parts.join('|'))).toString();
  }

  @override
  DateTime extractTimestamp(Map<String, dynamic> sourceData) {
    final str = sourceData['_occurredAt']?.toString();
    return str != null ? DateTime.tryParse(str) ?? DateTime.now() : DateTime.now();
  }

  @override
  TrackerTemplateModel deriveTemplate() => _template;
}
