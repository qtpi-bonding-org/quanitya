import 'package:freezed_annotation/freezed_annotation.dart';

part 'webhook_model.freezed.dart';
part 'webhook_model.g.dart';

/// Model for webhook configuration
@freezed
abstract class WebhookModel with _$WebhookModel {
  const WebhookModel._();
  const factory WebhookModel({
    required String id,
    required String templateId,
    required String name,
    required String url,
    String? apiKeyId,
    @Default(true) bool isEnabled,
    DateTime? lastTriggeredAt,
    required DateTime updatedAt,
  }) = _WebhookModel;

  factory WebhookModel.fromJson(Map<String, dynamic> json) => _$WebhookModelFromJson(json);
}

/// URL validation for webhooks
class WebhookUrlValidator {
  /// Validates that URL is HTTPS and well-formed
  static bool isValid(String url) {
    if (!url.startsWith('https://')) return false;
    final uri = Uri.tryParse(url);
    return uri != null && uri.hasAuthority && uri.host.isNotEmpty;
  }

  /// Returns validation error message or null if valid
  static String? validate(String url) {
    if (url.isEmpty) return 'URL is required';
    if (!url.startsWith('https://')) return 'URL must use HTTPS';
    final uri = Uri.tryParse(url);
    if (uri == null || !uri.hasAuthority || uri.host.isEmpty) {
      return 'Invalid URL format';
    }
    return null;
  }
}
