import 'package:freezed_annotation/freezed_annotation.dart';

part 'template_input.freezed.dart';

/// Input model for AI template generation.
///
/// This model encapsulates all the parameters needed for template generation,
/// providing type safety and clear structure for the orchestrator.
@freezed
class TemplateInput with _$TemplateInput {
  const factory TemplateInput({
    /// User's natural language description of what they want to track
    required String description,
    
    /// Name for the generated template (derived from description or user input)
    required String templateName,
    
    /// Optional emoji for the template
    String? emoji,
    
    /// Optional theme name for styling
    String? themeName,
  }) = _TemplateInput;
}