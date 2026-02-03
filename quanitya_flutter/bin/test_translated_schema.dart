#!/usr/bin/env dart

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

void main() async {
  print('🔍 Testing translated schema with Gemini...');
  
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
  
  // The translated schema from the previous test
  final translatedSchema = {
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
              "enum": [
                "text",
                "number",
                "boolean",
                "date"
              ],
              "description": "Type of field from foundation enums"
            },
            "widgetType": {
              "enum": [
                "textField",
                "textArea",
                "slider",
                "stepper",
                "checkbox",
                "datePicker"
              ],
              "description": "Widget type from foundation enums"
            },
            "label": {
              "type": "string",
              "description": "Field label"
            }
          },
          "required": [
            "fieldType",
            "widgetType",
            "label"
          ],
          "additionalProperties": false
        },
        "minItems": 1,
        "maxItems": 10
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
            "maxItems": 4,
            "description": "Main colors (color1-color4)"
          },
          "neutrals": {
            "type": "array",
            "items": {
              "type": "string",
              "description": "Must be 6-digit hex color format (e.g., #FF0000)"
            },
            "minItems": 2,
            "maxItems": 3,
            "description": "Neutral colors (neutral1-neutral3)"
          }
        },
        "required": [
          "colors",
          "neutrals"
        ],
        "additionalProperties": false
      },
      "fontConfiguration": {
        "type": "object",
        "properties": {
          "titleWeight": {
            "type": "integer",
            "minimum": 100,
            "maximum": 900,
            "enum": [
              100,
              200,
              300,
              400,
              500,
              600,
              700,
              800,
              900
            ],
            "default": 600,
            "description": "Font weight for titles"
          },
          "bodyWeight": {
            "type": "integer",
            "minimum": 100,
            "maximum": 900,
            "enum": [
              100,
              200,
              300,
              400,
              500,
              600,
              700,
              800,
              900
            ],
            "default": 400,
            "description": "Font weight for body text"
          }
        },
        "additionalProperties": false
      }
    },
    "required": [
      "templateName",
      "fields",
      "colorPalette",
      "fontConfiguration"
    ],
    "additionalProperties": false
  };
  
  try {
    final response = await _callGemini(
      geminiApiKey,
      'Create a fitness tracking template with weight, steps, and workout fields',
      translatedSchema,
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
      
      // Check if combination makes sense
      if (fieldType == 'text' && !['textField', 'textArea'].contains(widgetType)) {
        validCombinations = false;
      }
      if (fieldType == 'number' && !['slider', 'stepper'].contains(widgetType)) {
        validCombinations = false;
      }
      if (fieldType == 'boolean' && widgetType != 'checkbox') {
        validCombinations = false;
      }
      if (fieldType == 'date' && widgetType != 'datePicker') {
        validCombinations = false;
      }
    }
    
    print('  ✅ Field-widget combinations: ${validCombinations ? "✅" : "❌"}');
  }
  
  // Check font weights
  if (hasFontConfig) {
    final fontConfig = response['fontConfiguration'] as Map<String, dynamic>;
    final validWeights = [100, 200, 300, 400, 500, 600, 700, 800, 900];
    
    bool fontsValid = true;
    for (final key in ['titleWeight', 'bodyWeight']) {
      if (fontConfig.containsKey(key)) {
        final weight = fontConfig[key] as int;
        if (!validWeights.contains(weight)) {
          fontsValid = false;
        }
        print('    $key: $weight');
      }
    }
    
    print('  ✅ Font weights valid: ${fontsValid ? "✅" : "❌"}');
  }
  
  // Check colors
  if (hasColorPalette) {
    final colorPalette = response['colorPalette'] as Map<String, dynamic>;
    final hexPattern = RegExp(r'^#[0-9A-Fa-f]{6}$');
    
    bool colorsValid = true;
    
    if (colorPalette.containsKey('colors')) {
      final colors = colorPalette['colors'] as List;
      print('    Colors: ${colors.join(", ")}');
      for (final color in colors) {
        if (!hexPattern.hasMatch(color as String)) {
          colorsValid = false;
        }
      }
    }
    
    if (colorPalette.containsKey('neutrals')) {
      final neutrals = colorPalette['neutrals'] as List;
      print('    Neutrals: ${neutrals.join(", ")}');
      for (final neutral in neutrals) {
        if (!hexPattern.hasMatch(neutral as String)) {
          colorsValid = false;
        }
      }
    }
    
    print('  ✅ Colors valid hex format: ${colorsValid ? "✅" : "❌"}');
  }
}