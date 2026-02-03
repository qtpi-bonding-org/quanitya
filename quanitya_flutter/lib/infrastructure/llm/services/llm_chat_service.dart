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

  /// Analyze user data and provide insights
  Future<String> analyzeStats({
    required LlmConfig config,
    required String question,
    required Map<String, dynamic> userData,
    double temperature = 0.6,
  }) {
    return tryMethod(
      () async {
        final systemPrompt = '''You are a personal wellness assistant and data analyst.
You help users understand their mood, habit, and wellness patterns.

Guidelines:
- Be encouraging and supportive
- Provide actionable insights
- Focus on patterns and trends
- Suggest practical improvements
- Keep responses concise but helpful
- Never provide medical advice''';

        final userPrompt = '''$question

My recent data:
${_formatUserData(userData)}

Please analyze this data and provide insights.''';

        return await ask(
          config: config,
          systemPrompt: systemPrompt,
          question: userPrompt,
          temperature: temperature,
        );
      },
      LlmException.new,
      'analyzeStats',
    );
  }

  /// Format user data for LLM consumption
  String _formatUserData(Map<String, dynamic> userData) {
    final buffer = StringBuffer();
    
    userData.forEach((key, value) {
      buffer.writeln('$key: $value');
    });
    
    return buffer.toString();
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