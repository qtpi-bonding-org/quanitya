import 'package:injectable/injectable.dart';

import '../../logic/analytics/models/analysis_script.dart';
import '../dao/analysis_script_dual_dao.dart';
import '../dao/analysis_script_query_dao.dart';
import '../dao/log_entry_query_dao.dart';
import '../dao/template_query_dao.dart';
import '../interfaces/analysis_script_interface.dart';
import '../../infrastructure/core/try_operation.dart';
import '../../logic/analytics/exceptions/analysis_exceptions.dart';

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
  Future<FieldTimeSeries> fetchFieldTimeSeries(
    String fieldId, {
    int? maxEntries,
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

        // Query all entries (ordered desc by date)
        final allEntries = maxEntries != null
            ? await _logEntryDao.findRecentEntries(templateId, maxEntries)
            : await _logEntryDao.findByTemplateId(templateId);

        // Extract numeric values keyed by field UUID
        final values = <double>[];
        final timestamps = <DateTime>[];

        for (final entry in allEntries) {
          final ts = entry.occurredAt ?? entry.scheduledFor;
          if (ts == null) continue;

          final val = _extractNumericValue(entry.data, field.id);
          if (val != null) {
            values.add(val);
            timestamps.add(ts);
          }
        }

        return (values: values, timestamps: timestamps);
      },
      AnalysisException.new,
      'fetchFieldTimeSeries',
    );
  }

  static double? _extractNumericValue(
    Map<String, dynamic> data,
    String fieldUuid,
  ) {
    final value = data[fieldUuid];
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    if (value is Map) {
      final v = value['value'] ?? value['Value'];
      if (v is num) return v.toDouble();
      if (v is String) return double.tryParse(v);
    }
    return null;
  }
}
