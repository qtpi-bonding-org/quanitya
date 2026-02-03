import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

/// Simple test to see if Gemini can handle widget JSON objects in enum
void main() async {
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
  
  final apiKey = apiKeyMatch.group(1)!.trim();
  
  // Create simple schema with widget JSON enum
  final schema = {
    'type': 'object',
    'properties': {
      'widgetChoice': {
        'type': 'object',
        'enum': [
          // Simple slider widget
          {
            'type': 'slider',
            'min': 0,
            'max': 100,
            'activeColor': '{{color1}}',
            'thumbColor': '{{color2}}',
            'fieldType': 'integer'
          },
          // Simple text field widget
          {
            'type': 'textField',
            'borderColor': '{{color1}}',
            'backgroundColor': '{{neutral2}}',
            'fieldType': 'text'
          },
          // Simple switch widget
          {
            'type': 'switch',
            'activeColor': '{{color1}}',
            'inactiveColor': '{{neutral1}}',
            'fieldType': 'boolean'
          }
        ]
      }
    },
    'required': ['widgetChoice']
  };
  
  print('🧪 Testing Gemini with widget JSON enum...');
  print('Schema size: ${jsonEncode(schema).length} characters');
  
  // Test with Gemini
  final success = await testWithGemini(apiKey, schema);
  
  if (success) {
    print('✅ SUCCESS: Gemini can handle widget JSON enum!');
  } else {
    print('❌ FAILED: Gemini cannot handle widget JSON enum');
  }
}

Future<bool> testWithGemini(String apiKey, Map<String, dynamic> schema) async {
  try {
    final url = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$apiKey';
    
    final requestBody = {
      'contents': [{
        'parts': [{
          'text': 'Generate a widget configuration for a user input form. Pick one widget that would work well for collecting user preferences.'
        }]
      }],
      'generationConfig': {
        'responseMimeType': 'application/json',
        'responseSchema': schema,
      }
    };
    
    print('📤 Sending request to Gemini...');
    
    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode(requestBody),
    );
    
    print('📥 Response status: ${response.statusCode}');
    
    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      
      if (responseData['candidates'] != null && 
          responseData['candidates'].isNotEmpty) {
        
        final content = responseData['candidates'][0]['content'];
        if (content != null && content['parts'] != null && content['parts'].isNotEmpty) {
          final generatedText = content['parts'][0]['text'];
          print('📋 Generated response:');
          print(generatedText);
          
          // Try to parse as JSON
          try {
            final parsedJson = jsonDecode(generatedText);
            print('✅ Valid JSON generated');
            print('🎯 Widget choice: ${parsedJson['widgetChoice']}');
            return true;
          } catch (e) {
            print('❌ Invalid JSON: $e');
            return false;
          }
        }
      }
      
      print('❌ No content in response');
      return false;
    } else {
      print('❌ HTTP Error: ${response.statusCode}');
      print('Response: ${response.body}');
      return false;
    }
  } catch (e) {
    print('❌ Exception: $e');
    return false;
  }
}