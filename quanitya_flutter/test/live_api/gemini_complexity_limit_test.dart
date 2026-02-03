import 'dart:convert';
import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:quanitya_flutter/infrastructure/llm/services/schema_translator.dart';

import 'live_api_test_helper.dart';

/// Test to systematically find Gemini's complexity limits for JSON Schema generation.
/// 
/// This test creates schemas with increasing complexity and measures:
/// - Success rate
/// - Response time
/// - Quality of generated JSON
/// 
/// Goal: Find the optimal complexity level for reliable Gemini performance.
/// 
/// Skipped automatically if GEMINI_API_KEY is not found in .env
void main() {
  group('Gemini Complexity Limit Tests', () {
    String? geminiApiKey;
    bool shouldSkip = false;

    setUpAll(() async {
      await LiveApiTestHelper.loadEnv();
      if (!LiveApiTestHelper.hasGeminiKey) {
        shouldSkip = true;
        markTestSkipped(LiveApiTestHelper.skipGeminiMessage);
        return;
      }
      geminiApiKey = LiveApiTestHelper.geminiApiKey;
      print('✅ Gemini API Key loaded');
    });

    test('Test complexity levels from 100 to 10,000 combinations', () async {
      if (shouldSkip || geminiApiKey == null) {
        markTestSkipped(LiveApiTestHelper.skipGeminiMessage);
        return;
      }
      
      final results = <ComplexityTestResult>[];
      
      // Test different complexity levels
      final complexityLevels = [
        100,    // Very simple
        500,    // Simple
        1000,   // Target level
        2500,   // Medium
        5000,   // Complex
        10000,  // Very complex
      ];
      
      for (final targetCombinations in complexityLevels) {
        print('\n🧪 Testing complexity level: ~$targetCombinations combinations');
        
        final schema = _generateSchemaWithComplexity(targetCombinations);
        final actualCombinations = _calculateCombinations(schema);
        
        print('   Generated schema with ~$actualCombinations actual combinations');
        
        final result = await _testSchemaWithGemini(
          schema, 
          targetCombinations, 
          actualCombinations,
          geminiApiKey!,
        );
        
        results.add(result);
        
        // Print immediate results
        print('   Result: ${result.success ? "✅ SUCCESS" : "❌ FAILED"}');
        if (result.success) {
          print('   Response time: ${result.responseTimeMs}ms');
          print('   JSON quality: ${result.jsonQuality}');
        } else {
          print('   Error: ${result.errorMessage}');
        }
        
        // Add delay between tests to avoid rate limiting
        await Future.delayed(Duration(seconds: 2));
      }
      
      // Analyze results
      _analyzeResults(results);
    });

    test('Fine-tune optimal range (500-1500 combinations)', () async {
      if (shouldSkip || geminiApiKey == null) {
        markTestSkipped(LiveApiTestHelper.skipGeminiMessage);
        return;
      }
      
      final results = <ComplexityTestResult>[];
      
      // Test finer granularity in the promising range
      final fineTuneLevels = [500, 750, 1000, 1250, 1500];
      
      for (final targetCombinations in fineTuneLevels) {
        print('\n🔬 Fine-tuning test: ~$targetCombinations combinations');
        
        final schema = _generateSchemaWithComplexity(targetCombinations);
        final actualCombinations = _calculateCombinations(schema);
        
        // Run multiple attempts to get success rate
        int successCount = 0;
        final attempts = 3;
        
        for (int i = 0; i < attempts; i++) {
          final result = await _testSchemaWithGemini(
            schema, 
            targetCombinations, 
            actualCombinations,
            geminiApiKey!,
          );
          
          if (result.success) successCount++;
          
          if (i == 0) results.add(result); // Store first result
          
          await Future.delayed(Duration(seconds: 1));
        }
        
        final successRate = (successCount / attempts * 100).round();
        print('   Success rate: $successRate% ($successCount/$attempts)');
      }
    });
  });
}

/// Generates a JSON Schema with approximately the target number of combinations
Map<String, dynamic> _generateSchemaWithComplexity(int targetCombinations) {
  // Calculate how to distribute complexity across different schema parts
  final fieldCount = min(10, sqrt(targetCombinations / 10).round());
  final enumOptionsPerField = min(8, (targetCombinations / fieldCount / 5).round());
  final colorOptions = min(6, (targetCombinations / 100).round());
  
  return {
    "type": "object",
    "properties": {
      "templateName": {
        "type": "string",
        "description": "Name of the tracker template"
      },
      "fields": {
        "type": "array",
        "maxItems": fieldCount,
        "items": {
          "type": "object",
          "properties": {
            "fieldType": {
              "type": "string",
              "enum": _generateFieldTypes(enumOptionsPerField)
            },
            "label": {
              "type": "string"
            },
            "uiElement": {
              "type": "string", 
              "enum": _generateUiElements(enumOptionsPerField)
            },
            "required": {
              "type": "boolean"
            }
          },
          "required": ["fieldType", "label", "uiElement"]
        }
      },
      "styling": {
        "type": "object",
        "properties": {
          "primaryColor": {
            "type": "string",
            "enum": _generateColorOptions(colorOptions)
          },
          "fontWeight": {
            "type": "integer",
            "enum": [100, 200, 300, 400, 500, 600, 700, 800, 900]
          }
        }
      }
    },
    "required": ["templateName", "fields"]
  };
}

List<String> _generateFieldTypes(int count) {
  final baseTypes = ["text", "number", "boolean", "date", "time", "rating", "multipleChoice", "slider"];
  final result = <String>[];
  
  for (int i = 0; i < count && i < baseTypes.length; i++) {
    result.add(baseTypes[i]);
  }
  
  // Add numbered variants if we need more
  while (result.length < count) {
    result.add("customType${result.length - baseTypes.length + 1}");
  }
  
  return result;
}

List<String> _generateUiElements(int count) {
  final baseElements = ["textField", "slider", "checkbox", "datePicker", "dropdown", "radio", "toggle", "stepper"];
  final result = <String>[];
  
  for (int i = 0; i < count && i < baseElements.length; i++) {
    result.add(baseElements[i]);
  }
  
  while (result.length < count) {
    result.add("customElement${result.length - baseElements.length + 1}");
  }
  
  return result;
}

List<String> _generateColorOptions(int count) {
  final colors = ["#FF0000", "#00FF00", "#0000FF", "#FFFF00", "#FF00FF", "#00FFFF"];
  final result = <String>[];
  
  for (int i = 0; i < count && i < colors.length; i++) {
    result.add(colors[i]);
  }
  
  return result;
}

/// Calculates approximate number of valid combinations in a schema
int _calculateCombinations(Map<String, dynamic> schema) {
  int total = 1;
  
  final properties = schema['properties'] as Map<String, dynamic>?;
  if (properties == null) return 1;
  
  for (final prop in properties.values) {
    if (prop is Map<String, dynamic>) {
      if (prop['type'] == 'array') {
        final maxItems = prop['maxItems'] as int? ?? 5;
        final items = prop['items'] as Map<String, dynamic>?;
        
        if (items != null && items['properties'] != null) {
          final itemProps = items['properties'] as Map<String, dynamic>;
          int itemCombinations = 1;
          
          for (final itemProp in itemProps.values) {
            if (itemProp is Map<String, dynamic> && itemProp.containsKey('enum')) {
              final enumValues = itemProp['enum'] as List;
              itemCombinations *= enumValues.length;
            }
          }
          
          // Approximate: sum of combinations for 1 to maxItems
          int arrayCombinations = 0;
          for (int i = 1; i <= maxItems; i++) {
            arrayCombinations += pow(itemCombinations, i).toInt();
            if (arrayCombinations > 100000) break; // Cap to avoid overflow
          }
          
          total *= min(arrayCombinations, 10000);
        }
      } else if (prop['type'] == 'object') {
        final objProps = prop['properties'] as Map<String, dynamic>?;
        if (objProps != null) {
          int objCombinations = 1;
          
          for (final objProp in objProps.values) {
            if (objProp is Map<String, dynamic> && objProp.containsKey('enum')) {
              final enumValues = objProp['enum'] as List;
              objCombinations *= enumValues.length;
            }
          }
          
          total *= objCombinations;
        }
      }
    }
  }
  
  return total;
}

/// Tests a schema with Gemini and measures performance
Future<ComplexityTestResult> _testSchemaWithGemini(
  Map<String, dynamic> schema,
  int targetCombinations,
  int actualCombinations,
  String geminiApiKey,
) async {
  final stopwatch = Stopwatch()..start();
  
  try {
    // Translate schema for Gemini
    final translator = GeminiSchemaTranslator();
    final translatedSchema = translator.translateSchema(schema);
    
    // Create a simple prompt
    final prompt = '''
Generate a JSON object that matches this schema. Create a realistic tracker template with 2-3 fields.

Return only valid JSON, no explanations.
''';

    // Test with Gemini using the same pattern as your existing test
    final response = await _callGeminiAPI(geminiApiKey, prompt, translatedSchema);
    stopwatch.stop();
    
    // Validate response
    final jsonQuality = _validateJsonResponse(response, translatedSchema);
    
    return ComplexityTestResult(
      targetCombinations: targetCombinations,
      actualCombinations: actualCombinations,
      success: jsonQuality > 0.5,
      responseTimeMs: stopwatch.elapsedMilliseconds,
      jsonQuality: jsonQuality,
      errorMessage: null,
    );
    
  } catch (e) {
    stopwatch.stop();
    
    return ComplexityTestResult(
      targetCombinations: targetCombinations,
      actualCombinations: actualCombinations,
      success: false,
      responseTimeMs: stopwatch.elapsedMilliseconds,
      jsonQuality: 0.0,
      errorMessage: e.toString(),
    );
  }
}

/// Call Gemini API with translated schema (same as your existing test)
Future<Map<String, dynamic>> _callGeminiAPI(
  String apiKey,
  String prompt,
  Map<String, dynamic> schema,
) async {
  final url = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash-exp:generateContent?key=$apiKey';
  
  final requestBody = {
    'contents': [
      {
        'parts': [
          {'text': prompt}
        ]
      }
    ],
    'generationConfig': {
      'responseMimeType': 'application/json',
      'responseJsonSchema': schema,
    },
  };
  
  final response = await http.post(
    Uri.parse(url),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode(requestBody),
  );
  
  if (response.statusCode != 200) {
    throw Exception('Gemini API Error ${response.statusCode}: ${response.body}');
  }
  
  final data = jsonDecode(response.body);
  final textContent = data['candidates'][0]['content']['parts'][0]['text'] as String;
  return jsonDecode(textContent) as Map<String, dynamic>;
}

/// Validates JSON response quality (0.0 = invalid, 1.0 = perfect)
double _validateJsonResponse(Map<String, dynamic> response, Map<String, dynamic> schema) {
  try {
    // Response is already parsed JSON from Gemini API
    double score = 0.5; // Base score for valid JSON
    
    // Check required fields
    final required = schema['required'] as List?;
    if (required != null) {
      int requiredFound = 0;
      for (final field in required) {
        if (response.containsKey(field)) requiredFound++;
      }
      score += (requiredFound / required.length) * 0.3;
    }
    
    // Check field types match
    final properties = schema['properties'] as Map<String, dynamic>?;
    if (properties != null) {
      int typeMatches = 0;
      int totalChecks = 0;
      
      for (final entry in properties.entries) {
        if (response.containsKey(entry.key)) {
          totalChecks++;
          final expectedType = entry.value['type'];
          final actualValue = response[entry.key];
          
          bool typeMatched = false;
          switch (expectedType) {
            case 'string':
              typeMatched = actualValue is String;
              break;
            case 'integer':
            case 'number':
              typeMatched = actualValue is num;
              break;
            case 'boolean':
              typeMatched = actualValue is bool;
              break;
            case 'array':
              typeMatched = actualValue is List;
              break;
            case 'object':
              typeMatched = actualValue is Map;
              break;
          }
          
          if (typeMatched) typeMatches++;
        }
      }
      
      if (totalChecks > 0) {
        score += (typeMatches / totalChecks) * 0.2;
      }
    }
    
    return min(score, 1.0);
    
  } catch (e) {
    return 0.0; // Invalid JSON
  }
}

void _analyzeResults(List<ComplexityTestResult> results) {
  print('\n📊 COMPLEXITY ANALYSIS RESULTS');
  print('=' * 60);
  
  final successful = results.where((r) => r.success).toList();
  final failed = results.where((r) => !r.success).toList();
  
  print('✅ Successful tests: ${successful.length}/${results.length}');
  print('❌ Failed tests: ${failed.length}/${results.length}');
  
  if (successful.isNotEmpty) {
    final maxSuccessfulComplexity = successful.map((r) => r.actualCombinations).reduce(max);
    final avgResponseTime = successful.map((r) => r.responseTimeMs).reduce((a, b) => a + b) / successful.length;
    final avgQuality = successful.map((r) => r.jsonQuality).reduce((a, b) => a + b) / successful.length;
    
    print('\n🎯 OPTIMAL RANGE FOUND:');
    print('   Max successful complexity: $maxSuccessfulComplexity combinations');
    print('   Average response time: ${avgResponseTime.round()}ms');
    print('   Average JSON quality: ${(avgQuality * 100).round()}%');
    
    // Find the sweet spot
    final sweetSpot = successful
        .where((r) => r.jsonQuality > 0.8 && r.responseTimeMs < 10000)
        .toList();
    
    if (sweetSpot.isNotEmpty) {
      final optimalComplexity = sweetSpot.map((r) => r.actualCombinations).reduce(max);
      print('\n🏆 RECOMMENDED COMPLEXITY LIMIT: $optimalComplexity combinations');
    }
  }
  
  if (failed.isNotEmpty) {
    final minFailedComplexity = failed.map((r) => r.actualCombinations).reduce(min);
    print('\n⚠️  Failures start at: $minFailedComplexity combinations');
    
    // Show common error patterns
    final errorTypes = <String, int>{};
    for (final result in failed) {
      if (result.errorMessage != null) {
        final errorType = result.errorMessage!.split(':').first;
        errorTypes[errorType] = (errorTypes[errorType] ?? 0) + 1;
      }
    }
    
    if (errorTypes.isNotEmpty) {
      print('\n🔍 Common error patterns:');
      for (final entry in errorTypes.entries) {
        print('   ${entry.key}: ${entry.value} occurrences');
      }
    }
  }
}

class ComplexityTestResult {
  final int targetCombinations;
  final int actualCombinations;
  final bool success;
  final int responseTimeMs;
  final double jsonQuality;
  final String? errorMessage;

  ComplexityTestResult({
    required this.targetCombinations,
    required this.actualCombinations,
    required this.success,
    required this.responseTimeMs,
    required this.jsonQuality,
    this.errorMessage,
  });
}