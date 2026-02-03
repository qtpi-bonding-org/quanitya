import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

import 'app/bootstrap.dart';
import 'app/app.dart';

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
  debugPrint('🔍 ═══════════════════════════════════════════════════════════');
  debugPrint('🔍 COMPREHENSIVE WEB ENVIRONMENT DIAGNOSTICS');
  debugPrint('🔍 ═══════════════════════════════════════════════════════════');
  
  // 1. WASM Detection (Multiple Methods)
  debugPrint('🔍 1. WASM DETECTION:');
  const isWasmByEnv = bool.fromEnvironment('dart.tool.dart2wasm');
  final isWasmByNaN = identical(double.nan, double.nan);
  debugPrint('  ✓ dart.tool.dart2wasm environment: $isWasmByEnv');
  debugPrint('  ✓ NaN identity test: $isWasmByNaN');
  debugPrint('  ✓ Final WASM status: ${isWasmByEnv || isWasmByNaN}');
  
  // 2. Flutter Version & Build Info
  debugPrint('🔍 2. BUILD INFORMATION:');
  debugPrint('  ✓ Git commit: ${const String.fromEnvironment('GIT_COMMIT_HASH', defaultValue: 'unknown')}');
  debugPrint('  ✓ Flutter version: ${const String.fromEnvironment('FLUTTER_VERSION', defaultValue: 'unknown')}');
  debugPrint('  ✓ Dart version: ${const String.fromEnvironment('FLUTTER_DART_VERSION', defaultValue: 'unknown')}');
  debugPrint('  ✓ Build mode: ${kDebugMode ? 'debug' : kProfileMode ? 'profile' : 'release'}');
  debugPrint('  ✓ Web renderer: ${const String.fromEnvironment('FLUTTER_WEB_USE_SKWASM', defaultValue: 'false') == 'true' ? 'skwasm' : 'canvaskit'}');
  debugPrint('  ✓ WASM dry run disabled: ${const String.fromEnvironment('FLUTTER_WEB_WASM_DRY_RUN', defaultValue: 'true') == 'false'}');
  
  // 3. Compilation Target Detection
  debugPrint('🔍 3. COMPILATION TARGET:');
  debugPrint('  ✓ Compiled to JS: ${const bool.fromEnvironment('dart.library.js_util', defaultValue: false)}');
  debugPrint('  ✓ JS Interop available: ${const bool.fromEnvironment('dart.library.js_interop', defaultValue: false)}');
  debugPrint('  ✓ HTML library available: ${const bool.fromEnvironment('dart.library.html', defaultValue: false)}');
  debugPrint('  ✓ IO library available: ${const bool.fromEnvironment('dart.library.io', defaultValue: false)}');
  
  // 4. Runtime Environment
  debugPrint('🔍 4. RUNTIME ENVIRONMENT:');
  debugPrint('  ✓ Is Web: $kIsWeb');
  debugPrint('  ✓ Is Debug Mode: $kDebugMode');
  debugPrint('  ✓ Is Profile Mode: $kProfileMode');
  debugPrint('  ✓ Is Release Mode: ${!kDebugMode && !kProfileMode}');
  
  debugPrint('🔍 ═══════════════════════════════════════════════════════════');
  debugPrint('🔍 DIAGNOSTICS COMPLETE - Check browser console for JS logs');
  debugPrint('🔍 ═══════════════════════════════════════════════════════════');
}
