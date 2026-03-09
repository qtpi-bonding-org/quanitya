import 'package:cubit_ui_flow/cubit_ui_flow.dart';
import 'package:injectable/injectable.dart';
import 'package:quanitya_flutter/l10n/l10n_key_resolver.g.dart';

import 'webhook_state.dart';

@injectable
class WebhookMessageMapper implements IStateMessageMapper<WebhookState> {
  @override
  MessageKey? map(WebhookState state) {
    if (state.status.isSuccess && state.lastOperation != null) {
      return switch (state.lastOperation!) {
        WebhookOperation.load => null, // Silent load
        WebhookOperation.createWebhook => MessageKey.success(L10nKeys.webhookCreated),
        WebhookOperation.updateWebhook => MessageKey.success(L10nKeys.webhookUpdated),
        WebhookOperation.deleteWebhook => MessageKey.success(L10nKeys.webhookDeleted),
        WebhookOperation.retryWebhook => MessageKey.success(L10nKeys.webhookTriggered),
        WebhookOperation.createApiKey => MessageKey.success(L10nKeys.apiKeyCreated),
        WebhookOperation.updateApiKey => MessageKey.success(L10nKeys.apiKeyUpdated),
        WebhookOperation.deleteApiKey => MessageKey.success(L10nKeys.apiKeyDeleted),
      };
    }
    return null; // Use global exception mapping for errors
  }
}
