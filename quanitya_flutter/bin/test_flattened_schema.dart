import 'dart:convert';
import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

/// Test script to validate the flattened schema with Gemini API
void main() async {
  try {
    await dotenv.load(fileName: '.env');
    
    final geminiApiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
    if (geminiApiKey.isEmpty) {
      throw Exception('Gemini API key not found in .env');
    }
    
    print('🧪 Testing flattened schema with Gemini...');
    
    // Load the flattened schema
    final schemaFile = File('generated_schema_flattened.json');
    final schemaContent = await schemaFile.readAsString();
    final schema = jsonDecode(schemaContent) as Map<String, dynamic>;
    
    // Analyze schema complexity
    final stats = _analyzeSchema(schema);
    print('📊 Flattened schema stats:');
    print('   - Size: ${schemaContent.length} characters');
    print('   - Properties: ${stats['properties']}');
    print('   - Enum values: ${stats['enums']}');
    print('   - OneOf patterns: ${stats['oneOfs']}');
    print('   - Nesting depth: ${stats['depth']}');
    
    // Test with Gemini
    print('\n🚀 Testing with Gemini API...');
    
    final success = await _testWithGemini(geminiApiKey, schema);
    
    if (success) {
      print('✅ SUCCESS: Flattened schema works with Gemini!');
      print('🎯 The flattening approach is viable.');
    } else {
      print('❌ FAILED: Flattened schema still has issues.');
      print('🔧 Need further simplification.');
    }
    
  } catch (e, stackTrace) {
    print('❌ Error testing flattened schema: $e');
    print('Stack trace: $stackTrace');
    exit(1);
  }
}

/// Test the schema with Gemini API
Future<bool> _testWithGemini(String apiKey, Map<String, dynamic> schema) async {
  try {
    final url = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash-exp:generateContent?key=$apiKey';
    
    final requestBody = {
      'contents': [
        {
          'parts': [
            {'text': 'Generate a realistic example that matches this schema. Use appropriate field types and UI elements.'}
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
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final textContent = data['candidates'][0]['content']['parts'][0]['text'] as String;
      final result = jsonDecode(textContent) as Map<String, dynamic>;
      
      print('📝 Generated result:');
      print(const JsonEncoder.withIndent('  ').convert(result));
      
      return true;
    } else {
      print('❌ Gemini API Error ${response.statusCode}: ${response.body}');
      return false;
    }
    
  } catch (e) {
    print('❌ Test failed: $e');
    return false;
  }
}

/// Analyzes the schema structure to provide statistics
Map<String, int> _analyzeSchema(Map<String, dynamic> schema) {
  int propertyCount = 0;
  int enumCount = 0;
  int oneOfCount = 0;
  int maxDepth = 0;
  
  void analyzeObject(Map<String, dynamic> obj, int depth) {
    maxDepth = depth > maxDepth ? depth : maxDepth;
    
    for (final entry in obj.entries) {
      final value = entry.value;
      
      if (entry.key == 'properties' && value is Map<String, dynamic>) {
        propertyCount += value.length;
        for (final prop in value.values) {
          if (prop is Map<String, dynamic>) {
            analyzeObject(prop, depth + 1);
          }
        }
      } else if (entry.key == 'enum' && value is List) {
        enumCount += value.length;
      } else if (entry.key == 'oneOf' && value is List) {
        oneOfCount += value.length;
        for (final item in value) {
          if (item is Map<String, dynamic>) {
            analyzeObject(item, depth + 1);
          }
        }
      } else if (entry.key == 'items' && value is Map<String, dynamic>) {
        analyzeObject(value, depth + 1);
      } else if (value is Map<String, dynamic>) {
        analyzeObject(value, depth + 1);
      } else if (value is List) {
        for (final item in value) {
          if (item is Map<String, dynamic>) {
            analyzeObject(item, depth + 1);
          }
        }
      }
    }
  }
  
  analyzeObject(schema, 0);
  
  return {
    'properties': propertyCount,
    'enums': enumCount,
    'oneOfs': oneOfCount,
    'depth': maxDepth,
  };
}