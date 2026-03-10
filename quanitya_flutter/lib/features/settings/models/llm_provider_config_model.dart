import 'package:freezed_annotation/freezed_annotation.dart';

part 'llm_provider_config_model.freezed.dart';

@freezed
class LlmProviderConfigModel with _$LlmProviderConfigModel {
  const factory LlmProviderConfigModel({
    required String id,
    required String baseUrl,
    required String modelId,
    String? apiKeyId,
    required DateTime lastUsedAt,
  }) = _LlmProviderConfigModel;
}
