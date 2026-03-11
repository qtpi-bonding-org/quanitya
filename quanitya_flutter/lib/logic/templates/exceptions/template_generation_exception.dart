/// Exception thrown when AI template generation fails.
/// 
/// This exception provides detailed information about generation failures
/// to help with debugging and error reporting.
class TemplateGenerationException implements Exception {
  /// The error message describing what went wrong
  final String message;
  
  /// The original exception that caused the generation failure (if any)
  final Object? originalException;
  
  /// The stack trace from the original exception (if any)
  final StackTrace? stackTrace;
  
  /// The generation stage where the error occurred
  final GenerationStage stage;
  
  /// Additional context about the generation request
  final Map<String, dynamic> context;
  
  const TemplateGenerationException(
    this.message, {
    this.originalException,
    this.stackTrace,
    required this.stage,
    this.context = const {},
  });
  
  /// Creates a generation exception for prompt validation failures
  factory TemplateGenerationException.invalidPrompt(String reason, {Map<String, dynamic>? context}) {
    return TemplateGenerationException(
      'Invalid prompt: $reason',
      stage: GenerationStage.validation,
      context: context ?? {},
    );
  }
  
  /// Creates a generation exception for AI service failures
  factory TemplateGenerationException.serviceFailure(String reason, {Object? originalException, Map<String, dynamic>? context}) {
    return TemplateGenerationException(
      'AI service failure: $reason',
      originalException: originalException,
      stage: GenerationStage.aiGeneration,
      context: context ?? {},
    );
  }
  
  /// Creates a generation exception for timeout issues
  factory TemplateGenerationException.timeout(int timeoutMs, {Map<String, dynamic>? context}) {
    return TemplateGenerationException(
      'Generation timed out after ${timeoutMs}ms',
      stage: GenerationStage.aiGeneration,
      context: context ?? {},
    );
  }
  
  /// Creates a generation exception for schema validation failures
  factory TemplateGenerationException.schemaValidation(String reason, {Map<String, dynamic>? context}) {
    return TemplateGenerationException(
      'Schema validation failed: $reason',
      stage: GenerationStage.schemaValidation,
      context: context ?? {},
    );
  }
  
  /// Creates a generation exception for performance issues
  factory TemplateGenerationException.performance(String reason, {Map<String, dynamic>? context}) {
    return TemplateGenerationException(
      'Performance issue: $reason',
      stage: GenerationStage.optimization,
      context: context ?? {},
    );
  }
  
  /// Creates a generation exception for combination generation failures
  factory TemplateGenerationException.combinationGeneration(String reason, {Object? originalException, Map<String, dynamic>? context}) {
    return TemplateGenerationException(
      'Combination generation failed: $reason',
      originalException: originalException,
      stage: GenerationStage.combinationGeneration,
      context: context ?? {},
    );
  }
  
  /// Creates a generation exception for widget template generation failures
  factory TemplateGenerationException.widgetGeneration(String reason, {Object? originalException, Map<String, dynamic>? context}) {
    return TemplateGenerationException(
      'Widget template generation failed: $reason',
      originalException: originalException,
      stage: GenerationStage.widgetGeneration,
      context: context ?? {},
    );
  }
  
  /// Creates a generation exception for schema conversion failures
  factory TemplateGenerationException.schemaConversion(String reason, {Object? originalException, Map<String, dynamic>? context}) {
    return TemplateGenerationException(
      'Schema conversion failed: $reason',
      originalException: originalException,
      stage: GenerationStage.schemaConversion,
      context: context ?? {},
    );
  }
  
  /// Creates a generation exception for script orchestration failures
  factory TemplateGenerationException.scriptOrchestration(String reason, {Object? originalException, Map<String, dynamic>? context}) {
    return TemplateGenerationException(
      'Script orchestration failed: $reason',
      originalException: originalException,
      stage: GenerationStage.scriptOrchestration,
      context: context ?? {},
    );
  }
  
  @override
  String toString() {
    final buffer = StringBuffer('TemplateGenerationException: $message');
    
    buffer.write(' (stage: ${stage.name})');
    
    if (context.isNotEmpty) {
      final contextStr = context.entries
          .where((e) => e.value != null)
          .map((e) => '${e.key}: ${e.value}')
          .join(', ');
      if (contextStr.isNotEmpty) {
        buffer.write(' [context: $contextStr]');
      }
    }
    
    if (originalException != null) {
      buffer.write('\nCaused by: $originalException');
    }
    
    return buffer.toString();
  }
}

/// Stages of template generation where errors can occur
enum GenerationStage {
  validation,
  aiGeneration,
  schemaValidation,
  optimization,
  postProcessing,
  // Integration script specific stages
  combinationGeneration,
  widgetGeneration,
  schemaConversion,
  scriptOrchestration,
}