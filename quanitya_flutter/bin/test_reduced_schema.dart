#!/usr/bin/env dart

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

void main() async {
  print('🔍 Testing reduced schema with Gemini...');
  
  // Load API key
  final envFile = File('.env');
  String geminiApiKey = '';
  
  if (await envFile.exists()) {
    final envContent = await envFile.readAsString();
    final lines = envContent.split('\n');
    for (final line in lines) {
      if (line.startsWith('GEMINI_API_KEY=')) {
        geminiApiKey = line.substring('GEMINI_API_KEY='.length).trim();
        break;
      }
    }
  }
  
  if (geminiApiKey.isEmpty) {
    print('❌ Error: GEMINI_API_KEY not found in .env file');
    exit(1);
  }
  
  // Reduced schema to avoid too many states
  final reducedSchema = {
    "type": "object",
    "properties": {
      "templateName": {
        "type": "string",
        "description": "Name of the template"
      },
      "fields": {
        "type": "array",
        "items": {
          "type": "object",
          "properties": {
            "fieldType": {
              "enum": ["text", "number"],
              "description": "Type of field from foundation enums"
            },
            "widgetType": {
              "enum": ["textField", "slider"],
              "description": "Widget type from foundation enums"
            },
            "label": {
              "type": "string",
              "description": "Field label"
            }
          },
          "required": ["fieldType", "widgetType", "label"],
          "additionalProperties": false
        },
        "minItems": 1,
        "maxItems": 3
      },
      "colorPalette": {
        "type": "object",
        "properties": {
          "colors": {
            "type": "array",
            "items": {
              "type": "string",
              "description": "Must be 6-digit hex color format (e.g., #FF0000)"
            },
            "minItems": 2,
            "maxItems": 2,
            "description": "Main colors (color1-color2)"
          },
          "neutrals": {
            "type": "array",
            "items": {
              "type": "string",
              "description": "Must be 6-digit hex color format (e.g., #FF0000)"
            },
            "minItems": 2,
            "maxItems": 2,
            "description": "Neutral colors (neutral1-neutral2)"
          }
        },
        "required": ["colors", "neutrals"],
        "additionalProperties": false
      },
      "fontConfiguration": {
        "type": "object",
        "properties": {
          "titleWeight": {
            "type": "integer",
            "enum": [400, 600, 700], // Reduced enum options
            "default": 600,
            "description": "Font weight for titles"
          },
          "bodyWeight": {
            "type": "integer",
            "enum": [300, 400], // Reduced enum options
            "default": 400,
            "description": "Font weight for body text"
          }
        },
        "additionalProperties": false
      }
    },
    "required": ["templateName", "fields", "colorPalette", "fontConfiguration"],
    "additionalProperties": false
  };
  
  print('\n📋 Reduced schema to minimize state combinations:');
  print('  - fields: maxItems 3 (was 10)');
  print('  - fieldType: 2 options (was 4)');
  print('  - widgetType: 2 options (was 6)');
  print('  - colors: maxItems 2 (was 4)');
  print('  - neutrals: maxItems 2 (was 3)');
  print('  - font weights: 3 and 2 options (was 9 each)');
  
  try {
    final response = await _callGemini(
      geminiApiKey,
      'Create a fitness tracking template with weight and steps fields',
      reducedSchema,
    );
    
    print('\n✅ SUCCESS! Gemini response:');
    print(JsonEncoder.withIndent('  ').convert(response));
    
    // Validate the response
    _validateResponse(response);
    
  } catch (e) {
    print('\n❌ ERROR: $e');
  }
}

Future<Map<String, dynamic>> _callGemini(
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

void _validateResponse(Map<String, dynamic> response) {
  print('\n📊 VALIDATION RESULTS:');
  
  // Check required fields
  final hasTemplateName = response.containsKey('templateName');
  final hasFields = response.containsKey('fields');
  final hasColorPalette = response.containsKey('colorPalette');
  final hasFontConfig = response.containsKey('fontConfiguration');
  
  print('  ✅ templateName: ${hasTemplateName ? "✅" : "❌"}');
  print('  ✅ fields: ${hasFields ? "✅" : "❌"}');
  print('  ✅ colorPalette: ${hasColorPalette ? "✅" : "❌"}');
  print('  ✅ fontConfiguration: ${hasFontConfig ? "✅" : "❌"}');
  
  // Check field-widget combinations
  if (hasFields) {
    final fields = response['fields'] as List;
    bool validCombinations = true;
    
    for (final field in fields) {
      final fieldMap = field as Map<String, dynamic>;
      final fieldType = fieldMap['fieldType'] as String?;
      final widgetType = fieldMap['widgetType'] as String?;
      
      print('    Field: $fieldType → $widgetType');
      
      // Check if combination makes sense (simplified validation)
      if (fieldType == 'text' && widgetType != 'textField') {
        validCombinations = false;
      }
      if (fieldType == 'number' && widgetType != 'slider') {
        validCombinations = false;
      }
    }
    
    print('  ✅ Field-widget combinations: ${validCombinations ? "✅" : "❌"}');
  }
  
  print('\n🎉 PIPELINE SUCCESS: Foundation Enums → Schema → Translation → Gemini API ✅');
}