import 'package:freezed_annotation/freezed_annotation.dart';

part 'llm_types.freezed.dart';
part 'llm_types.g.dart';

enum LlmProvider { openRouter, ollama }

/// Configuration for LLM providers (OpenRouter/Ollama)
@freezed
class LlmConfig with _$LlmConfig {
  const factory LlmConfig({
    required LlmProvider provider,
    required String apiKey,
    required String baseUrl,
    required String model,
    String? appName,
    String? appUrl,
    @Default(false) bool useCloudProxy,
  }) = _LlmConfig;

  factory LlmConfig.fromJson(Map<String, dynamic> json) => _$LlmConfigFromJson(json);

  /// Factory for OpenRouter (Cloud)
  factory LlmConfig.openRouter({
    required String apiKey,
    required String model, // e.g., 'anthropic/claude-3.5-sonnet'
    String? appName,
    String? appUrl,
    bool useCloudProxy = false,
  }) {
    return LlmConfig(
      provider: LlmProvider.openRouter,
      apiKey: apiKey,
      baseUrl: 'https://openrouter.ai/api/v1',
      model: model,
      appName: appName,
      appUrl: appUrl,
      useCloudProxy: useCloudProxy,
    );
  }

  /// Factory for Ollama (Local)
  factory LlmConfig.ollama({
    required String model, // e.g., 'llama3.2'
    String url = 'http://localhost:11434/v1',
  }) {
    return LlmConfig(
      provider: LlmProvider.ollama,
      apiKey: 'ollama', // Required placeholder
      baseUrl: url,
      model: model,
    );
  }
}

/// Request with system/user prompts and strict JSON schema
@freezed
class LlmRequest with _$LlmRequest {
  const factory LlmRequest({
    required String systemPrompt,
    required String userPrompt,
    required Map<String, dynamic> jsonSchema,
    @Default('structured_response') String schemaName,
  }) = _LlmRequest;

  factory LlmRequest.fromJson(Map<String, dynamic> json) => _$LlmRequestFromJson(json);
}

/// Chat message roles for LLM conversations
enum LlmChatRole {
  system,
  user,
  assistant,
}

/// Chat message for conversational requests
@freezed
class LlmChatMessage with _$LlmChatMessage {
  const factory LlmChatMessage({
    required LlmChatRole role,
    required String content,
  }) = _LlmChatMessage;

  factory LlmChatMessage.fromJson(Map<String, dynamic> json) => _$LlmChatMessageFromJson(json);

  /// Helper constructors
  factory LlmChatMessage.system(String content) => LlmChatMessage(role: LlmChatRole.system, content: content);
  factory LlmChatMessage.user(String content) => LlmChatMessage(role: LlmChatRole.user, content: content);
  factory LlmChatMessage.assistant(String content) => LlmChatMessage(role: LlmChatRole.assistant, content: content);
}

/// Request for conversational chat (no structured output)
@freezed
class LlmChatRequest with _$LlmChatRequest {
  const factory LlmChatRequest({
    required List<LlmChatMessage> messages,
    @Default(0.7) double temperature,
    @Default(1000) int maxTokens,
    bool? stream,
  }) = _LlmChatRequest;

  factory LlmChatRequest.fromJson(Map<String, dynamic> json) => _$LlmChatRequestFromJson(json);

  /// Helper constructor for simple single-turn chat
  factory LlmChatRequest.simple({
    required String systemPrompt,
    required String userPrompt,
    double temperature = 0.7,
  }) {
    return LlmChatRequest(
      messages: [
        LlmChatMessage.system(systemPrompt),
        LlmChatMessage.user(userPrompt),
      ],
      temperature: temperature,
    );
  }
}

/// Response from LLM service (structured)
@freezed
class LlmResponse with _$LlmResponse {
  const factory LlmResponse({
    required Map<String, dynamic> data,
    String? model,
    int? tokensUsed,
  }) = _LlmResponse;

  factory LlmResponse.fromJson(Map<String, dynamic> json) => _$LlmResponseFromJson(json);
}

/// Response from LLM chat service (conversational)
@freezed
class LlmChatResponse with _$LlmChatResponse {
  const factory LlmChatResponse({
    required String content,
    String? model,
    int? tokensUsed,
    String? finishReason,
  }) = _LlmChatResponse;

  factory LlmChatResponse.fromJson(Map<String, dynamic> json) => _$LlmChatResponseFromJson(json);
}