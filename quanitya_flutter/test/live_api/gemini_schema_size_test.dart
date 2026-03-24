import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:quanitya_flutter/infrastructure/llm/services/schema_translator.dart';

import 'live_api_test_helper.dart';

/// Test to find optimal schema size for Gemini by measuring actual schema complexity
/// rather than theoretical combinations.
@Tags(['live_api'])
void main() {
  group('Gemini Schema Size Tests', () {
    String? geminiApiKey;
    bool hasApiKey = false;

    setUpAll(() async {
      await LiveApiTestHelper.loadEnv();
      hasApiKey = LiveApiTestHelper.hasGeminiKey;
      
      if (!hasApiKey) return;
      
      geminiApiKey = LiveApiTestHelper.geminiApiKey;
      print('✅ Gemini API Key loaded');
    });

    test('Test schema sizes from simple to complex', () async {
      final results = <SchemaTestResult>[];
      
      // Test schemas with increasing actual size/complexity
      final testSchemas = [
        ('Minimal Schema', _createMinimalSchema()),
        ('Simple Schema', _createSimpleSchema()),
        ('Medium Schema', _createMediumSchema()),
        ('Complex Schema', _createComplexSchema()),
        ('Your Current Schema (Simplified)', _createYourSchemaSimplified()),
        ('Your Current Schema (Full)', _createYourSchemaFull()),
      ];
      
      for (final (name, schema) in testSchemas) {
        print('\n🧪 Testing: $name');
        
        final schemaSize = _calculateSchemaSize(schema);
        print('   Schema size: $schemaSize characters');
        print('   Properties: ${_countProperties(schema)}');
        print('   Enum values: ${_countEnumValues(schema)}');
        
        final result = await _testSchemaReliability(name, schema, geminiApiKey!);
        results.add(result);

        print('   Success rate: ${result.successRate}%');
        print('   Avg response time: ${result.avgResponseTime}ms');
        print('   Avg quality: ${(result.avgQuality * 100).round()}%');
        
        if (result.errors.isNotEmpty) {
          print('   Errors: ${result.errors.join(", ")}');
        }
        
        // Delay between tests
        await Future.delayed(Duration(seconds: 1));
      }
      
      _analyzeSchemaResults(results);
    }, skip: !hasApiKey ? 'GEMINI_API_KEY not found in .env' : null);
  });
}

/// Test schema reliability with multiple attempts
Future<SchemaTestResult> _testSchemaReliability(
  String name,
  Map<String, dynamic> schema,
  String apiKey,
) async {
  final attempts = 1;
  final results = <SingleTestResult>[];
  
  for (int i = 0; i < attempts; i++) {
    try {
      final stopwatch = Stopwatch()..start();
      
      final translator = GeminiSchemaTranslator();
      final translatedSchema = translator.translateSchema(schema);
      
      final prompt = 'Generate a realistic example that matches this schema. Use appropriate values.';
      final response = await _callGeminiAPI(apiKey, prompt, translatedSchema);
      
      stopwatch.stop();
      
      final quality = _validateResponse(response, translatedSchema);
      
      results.add(SingleTestResult(
        success: true,
        responseTime: stopwatch.elapsedMilliseconds,
        quality: quality,
        error: null,
      ));
      
    } catch (e) {
      results.add(SingleTestResult(
        success: false,
        responseTime: 0,
        quality: 0.0,
        error: e.toString(),
      ));
    }
    
    // Small delay between attempts
    await Future.delayed(Duration(milliseconds: 500));
  }
  
  final successful = results.where((r) => r.success).toList();
  final errors = results.where((r) => !r.success).map((r) => r.error!).toSet().toList();
  
  return SchemaTestResult(
    name: name,
    successRate: (successful.length / attempts * 100).round(),
    avgResponseTime: successful.isEmpty ? 0 : 
        (successful.map((r) => r.responseTime).reduce((a, b) => a + b) / successful.length).round(),
    avgQuality: successful.isEmpty ? 0.0 :
        successful.map((r) => r.quality).reduce((a, b) => a + b) / successful.length,
    errors: errors,
  );
}


/// Create minimal schema (baseline)
Map<String, dynamic> _createMinimalSchema() {
  return {
    "type": "object",
    "properties": {
      "name": {"type": "string"},
      "value": {"type": "integer"}
    },
    "required": ["name", "value"]
  };
}

/// Create simple schema (~10 properties)
Map<String, dynamic> _createSimpleSchema() {
  return {
    "type": "object",
    "properties": {
      "templateName": {"type": "string"},
      "description": {"type": "string"},
      "isActive": {"type": "boolean"},
      "priority": {"type": "integer", "minimum": 1, "maximum": 5},
      "category": {"type": "string", "enum": ["health", "fitness", "work", "personal"]},
      "fields": {
        "type": "array",
        "maxItems": 3,
        "items": {
          "type": "object",
          "properties": {
            "name": {"type": "string"},
            "type": {"type": "string", "enum": ["text", "number", "boolean"]}
          },
          "required": ["name", "type"]
        }
      }
    },
    "required": ["templateName", "fields"]
  };
}

/// Create medium schema (~20 properties)
Map<String, dynamic> _createMediumSchema() {
  return {
    "type": "object",
    "properties": {
      "templateName": {"type": "string"},
      "description": {"type": "string"},
      "isActive": {"type": "boolean"},
      "priority": {"type": "integer", "minimum": 1, "maximum": 10},
      "category": {"type": "string", "enum": ["health", "fitness", "work", "personal", "education", "finance"]},
      "tags": {"type": "array", "maxItems": 5, "items": {"type": "string"}},
      "fields": {
        "type": "array",
        "maxItems": 5,
        "items": {
          "type": "object",
          "properties": {
            "name": {"type": "string"},
            "type": {"type": "string", "enum": ["text", "number", "boolean", "date", "time"]},
            "required": {"type": "boolean"},
            "defaultValue": {"type": "string"},
            "validation": {
              "type": "object",
              "properties": {
                "minLength": {"type": "integer"},
                "maxLength": {"type": "integer"},
                "pattern": {"type": "string"}
              }
            }
          },
          "required": ["name", "type"]
        }
      },
      "styling": {
        "type": "object",
        "properties": {
          "primaryColor": {"type": "string"},
          "secondaryColor": {"type": "string"},
          "fontFamily": {"type": "string", "enum": ["Arial", "Helvetica", "Times", "Courier"]},
          "fontSize": {"type": "integer", "minimum": 8, "maximum": 72}
        }
      }
    },
    "required": ["templateName", "fields"]
  };
}


/// Create complex schema (~40+ properties)
Map<String, dynamic> _createComplexSchema() {
  return {
    "type": "object",
    "properties": {
      "templateName": {"type": "string"},
      "description": {"type": "string"},
      "version": {"type": "string"},
      "isActive": {"type": "boolean"},
      "priority": {"type": "integer", "minimum": 1, "maximum": 10},
      "category": {"type": "string", "enum": ["health", "fitness", "work", "personal", "education", "finance", "travel", "hobbies"]},
      "subcategory": {"type": "string"},
      "tags": {"type": "array", "maxItems": 10, "items": {"type": "string"}},
      "metadata": {
        "type": "object",
        "properties": {
          "createdBy": {"type": "string"},
          "createdAt": {"type": "string"},
          "lastModified": {"type": "string"},
          "permissions": {
            "type": "object",
            "properties": {
              "read": {"type": "array", "items": {"type": "string"}},
              "write": {"type": "array", "items": {"type": "string"}},
              "admin": {"type": "array", "items": {"type": "string"}}
            }
          }
        }
      },
      "fields": {
        "type": "array",
        "maxItems": 10,
        "items": {
          "type": "object",
          "properties": {
            "id": {"type": "string"},
            "name": {"type": "string"},
            "type": {"type": "string", "enum": ["text", "number", "boolean", "date", "time", "datetime", "email", "url", "phone"]},
            "required": {"type": "boolean"},
            "defaultValue": {"type": "string"},
            "placeholder": {"type": "string"},
            "helpText": {"type": "string"},
            "validation": {
              "type": "object",
              "properties": {
                "minLength": {"type": "integer"},
                "maxLength": {"type": "integer"},
                "minValue": {"type": "number"},
                "maxValue": {"type": "number"},
                "pattern": {"type": "string"},
                "customRules": {"type": "array", "items": {"type": "string"}}
              }
            },
            "uiConfig": {
              "type": "object",
              "properties": {
                "widget": {"type": "string", "enum": ["textField", "textArea", "slider", "checkbox", "radio", "dropdown", "datePicker"]},
                "width": {"type": "string", "enum": ["full", "half", "third", "quarter"]},
                "order": {"type": "integer"},
                "conditional": {
                  "type": "object",
                  "properties": {
                    "dependsOn": {"type": "string"},
                    "condition": {"type": "string", "enum": ["equals", "notEquals", "contains", "greaterThan", "lessThan"]},
                    "value": {"type": "string"}
                  }
                }
              }
            }
          },
          "required": ["id", "name", "type"]
        }
      },
      "styling": {
        "type": "object",
        "properties": {
          "theme": {"type": "string", "enum": ["light", "dark", "auto"]},
          "primaryColor": {"type": "string"},
          "secondaryColor": {"type": "string"},
          "accentColor": {"type": "string"},
          "backgroundColor": {"type": "string"},
          "textColor": {"type": "string"},
          "fontFamily": {"type": "string", "enum": ["Arial", "Helvetica", "Times", "Courier", "Georgia", "Verdana"]},
          "fontSize": {"type": "integer", "minimum": 8, "maximum": 72},
          "fontWeight": {"type": "integer", "enum": [100, 200, 300, 400, 500, 600, 700, 800, 900]},
          "borderRadius": {"type": "integer", "minimum": 0, "maximum": 50},
          "spacing": {"type": "string", "enum": ["compact", "normal", "relaxed"]},
          "animations": {"type": "boolean"}
        }
      },
      "layout": {
        "type": "object",
        "properties": {
          "type": {"type": "string", "enum": ["single-column", "two-column", "grid", "tabs"]},
          "sections": {
            "type": "array",
            "items": {
              "type": "object",
              "properties": {
                "title": {"type": "string"},
                "fields": {"type": "array", "items": {"type": "string"}},
                "collapsible": {"type": "boolean"},
                "defaultExpanded": {"type": "boolean"}
              }
            }
          }
        }
      }
    },
    "required": ["templateName", "fields"]
  };
}


/// Create simplified version of your current schema
Map<String, dynamic> _createYourSchemaSimplified() {
  return {
    "type": "object",
    "properties": {
      "templateName": {"type": "string"},
      "fields": {
        "type": "array",
        "maxItems": 5,
        "items": {
          "type": "object",
          "properties": {
            "fieldType": {"type": "string", "enum": ["text", "integer", "boolean", "datetime"]},
            "uiElement": {"type": "string", "enum": ["textField", "slider", "checkbox", "datePicker"]},
            "label": {"type": "string"}
          },
          "required": ["fieldType", "uiElement", "label"]
        }
      },
      "colorPalette": {
        "type": "object",
        "properties": {
          "colors": {"type": "array", "items": {"type": "string"}, "minItems": 2, "maxItems": 4}
        }
      },
      "fontWeight": {"type": "integer", "enum": [400, 600, 700]}
    },
    "required": ["templateName", "fields"]
  };
}

/// Create full version of your current schema (the problematic one)
Map<String, dynamic> _createYourSchemaFull() {
  return {
    "type": "object",
    "properties": {
      "fields": {
        "type": "object",
        "properties": {
          "fieldCombinations": {
            "type": "object",
            "properties": {
              "integer": {
                "oneOf": [
                  {
                    "type": "object",
                    "properties": {
                      "fieldType": {"type": "string", "const": "integer"},
                      "uiElement": {"type": "string", "const": "slider"},
                      "requiredValidators": {
                        "type": "array",
                        "items": {"type": "string", "enum": ["numeric"]},
                        "minItems": 1,
                        "maxItems": 1
                      }
                    },
                    "required": ["fieldType", "uiElement", "requiredValidators"]
                  },
                  {
                    "type": "object",
                    "properties": {
                      "fieldType": {"type": "string", "const": "integer"},
                      "uiElement": {"type": "string", "const": "textField"},
                      "requiredValidators": {
                        "type": "array",
                        "items": {"type": "string", "enum": <String>[]},
                        "minItems": 0,
                        "maxItems": 0
                      }
                    },
                    "required": ["fieldType", "uiElement", "requiredValidators"]
                  }
                ]
              },
              "text": {
                "oneOf": [
                  {
                    "type": "object",
                    "properties": {
                      "fieldType": {"type": "string", "const": "text"},
                      "uiElement": {"type": "string", "const": "textField"},
                      "requiredValidators": {
                        "type": "array",
                        "items": {"type": "string", "enum": <String>[]},
                        "minItems": 0,
                        "maxItems": 0
                      }
                    },
                    "required": ["fieldType", "uiElement", "requiredValidators"]
                  }
                ]
              }
            }
          }
        }
      },
      "colorPalette": {
        "type": "object",
        "properties": {
          "colors": {"type": "array", "items": {"type": "string"}, "minItems": 2, "maxItems": 4},
          "neutrals": {"type": "array", "items": {"type": "string"}, "minItems": 2, "maxItems": 3}
        },
        "required": ["colors", "neutrals"]
      },
      "fontConfiguration": {
        "type": "object",
        "properties": {
          "titleWeight": {"type": "integer", "enum": [100, 200, 300, 400, 500, 600, 700, 800, 900]},
          "subtitleWeight": {"type": "integer", "enum": [100, 200, 300, 400, 500, 600, 700, 800, 900]},
          "bodyWeight": {"type": "integer", "enum": [100, 200, 300, 400, 500, 600, 700, 800, 900]}
        }
      }
    }
  };
}


int _calculateSchemaSize(Map<String, dynamic> schema) {
  return jsonEncode(schema).length;
}

int _countProperties(Map<String, dynamic> schema) {
  int count = 0;
  
  void countInObject(Map<String, dynamic> obj) {
    final properties = obj['properties'] as Map<String, dynamic>?;
    if (properties != null) {
      count += properties.length;
      for (final prop in properties.values) {
        if (prop is Map<String, dynamic>) {
          countInObject(prop);
          final items = prop['items'] as Map<String, dynamic>?;
          if (items != null) countInObject(items);
          final oneOf = prop['oneOf'] as List?;
          if (oneOf != null) {
            for (final item in oneOf) {
              if (item is Map<String, dynamic>) countInObject(item);
            }
          }
        }
      }
    }
  }
  
  countInObject(schema);
  return count;
}

int _countEnumValues(Map<String, dynamic> schema) {
  int count = 0;
  
  void countInObject(Map<String, dynamic> obj) {
    for (final value in obj.values) {
      if (value is Map<String, dynamic>) {
        final enumValues = value['enum'] as List?;
        if (enumValues != null) count += enumValues.length;
        countInObject(value);
        final items = value['items'] as Map<String, dynamic>?;
        if (items != null) countInObject(items);
        final oneOf = value['oneOf'] as List?;
        if (oneOf != null) {
          for (final item in oneOf) {
            if (item is Map<String, dynamic>) countInObject(item);
          }
        }
      } else if (value is List) {
        for (final item in value) {
          if (item is Map<String, dynamic>) countInObject(item);
        }
      }
    }
  }
  
  countInObject(schema);
  return count;
}

double _validateResponse(Map<String, dynamic> response, Map<String, dynamic> schema) {
  final required = schema['required'] as List?;
  if (required == null) return 1.0;
  
  int foundRequired = 0;
  for (final field in required) {
    if (response.containsKey(field)) foundRequired++;
  }
  
  return foundRequired / required.length;
}

/// Call Gemini API
Future<Map<String, dynamic>> _callGeminiAPI(
  String apiKey,
  String prompt,
  Map<String, dynamic> schema,
) async {
  final url = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash-exp:generateContent?key=$apiKey';
  
  final requestBody = {
    'contents': [{'parts': [{'text': prompt}]}],
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


void _analyzeSchemaResults(List<SchemaTestResult> results) {
  print('\n📊 SCHEMA SIZE ANALYSIS RESULTS');
  print('=' * 60);
  
  for (final result in results) {
    final status = result.successRate >= 80 ? '✅' : 
                   result.successRate >= 50 ? '⚠️' : '❌';
    print('$status ${result.name}: ${result.successRate}% success');
  }
  
  final reliable = results.where((r) => r.successRate >= 80).toList();
  final unreliable = results.where((r) => r.successRate < 50).toList();
  
  if (reliable.isNotEmpty) {
    print('\n🎯 RELIABLE SCHEMAS (≥80% success):');
    for (final result in reliable) {
      print('   ${result.name}: ${result.successRate}% (${result.avgResponseTime}ms avg)');
    }
  }
  
  if (unreliable.isNotEmpty) {
    print('\n⚠️ UNRELIABLE SCHEMAS (<50% success):');
    for (final result in unreliable) {
      print('   ${result.name}: ${result.successRate}%');
      if (result.errors.isNotEmpty) {
        print('     Common errors: ${result.errors.take(2).join(", ")}');
      }
    }
  }
  
  print('\n🏆 RECOMMENDATION:');
  if (reliable.isNotEmpty) {
    final best = reliable.reduce((a, b) => a.successRate > b.successRate ? a : b);
    print('   Use schema complexity similar to: ${best.name}');
    print('   Expected success rate: ${best.successRate}%');
    print('   Expected response time: ${best.avgResponseTime}ms');
  } else {
    print('   All tested schemas show reliability issues');
    print('   Consider further simplification');
  }
}

class SchemaTestResult {
  final String name;
  final int successRate;
  final int avgResponseTime;
  final double avgQuality;
  final List<String> errors;

  SchemaTestResult({
    required this.name,
    required this.successRate,
    required this.avgResponseTime,
    required this.avgQuality,
    required this.errors,
  });
}

class SingleTestResult {
  final bool success;
  final int responseTime;
  final double quality;
  final String? error;

  SingleTestResult({
    required this.success,
    required this.responseTime,
    required this.quality,
    this.error,
  });
}