/// Exception thrown when template rendering fails.
/// 
/// This exception provides detailed information about rendering failures
/// to help with debugging and error reporting.
class TemplateRenderingException implements Exception {
  /// The error message describing what went wrong
  final String message;
  
  /// The original exception that caused the rendering failure (if any)
  final Object? originalException;
  
  /// The stack trace from the original exception (if any)
  final StackTrace? stackTrace;
  
  /// The rendering stage where the error occurred
  final RenderingStage stage;
  
  /// The field that was being rendered when the error occurred (if applicable)
  final String? fieldId;
  
  /// Additional context about the rendering process
  final Map<String, dynamic> context;
  
  const TemplateRenderingException(
    this.message, {
    this.originalException,
    this.stackTrace,
    required this.stage,
    this.fieldId,
    this.context = const {},
  });
  
  /// Creates a rendering exception for widget creation failures
  factory TemplateRenderingException.widgetCreation(String fieldId, String reason, {Object? originalException, Map<String, dynamic>? context}) {
    return TemplateRenderingException(
      'Widget creation failed for field $fieldId: $reason',
      originalException: originalException,
      stage: RenderingStage.widgetCreation,
      fieldId: fieldId,
      context: context ?? {},
    );
  }
  
  /// Creates a rendering exception for color resolution failures
  factory TemplateRenderingException.colorResolution(String fieldId, String reason, {Map<String, dynamic>? context}) {
    return TemplateRenderingException(
      'Color resolution failed for field $fieldId: $reason',
      stage: RenderingStage.colorResolution,
      fieldId: fieldId,
      context: context ?? {},
    );
  }
  
  /// Creates a rendering exception for context creation failures
  factory TemplateRenderingException.contextCreation(String reason, {Object? originalException, Map<String, dynamic>? context}) {
    return TemplateRenderingException(
      'Rendering context creation failed: $reason',
      originalException: originalException,
      stage: RenderingStage.contextCreation,
      context: context ?? {},
    );
  }
  
  /// Creates a rendering exception for validation failures
  factory TemplateRenderingException.validation(String fieldId, String reason, {Map<String, dynamic>? context}) {
    return TemplateRenderingException(
      'Validation failed for field $fieldId: $reason',
      stage: RenderingStage.validation,
      fieldId: fieldId,
      context: context ?? {},
    );
  }
  
  /// Creates a rendering exception for accessibility failures
  factory TemplateRenderingException.accessibility(String reason, {String? fieldId, Map<String, dynamic>? context}) {
    return TemplateRenderingException(
      'Accessibility requirement failed: $reason',
      stage: RenderingStage.accessibility,
      fieldId: fieldId,
      context: context ?? {},
    );
  }
  
  @override
  String toString() {
    final buffer = StringBuffer('TemplateRenderingException: $message');
    
    buffer.write(' (stage: ${stage.name})');
    
    if (fieldId != null) {
      buffer.write(' [field: $fieldId]');
    }
    
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

/// Stages of template rendering where errors can occur
enum RenderingStage {
  contextCreation,
  colorResolution,
  validation,
  widgetCreation,
  accessibility,
  layout,
}