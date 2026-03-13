import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../infrastructure/llm/models/llm_types.dart';

part 'llm_provider_config_model.freezed.dart';

@freezed
class LlmProviderConfigModel with _$LlmProviderConfigModel {
  const factory LlmProviderConfigModel({
    required String id,
    @Default(LlmProvider.openRouter) LlmProvider provider,
    required String baseUrl,
    required String modelId,
    String? apiKeyId,
    required DateTime lastUsedAt,
  }) = _LlmProviderConfigModel;
}
