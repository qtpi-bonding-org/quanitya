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
      // Generate schema using existing script
      final schema = _schemaGenerator.generateSchema();

      final response = await _llm.execute(
        config,
        LlmRequest(
          systemPrompt: systemPrompt ?? _getDefaultSystemPrompt(),
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

  String _getDefaultSystemPrompt() {
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
}
