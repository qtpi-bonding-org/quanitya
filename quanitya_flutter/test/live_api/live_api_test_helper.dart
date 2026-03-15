import 'dart:io';

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
  
  /// Synchronous env loader — call from main() before test registration
  /// so that skip: checks work at registration time.
  static void loadEnvSync() {
    if (_dotenvLoaded) return;
    _dotenvLoaded = true;
    _loadFromFile();
  }

  /// Async env loader — kept for backward compatibility.
  static Future<void> loadEnv() async {
    loadEnvSync();
  }

  static void _loadFromFile() {
    final envFile = File('.env');
    if (!envFile.existsSync()) return;

    final lines = envFile.readAsLinesSync();
    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty || trimmed.startsWith('#')) continue;
      final eqIdx = trimmed.indexOf('=');
      if (eqIdx < 0) continue;
      final key = trimmed.substring(0, eqIdx).trim();
      final value = trimmed.substring(eqIdx + 1).trim();
      switch (key) {
        case 'GEMINI_API_KEY': _geminiApiKey = value;
        case 'OPENAI_API_KEY': _openaiApiKey = value;
        case 'OPENROUTER_API_KEY': _openRouterApiKey = value;
      }
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
