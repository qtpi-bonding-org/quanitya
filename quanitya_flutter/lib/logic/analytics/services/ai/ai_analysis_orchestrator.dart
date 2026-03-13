import 'package:flutter/services.dart' show rootBundle;
import 'package:injectable/injectable.dart';
import 'package:jinja/jinja.dart' as jinja;
import 'dart:convert';

import '../../../../infrastructure/ai/orchestrators/ai_structured_output_orchestrator.dart';
import '../../../../infrastructure/llm/services/llm_service.dart';
import '../../../../infrastructure/llm/models/llm_types.dart';
import '../../models/analysis_input.dart';
import '../../models/analysis_enums.dart';
import '../../models/field_analysis_context.dart';
import '../../enums/analysis_output_mode.dart';
import '../../models/matrix_vector_scalar/analysis_data_type.dart';
import '../../exceptions/analysis_exceptions.dart';

/// Simple suggestion model for AI-generated analysis scripts
class ScriptSuggestion {
  final String snippet;
  final String reasoning;
  final AnalysisOutputMode outputMode;
  final AnalysisSnippetLanguage snippetLanguage;

  const ScriptSuggestion({
    required this.snippet,
    required this.reasoning,
    required this.outputMode,
    required this.snippetLanguage,
  });
}

/// AI orchestrator for generating script-based analysis suggestions.
@injectable
class AiAnalysisOrchestrator
    extends AiStructuredOutputOrchestrator<AnalysisInput, ScriptSuggestion> {
  final LlmService _llmService;

  AiAnalysisOrchestrator(super.llmService) : _llmService = llmService;

  @override
  LlmCallType get callType => LlmCallType.analysisSuggestion;

  @override
  Map<String, dynamic> generateSchema(AnalysisInput input) {
    throw UnimplementedError('Use generateSuggestion() instead');
  }

  @override
  String buildSystemPrompt(AnalysisInput input) {
    throw UnimplementedError('Use generateSuggestion() instead');
  }

  @override
  String buildUserPrompt(AnalysisInput input) {
    return input.intent;
  }

  @override
  ScriptSuggestion parseResponse(
    Map<String, dynamic> json,
    AnalysisInput input,
  ) {
    return ScriptSuggestion(
      reasoning: json['reasoning'] as String,
      snippet: json['logic_fragment'] as String,
      outputMode: AnalysisOutputMode.values.byName(
        json['output_mode'] as String,
      ),
      snippetLanguage: AnalysisSnippetLanguage.js,
    );
  }

  Future<ScriptSuggestion> generateSuggestion({
    required String intent,
    required FieldAnalysisContext fieldContext,
    required LlmConfig llmConfig,
  }) async {
    try {
      // 1. Load the centralized prompt configuration
      final promptConfigStr = await rootBundle.loadString('prompt.json');
      final promptConfig = jsonDecode(promptConfigStr);

      // 2. Build the system prompt using jinja
      final env = jinja.Environment();
      final systemTemplate = env.fromString(promptConfig['system_prompt']);
      final systemPrompt = systemTemplate.render({'user_intent': intent});

      // 3. Execute LLM request with Structured Output
      final response = await _llmService.execute(
        llmConfig,
        LlmRequest(
          systemPrompt: systemPrompt,
          userPrompt: intent,
          jsonSchema: promptConfig['json_schema'],
          callType: callType,
        ),
      );

      // 4. Parse the response
      final input = AnalysisInput(
        intent: intent,
        startType: AnalysisDataType.timeSeriesMatrix,
        fieldContext: fieldContext,
      );

      return parseResponse(response.data, input);
    } catch (e) {
      throw AnalysisException('AI Suggestion failed: $e', e);
    }
  }
}
