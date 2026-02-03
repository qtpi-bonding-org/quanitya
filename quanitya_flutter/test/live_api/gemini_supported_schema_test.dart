import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import 'live_api_test_helper.dart';

void main() {
  group('Gemini Supported Schema Tests', () {
    String? geminiApiKey;
    bool hasApiKey = false;

    setUpAll(() async {
      await LiveApiTestHelper.loadEnv();
      hasApiKey = LiveApiTestHelper.hasGeminiKey;
      
      if (!hasApiKey) return;
      
      geminiApiKey = LiveApiTestHelper.geminiApiKey;
      print('✅ Gemini API Key loaded: ${geminiApiKey!.substring(0, 10)}...');
    });

    test('Gemini API - Color constraints with supported schema', () async {
      print('\n🎨 Testing color constraints with Gemini-supported schema...');
      
      final colorSchema = {
        'type': 'object',
        'properties': {
          'colors': {
            'type': 'array',
            'items': {
              'type': 'string',
              'description': 'Hex color in #FFFFFF format (6 digits)',
            },
            'minItems': 3,
            'maxItems': 3,
            'description': 'Exactly 3 hex colors in #FFFFFF format',
          },
        },
        'required': ['colors'],
        'additionalProperties': false,
      };
      
      final response = await _callGeminiWithSchema(
        geminiApiKey!,
        'Generate exactly 3 beautiful hex colors for a modern app. Each color must be in #FFFFFF format.',
        colorSchema,
      );
      
      print('📥 Gemini Response:');
      print(JsonEncoder.withIndent('  ').convert(response));
      
      expect(response, isA<Map<String, dynamic>>());
      expect(response.containsKey('colors'), isTrue);
      
      final colors = response['colors'] as List;
      expect(colors.length, equals(3));

      final hexPattern = RegExp(r'^#[0-9A-Fa-f]{6}$');
      for (int i = 0; i < colors.length; i++) {
        final color = colors[i] as String;
        print('🎨 Color ${i + 1}: $color');
        
        expect(color, isA<String>());
        expect(hexPattern.hasMatch(color), isTrue, 
          reason: 'Color "$color" should match pattern ^#[0-9A-Fa-f]{6}\$');
        expect(color.length, equals(7), 
          reason: 'Color "$color" should be exactly 7 characters (#FFFFFF)');
      }
      
      print('✅ Color constraint validation SUCCESSFUL!');
    }, timeout: const Timeout(Duration(seconds: 30)), skip: !hasApiKey ? 'GEMINI_API_KEY not found in .env' : null);

    test('Gemini API - Font weight constraints with supported schema', () async {
      print('\n🔤 Testing font weight constraints with Gemini-supported schema...');
      
      final fontSchema = {
        'type': 'object',
        'properties': {
          'fontWeights': {
            'type': 'object',
            'properties': {
              'title': {'type': 'integer', 'enum': [100, 200, 300, 400, 500, 600, 700, 800, 900]},
              'body': {'type': 'integer', 'enum': [100, 200, 300, 400, 500, 600, 700, 800, 900]},
              'caption': {'type': 'integer', 'enum': [100, 200, 300, 400, 500, 600, 700, 800, 900]},
            },
            'required': ['title', 'body', 'caption'],
            'additionalProperties': false,
          },
        },
        'required': ['fontWeights'],
        'additionalProperties': false,
      };
      
      final response = await _callGeminiWithSchema(
        geminiApiKey!,
        'Generate appropriate font weights for title (bold), body (normal), and caption (light).',
        fontSchema,
      );
      
      print('📥 Font Weight Response:');
      print(JsonEncoder.withIndent('  ').convert(response));
      
      final fontWeights = response['fontWeights'] as Map<String, dynamic>;
      final validWeights = [100, 200, 300, 400, 500, 600, 700, 800, 900];
      
      for (final entry in fontWeights.entries) {
        final weight = entry.value as int;
        print('📝 ${entry.key}: $weight');
        expect(validWeights.contains(weight), isTrue);
      }
      
      print('✅ Font weight constraint enforcement SUCCESSFUL!');
    }, timeout: const Timeout(Duration(seconds: 30)), skip: !hasApiKey ? 'GEMINI_API_KEY not found in .env' : null);

    test('Gemini API - Enum constraint enforcement', () async {
      print('\n📋 Testing enum constraint enforcement...');
      
      final enumSchema = {
        'type': 'object',
        'properties': {
          'fieldType': {'type': 'string', 'enum': ['text', 'integer', 'boolean', 'datetime']},
          'uiElement': {'type': 'string', 'enum': ['textField', 'slider', 'checkbox', 'datePicker']},
          'priority': {'type': 'integer', 'enum': [1, 2, 3, 4, 5]},
        },
        'required': ['fieldType', 'uiElement', 'priority'],
        'additionalProperties': false,
      };
      
      final response = await _callGeminiWithSchema(
        geminiApiKey!,
        'Generate a form field configuration. Choose appropriate values from the allowed options.',
        enumSchema,
      );
      
      print('📥 Enum Response:');
      print(JsonEncoder.withIndent('  ').convert(response));
      
      final fieldType = response['fieldType'] as String;
      final uiElement = response['uiElement'] as String;
      final priority = response['priority'] as int;
      
      expect(['text', 'integer', 'boolean', 'datetime'].contains(fieldType), isTrue);
      expect(['textField', 'slider', 'checkbox', 'datePicker'].contains(uiElement), isTrue);
      expect([1, 2, 3, 4, 5].contains(priority), isTrue);
      
      print('✅ Enum constraint enforcement SUCCESSFUL!');
    }, timeout: const Timeout(Duration(seconds: 30)), skip: !hasApiKey ? 'GEMINI_API_KEY not found in .env' : null);

    test('Gemini API - Array constraints enforcement', () async {
      print('\n📊 Testing array constraints enforcement...');
      
      final arraySchema = {
        'type': 'object',
        'properties': {
          'tags': {
            'type': 'array',
            'items': {'type': 'string', 'enum': ['urgent', 'normal', 'low', 'feature', 'bug', 'enhancement']},
            'minItems': 2,
            'maxItems': 4,
          },
          'scores': {
            'type': 'array',
            'items': {'type': 'integer', 'minimum': 1, 'maximum': 10},
            'minItems': 3,
            'maxItems': 3,
          },
        },
        'required': ['tags', 'scores'],
        'additionalProperties': false,
      };
      
      final response = await _callGeminiWithSchema(
        geminiApiKey!,
        'Generate tags (2-4 items) and scores (exactly 3 numbers between 1-10) for a project.',
        arraySchema,
      );
      
      print('📥 Array Response:');
      print(JsonEncoder.withIndent('  ').convert(response));
      
      final tags = response['tags'] as List;
      final scores = response['scores'] as List;
      
      expect(tags.length >= 2 && tags.length <= 4, isTrue);
      expect(scores.length, equals(3));
      
      final allowedTags = ['urgent', 'normal', 'low', 'feature', 'bug', 'enhancement'];
      for (final tag in tags) {
        expect(allowedTags.contains(tag), isTrue);
      }
      
      for (final score in scores) {
        final scoreInt = score as int;
        expect(scoreInt >= 1 && scoreInt <= 10, isTrue);
      }
      
      print('✅ Array constraint enforcement SUCCESSFUL!');
    }, timeout: const Timeout(Duration(seconds: 30)), skip: !hasApiKey ? 'GEMINI_API_KEY not found in .env' : null);
  });
}

Future<Map<String, dynamic>> _callGeminiWithSchema(
  String apiKey,
  String prompt,
  Map<String, dynamic> schema,
) async {
  final url = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=$apiKey';
  
  final requestBody = {
    'contents': [{'parts': [{'text': prompt}]}],
    'generationConfig': {
      'responseMimeType': 'application/json',
      'responseJsonSchema': schema,
    },
  };
  
  print('📤 Calling Gemini API with structured output...');
  
  final response = await http.post(
    Uri.parse(url),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode(requestBody),
  );
  
  if (response.statusCode != 200) {
    throw Exception('Gemini API Error ${response.statusCode}: ${response.body}');
  }
  
  final data = jsonDecode(response.body);
  
  if (data['candidates'] == null || data['candidates'].isEmpty) {
    throw Exception('No candidates in Gemini response: ${response.body}');
  }
  
  final candidate = data['candidates'][0];
  if (candidate['content'] == null || candidate['content']['parts'] == null) {
    throw Exception('No content in Gemini candidate: ${response.body}');
  }
  
  final textContent = candidate['content']['parts'][0]['text'] as String;
  return jsonDecode(textContent) as Map<String, dynamic>;
}