import 'package:javascript_flutter/javascript_flutter.dart';
import '../../logic/analysis/exceptions/analysis_exceptions.dart';
import 'i_js_executor.dart';

/// Native JS executor using `javascript_flutter` (JavaScriptCore on iOS, V8 on Android).
class NativeJsExecutor implements IJsExecutor {
  static const _defaultTimeout = Duration(seconds: 30);

  @override
  Future<dynamic> evaluate({
    required List<String> libraries,
    required String script,
    Duration? timeout,
  }) async {
    final effectiveTimeout = timeout ?? _defaultTimeout;
    final javascript = await JavaScript.createNew();

    try {
      // Inject libraries (stats, etc.)
      for (final lib in libraries) {
        await javascript.runJavaScriptReturningResult(lib);
      }

      // Execute the script with timeout
      final jsResult = await javascript
          .runJavaScriptReturningResult(script)
          .timeout(
            effectiveTimeout,
            onTimeout: () => throw AnalysisException(
              'Script timed out after ${effectiveTimeout.inSeconds}s. '
              'Check for infinite loops or reduce data size.',
            ),
          );

      return jsResult;
    } finally {
      await javascript.dispose();
    }
  }
}

/// Factory function used by conditional import.
IJsExecutor createPlatformJsExecutor() => NativeJsExecutor();
