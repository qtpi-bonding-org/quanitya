import 'package:cubit_ui_flow/cubit_ui_flow.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../data/repositories/data_retrieval_service.dart';

part 'visualization_state.freezed.dart';

enum VisualizationOperation { load }

@freezed
class VisualizationState
    with _$VisualizationState, UiFlowStateMixin
    implements IUiFlowState {
  const VisualizationState._();

  const factory VisualizationState({
    @Default(UiFlowStatus.idle) UiFlowStatus status,
    Object? error,
    VisualizationOperation? lastOperation,
    TemplateAggregatedData? data,
    /// Consistency rate (0.0 to 1.0) - percentage of days with entries
    @Default(0.0) double consistencyRate,
  }) = _VisualizationState;
}
