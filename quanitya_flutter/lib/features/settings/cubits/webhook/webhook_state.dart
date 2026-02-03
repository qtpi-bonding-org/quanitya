import 'package:cubit_ui_flow/cubit_ui_flow.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../infrastructure/webhooks/models/api_key_model.dart';
import '../../../../infrastructure/webhooks/models/webhook_model.dart';

part 'webhook_state.freezed.dart';

enum WebhookOperation {
  load,
  createWebhook,
  updateWebhook,
  deleteWebhook,
  retryWebhook,
  createApiKey,
  updateApiKey,
  deleteApiKey,
}

@freezed
class WebhookState with _$WebhookState implements IUiFlowState {
  const WebhookState._();
  
  const factory WebhookState({
    @Default([]) List<WebhookModel> webhooks,
    @Default([]) List<ApiKeyModel> apiKeys,
    @Default(UiFlowStatus.idle) UiFlowStatus status,
    Object? error,
    WebhookOperation? lastOperation,
  }) = _WebhookState;

  @override
  bool get isIdle => status == UiFlowStatus.idle;

  @override
  bool get isLoading => status == UiFlowStatus.loading;

  @override
  bool get isSuccess => status == UiFlowStatus.success;

  @override
  bool get isFailure => status == UiFlowStatus.failure;

  @override
  bool get hasError => error != null;
}
