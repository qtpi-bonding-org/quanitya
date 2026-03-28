import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:injectable/injectable.dart';

import '../engine/json_to_model_parser.dart';
import '../../exceptions/template_generation_exception.dart';
import '../../../../infrastructure/llm/models/llm_types.dart';
import '../../../../infrastructure/llm/services/llm_service.dart';
import 'ai_template_generator.dart';

/// Service for generating tracker templates using AI.
///
/// Takes a user description and generates:
/// - TrackerTemplateModel (PII - stored via DualDAO with E2EE)
/// - TemplateAestheticsModel (non-PII - stored directly)
@injectable
class AiTemplateService {
  final LlmService _llm;
  final JsonToModelParser _parser;
  final AiTemplateGenerator _schemaGenerator;

  AiTemplateService(this._llm, this._parser, this._schemaGenerator);

  String? _cachedSystemPrompt;

  /// Loads system prompt from assets/template_prompt.json.
  Future<String> _loadSystemPrompt() async {
    if (_cachedSystemPrompt != null) return _cachedSystemPrompt!;
    final raw = await rootBundle.loadString('assets/template_prompt.json');
    final config = jsonDecode(raw) as Map<String, dynamic>;
    _cachedSystemPrompt = config['system_prompt'] as String;
    return _cachedSystemPrompt!;
  }

  /// Generates a template from user description.
  ///
  /// Returns [ParsedAiTemplate] containing:
  /// - template: TrackerTemplateModel with fields (PII)
  /// - aesthetics: TemplateAestheticsModel with colors/fonts (non-PII)
  Future<ParsedAiTemplate> generateTemplate(
    String description, {
    required LlmConfig config,
    required String templateName,
    String? emoji,
    String? themeName,
    String? systemPrompt,
  }) async {
    try {
      final schema = _schemaGenerator.generateSchema();
      final prompt = systemPrompt ?? await _loadSystemPrompt();

      final response = await _llm.execute(
        config,
        LlmRequest(
          systemPrompt: prompt,
          userPrompt: description,
          jsonSchema: schema,
        ),
      );

      return _parser.parse(
        aiJson: response.data,
        templateName: templateName,
        emoji: emoji,
        themeName: themeName,
      );
    } on TemplateGenerationException {
      rethrow;
    } catch (e) {
      throw TemplateGenerationException.serviceFailure(
        'generateTemplate failed',
        originalException: e,
        context: {'description': description, 'templateName': templateName},
      );
    }
  }
}
