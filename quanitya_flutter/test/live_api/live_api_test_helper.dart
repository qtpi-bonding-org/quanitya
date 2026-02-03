import 'dart:io';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';

/// Helper for live API tests that require API keys.
/// 
/// Provides utilities to:
/// - Load and check for API keys
/// - Skip tests when keys are missing
/// - Provide consistent setup across all live API tests
class LiveApiTestHelper {
  static bool _dotenvLoaded = false;
  static String? _geminiApiKey;
  static String? _openaiApiKey;
  static String? _openRouterApiKey;
  
  /// Load dotenv and cache API keys
  static Future<void> loadEnv() async {
    if (_dotenvLoaded) return;
    
    try {
      await dotenv.load(fileName: '.env');
      _dotenvLoaded = true;
      _geminiApiKey = dotenv.env['GEMINI_API_KEY'];
      _openaiApiKey = dotenv.env['OPENAI_API_KEY'];
      _openRouterApiKey = dotenv.env['OPENROUTER_API_KEY'];
    } catch (e) {
      // .env file might not exist
      _dotenvLoaded = true;
    }
  }
  
  /// Get Gemini API key, or null if not available
  static String? get geminiApiKey => _geminiApiKey;
  
  /// Get OpenAI API key, or null if not available
  static String? get openaiApiKey => _openaiApiKey;
  
  /// Get OpenRouter API key, or null if not available
  static String? get openRouterApiKey => _openRouterApiKey;
  
  /// Check if Gemini API key is available
  static bool get hasGeminiKey => 
      _geminiApiKey != null && _geminiApiKey!.isNotEmpty;
  
  /// Check if OpenAI API key is available
  static bool get hasOpenaiKey => 
      _openaiApiKey != null && _openaiApiKey!.isNotEmpty;
  
  /// Check if OpenRouter API key is available
  static bool get hasOpenRouterKey => 
      _openRouterApiKey != null && _openRouterApiKey!.isNotEmpty;
  
  /// Skip message for missing Gemini key
  static String get skipGeminiMessage => 
      'Skipping: GEMINI_API_KEY not found in .env';
  
  /// Skip message for missing OpenAI key
  static String get skipOpenaiMessage => 
      'Skipping: OPENAI_API_KEY not found in .env';
  
  /// Skip message for missing OpenRouter key
  static String get skipOpenRouterMessage => 
      'Skipping: OPENROUTER_API_KEY not found in .env';
  
  /// Setup for tests requiring Gemini API key.
  /// Returns the API key or null if not available.
  static Future<String?> requireGeminiKey() async {
    await loadEnv();
    return hasGeminiKey ? _geminiApiKey : null;
  }
  
  /// Setup for tests requiring OpenAI API key.
  /// Returns the API key or null if not available.
  static Future<String?> requireOpenaiKey() async {
    await loadEnv();
    return hasOpenaiKey ? _openaiApiKey : null;
  }
  
  /// Setup for tests requiring OpenRouter API key.
  /// Returns the API key or null if not available.
  static Future<String?> requireOpenRouterKey() async {
    await loadEnv();
    return hasOpenRouterKey ? _openRouterApiKey : null;
  }
  
  /// Check if running in CI environment
  static bool get isCI => 
      Platform.environment['CI'] == 'true' ||
      Platform.environment['GITHUB_ACTIONS'] == 'true';
}
