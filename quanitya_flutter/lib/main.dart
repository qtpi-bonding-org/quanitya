import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'infrastructure/config/debug_log.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

import 'app/bootstrap.dart';
import 'app/app.dart';

const _tag = 'main';

void main() async {
  // Preserve splash screen while initializing
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  
  // Comprehensive WASM and environment detection
  if (kIsWeb) {
    _performWebDiagnostics();
  }
  
  await bootstrap();
  
  // Remove splash screen after bootstrap completes
  FlutterNativeSplash.remove();
  
  runApp(const QuanityaApp());
}

void _performWebDiagnostics() {
  Log.d(_tag, '🔍 ═══════════════════════════════════════════════════════════');
  Log.d(_tag, '🔍 COMPREHENSIVE WEB ENVIRONMENT DIAGNOSTICS');
  Log.d(_tag, '🔍 ═══════════════════════════════════════════════════════════');
  
  // 1. WASM Detection (Multiple Methods)
  Log.d(_tag, '🔍 1. WASM DETECTION:');
  const isWasmByEnv = bool.fromEnvironment('dart.tool.dart2wasm');
  final isWasmByNaN = identical(double.nan, double.nan);
  Log.d(_tag, '  ✓ dart.tool.dart2wasm environment: $isWasmByEnv');
  Log.d(_tag, '  ✓ NaN identity test: $isWasmByNaN');
  Log.d(_tag, '  ✓ Final WASM status: ${isWasmByEnv || isWasmByNaN}');
  
  // 2. Flutter Version & Build Info
  Log.d(_tag, '🔍 2. BUILD INFORMATION:');
  Log.d(_tag, '  ✓ Git commit: ${const String.fromEnvironment('GIT_COMMIT_HASH', defaultValue: 'unknown')}');
  Log.d(_tag, '  ✓ Flutter version: ${const String.fromEnvironment('FLUTTER_VERSION', defaultValue: 'unknown')}');
  Log.d(_tag, '  ✓ Dart version: ${const String.fromEnvironment('FLUTTER_DART_VERSION', defaultValue: 'unknown')}');
  Log.d(_tag, '  ✓ Build mode: ${kDebugMode ? 'debug' : kProfileMode ? 'profile' : 'release'}');
  Log.d(_tag, '  ✓ Web renderer: ${const String.fromEnvironment('FLUTTER_WEB_USE_SKWASM', defaultValue: 'false') == 'true' ? 'skwasm' : 'canvaskit'}');
  Log.d(_tag, '  ✓ WASM dry run disabled: ${const String.fromEnvironment('FLUTTER_WEB_WASM_DRY_RUN', defaultValue: 'true') == 'false'}');
  
  // 3. Compilation Target Detection
  Log.d(_tag, '🔍 3. COMPILATION TARGET:');
  Log.d(_tag, '  ✓ Compiled to JS: ${const bool.fromEnvironment('dart.library.js_util', defaultValue: false)}');
  Log.d(_tag, '  ✓ JS Interop available: ${const bool.fromEnvironment('dart.library.js_interop', defaultValue: false)}');
  Log.d(_tag, '  ✓ HTML library available: ${const bool.fromEnvironment('dart.library.html', defaultValue: false)}');
  Log.d(_tag, '  ✓ IO library available: ${const bool.fromEnvironment('dart.library.io', defaultValue: false)}');
  
  // 4. Runtime Environment
  Log.d(_tag, '🔍 4. RUNTIME ENVIRONMENT:');
  Log.d(_tag, '  ✓ Is Web: $kIsWeb');
  Log.d(_tag, '  ✓ Is Debug Mode: $kDebugMode');
  Log.d(_tag, '  ✓ Is Profile Mode: $kProfileMode');
  Log.d(_tag, '  ✓ Is Release Mode: ${!kDebugMode && !kProfileMode}');
  
  Log.d(_tag, '🔍 ═══════════════════════════════════════════════════════════');
  Log.d(_tag, '🔍 DIAGNOSTICS COMPLETE - Check browser console for JS logs');
  Log.d(_tag, '🔍 ═══════════════════════════════════════════════════════════');
}
