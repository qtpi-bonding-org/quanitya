#!/usr/bin/env dart

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

void main() async {
  print('🔍 Testing simple schema with Gemini...');
  
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
  
  // Simple schema to test
  final simpleSchema = {
    'type': 'object',
    'properties': {
      'templateName': {
        'type': 'string',
        'description': 'Name of the template',
      },
      'fields': {
        'type': 'array',
        'items': {
          'type': 'object',
          'properties': {
            'fieldType': {
              'enum': ['text', 'number'],
              'description': 'Type of field',
            },
            'label': {
              'type': 'string',
              'description': 'Field label',
            },
          },
          'required': ['fieldType', 'label'],
        },
        'minItems': 1,
        'maxItems': 5,
      },
    },
    'required': ['templateName', 'fields'],
  };
  
  print('\n📋 Testing with simple schema:');
  print(JsonEncoder.withIndent('  ').convert(simpleSchema));
  
  try {
    final response = await _callGemini(
      geminiApiKey,
      'Create a simple fitness tracking template',
      simpleSchema,
    );
    
    print('\n✅ SUCCESS! Gemini response:');
    print(JsonEncoder.withIndent('  ').convert(response));
    
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