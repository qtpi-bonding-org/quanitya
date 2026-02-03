import 'package:cubit_ui_flow/cubit_ui_flow.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../models/analysis_pipeline.dart';
import '../models/matrix_vector_scalar/mvs_union.dart';

part 'analytics_state.freezed.dart';

enum AnalyticsOperation {
  loadPipelines,
  executePipeline,
  savePipeline,
  updatePipeline,
  deletePipeline,
}

@freezed
class AnalyticsState with _$AnalyticsState implements IUiFlowState {
  const AnalyticsState._();
  
  const factory AnalyticsState({
    @Default(UiFlowStatus.idle) UiFlowStatus status,
    Object? error,
    AnalyticsOperation? lastOperation,
    @Default([]) List<AnalysisPipelineModel> pipelines,
    @Default({}) Map<String, MvsUnion> results,
  }) = _AnalyticsState;

  // IUiFlowState implementations
  @override
  bool get hasError => error != null;
  
  @override
  bool get isFailure => status == UiFlowStatus.failure;
  
  @override
  bool get isIdle => status == UiFlowStatus.idle;
  
  @override
  bool get isLoading => status == UiFlowStatus.loading;
  
  @override
  bool get isSuccess => status == UiFlowStatus.success;
}