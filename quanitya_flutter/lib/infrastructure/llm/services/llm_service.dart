import 'dart:convert';
import 'package:dartantic_ai/dartantic_ai.dart';
import 'package:dartantic_interface/dartantic_interface.dart';
import 'package:json_schema/json_schema.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:injectable/injectable.dart';
import '../../core/try_operation.dart';
import '../models/llm_types.dart';
import 'schema_translator.dart';

import 'package:quanitya_cloud_client/quanitya_cloud_client.dart';

/// Super lightweight LLM service with structured output support
/// Compatible with OpenRouter and Ollama
@lazySingleton
class LlmService {
  final http.Client _client;
  final Client _serverpodClient;

  LlmService(this._client, this._serverpodClient);

  /// Execute structured LLM request with strict JSON schema enforcement
  Future<LlmResponse> execute(LlmConfig config, LlmRequest request) {
    return tryMethod(
      () async {
        _validateSchema(request.jsonSchema);

        // Quanitya provider routes through cloud proxy (managed, no API key)
        if (config.provider == LlmProvider.quanitya) {
          if (kDebugMode) {
            debugPrint('\n☁️☁️☁️ CLOUD PROXY REQUEST START ☁️☁️☁️');
            debugPrint('Model: ${config.model}');
            debugPrint('JsonSchema size: ${jsonEncode(request.jsonSchema).length}');
          }

          final cloudRequest = CloudLlmStructuredRequest(
            systemPrompt: request.systemPrompt,
            userPrompt: request.userPrompt,
            jsonSchema: jsonEncode(request.jsonSchema),
            callType: _toCloudCallType(request.callType),
            model: config.model,
          );

          // Execute via Serverpod Endpoint (server-side OpenRouter timeout is 30s,
          // so client needs ≥35s to avoid timing out before the server does)
          final response = await _serverpodClient.cloudLlm
              .generateStructured(cloudRequest)
              .timeout(const Duration(seconds: 45));

          if (kDebugMode) {
             debugPrint('☁️☁️☁️ CLOUD PROXY SUCCESS (balance: ${response.balance}) ☁️☁️☁️\n');
          }

          // Decode the JSON string from the response
          final data = jsonDecode(response.resultJson) as Map<String, dynamic>;

          return LlmResponse(
            data: data,
            model: config.model,
            tokensUsed: 0, // Server doesn't return usage yet, can add later
          );
        }

        // Convert Map to JsonSchema object
        final schema = JsonSchema.create(request.jsonSchema);

        // Create provider and agent
        final provider = _createProvider(config);
        final agent = Agent.forProvider(
          provider,
          chatModelName: config.model,
          temperature: 0.1, // Keep deterministic
        );

        // Debug logging
        if (kDebugMode) {
          debugPrint('\n🚀🚀🚀 LLM REQUEST START 🚀🚀🚀');
          debugPrint('Model: ${config.model}');
          debugPrint('Provider: ${config.provider}');
          debugPrint('System Prompt: ${request.systemPrompt}');
          debugPrint('User Prompt: ${request.userPrompt}');
          debugPrint('🚀🚀🚀 LLM REQUEST END 🚀🚀🚀\n');
        }

        // Execute using Dartantic's native structured output capability
        final response = await agent.sendFor<Map<String, dynamic>>(
          request.userPrompt,
          outputSchema: schema,
          history: [ChatMessage.system(request.systemPrompt)],
        );

        // Debug logging
        if (kDebugMode) {
          debugPrint('\n📨📨📨 LLM RESPONSE START 📨📨📨');
          debugPrint('Response: ${jsonEncode(response.output)}');
          debugPrint('📨📨📨 LLM RESPONSE END 📨📨📨\n');
        }

        return LlmResponse(
          data: response.output,
          model: agent.model,
          tokensUsed: response.usage?.totalTokens,
        );
      },
      LlmException.new,
      'execute',
    );
  }

  /// Execute conversational chat request (no structured output)
  Future<LlmChatResponse> chat(LlmConfig config, LlmChatRequest request) {
    return tryMethod(
      () async {
        final provider = _createProvider(config);
        
        // Convert messages to ChatMessage
        final history = <ChatMessage>[];
        String? userPrompt;
        
        // Process messages to build history and find the last user message as prompt
        for (int i = 0; i < request.messages.length; i++) {
          final msg = request.messages[i];
          final isLast = i == request.messages.length - 1;
          
          if (isLast && msg.role == LlmChatRole.user) {
            userPrompt = msg.content;
          } else {
            switch (msg.role) {
              case LlmChatRole.system:
                history.add(ChatMessage.system(msg.content));
                break;
              case LlmChatRole.user:
                history.add(ChatMessage.user(msg.content));
                break;
              case LlmChatRole.assistant:
                history.add(ChatMessage.model(msg.content));
                break;
            }
          }
        }
        
        userPrompt ??= ''; 

        final agent = Agent.forProvider(
          provider,
          chatModelName: config.model,
          temperature: request.temperature,
        );

        final response = await agent.send(
          userPrompt,
          history: history,
        );

        return LlmChatResponse(
          content: response.output,
          model: agent.model,
          tokensUsed: response.usage?.totalTokens,
          finishReason: response.finishReason.toString(),
        );
      },
      LlmException.new,
      'chat',
    );
  }

  /// Create Dartantic Provider based on LlmConfig
  Provider _createProvider(LlmConfig config) {
    switch (config.provider) {
      case LlmProvider.openRouter:
        return OpenAIProvider(
          name: 'openrouter',
          displayName: 'OpenRouter',
          baseUrl: Uri.parse(config.baseUrl),
          apiKey: config.apiKey,
          caps: {
             // Basic caps for OpenRouter
             ProviderCaps.chat,
             ProviderCaps.typedOutput,
          },
        );
      case LlmProvider.ollama:
         // Use the built-in Ollama provider or OpenAI compatible one
         // The builtin 'OllamaProvider' uses ChatOllama.
         return OllamaProvider(
           baseUrl: Uri.parse(config.baseUrl),
         );
      case LlmProvider.quanitya:
        throw LlmException(
            'Quanitya provider uses cloud proxy — direct provider not supported');
    }
  }

  void _validateSchema(Map<String, dynamic> schema) {
    // Strict checks can be added here if needed, but Dartantic handles validation
  }

  /// Map Flutter call type to Serverpod protocol enum
  static CloudLlmCallType _toCloudCallType(LlmCallType? callType) {
    return switch (callType) {
      LlmCallType.templateGeneration => CloudLlmCallType.templateGeneration,
      LlmCallType.analysisSuggestion => CloudLlmCallType.analysisSuggestion,
      null => CloudLlmCallType.templateGeneration, // default fallback
    };
  }
}



/// Exception for LLM service errors
class LlmException implements Exception {
  final String message;
  final Object? cause;

  const LlmException(this.message, [this.cause]);

  @override
  String toString() =>
      cause != null ? 'LlmException: $message (cause: $cause)' : 'LlmException: $message';
}