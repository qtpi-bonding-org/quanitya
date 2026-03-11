import 'package:injectable/injectable.dart';

import '../../logic/analytics/models/analysis_script.dart';
import '../dao/analysis_script_dual_dao.dart';
import '../dao/analysis_script_query_dao.dart';
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

  const AnalysisScriptRepository(this._writeDao, this._queryDao);

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
}
