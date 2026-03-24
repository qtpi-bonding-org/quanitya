import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_error_privserver/flutter_error_privserver.dart';
import 'package:http/http.dart' as http;
import 'package:injectable/injectable.dart';

import '../core/try_operation.dart';
import 'api_key_repository.dart';
import 'models/api_key_model.dart';
import 'models/webhook_model.dart';
import 'webhook_exception.dart';
import 'webhook_repository.dart';

/// Service for triggering webhooks.
/// 
/// Fire-and-forget pattern: triggers don't block the calling code.
/// No data is sent - just a GET request to ping external services.
@lazySingleton
class WebhookService {
  final WebhookRepository _webhookRepo;
  final ApiKeyRepository _apiKeyRepo;
  final http.Client _httpClient;

  WebhookService(
    this._webhookRepo,
    this._apiKeyRepo,
    this._httpClient,
  );

  /// Trigger all enabled webhooks for a template.
  /// 
  /// Fire-and-forget: returns immediately, webhooks execute in background.
  /// Called after a log entry is saved.
  void triggerForTemplate(String templateId) {
    // Fire and forget - don't await
    unawaited(_triggerForTemplateAsync(templateId));
  }

  /// Manual retry for a specific webhook.
  /// 
  /// Unlike triggerForTemplate, this awaits and can throw.
  Future<void> retryWebhook(String webhookId) {
    return tryMethod(
      () async {
        final webhook = await _webhookRepo.getById(webhookId);
        if (webhook == null) {
          throw WebhookException('Webhook not found: $webhookId');
        }
        await _fireWebhook(webhook);
      },
      WebhookException.new,
      'retryWebhook',
    );
  }

  /// Internal async trigger (fire-and-forget target)
  Future<void> _triggerForTemplateAsync(String templateId) async {
    try {
      final webhooks = await _webhookRepo.getEnabledByTemplateId(templateId);
      for (final webhook in webhooks) {
        // Fire each webhook independently - don't let one failure stop others
        unawaited(_fireWebhookSafe(webhook));
      }
    } catch (e, stack) {
      debugPrint('WebhookService: triggerForTemplateAsync failed: $e');
      await ErrorPrivserver.captureError(e, stack, source: 'WebhookService');
    }
  }

  /// Fire a single webhook with error handling (silent fail)
  Future<void> _fireWebhookSafe(WebhookModel webhook) async {
    try {
      await _fireWebhook(webhook);
    } catch (e, stack) {
      debugPrint('WebhookService: _fireWebhookSafe failed: $e');
      await ErrorPrivserver.captureError(e, stack, source: 'WebhookService');
    }
  }

  /// Fire a single webhook (can throw)
  Future<void> _fireWebhook(WebhookModel webhook) async {
    final headers = await _buildHeaders(webhook.apiKeyId);
    
    final response = await _httpClient.get(
      Uri.parse(webhook.url),
      headers: headers,
    );

    // Update last triggered regardless of response status
    // (we triggered it, even if the endpoint returned an error)
    await _webhookRepo.updateLastTriggered(webhook.id, DateTime.now());

    // Log non-2xx responses but don't throw (fire-and-forget philosophy)
    if (response.statusCode < 200 || response.statusCode >= 300) {
      // Could add logging here if needed
    }
  }

  /// Build HTTP headers for a webhook request
  Future<Map<String, String>> _buildHeaders(String? apiKeyId) async {
    final headers = <String, String>{};

    if (apiKeyId == null) return headers;

    final apiKey = await _apiKeyRepo.getById(apiKeyId);
    if (apiKey == null) return headers;

    final keyValue = await _apiKeyRepo.getKeyValue(apiKeyId);
    if (keyValue == null) return headers;

    switch (apiKey.authType) {
      case AuthType.bearer:
        headers['Authorization'] = 'Bearer $keyValue';
      case AuthType.apiKeyHeader:
        final headerName = apiKey.headerName ?? 'X-API-Key';
        headers[headerName] = keyValue;
    }

    return headers;
  }
}
