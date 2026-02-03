/// Exception thrown when accessibility requirements cannot be met.
/// 
/// This exception provides detailed information about accessibility failures
/// and suggests possible solutions or adjustments.
class AccessibilityException implements Exception {
  /// The error message describing what accessibility requirement failed
  final String message;
  
  /// The type of accessibility requirement that failed
  final AccessibilityRequirementType requirementType;
  
  /// The UI element that failed the accessibility check
  final String? elementName;
  
  /// The specific accessibility standard that was not met
  final AccessibilityStandard standard;
  
  /// Current value that failed the requirement
  final String? currentValue;
  
  /// Required value to meet the accessibility standard
  final String? requiredValue;
  
  /// Suggested adjustments to fix the accessibility issue
  final List<String> suggestedAdjustments;
  
  /// Additional context about the accessibility failure
  final Map<String, dynamic> context;
  
  const AccessibilityException(
    this.message, {
    required this.requirementType,
    this.elementName,
    required this.standard,
    this.currentValue,
    this.requiredValue,
    this.suggestedAdjustments = const [],
    this.context = const {},
  });
  
  /// Creates an accessibility exception for contrast ratio failures
  factory AccessibilityException.contrastRatio({
    required String elementName,
    required double currentRatio,
    required double requiredRatio,
    required AccessibilityStandard standard,
    Map<String, dynamic>? context,
  }) {
    return AccessibilityException(
      'Contrast ratio ${currentRatio.toStringAsFixed(2)}:1 does not meet ${standard.name} requirement of ${requiredRatio.toStringAsFixed(2)}:1 for $elementName',
      requirementType: AccessibilityRequirementType.contrastRatio,
      elementName: elementName,
      standard: standard,
      currentValue: '${currentRatio.toStringAsFixed(2)}:1',
      requiredValue: '${requiredRatio.toStringAsFixed(2)}:1',
      suggestedAdjustments: [
        'Increase color brightness difference',
        'Use darker background or lighter text',
        'Choose colors with higher luminance contrast',
        'Consider using system colors for better accessibility',
      ],
      context: context ?? {},
    );
  }
  
  /// Creates an accessibility exception for color blindness issues
  factory AccessibilityException.colorBlindness({
    required String elementName,
    required String colorBlindnessType,
    Map<String, dynamic>? context,
  }) {
    return AccessibilityException(
      'Color combination in $elementName may not be distinguishable for users with $colorBlindnessType',
      requirementType: AccessibilityRequirementType.colorBlindness,
      elementName: elementName,
      standard: AccessibilityStandard.wcagAA,
      suggestedAdjustments: [
        'Add non-color indicators (icons, patterns, text)',
        'Increase contrast between colors',
        'Use color-blind friendly palette',
        'Test with color blindness simulators',
      ],
      context: context ?? {},
    );
  }
  
  /// Creates an accessibility exception for focus indicator issues
  factory AccessibilityException.focusIndicator({
    required String elementName,
    Map<String, dynamic>? context,
  }) {
    return AccessibilityException(
      'Focus indicator for $elementName does not meet visibility requirements',
      requirementType: AccessibilityRequirementType.focusIndicator,
      elementName: elementName,
      standard: AccessibilityStandard.wcagAA,
      suggestedAdjustments: [
        'Add visible focus outline',
        'Increase focus indicator contrast',
        'Use system focus indicators',
        'Ensure focus indicator is at least 2px thick',
      ],
      context: context ?? {},
    );
  }
  
  /// Creates an accessibility exception for touch target size issues
  factory AccessibilityException.touchTargetSize({
    required String elementName,
    required double currentSize,
    required double requiredSize,
    Map<String, dynamic>? context,
  }) {
    return AccessibilityException(
      'Touch target size ${currentSize}dp for $elementName is below the required ${requiredSize}dp',
      requirementType: AccessibilityRequirementType.touchTargetSize,
      elementName: elementName,
      standard: AccessibilityStandard.wcagAA,
      currentValue: '${currentSize}dp',
      requiredValue: '${requiredSize}dp',
      suggestedAdjustments: [
        'Increase button/touch area size',
        'Add padding around interactive elements',
        'Use minimum 44dp touch targets',
        'Ensure adequate spacing between interactive elements',
      ],
      context: context ?? {},
    );
  }
  
  /// Creates an accessibility exception for text readability issues
  factory AccessibilityException.textReadability({
    required String elementName,
    required String issue,
    Map<String, dynamic>? context,
  }) {
    return AccessibilityException(
      'Text readability issue in $elementName: $issue',
      requirementType: AccessibilityRequirementType.textReadability,
      elementName: elementName,
      standard: AccessibilityStandard.wcagAA,
      suggestedAdjustments: [
        'Increase font size',
        'Improve text contrast',
        'Use readable font families',
        'Ensure adequate line spacing',
        'Avoid text over complex backgrounds',
      ],
      context: context ?? {},
    );
  }
  
  @override
  String toString() {
    final buffer = StringBuffer('AccessibilityException: $message');
    
    buffer.write(' (${requirementType.name} - ${standard.name})');
    
    if (currentValue != null && requiredValue != null) {
      buffer.write(' [current: $currentValue, required: $requiredValue]');
    }
    
    if (suggestedAdjustments.isNotEmpty) {
      buffer.write('\nSuggested adjustments:');
      for (int i = 0; i < suggestedAdjustments.length; i++) {
        buffer.write('\n  ${i + 1}. ${suggestedAdjustments[i]}');
      }
    }
    
    return buffer.toString();
  }
}

/// Types of accessibility requirements
enum AccessibilityRequirementType {
  contrastRatio,
  colorBlindness,
  focusIndicator,
  touchTargetSize,
  textReadability,
  keyboardNavigation,
  screenReader,
}

/// Accessibility standards
enum AccessibilityStandard {
  wcagA,
  wcagAA,
  wcagAAA,
  section508,
  ada,
}