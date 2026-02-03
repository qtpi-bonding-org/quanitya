#!/usr/bin/env dart

import 'dart:convert';
import 'dart:io';

// Simple standalone pipeline tester
void main() async {
  print('🚀 SCHEMA TRANSLATION PIPELINE TESTER');
  print('=' * 60);
  
  // Load API key
  final envFile = File('.env');
  if (!envFile.existsSync()) {
    print('❌ .env file not found');
    exit(1);
  }
  
  final envContent = await envFile.readAsString();
  final apiKeyMatch = RegExp(r'GEMINI_API_KEY=(.+)').firstMatch(envContent);
  
  if (apiKeyMatch == null) {
    print('❌ GEMINI_API_KEY not found in .env');
    exit(1);
  }
  
  final apiKey = apiKeyMatch.group(1)!;
  print('✅ API key loaded');
  
  // Create schema with unsupported features
  final originalSchema = {
    'type': 'object',
    'properties': {
      'templateName': {'type': 'string'},
      'fontWeight': {
        'type': 'integer',
        'multipleOf': 100, // ← Unsupported by Gemini
        'minimum': 100,
        'maximum': 900,
      },
      'color': {
        'type': 'string',
        'pattern': r'^#[0-9A-Fa-f]{6}$', // ← Unsupported by Gemini
      },
      'type': {
        'oneOf': [ // ← Unsupported by Gemini
          {'const': 'fitness'},
          {'const': 'recipe'},
          {'const': 'project'},
        ],
      },
    },
    'required': ['templateName', 'fontWeight', 'color', 'type'],
    'additionalProperties': false,
  };
  
  // Translate schema (simulate our translator)
  final translatedSchema = {
    'type': 'object',
    'properties': {
      'templateName': {'type': 'string'},
      'fontWeight': {
        'type': 'integer',
        'enum': [100, 200, 300, 400, 500, 600, 700, 800, 900], // ← Translated
      },
      'color': {
        'type': 'string',
        'description': 'Must be 6-digit hex color format (#FF0000)', // ← Translated
      },
      'type': {
        'type': 'string',
        'enum': ['fitness', 'recipe', 'project'], // ← Translated
      },
    },
    'required': ['templateName', 'fontWeight', 'color', 'type'],
    'additionalProperties': false,
  };
  
  print('\n📋 Schema Translation Complete:');
  print('  - multipleOf:100 → enum:[100,200,300,400,500,600,700,800,900]');
  print('  - pattern:regex → description:"Must be hex format"');
  print('  - oneOf:const → enum:["fitness","recipe","project"]');
  
  print('\n🎮 Interactive Mode - Enter your prompts!');
  print('Commands: "schema" to see schema, "quit" to exit');
  
  while (true) {
    print('\n📝 Enter your template prompt:');
    stdout.write('> ');
    final input = stdin.readLineSync();
    
    if (input == null || input.toLowerCase() == 'quit') {
      print('👋 Goodbye!');
      break;
    }
    
    if (input.toLowerCase() == 'schema') {
      print('\n📋 TRANSLATED SCHEMA:');
      print(JsonEncoder.withIndent('  ').convert(translatedSchema));
      continue;
    }
    
    if (input.trim().isEmpty) {
      print('❌ Please enter a prompt');
      continue;
    }
    
    try {
      print('\n🚀 Calling Gemini API with translated schema...');
      
      final response = await _callGemini(apiKey, input, translatedSchema);
      
      print('\n📥 GEMINI RESPONSE:');
      print('=' * 50);
      print(JsonEncoder.withIndent('  ').convert(response));
      print('=' * 50);
      
      print('\n📊 VALIDATION:');
      _validateResponse(response);
      
    } catch (e) {
      print('❌ Error: $e');
    }
  }
}

Future<Map<String, dynamic>> _callGemini(
  String apiKey,
  String prompt,
  Map<String, dynamic> schema,
) async {
  final url = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash-exp:generateContent?key=$apiKey';
  
  final body = {
    'contents': [
      {
        'parts': [
          {'text': 'Create a template based on: $prompt'}
        ]
      }
    ],
    'generationConfig': {
      'responseMimeType': 'application/json',
      'responseJsonSchema': schema,
    },
  };
  
  final response = await HttpClient().postUrl(Uri.parse(url))
    ..headers.contentType = ContentType.json
    ..write(jsonEncode(body));
  
  final httpResponse = await response.close();
  final responseBody = await httpResponse.transform(utf8.decoder).join();
  
  if (httpResponse.statusCode != 200) {
    throw Exception('API Error ${httpResponse.statusCode}: $responseBody');
  }
  
  final data = jsonDecode(responseBody);
  final textContent = data['candidates'][0]['content']['parts'][0]['text'] as String;
  return jsonDecode(textContent) as Map<String, dynamic>;
}

void _validateResponse(Map<String, dynamic> response) {
  final validWeights = [100, 200, 300, 400, 500, 600, 700, 800, 900];
  final hexPattern = RegExp(r'^#[0-9A-Fa-f]{6}$');
  final validTypes = ['fitness', 'recipe', 'project'];
  
  final fontWeight = response['fontWeight'] as int;
  final color = response['color'] as String;
  final type = response['type'] as String;
  
  final checks = [
    ('Font weight is valid multiple of 100', validWeights.contains(fontWeight)),
    ('Color is valid hex format', hexPattern.hasMatch(color)),
    ('Type is from allowed enum', validTypes.contains(type)),
  ];
  
  for (final (check, passed) in checks) {
    final icon = passed ? '✅' : '❌';
    print('$icon $check');
  }
  
  final allPassed = checks.every((check) => check.$2);
  if (allPassed) {
    print('🎉 All schema constraints enforced successfully!');
  }
}