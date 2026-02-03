/// Abstract interface for translating JSON Schema to provider-specific formats
abstract class ISchemaTranslator {
  /// Translate a full JSON Schema to provider-compatible format
  Map<String, dynamic> translateSchema(Map<String, dynamic> jsonSchema);
  
  /// Get the provider identifier this translator supports
  String get providerId;
  
  /// Check if a schema feature is supported by this provider
  bool supportsFeature(SchemaFeature feature);
}

/// Schema features that may or may not be supported by providers
enum SchemaFeature {
  multipleOf,
  constValue,
  oneOf,
  anyOf,
  allOf,
  pattern,
  format,
  additionalProperties,
  minItems,
  maxItems,
  minimum,
  maximum,
  enumValue,
  requiredFields,
}

/// Gemini-specific schema translator
class GeminiSchemaTranslator implements ISchemaTranslator {
  @override
  String get providerId => 'google';
  
  @override
  bool supportsFeature(SchemaFeature feature) {
    return switch (feature) {
      SchemaFeature.enumValue => true,
      SchemaFeature.minimum => true,
      SchemaFeature.maximum => true,
      SchemaFeature.minItems => true,
      SchemaFeature.maxItems => true,
      SchemaFeature.requiredFields => true,
      SchemaFeature.additionalProperties => true,
      SchemaFeature.format => true,
      // Unsupported features
      SchemaFeature.multipleOf => false,
      SchemaFeature.constValue => false,
      SchemaFeature.oneOf => false,
      SchemaFeature.anyOf => false,
      SchemaFeature.allOf => false,
      SchemaFeature.pattern => false,
    };
  }
  
  @override
  Map<String, dynamic> translateSchema(Map<String, dynamic> jsonSchema) {
    final translated = <String, dynamic>{};
    
    // Copy supported properties directly
    for (final entry in jsonSchema.entries) {
      switch (entry.key) {
        case 'type':
        case 'description':
        case 'title':
        case 'minimum':
        case 'maximum':
        case 'required':
        case 'additionalProperties':
        case 'format':
          translated[entry.key] = entry.value;
          break;
          
        case 'minItems':
        case 'maxItems':
          // Limit array sizes to prevent excessive state combinations
          if (entry.key == 'maxItems') {
            final maxItems = entry.value as int;
            translated[entry.key] = maxItems > 5 ? 5 : maxItems; // Cap at 5
          } else {
            translated[entry.key] = entry.value;
          }
          break;
          
        case 'properties':
          translated['properties'] = _translateProperties(entry.value as Map<String, dynamic>);
          break;
          
        case 'items':
          translated['items'] = translateSchema(entry.value as Map<String, dynamic>);
          break;
          
        case 'enum':
          // Limit enum options to prevent excessive state combinations
          final enumList = entry.value as List;
          translated['enum'] = enumList.length > 6 ? enumList.take(6).toList() : enumList;
          break;
          
        // Transform unsupported features
        case 'multipleOf':
          translated.addAll(_translateMultipleOf(entry.value as int, jsonSchema));
          break;
          
        case 'const':
          translated['enum'] = [entry.value];
          break;
          
        case 'oneOf':
          translated.addAll(_translateOneOf(entry.value as List, jsonSchema));
          break;
          
        case 'pattern':
          // Convert pattern to description guidance
          translated['description'] = _enhanceDescriptionWithPattern(
            jsonSchema['description'] as String?, 
            entry.value as String
          );
          break;
          
        // Skip unsupported properties
        case r'$schema':
          break;
          
        default:
          // Copy unknown properties (might be supported)
          translated[entry.key] = entry.value;
      }
    }
    
    return translated;
  }
  
  Map<String, dynamic> _translateProperties(Map<String, dynamic> properties) {
    final translated = <String, dynamic>{};
    for (final entry in properties.entries) {
      translated[entry.key] = translateSchema(entry.value as Map<String, dynamic>);
    }
    return translated;
  }
  
  Map<String, dynamic> _translateMultipleOf(int multipleOf, Map<String, dynamic> schema) {
    final min = schema['minimum'] as int? ?? 0;
    final max = schema['maximum'] as int? ?? 1000;
    
    // Generate enum values that are multiples
    final enumValues = <int>[];
    for (int i = min; i <= max; i += multipleOf) {
      enumValues.add(i);
    }
    
    return {'enum': enumValues};
  }
  
  Map<String, dynamic> _translateOneOf(List oneOfList, Map<String, dynamic> schema) {
    // For simple oneOf with const values, convert to enum
    final constValues = <dynamic>[];
    bool allConst = true;
    
    for (final option in oneOfList) {
      if (option is Map<String, dynamic> && option.containsKey('const')) {
        constValues.add(option['const']);
      } else {
        allConst = false;
        break;
      }
    }
    
    if (allConst && constValues.isNotEmpty) {
      return {'enum': constValues};
    }
    
    // For complex oneOf with objects that have properties with const values,
    // extract all unique values for each property and convert to enums.
    // This handles our flattened field combination pattern.
    if (_isFieldCombinationOneOf(oneOfList)) {
      return _translateFieldCombinationOneOf(oneOfList);
    }
    
    // For other complex oneOf, just take the first option and translate it normally
    // This avoids nesting depth issues by flattening the structure
    final firstOption = oneOfList.first as Map<String, dynamic>;
    final translated = translateSchema(firstOption);
    
    // Add description explaining the oneOf was simplified
    final optionCount = oneOfList.length;
    final existingDesc = translated['description'] as String?;
    final oneOfDesc = 'Supports $optionCount different patterns';
    
    translated['description'] = existingDesc != null 
        ? '$existingDesc. $oneOfDesc'
        : oneOfDesc;
    
    return translated;
  }
  
  /// Checks if this oneOf represents field combinations (objects with fieldType, uiElement, etc.)
  bool _isFieldCombinationOneOf(List oneOfList) {
    if (oneOfList.isEmpty) return false;
    
    final first = oneOfList.first;
    if (first is! Map<String, dynamic>) return false;
    
    final properties = first['properties'] as Map<String, dynamic>?;
    if (properties == null) return false;
    
    // Check if it has our field combination structure
    return properties.containsKey('fieldType') && 
           properties.containsKey('uiElement');
  }
  
  /// Translates field combination oneOf by converting to string enum of encoded combinations
  Map<String, dynamic> _translateFieldCombinationOneOf(List oneOfList) {
    // Extract all complete combination objects and encode as strings
    final validCombinations = <String>[];
    
    for (final option in oneOfList) {
      if (option is! Map<String, dynamic>) continue;
      
      final properties = option['properties'] as Map<String, dynamic>?;
      if (properties == null) continue;
      
      // Extract the const values to build the combination string
      final fieldTypeSchema = properties['fieldType'] as Map<String, dynamic>?;
      final uiElementSchema = properties['uiElement'] as Map<String, dynamic>?;
      final validatorsSchema = properties['requiredValidators'] as Map<String, dynamic>?;
      
      if (fieldTypeSchema != null && uiElementSchema != null && validatorsSchema != null) {
        final fieldType = fieldTypeSchema['const'];
        final uiElement = uiElementSchema['const'];
        
        // Extract validator enum values
        final items = validatorsSchema['items'] as Map<String, dynamic>?;
        final validatorEnums = items?['enum'] as List? ?? [];
        
        if (fieldType != null && uiElement != null) {
          // Encode as "fieldType|uiElement|validator1,validator2"
          final validatorsStr = validatorEnums.isEmpty ? 'none' : validatorEnums.join(',');
          validCombinations.add('$fieldType|$uiElement|$validatorsStr');
        }
      }
    }
    
    // Return as string enum
    return {
      'type': 'string',
      'enum': validCombinations,
      'description': 'Valid field combination encoded as "fieldType|uiElement|validators". '
          'Examples: "integer|slider|numeric", "text|textField|none", "enumerated|dropdown|enumerated". '
          'Choose one complete combination from the enum list.',
    };
  }
  
  String _enhanceDescriptionWithPattern(String? description, String pattern) {
    final patternDesc = switch (pattern) {
      r'^#[0-9A-Fa-f]{6}$' => 'Must be 6-digit hex color format (e.g., #FF0000)',
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$' => 'Must be valid email format',
      _ => 'Must match pattern: $pattern',
    };
    
    return description != null ? '$description. $patternDesc' : patternDesc;
  }
}

/// OpenAI-specific schema translator (supports full JSON Schema)
class OpenAISchemaTranslator implements ISchemaTranslator {
  @override
  String get providerId => 'openai';
  
  @override
  bool supportsFeature(SchemaFeature feature) {
    // OpenAI supports full JSON Schema
    return true;
  }
  
  @override
  Map<String, dynamic> translateSchema(Map<String, dynamic> jsonSchema) {
    // OpenAI supports full JSON Schema, so no translation needed
    return Map<String, dynamic>.from(jsonSchema);
  }
}

/// Anthropic-specific schema translator
class AnthropicSchemaTranslator implements ISchemaTranslator {
  @override
  String get providerId => 'anthropic';
  
  @override
  bool supportsFeature(SchemaFeature feature) {
    return switch (feature) {
      SchemaFeature.enumValue => true,
      SchemaFeature.minimum => true,
      SchemaFeature.maximum => true,
      SchemaFeature.minItems => true,
      SchemaFeature.maxItems => true,
      SchemaFeature.requiredFields => true,
      SchemaFeature.additionalProperties => true,
      SchemaFeature.pattern => true,
      // Limited support for complex features
      SchemaFeature.multipleOf => false,
      SchemaFeature.constValue => true,
      SchemaFeature.oneOf => true,
      SchemaFeature.anyOf => false,
      SchemaFeature.allOf => false,
      SchemaFeature.format => true,
    };
  }
  
  @override
  Map<String, dynamic> translateSchema(Map<String, dynamic> jsonSchema) {
    // Anthropic supports most JSON Schema features
    // Only need to handle multipleOf
    final translated = Map<String, dynamic>.from(jsonSchema);
    
    if (translated.containsKey('multipleOf')) {
      final multipleOf = translated.remove('multipleOf') as int;
      final min = translated['minimum'] as int? ?? 0;
      final max = translated['maximum'] as int? ?? 1000;
      
      final enumValues = <int>[];
      for (int i = min; i <= max; i += multipleOf) {
        enumValues.add(i);
      }
      translated['enum'] = enumValues;
    }
    
    return translated;
  }
}

/// Factory for creating schema translators
class SchemaTranslatorFactory {
  static final Map<String, ISchemaTranslator> _translators = {
    'google': GeminiSchemaTranslator(),
    'openai': OpenAISchemaTranslator(),
    'anthropic': AnthropicSchemaTranslator(),
  };
  
  static ISchemaTranslator getTranslator(String providerId) {
    final translator = _translators[providerId];
    if (translator == null) {
      throw UnsupportedError('No schema translator found for provider: $providerId');
    }
    return translator;
  }
  
  static ISchemaTranslator getTranslatorForModel(String model) {
    if (model.startsWith('google/') || model.startsWith('gemini')) {
      return _translators['google']!;
    } else if (model.startsWith('openai/') || model.startsWith('gpt')) {
      return _translators['openai']!;
    } else if (model.startsWith('anthropic/') || model.startsWith('claude')) {
      return _translators['anthropic']!;
    } else {
      // Default to OpenAI format for unknown models
      return _translators['openai']!;
    }
  }
}