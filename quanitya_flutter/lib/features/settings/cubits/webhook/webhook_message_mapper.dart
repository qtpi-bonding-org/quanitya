import 'package:cubit_ui_flow/cubit_ui_flow.dart';
import 'package:injectable/injectable.dart';

import 'webhook_state.dart';

@injectable
class WebhookMessageMapper implements IStateMessageMapper<WebhookState> {
  @override
  MessageKey? map(WebhookState state) {
    if (state.status.isSuccess && state.lastOperation != null) {
      return switch (state.lastOperation!) {
        WebhookOperation.load => null, // Silent load
        WebhookOperation.createWebhook => MessageKey.success('webhook.created'),
        WebhookOperation.updateWebhook => MessageKey.success('webhook.updated'),
        WebhookOperation.deleteWebhook => MessageKey.success('webhook.deleted'),
        WebhookOperation.retryWebhook => MessageKey.success('webhook.triggered'),
        WebhookOperation.createApiKey => MessageKey.success('apiKey.created'),
        WebhookOperation.updateApiKey => MessageKey.success('apiKey.updated'),
        WebhookOperation.deleteApiKey => MessageKey.success('apiKey.deleted'),
      };
    }
    return null; // Use global exception mapping for errors
  }
}
