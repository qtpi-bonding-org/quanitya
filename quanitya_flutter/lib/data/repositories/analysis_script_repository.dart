import 'package:injectable/injectable.dart';

import '../../logic/analysis/models/analysis_script.dart';
import '../dao/analysis_script_dual_dao.dart';
import '../dao/analysis_script_query_dao.dart';
import '../dao/log_entry_query_dao.dart';
import '../dao/template_query_dao.dart';
import '../interfaces/analysis_script_interface.dart';
import '../../infrastructure/core/try_operation.dart';
import '../../logic/analysis/exceptions/analysis_exceptions.dart';
import '../../logic/templates/enums/field_enum.dart';

/// Repository for AnalysisScriptModel operations with encryption handling.
///
/// Uses AnalysisScriptQueryDao for reads and AnalysisScriptDualDao for writes.
/// - Reads: Query local plaintext table directly (fast)
/// - Writes: DualDao handles atomic writes to both local + encrypted tables
@Injectable(as: IAnalysisScriptRepository)
class AnalysisScriptRepository implements IAnalysisScriptRepository {
  final AnalysisScriptDualDao _writeDao;
  final AnalysisScriptQueryDao _queryDao;
  final LogEntryQueryDao _logEntryDao;
  final TemplateQueryDao _templateDao;

  const AnalysisScriptRepository(
    this._writeDao,
    this._queryDao,
    this._logEntryDao,
    this._templateDao,
  );

  @override
  Stream<List<AnalysisScriptModel>> watchAllScripts() {
    return _queryDao.watchAll();
  }

  @override
  Stream<List<AnalysisScriptModel>> watchScriptsForField(String fieldId) {
    return _queryDao.watchByFieldId(fieldId);
  }

  @override
  Future<AnalysisScriptModel?> getScript(String id) {
    return tryMethod(
      () => _queryDao.findById(id),
      AnalysisException.new,
      'getScript',
    );
  }

  @override
  Future<List<AnalysisScriptModel>> getAllScripts() {
    return tryMethod(
      () => _queryDao.findAll(),
      AnalysisException.new,
      'getAllScripts',
    );
  }

  @override
  Future<List<AnalysisScriptModel>> getScriptsForField(String fieldId) {
    return tryMethod(
      () => _queryDao.findByFieldId(fieldId),
      AnalysisException.new,
      'getScriptsForField',
    );
  }

  @override
  Future<void> saveScript(AnalysisScriptModel script) {
    return tryMethod(
      () async {
        final entity = _writeDao.modelToEntity(script);
        await _writeDao.upsert(entity);
      },
      AnalysisException.new,
      'saveScript',
    );
  }

  @override
  Future<void> updateScript(AnalysisScriptModel script) {
    return tryMethod(
      () async {
        final entity = _writeDao.modelToEntity(script);
        await _writeDao.upsert(entity);
      },
      AnalysisException.new,
      'updateScript',
    );
  }

  @override
  Future<void> deleteScript(String id) {
    return tryMethod(
      () => _writeDao.delete(id),
      AnalysisException.new,
      'deleteScript',
    );
  }

  @override
  Future<void> bulkInsert(List<AnalysisScriptModel> scripts) {
    return tryMethod(
      () async {
        final entities = scripts.map(_writeDao.modelToEntity).toList();
        await _writeDao.bulkUpsert(entities);
      },
      AnalysisException.new,
      'bulkInsert',
    );
  }

  @override
  Future<int> countScripts() {
    return tryMethod(
      () => _queryDao.count(),
      AnalysisException.new,
      'countScripts',
    );
  }

  @override
  Future<int> countEntriesForTemplate(String templateId) {
    return tryMethod(
      () => _logEntryDao.countByTemplateId(templateId),
      AnalysisException.new,
      'countEntriesForTemplate',
    );
  }

  @override
  Future<FieldTimeSeries> fetchFieldTimeSeries(
    String fieldId, {
    int? entryRangeStart,
    int? entryRangeEnd,
  }) {
    return tryMethod(
      () async {
        // Parse fieldId format: "templateId:fieldName"
        final parts = fieldId.split(':');
        if (parts.length != 2) {
          throw AnalysisException('Invalid fieldId format: $fieldId');
        }
        final templateId = parts[0];
        final fieldName = parts[1];

        // Resolve display name → field UUID
        final template = await _templateDao.findById(templateId);
        if (template == null) {
          throw AnalysisException('Template not found: $templateId');
        }
        final field = template.fields.where((f) => f.label == fieldName).firstOrNull;
        if (field == null) {
          throw AnalysisException(
            'Field "$fieldName" not found in template "${template.name}"',
          );
        }

        // Query all entries chronologically (oldest first) for analysis
        final allEntries = (await _logEntryDao.findByTemplateId(templateId)).reversed.toList();
        final clampedStart = (entryRangeStart ?? 0).clamp(0, allEntries.length);
        final clampedEnd = (entryRangeEnd ?? allEntries.length).clamp(clampedStart, allEntries.length);
        final sliced = allEntries.sublist(clampedStart, clampedEnd);

        // Extract field values
        final values = <dynamic>[];
        final timestamps = <DateTime>[];

        // Build UUID → label map for group sub-fields
        final subFieldLabelMap = <String, String>{};
        if (field.type == FieldEnum.group && field.subFields != null) {
          for (final sf in field.subFields!) {
            subFieldLabelMap[sf.id] = sf.label;
          }
        }

        for (final entry in sliced) {
          final ts = entry.occurredAt ?? entry.scheduledFor;
          if (ts == null) continue;

          final val = entry.data[field.id];
          if (val != null) {
            // Remap group sub-field UUIDs to labels for JS readability
            values.add(subFieldLabelMap.isEmpty
                ? val
                : _remapGroupKeys(val, subFieldLabelMap));
            timestamps.add(ts);
          }
        }

        return (values: values, timestamps: timestamps);
      },
      AnalysisException.new,
      'fetchFieldTimeSeries',
    );
  }

  /// Remaps UUID keys to labels in group field values.
  ///
  /// Handles both single group objects and isList arrays of objects.
  /// Non-group values pass through unchanged.
  static dynamic _remapGroupKeys(
    dynamic val,
    Map<String, String> uuidToLabel,
  ) {
    if (val is List) {
      return val.map((item) => _remapGroupKeys(item, uuidToLabel)).toList();
    }
    if (val is Map<String, dynamic>) {
      return {
        for (final entry in val.entries)
          (uuidToLabel[entry.key] ?? entry.key): entry.value,
      };
    }
    return val;
  }
}
