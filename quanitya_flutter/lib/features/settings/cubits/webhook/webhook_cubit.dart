import 'package:cubit_ui_flow/cubit_ui_flow.dart';
import 'package:injectable/injectable.dart';

import '../../../../infrastructure/webhooks/api_key_repository.dart';
import '../../../../infrastructure/webhooks/models/api_key_model.dart';
import '../../../../infrastructure/webhooks/webhook_repository.dart';
import '../../../../infrastructure/webhooks/webhook_service.dart';
import '../../../../support/extensions/cubit_ui_flow_extension.dart';
import 'webhook_state.dart';

@injectable
class WebhookCubit extends QuanityaCubit<WebhookState> {
  final WebhookRepository _webhookRepo;
  final ApiKeyRepository _apiKeyRepo;
  final WebhookService _webhookService;

  WebhookCubit(
    this._webhookRepo,
    this._apiKeyRepo,
    this._webhookService,
  ) : super(const WebhookState());

  /// Load all webhooks and API keys
  Future<void> load() async {
    await tryOperation(() async {
      final webhooks = await _webhookRepo.getAll();
      final apiKeys = await _apiKeyRepo.getAll();
      return state.copyWith(
        webhooks: webhooks,
        apiKeys: apiKeys,
        status: UiFlowStatus.success,
        lastOperation: WebhookOperation.load,
      );
    }, emitLoading: true);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Webhook Operations
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> createWebhook({
    required String templateId,
    required String name,
    required String url,
    String? apiKeyId,
    bool isEnabled = true,
  }) async {
    await tryOperation(() async {
      await _webhookRepo.create(
        templateId: templateId,
        name: name,
        url: url,
        apiKeyId: apiKeyId,
        isEnabled: isEnabled,
      );
      final webhooks = await _webhookRepo.getAll();
      analytics?.trackWebhookCreated();
      return state.copyWith(
        webhooks: webhooks,
        status: UiFlowStatus.success,
        lastOperation: WebhookOperation.createWebhook,
      );
    }, emitLoading: true);
  }

  Future<void> updateWebhook({
    required String id,
    String? name,
    String? url,
    String? apiKeyId,
    bool? isEnabled,
  }) async {
    await tryOperation(() async {
      await _webhookRepo.update(
        id: id,
        name: name,
        url: url,
        apiKeyId: apiKeyId,
        isEnabled: isEnabled,
      );
      final webhooks = await _webhookRepo.getAll();
      return state.copyWith(
        webhooks: webhooks,
        status: UiFlowStatus.success,
        lastOperation: WebhookOperation.updateWebhook,
      );
    }, emitLoading: true);
  }

  Future<void> deleteWebhook(String id) async {
    await tryOperation(() async {
      await _webhookRepo.delete(id);
      final webhooks = await _webhookRepo.getAll();
      analytics?.trackWebhookDeleted();
      return state.copyWith(
        webhooks: webhooks,
        status: UiFlowStatus.success,
        lastOperation: WebhookOperation.deleteWebhook,
      );
    }, emitLoading: true);
  }

  Future<void> toggleWebhook(String id, bool isEnabled) async {
    await updateWebhook(id: id, isEnabled: isEnabled);
  }

  Future<void> retryWebhook(String id) async {
    await tryOperation(() async {
      await _webhookService.retryWebhook(id);
      final webhooks = await _webhookRepo.getAll();
      return state.copyWith(
        webhooks: webhooks,
        status: UiFlowStatus.success,
        lastOperation: WebhookOperation.retryWebhook,
      );
    }, emitLoading: true);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // API Key Operations
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> createApiKey({
    required String name,
    required AuthType authType,
    String? headerName,
    required String keyValue,
  }) async {
    await tryOperation(() async {
      await _apiKeyRepo.create(
        name: name,
        authType: authType,
        headerName: headerName,
        keyValue: keyValue,
      );
      final apiKeys = await _apiKeyRepo.getAll();
      return state.copyWith(
        apiKeys: apiKeys,
        status: UiFlowStatus.success,
        lastOperation: WebhookOperation.createApiKey,
      );
    }, emitLoading: true);
  }

  Future<void> updateApiKey({
    required String id,
    String? name,
    AuthType? authType,
    String? headerName,
    String? keyValue,
  }) async {
    await tryOperation(() async {
      await _apiKeyRepo.update(
        id: id,
        name: name,
        authType: authType,
        headerName: headerName,
        keyValue: keyValue,
      );
      final apiKeys = await _apiKeyRepo.getAll();
      return state.copyWith(
        apiKeys: apiKeys,
        status: UiFlowStatus.success,
        lastOperation: WebhookOperation.updateApiKey,
      );
    }, emitLoading: true);
  }

  Future<String?> getApiKeyValue(String apiKeyId) {
    return _apiKeyRepo.getKeyValue(apiKeyId);
  }

  Future<void> deleteApiKey(String id) async {
    await tryOperation(() async {
      await _apiKeyRepo.delete(id);
      final apiKeys = await _apiKeyRepo.getAll();
      return state.copyWith(
        apiKeys: apiKeys,
        status: UiFlowStatus.success,
        lastOperation: WebhookOperation.deleteApiKey,
      );
    }, emitLoading: true);
  }
}
