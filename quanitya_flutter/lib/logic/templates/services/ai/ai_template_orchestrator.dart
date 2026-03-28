import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:injectable/injectable.dart';

import '../../../../infrastructure/ai/orchestrators/ai_structured_output_orchestrator.dart';
import '../../../../infrastructure/llm/models/llm_types.dart';
import '../../models/template_input.dart';
import '../engine/json_to_model_parser.dart';
import '../../exceptions/template_generation_exception.dart';
import 'ai_template_generator.dart';

/// AI orchestrator for generating tracker templates using structured output.
///
/// This orchestrator manages the complete template generation script:
/// 1. Generates JSON schema for template structure
/// 2. Builds system prompt with template creation guidelines
/// 3. Calls LLM with user's description
/// 4. Parses JSON response into ParsedAiTemplate
///
/// Generates:
/// - TrackerTemplateModel (PII - stored via DualDAO with E2EE)
/// - TemplateAestheticsModel (non-PII - stored directly)
@injectable
class AiTemplateOrchestrator extends AiStructuredOutputOrchestrator<TemplateInput, ParsedAiTemplate> {
  final JsonToModelParser _parser;
  final AiTemplateGenerator _schemaGenerator;
  
  AiTemplateOrchestrator(
    super.llmService,
    this._parser,
    this._schemaGenerator,
  );
  
  @override
  LlmCallType get callType => LlmCallType.templateGeneration;

  @override
  Map<String, dynamic> generateSchema(TemplateInput input) {
    return _schemaGenerator.generateSchema();
  }
  
  String? _cachedSystemPrompt;

  /// Loads system prompt from assets/template_prompt.json.
  Future<String> _loadSystemPrompt() async {
    if (_cachedSystemPrompt != null) return _cachedSystemPrompt!;
    final raw = await rootBundle.loadString('assets/template_prompt.json');
    final config = jsonDecode(raw) as Map<String, dynamic>;
    _cachedSystemPrompt = config['system_prompt'] as String;
    return _cachedSystemPrompt!;
  }

  @override
  String buildSystemPrompt(TemplateInput input) {
    // Synchronous fallback — prompt should be pre-loaded via generateTemplate
    return _cachedSystemPrompt ?? 'Generate a tracker template. Return valid JSON matching the schema.';
  }
  
  @override
  String buildUserPrompt(TemplateInput input) {
    return input.description;
  }
  
  @override
  ParsedAiTemplate parseResponse(Map<String, dynamic> json, TemplateInput input) {
    try {
      return _parser.parse(
        aiJson: json,
        templateName: input.templateName,
        emoji: input.emoji,
        themeName: input.themeName,
      );
    } catch (e) {
      throw TemplateGenerationException.serviceFailure(
        'Failed to parse AI response',
        originalException: e,
        context: {
          'templateName': input.templateName,
          'description': input.description,
        },
      );
    }
  }
  
  /// Public convenience method that maintains the existing API.
  ///
  /// This method provides backward compatibility with the existing AiTemplateService
  /// while using the new orchestrator pattern internally.
  Future<ParsedAiTemplate> generateTemplate(
    String description, {
    required LlmConfig config,
    required String templateName,
    String? emoji,
    String? themeName,
  }) async {
    try {
      // Pre-load prompt from asset before synchronous buildSystemPrompt is called
      await _loadSystemPrompt();

      final input = TemplateInput(
        description: description,
        templateName: templateName,
        emoji: emoji,
        themeName: themeName,
      );

      return await generate(input, config);
    } on TemplateGenerationException {
      rethrow;
    } catch (e) {
      throw TemplateGenerationException.serviceFailure(
        'generateTemplate failed',
        originalException: e,
        context: {
          'description': description,
          'templateName': templateName,
        },
      );
    }
  }
}