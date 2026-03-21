import 'package:cubit_ui_flow/cubit_ui_flow.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../models/llm_provider_config_model.dart';
import '../../repositories/open_router_model_repository.dart';

part 'llm_provider_state.freezed.dart';

enum LlmProviderOperation { load, save, delete, testConnection, fetchModels }

@freezed
class LlmProviderState with _$LlmProviderState, UiFlowStateMixin implements IUiFlowState {
  const LlmProviderState._();

  const factory LlmProviderState({
    @Default([]) List<LlmProviderConfigModel> configs,
    LlmProviderConfigModel? activeConfig,
    @Default([]) List<OpenRouterModelRecord> availableModels,
    @Default(UiFlowStatus.idle) UiFlowStatus status,
    Object? error,
    LlmProviderOperation? lastOperation,
  }) = _LlmProviderState;
}
