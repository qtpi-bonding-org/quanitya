import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import 'live_api_test_helper.dart';

@Tags(['live_api'])
void main() {
  group('BYOK Verification Tests', () {
    String? openRouterApiKey;
    String? geminiApiKey;
    bool hasApiKeys = false;

    setUpAll(() async {
      await LiveApiTestHelper.loadEnv();
      // hasApiKeys = LiveApiTestHelper.hasOpenRouterKey && LiveApiTestHelper.hasGeminiKey;
      hasApiKeys = LiveApiTestHelper.hasOpenRouterKey;
      
      if (!hasApiKeys) return;
      
      openRouterApiKey = LiveApiTestHelper.openRouterApiKey;
      // geminiApiKey = LiveApiTestHelper.geminiApiKey;
      print('✅ OpenRouter Key: ${openRouterApiKey!.substring(0, 10)}...');
    });

    test('Check OpenRouter BYOK configuration', () async {
      if (!hasApiKeys) {
        markTestSkipped('OPENROUTER_API_KEY not found in .env');
        return;
      }
      print('\n🔍 Checking OpenRouter BYOK setup...');
      
      // Test with simple request to see if BYOK is working
      final response = await http.post(
        Uri.parse('https://openrouter.ai/api/v1/chat/completions'),
        headers: {
          'Authorization': 'Bearer $openRouterApiKey',
          'Content-Type': 'application/json',
          'HTTP-Referer': 'https://github.com/qtpi-bonding/quanitya_flutter',
          'X-Title': 'Quanitya BYOK Test',
        },
        body: jsonEncode({
          'model': 'google/gemini-3-flash-preview',
          'messages': [
            {
              'role': 'user',
              'content': 'Say "BYOK test successful" if you can read this.'
            }
          ],
          'max_tokens': 50,
        }),
      );
      
      print('📤 Response Status: ${response.statusCode}');
      print('📥 Response Body: ${response.body}');
      
      if (response.statusCode == 402) {
        print('❌ BYOK not working - still getting credit error');
        print('💡 Possible issues:');
        print('   1. Gemini key not added to OpenRouter web interface');
        print('   2. BYOK not enabled for this model');
        print('   3. Account verification needed');
      } else if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('✅ BYOK working! Response: ${data['choices'][0]['message']['content']}');
      } else {
        print('⚠️  Unexpected response: ${response.statusCode}');
      }
    });

    test('List available models to check BYOK support', () async {
      if (!hasApiKeys) {
        markTestSkipped('OPENROUTER_API_KEY not found in .env');
        return;
      }
      print('\n📋 Checking available models...');
      
      final response = await http.get(
        Uri.parse('https://openrouter.ai/api/v1/models'),
        headers: {
          'Authorization': 'Bearer $openRouterApiKey',
        },
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final models = data['data'] as List;
        
        // Find Gemini models
        final geminiModels = models.where((model) => 
          model['id'].toString().contains('gemini')).toList();
        
        print('🔍 Found ${geminiModels.length} Gemini models:');
        for (final model in geminiModels) {
          final id = model['id'];
          final pricing = model['pricing'];
          print('   - $id');
          if (pricing != null) {
            print("     Prompt: ${pricing['prompt']} / 1M tokens");
            print("     Completion: ${pricing['completion']} / 1M tokens");
          }
        }
        
        // Check if our model exists
        final ourModel = models.firstWhere(
          (model) => model['id'] == 'google/gemini-3-flash-preview',
          orElse: () => null,
        );
        
        if (ourModel != null) {
          print('✅ Model google/gemini-3-flash-preview found');
          print('   Context: ${ourModel['context_length']} tokens');
        } else {
          print('❌ Model google/gemini-3-flash-preview not found');
          print('💡 Try these alternatives:');
          for (final model in geminiModels.take(3)) {
            print('   - ${model['id']}');
          }
        }
      } else {
        print('❌ Failed to fetch models: ${response.statusCode}');
        print('Response: ${response.body}');
      }
    });

    test('Test with different Gemini model names', () async {
      if (!hasApiKeys) {
        markTestSkipped('OPENROUTER_API_KEY not found in .env');
        return;
      }
      print('\n🧪 Testing different Gemini model names...');
      
      final modelsToTry = [
        'google/gemini-3-flash-preview',
        'google/gemini-1.5-flash',
        'google/gemini-1.5-pro',
        'google/gemini-pro',
      ];
      
      for (final modelName in modelsToTry) {
        print('\n🔄 Testing model: $modelName');
        
        final response = await http.post(
          Uri.parse('https://openrouter.ai/api/v1/chat/completions'),
          headers: {
            'Authorization': 'Bearer $openRouterApiKey',
            'Content-Type': 'application/json',
            'HTTP-Referer': 'https://github.com/qtpi-bonding/quanitya_flutter',
            'X-Title': 'Quanitya BYOK Test',
          },
          body: jsonEncode({
            'model': modelName,
            'messages': [
              {
                'role': 'user',
                'content': 'Reply with just "OK" if you can read this.'
              }
            ],
            'max_tokens': 10,
          }),
        );
        
        print('   Status: ${response.statusCode}');
        
        if (response.statusCode == 200) {
          print('   ✅ $modelName works!');
          final data = jsonDecode(response.body);
          print('   Response: ${data['choices'][0]['message']['content']}');
          break; // Found working model
        } else if (response.statusCode == 402) {
          print('   💳 $modelName needs credits (BYOK not working)');
        } else if (response.statusCode == 400) {
          print('   ❌ $modelName invalid model');
        } else {
          print('   ⚠️  $modelName unexpected error: ${response.body}');
        }
      }
    });
  });
}