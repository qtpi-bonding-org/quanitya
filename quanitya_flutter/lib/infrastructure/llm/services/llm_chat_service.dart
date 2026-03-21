import 'package:injectable/injectable.dart';
import '../../core/try_operation.dart';
import '../models/llm_types.dart';
import 'llm_service.dart';

/// Service for conversational LLM interactions
/// Handles chat-based use cases like stats analysis, wellness coaching, etc.
@injectable
class LlmChatService {
  final LlmService _llmService;

  LlmChatService(this._llmService);

  /// Simple question-answer chat
  Future<String> ask({
    required LlmConfig config,
    required String systemPrompt,
    required String question,
    double temperature = 0.7,
  }) {
    return tryMethod(
      () async {
        final request = LlmChatRequest.simple(
          systemPrompt: systemPrompt,
          userPrompt: question,
          temperature: temperature,
        );

        final response = await _llmService.chat(config, request);
        return response.content;
      },
      LlmException.new,
      'ask',
    );
  }

  /// Multi-turn conversation
  Future<String> converse({
    required LlmConfig config,
    required List<LlmChatMessage> messages,
    double temperature = 0.7,
  }) {
    return tryMethod(
      () async {
        final request = LlmChatRequest(
          messages: messages,
          temperature: temperature,
        );

        final response = await _llmService.chat(config, request);
        return response.content;
      },
      LlmException.new,
      'converse',
    );
  }

  /// Get default config (can be overridden by user settings)
  LlmConfig getDefaultConfig() {
    // TODO: Get from user preferences/settings
    // For now, default to Ollama for privacy
    return LlmConfig.ollama(
      model: 'llama3.2',
      url: 'http://localhost:11434/v1',
    );
  }
}