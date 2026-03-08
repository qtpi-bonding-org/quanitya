import 'package:injectable/injectable.dart';

import '../../../../infrastructure/ai/orchestrators/ai_structured_output_orchestrator.dart';
import '../../../../infrastructure/llm/models/llm_types.dart';
import '../../models/template_input.dart';
import '../engine/json_to_model_parser.dart';
import '../../exceptions/template_generation_exception.dart';
import 'ai_template_generator.dart';

/// AI orchestrator for generating tracker templates using structured output.
///
/// This orchestrator manages the complete template generation pipeline:
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
  
  @override
  String buildSystemPrompt(TemplateInput input) {
    return '''You are an expert at creating tracker templates for Quanitya, a privacy-first mood and habit tracking app.

Your job is to create structured templates that help users track their emotional well-being, habits, and personal metrics.

Key principles:
- Templates should be intuitive and easy to use
- Field types must match the supported widget types
- Consider accessibility and user experience
- Templates should encourage consistent daily tracking
- Create visually appealing color palettes that work well together
- Choose appropriate UI elements for each field type

List fields (isList: true):
- Use isList: true when users need to record MULTIPLE values of the same type
- Examples: workout sets (multiple reps/weights), meal ingredients, medication doses, symptoms
- Set listMinItems/listMaxItems to constrain the list (0 = no min, 10 = no max)
- Most fields should be isList: false (single value) - only use lists when truly needed

Create a complete template specification including:
- 1-10 fields with appropriate types and widgets
- A cohesive color palette (2-4 accent colors, 2-3 neutrals as hex values)
- Color configuration for each widget type
- Optional font configuration

Always return valid JSON matching the provided schema.''';
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