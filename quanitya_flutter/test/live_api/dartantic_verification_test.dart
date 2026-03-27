import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:quanitya_flutter/infrastructure/auth/auth_account_orchestrator.dart';
import 'package:quanitya_flutter/infrastructure/llm/services/llm_service.dart';
import 'package:quanitya_flutter/infrastructure/llm/models/llm_types.dart';
import 'package:quanitya_cloud_client/quanitya_cloud_client.dart';
import 'live_api_test_helper.dart';

class _MockAuthOrchestrator extends Mock implements AuthAccountOrchestrator {}

void main() {
  group('Dartantic AI Verification', () {
    late LlmService llmService;
    String? openRouterApiKey;
    bool hasKey = false;

    setUpAll(() async {
      await LiveApiTestHelper.loadEnv();
      openRouterApiKey = LiveApiTestHelper.openRouterApiKey;
      hasKey = LiveApiTestHelper.hasOpenRouterKey;
      llmService = LlmService(http.Client(), Client('http://localhost:8080/'), _MockAuthOrchestrator());
    });

    test('Structured Output with OpenRouter', () async {
      if (!hasKey) {
        markTestSkipped('OPENROUTER_API_KEY not found');
        return;
      }

      final config = LlmConfig(
        provider: LlmProvider.openRouter,
        apiKey: openRouterApiKey!,
        baseUrl: 'https://openrouter.ai/api/v1',
        model: 'openai/gpt-4o-mini',
        appName: 'Quanitya Test',
        appUrl: 'https://quanitya.com'
      );

      final schema = {
        "type": "object",
        "properties": {
          "answer": {"type": "string"},
          "confidence": {"type": "number"}
        },
        "required": ["answer", "confidence"],
        "additionalProperties": false
      };

      final request = LlmRequest(
        systemPrompt: "You are a helpful assistant.",
        userPrompt: "What is 2+2?",
        jsonSchema: schema,
      );

      final response = await llmService.execute(config, request);

      print('Response: ${response.data}');

      expect(response.data, isA<Map<String, dynamic>>());
      expect(response.data.containsKey('answer'), isTrue);
      expect(response.data.containsKey('confidence'), isTrue);
    });

    test('Chat with OpenRouter', () async {
      if (!hasKey) {
        markTestSkipped('OPENROUTER_API_KEY not found');
        return;
      }

      final config = LlmConfig(
        provider: LlmProvider.openRouter,
        apiKey: openRouterApiKey!,
        baseUrl: 'https://openrouter.ai/api/v1',
        model: 'openai/gpt-4o-mini',
      );

      final request = LlmChatRequest(
        messages: [
          LlmChatMessage(role: LlmChatRole.system, content: "You are a helpful assistant."),
          LlmChatMessage(role: LlmChatRole.user, content: "Say hello!"),
        ],
        temperature: 0.7,
        maxTokens: 50,
      );

      final response = await llmService.chat(config, request);

      print('Chat Response: ${response.content}');

      expect(response.content, isNotEmpty);
      expect(response.model, isNotEmpty);
    });
  });
}
