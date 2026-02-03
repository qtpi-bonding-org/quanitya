import 'package:injectable/injectable.dart';

import '../../logic/analytics/models/analysis_pipeline.dart';
import '../dao/analysis_pipeline_dual_dao.dart';
import '../dao/analysis_pipeline_query_dao.dart';
import '../interfaces/analysis_pipeline_interface.dart';
import '../../infrastructure/core/try_operation.dart';
import '../../logic/analytics/exceptions/analysis_exceptions.dart';

/// Repository for AnalysisPipelineModel operations with encryption handling.
///
/// Uses AnalysisPipelineQueryDao for reads and AnalysisPipelineDualDao for writes.
/// - Reads: Query local plaintext table directly (fast)
/// - Writes: DualDao handles atomic writes to both local + encrypted tables
@Injectable(as: IAnalysisPipelineRepository)
class AnalysisPipelineRepository implements IAnalysisPipelineRepository {
  final AnalysisPipelineDualDao _writeDao;
  final AnalysisPipelineQueryDao _queryDao;

  const AnalysisPipelineRepository(this._writeDao, this._queryDao);

  @override
  Stream<List<AnalysisPipelineModel>> watchAllPipelines() {
    return _queryDao.watchAll();
  }

  @override
  Stream<List<AnalysisPipelineModel>> watchPipelinesForField(String fieldId) {
    return _queryDao.watchByFieldId(fieldId);
  }

  @override
  Future<AnalysisPipelineModel?> getPipeline(String id) {
    return tryMethod(
      () => _queryDao.findById(id),
      AnalysisException.new,
      'getPipeline',
    );
  }

  @override
  Future<List<AnalysisPipelineModel>> getAllPipelines() {
    return tryMethod(
      () => _queryDao.findAll(),
      AnalysisException.new,
      'getAllPipelines',
    );
  }

  @override
  Future<List<AnalysisPipelineModel>> getPipelinesForField(String fieldId) {
    return tryMethod(
      () => _queryDao.findByFieldId(fieldId),
      AnalysisException.new,
      'getPipelinesForField',
    );
  }

  @override
  Future<void> savePipeline(AnalysisPipelineModel pipeline) {
    return tryMethod(
      () async {
        final entity = _writeDao.modelToEntity(pipeline);
        await _writeDao.upsert(entity);
      },
      AnalysisException.new,
      'savePipeline',
    );
  }

  @override
  Future<void> updatePipeline(AnalysisPipelineModel pipeline) {
    return tryMethod(
      () async {
        final entity = _writeDao.modelToEntity(pipeline);
        await _writeDao.upsert(entity);
      },
      AnalysisException.new,
      'updatePipeline',
    );
  }

  @override
  Future<void> deletePipeline(String id) {
    return tryMethod(
      () => _writeDao.delete(id),
      AnalysisException.new,
      'deletePipeline',
    );
  }

  @override
  Future<void> bulkInsert(List<AnalysisPipelineModel> pipelines) {
    return tryMethod(
      () async {
        final entities = pipelines.map(_writeDao.modelToEntity).toList();
        await _writeDao.bulkUpsert(entities);
      },
      AnalysisException.new,
      'bulkInsert',
    );
  }

  @override
  Future<int> countPipelines() {
    return tryMethod(
      () => _queryDao.count(),
      AnalysisException.new,
      'countPipelines',
    );
  }
}
