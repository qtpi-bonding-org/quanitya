import 'dart:convert';
import 'package:crypto/crypto.dart';
import '../../llm/models/gbnf_field.dart';
import '../../log_entries/models/log_entry.dart';
import '../../ocr/models/extraction_field.dart';
import '../../templates/models/shared/tracker_template.dart';
import 'json_data_source_adapter.dart';

/// Data source adapter for OCR-extracted data via on-device LLM.
///
/// Extends [JsonDataSourceAdapter] to plug into the existing
/// [DataIngestionService.syncJson] pipeline. Constructed per-extraction
/// with the target template and extraction fields.
///
/// Dedup key is a SHA1 hash of sorted field values, so re-scanning
/// the same document won't create duplicate entries.
class OcrDataSourceAdapter extends JsonDataSourceAdapter {
  final TrackerTemplateModel _template;
  final List<ExtractionField> _extractionFields;
  final DateTime _batchTimestamp;

  OcrDataSourceAdapter(
    this._template,
    this._extractionFields, {
    DateTime? batchTimestamp,
  }) : _batchTimestamp = batchTimestamp ?? DateTime.now();

  @override
  String get adapterId => 'ocr.on_device';

  @override
  String get displayName => 'OCR (On-Device LLM)';

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
    return {
      'type': 'object',
      'required': required,
      'properties': properties,
    };
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
          'expected ${field.type.name}, got ${value.runtimeType}',
        );
      }
    }
    return errors;
  }

  @override
  LogEntryModel mapToEntry(
    Map<String, dynamic> sourceData,
    String templateId,
  ) {
    return LogEntryModel.logNow(
      templateId: templateId,
      occurredAt: _batchTimestamp,
      data: {
        ...sourceData,
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
      final value = sourceData[id];
      parts.add('$id:$value');
    }
    final content = parts.join('|');
    return sha1.convert(utf8.encode(content)).toString();
  }

  @override
  DateTime extractTimestamp(Map<String, dynamic> sourceData) => _batchTimestamp;

  /// Returns the template this adapter was constructed with.
  /// Note: DataIngestionService.syncJson does not call this method.
  @override
  TrackerTemplateModel deriveTemplate() => _template;
}
