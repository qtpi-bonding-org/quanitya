import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

/// Test if OpenAI can handle widget JSON objects in enum (Option 1)
void main() async {
  // Load API key
  final envFile = File('.env');
  if (!envFile.existsSync()) {
    print('❌ .env file not found');
    exit(1);
  }
  
  final envContent = await envFile.readAsString();
  final apiKeyMatch = RegExp(r'OPENROUTER_API_KEY=(.+)').firstMatch(envContent);
  if (apiKeyMatch == null) {
    print('❌ OPENROUTER_API_KEY not found in .env');
    print('Available keys: ${envContent.split('\n').where((line) => line.contains('=')).map((line) => line.split('=')[0]).join(', ')}');
    exit(1);
  }
  
  final apiKey = apiKeyMatch.group(1)!.trim();
  
  // Create schema with widget JSON enum (what OpenAI should handle)
  final schema = {
    'type': 'object',
    'properties': {
      'widgetChoice': {
        'enum': [
          // Complete widget JSON objects
          {
            'type': 'slider',
            'args': {
              'min': 0.0,
              'max': 100.0,
              'activeColor': '{{color1}}',
              'thumbColor': '{{color2}}',
            },
            'fieldType': 'integer',
            'validators': [
              {'type': 'numeric', 'min': 0, 'max': 100}
            ]
          },
          {
            'type': 'textField',
            'args': {
              'decoration': {
                'borderColor': '{{color1}}',
                'backgroundColor': '{{neutral2}}',
              }
            },
            'fieldType': 'text',
            'validators': [
              {'type': 'text', 'minLength': 1, 'maxLength': 100}
            ]
          },
          {
            'type': 'switch',
            'args': {
              'activeColor': '{{color1}}',
              'inactiveColor': '{{neutral1}}',
            },
            'fieldType': 'boolean',
            'validators': []
          }
        ]
      }
    },
    'required': ['widgetChoice'],
    'additionalProperties': false
  };
  
  print('🧪 Testing OpenAI with widget JSON enum...');
  print('Schema size: ${jsonEncode(schema).length} characters');
  
  // Test with OpenAI
  final result = await testWithOpenAI(apiKey, schema);
  
  if (result != null) {
    print('✅ SUCCESS: OpenAI can handle widget JSON enum!');
    print('🎯 Selected widget:');
    print(jsonEncode(result, toEncodable: (obj) => obj.toString()));
  } else {
    print('❌ FAILED: OpenAI cannot handle widget JSON enum');
  }
}

Future<Map<String, dynamic>?> testWithOpenAI(String apiKey, Map<String, dynamic> schema) async {
  try {
    final url = 'https://openrouter.ai/api/v1/chat/completions';
    
    final requestBody = {
      'model': 'openai/gpt-4o-mini',
      'messages': [
        {
          'role': 'system',
          'content': 'You are a UI generator. Select the most appropriate widget for the user\'s request.'
        },
        {
          'role': 'user', 
          'content': 'I need a widget to collect a user\'s age (0-120 years). Pick the best widget configuration.'
        }
      ],
      'response_format': {
        'type': 'json_schema',
        'json_schema': {
          'name': 'widget_selection',
          'strict': true,
          'schema': schema,
        }
      }
    };
    
    print('📤 Sending request to OpenAI...');
    
    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: jsonEncode(requestBody),
    );
    
    print('📥 Response status: ${response.statusCode}');
    
    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      
      if (responseData['choices'] != null && 
          responseData['choices'].isNotEmpty) {
        
        final message = responseData['choices'][0]['message'];
        if (message != null && message['content'] != null) {
          final generatedText = message['content'];
          print('📋 Generated response:');
          print(generatedText);
          
          // Try to parse as JSON
          try {
            final parsedJson = jsonDecode(generatedText);
            return parsedJson['widgetChoice'] as Map<String, dynamic>?;
          } catch (e) {
            print('❌ Invalid JSON: $e');
            return null;
          }
        }
      }
      
      print('❌ No content in response');
      print('Full response: ${response.body}');
      return null;
    } else {
      print('❌ HTTP Error: ${response.statusCode}');
      print('Response: ${response.body}');
      return null;
    }
  } catch (e) {
    print('❌ Exception: $e');
    return null;
  }
}