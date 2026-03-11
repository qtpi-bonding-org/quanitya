import 'package:cubit_ui_flow/cubit_ui_flow.dart';
import 'package:injectable/injectable.dart';
import 'package:quanitya_flutter/l10n/l10n_key_resolver.g.dart';

import '../../exceptions/accessibility_exception.dart';
import '../../exceptions/template_generation_exception.dart';
import '../../exceptions/template_parsing_exception.dart';
import '../../exceptions/template_rendering_exception.dart';

/// Exception mapper for AI template generator exceptions.
///
/// Maps template-specific exceptions to user-friendly message keys
/// for the UI flow system to display appropriate error messages.
@injectable
class TemplateExceptionMapper implements IExceptionKeyMapper {
  @override
  MessageKey? map(Object exception) {
    if (exception is TemplateGenerationException) {
      return _mapGenerationException(exception);
    }

    if (exception is TemplateParsingException) {
      return _mapParsingException(exception);
    }

    if (exception is TemplateRenderingException) {
      return _mapRenderingException(exception);
    }

    if (exception is AccessibilityException) {
      return _mapAccessibilityException(exception);
    }

    // Return null to let other mappers handle unknown exceptions
    return null;
  }

  /// Maps template generation exceptions to message keys
  MessageKey _mapGenerationException(TemplateGenerationException exception) {
    return switch (exception.stage) {
      GenerationStage.validation => MessageKey.error(
        L10nKeys.templateGenerationValidationFailed,
        {
          'reason': exception.message,
          'suggestions': _getValidationSuggestions(exception),
        },
      ),

      GenerationStage.aiGeneration => MessageKey.error(
        L10nKeys.templateGenerationAiServiceFailed,
        {
          'reason': exception.message,
          'isRetryable': true,
        },
      ),

      GenerationStage.schemaValidation => MessageKey.error(
        L10nKeys.templateGenerationSchemaValidationFailed,
        {
          'reason': exception.message,
          'suggestions': [
            'Try simplifying your prompt',
            'Reduce the number of requested fields',
          ],
        },
      ),

      GenerationStage.optimization => MessageKey.error(
        L10nKeys.templateGenerationPerformanceFailed,
        {
          'reason': exception.message,
          'suggestions': [
            'Reduce template complexity',
            'Try fewer fields',
            'Simplify your prompt',
          ],
        },
      ),

      GenerationStage.postProcessing => MessageKey.error(
        L10nKeys.templateGenerationProcessingFailed,
        {
          'reason': exception.message,
          'isRetryable': true,
        },
      ),

      // Integration script specific stages
      GenerationStage.combinationGeneration => MessageKey.error(
        L10nKeys.templateIntegrationCombinationGenerationFailed,
        {
          'reason': exception.message,
          'suggestions': [
            'Check field type and UI element compatibility',
            'Verify enum definitions are valid',
          ],
          'isRetryable': false,
        },
      ),

      GenerationStage.schemaConversion => MessageKey.error(
        L10nKeys.templateIntegrationSchemaConversionFailed,
        {
          'reason': exception.message,
          'suggestions': [
            'Verify field combinations are valid',
            'Check schema converter configuration',
          ],
          'isRetryable': false,
        },
      ),

      GenerationStage.scriptOrchestration => MessageKey.error(
        L10nKeys.templateIntegrationScriptOrchestrationFailed,
        {
          'reason': exception.message,
          'suggestions': [
            'Check service dependencies',
            'Verify dependency injection configuration',
          ],
          'isRetryable': true,
        },
      ),

      GenerationStage.widgetGeneration => MessageKey.error(
        L10nKeys.templateIntegrationWidgetGenerationFailed,
        {
          'reason': exception.message,
          'suggestions': [
            'Check widget template definitions',
            'Verify enum combinations are valid',
          ],
          'isRetryable': false,
        },
      ),
    };
  }

  /// Maps template parsing exceptions to message keys
  MessageKey _mapParsingException(TemplateParsingException exception) {
    if (exception.message.contains('Missing required field')) {
      return MessageKey.error(L10nKeys.templateParsingMissingField, {
        'field': _extractFieldName(exception.message),
        'jsonPath': exception.jsonPath,
      });
    }

    if (exception.message.contains('Invalid value')) {
      return MessageKey.error(L10nKeys.templateParsingInvalidValue, {
        'field': _extractFieldName(exception.message),
        'jsonPath': exception.jsonPath,
      });
    }

    if (exception.message.contains('Invalid field-widget combination')) {
      return MessageKey.error(L10nKeys.templateParsingInvalidCombination, {
        'reason': exception.message,
        'suggestions': [
          'Try a different UI element for this field type',
          'Simplify your field requirements',
        ],
      });
    }

    if (exception.message.contains('Color palette error')) {
      return MessageKey.error(L10nKeys.templateParsingColorPaletteError, {
        'reason': exception.message,
        'suggestions': [
          'Try a simpler color scheme',
          'Use fewer colors',
          'Choose standard color themes',
        ],
      });
    }

    if (exception.message.contains('Color mapping error')) {
      return MessageKey.error(L10nKeys.templateParsingColorMappingError, {
        'reason': exception.message,
        'suggestions': [
          'Simplify color requirements',
          'Use default color mappings',
        ],
      });
    }

    // Generic parsing error
    return MessageKey.error(L10nKeys.templateParsingGenericError, {
      'reason': exception.message,
      'jsonPath': exception.jsonPath,
    });
  }

  /// Maps template rendering exceptions to message keys
  MessageKey _mapRenderingException(TemplateRenderingException exception) {
    return switch (exception.stage) {
      RenderingStage.contextCreation => MessageKey.error(
        L10nKeys.templateRenderingContextFailed,
        {
          'reason': exception.message,
          'fieldId': exception.fieldId,
        },
      ),

      RenderingStage.colorResolution => MessageKey.error(
        L10nKeys.templateRenderingColorResolutionFailed,
        {
          'reason': exception.message,
          'fieldId': exception.fieldId,
          'suggestions': ['Try simpler colors', 'Use default color scheme'],
        },
      ),

      RenderingStage.validation => MessageKey.error(
        L10nKeys.templateRenderingValidationFailed,
        {
          'reason': exception.message,
          'fieldId': exception.fieldId,
        },
      ),

      RenderingStage.widgetCreation => MessageKey.error(
        L10nKeys.templateRenderingWidgetCreationFailed,
        {
          'reason': exception.message,
          'fieldId': exception.fieldId,
          'suggestions': [
            'Try a different UI element',
            'Simplify field configuration',
          ],
        },
      ),

      RenderingStage.accessibility => MessageKey.error(
        L10nKeys.templateRenderingAccessibilityFailed,
        {
          'reason': exception.message,
          'fieldId': exception.fieldId,
          'suggestions': [
            'Allow automatic accessibility adjustments',
            'Use high contrast colors',
          ],
        },
      ),

      RenderingStage.layout => MessageKey.error(
        L10nKeys.templateRenderingLayoutFailed,
        {
          'reason': exception.message,
          'suggestions': [
            'Reduce number of fields',
            'Simplify layout requirements',
          ],
        },
      ),
    };
  }

  /// Maps accessibility exceptions to message keys
  MessageKey _mapAccessibilityException(AccessibilityException exception) {
    return switch (exception.requirementType) {
      AccessibilityRequirementType.contrastRatio => MessageKey.warning(
        L10nKeys.templateAccessibilityContrastRatioFailed,
        {
          'elementName': exception.elementName,
          'currentRatio': exception.currentValue,
          'requiredRatio': exception.requiredValue,
          'standard': exception.standard.name,
          'suggestions': exception.suggestedAdjustments,
          'canAutoFix': true,
        },
      ),

      AccessibilityRequirementType.colorBlindness => MessageKey.warning(
        L10nKeys.templateAccessibilityColorBlindnessIssue,
        {
          'elementName': exception.elementName,
          'suggestions': exception.suggestedAdjustments,
          'canAutoFix': true,
        },
      ),

      AccessibilityRequirementType.focusIndicator => MessageKey.warning(
        L10nKeys.templateAccessibilityFocusIndicatorFailed,
        {
          'elementName': exception.elementName,
          'suggestions': exception.suggestedAdjustments,
          'canAutoFix': true,
        },
      ),

      AccessibilityRequirementType.touchTargetSize => MessageKey.warning(
        L10nKeys.templateAccessibilityTouchTargetSizeFailed,
        {
          'elementName': exception.elementName,
          'currentSize': exception.currentValue,
          'requiredSize': exception.requiredValue,
          'suggestions': exception.suggestedAdjustments,
          'canAutoFix': true,
        },
      ),

      AccessibilityRequirementType.textReadability => MessageKey.warning(
        L10nKeys.templateAccessibilityTextReadabilityFailed,
        {
          'elementName': exception.elementName,
          'suggestions': exception.suggestedAdjustments,
          'canAutoFix': true,
        },
      ),

      _ => MessageKey.warning(L10nKeys.templateAccessibilityGenericIssue, {
        'elementName': exception.elementName,
        'requirementType': exception.requirementType.name,
        'suggestions': exception.suggestedAdjustments,
      }),
    };
  }

  /// Gets validation suggestions based on exception context
  List<String> _getValidationSuggestions(
    TemplateGenerationException exception,
  ) {
    final context = exception.context;
    final suggestions = <String>[];

    if (context['prompt'] != null) {
      final prompt = context['prompt'] as String;
      if (prompt.isEmpty) {
        suggestions.add(
          'Provide a description of the template you want to create',
        );
      } else if (prompt.length > 1000) {
        suggestions.add('Shorten your prompt to under 1000 characters');
      } else if (prompt.length < 2) {
        suggestions.add('Provide a more detailed description');
      }
    }

    if (context['maxFields'] != null) {
      final maxFields = context['maxFields'] as int;
      if (maxFields < 1) {
        suggestions.add('Set maximum fields to at least 1');
      } else if (maxFields > 20) {
        suggestions.add('Reduce maximum fields to 20 or fewer');
      }
    }

    if (context['timeout'] != null) {
      suggestions.add('Increase timeout or simplify your request');
    }

    if (suggestions.isEmpty) {
      suggestions.addAll([
        'Check your input parameters',
        'Try a simpler request',
        'Contact support if the problem persists',
      ]);
    }

    return suggestions;
  }

  /// Extracts field name from error message
  String _extractFieldName(String message) {
    final match = RegExp(r'field (\w+)').firstMatch(message);
    return match?.group(1) ?? 'unknown';
  }
}
