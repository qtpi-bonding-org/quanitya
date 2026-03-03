import 'dart:async';
import 'package:cubit_ui_flow/cubit_ui_flow.dart';
import 'package:injectable/injectable.dart';

import '../models/analysis_pipeline.dart';
import '../models/matrix_vector_scalar/mvs_union.dart';
import '../services/analysis_engine.dart';
import '../../../data/interfaces/analysis_pipeline_interface.dart';
import '../../../support/extensions/cubit_ui_flow_extension.dart';
import 'analytics_state.dart';

@injectable
class AnalyticsCubit extends QuanityaCubit<AnalyticsState> {
  final AnalysisEngine _engine;
  final IAnalysisPipelineRepository _pipelineRepo;
  StreamSubscription? _pipelinesSubscription;

  AnalyticsCubit(this._engine, this._pipelineRepo) : super(const AnalyticsState());

  @override
  Future<void> close() async {
    await _pipelinesSubscription?.cancel();
    return super.close();
  }

  void loadPipelines() {
    _pipelinesSubscription?.cancel();
    _pipelinesSubscription = _pipelineRepo.watchAllPipelines().listen(
      (pipelines) {
        emit(state.copyWith(
          status: UiFlowStatus.success,
          pipelines: pipelines,
          lastOperation: AnalyticsOperation.loadPipelines,
        ));
      },
      onError: (e) {
        emit(state.copyWith(
          status: UiFlowStatus.failure,
          error: e,
        ));
      },
    );
  }

  void loadPipelinesForField(String fieldId) {
    _pipelinesSubscription?.cancel();
    _pipelinesSubscription = _pipelineRepo.watchPipelinesForField(fieldId).listen(
      (pipelines) {
        emit(state.copyWith(
          status: UiFlowStatus.success,
          pipelines: pipelines,
          lastOperation: AnalyticsOperation.loadPipelines,
        ));
      },
      onError: (e) {
        emit(state.copyWith(
          status: UiFlowStatus.failure,
          error: e,
        ));
      },
    );
  }

  Future<void> executePipeline(AnalysisPipelineModel pipeline) async {
    await tryOperation(() async {
      final result = await _engine.executePipeline(pipeline);
      final updatedResults = Map<String, MvsUnion>.from(state.results);
      updatedResults[pipeline.id] = result;
      analytics?.trackAnalysisRun();

      return state.copyWith(
        status: UiFlowStatus.success,
        results: updatedResults,
        lastOperation: AnalyticsOperation.executePipeline,
      );
    }, emitLoading: true);
  }

  Future<void> savePipeline(AnalysisPipelineModel pipeline) async {
    await tryOperation(() async {
      await _pipelineRepo.savePipeline(pipeline);
      // Stream will automatically update pipelines
      return state.copyWith(
        status: UiFlowStatus.success,
        lastOperation: AnalyticsOperation.savePipeline,
      );
    }, emitLoading: true);
  }

  Future<void> updatePipeline(AnalysisPipelineModel pipeline) async {
    await tryOperation(() async {
      await _pipelineRepo.updatePipeline(pipeline);
      // Stream will automatically update pipelines
      return state.copyWith(
        status: UiFlowStatus.success,
        lastOperation: AnalyticsOperation.updatePipeline,
      );
    }, emitLoading: true);
  }

  Future<void> deletePipeline(String pipelineId) async {
    await tryOperation(() async {
      await _pipelineRepo.deletePipeline(pipelineId);
      
      // Remove from results (pipelines will be updated by stream)
      final updatedResults = Map<String, MvsUnion>.from(state.results);
      updatedResults.remove(pipelineId);
      
      return state.copyWith(
        status: UiFlowStatus.success,
        results: updatedResults,
        lastOperation: AnalyticsOperation.deletePipeline,
      );
    }, emitLoading: true);
  }

  void clearResults() {
    emit(state.copyWith(
      results: {},
      status: UiFlowStatus.idle,
    ));
  }
}