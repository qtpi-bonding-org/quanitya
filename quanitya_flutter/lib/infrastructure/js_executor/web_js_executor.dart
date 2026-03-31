import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

import '../../logic/analysis/exceptions/analysis_exceptions.dart';
import 'i_js_executor.dart';

/// Web JS executor using a sandboxed iframe + postMessage.
///
/// Security: The iframe has `sandbox="allow-scripts"` WITHOUT `allow-same-origin`,
/// meaning the script runs in an opaque origin with no access to the parent
/// page's DOM, cookies, localStorage, or IndexedDB. Communication is only
/// via postMessage.
class WebJsExecutor implements IJsExecutor {
  static const _defaultTimeout = Duration(seconds: 30);

  @override
  Future<dynamic> evaluate({
    required List<String> libraries,
    required String script,
    Duration? timeout,
  }) async {
    final effectiveTimeout = timeout ?? _defaultTimeout;
    final completer = Completer<dynamic>();

    // Build the iframe HTML: a message listener that evals received code
    final iframeHtml = _buildIframeHtml();
    final blob = web.Blob(
      [iframeHtml.toJS].toJS,
      web.BlobPropertyBag(type: 'text/html'),
    );
    final blobUrl = web.URL.createObjectURL(blob);

    // Create hidden sandboxed iframe
    final iframe = web.document.createElement('iframe') as web.HTMLIFrameElement;
    iframe.setAttribute('sandbox', 'allow-scripts');
    iframe.style.display = 'none';
    iframe.src = blobUrl;

    // Listen for response from iframe
    void Function(web.MessageEvent)? onMessage;
    web.EventListener? jsOnMessage;

    Timer? timeoutTimer;

    void cleanup() {
      if (jsOnMessage != null) {
        web.window.removeEventListener('message', jsOnMessage!);
      }
      timeoutTimer?.cancel();
      iframe.remove();
      web.URL.revokeObjectURL(blobUrl);
    }

    onMessage = (web.MessageEvent event) {
      // Only accept messages from our iframe
      final data = event.data;
      if (data == null) return;

      final Map<String, dynamic> result;
      try {
        // The iframe posts JSON strings
        if (data.isA<JSString>()) {
          result = jsonDecode((data as JSString).toDart) as Map<String, dynamic>;
        } else {
          return; // Ignore non-string messages
        }
      } catch (_) {
        return; // Ignore unparseable messages
      }

      if (!result.containsKey('__quanitya_js_executor')) return;

      cleanup();

      if (result.containsKey('error')) {
        completer.completeError(
          AnalysisException('JS Runtime Error: ${result['error']}'),
        );
      } else if (result.containsKey('resultString')) {
        // Script returned a string (e.g. JSON.stringify output from shell).
        // Pass it through as-is so the service can jsonDecode it.
        completer.complete(result['resultString']);
      } else {
        // Script returned an object — pass as decoded Map.
        completer.complete(result['result']);
      }
    };

    jsOnMessage = onMessage.toJS;
    web.window.addEventListener('message', jsOnMessage!);

    // Timeout
    timeoutTimer = Timer(effectiveTimeout, () {
      cleanup();
      if (!completer.isCompleted) {
        completer.completeError(
          AnalysisException(
            'Script timed out after ${effectiveTimeout.inSeconds}s. '
            'Check for infinite loops or reduce data size.',
          ),
        );
      }
    });

    // Wait for iframe to load, then send the code
    iframe.addEventListener('load', ((web.Event _) {
      final payload = jsonEncode({
        '__quanitya_js_executor': true,
        'libraries': libraries,
        'script': script,
      });
      iframe.contentWindow?.postMessage(payload.toJS, '*'.toJS);
    }).toJS);

    // Add iframe to DOM to trigger load
    web.document.body?.append(iframe);

    return completer.future;
  }

  /// Builds the HTML content for the sandboxed iframe.
  ///
  /// The iframe listens for a message containing libraries and a script,
  /// evaluates them, and posts the result back.
  String _buildIframeHtml() {
    return '''
<!DOCTYPE html>
<html>
<head><meta charset="utf-8"></head>
<body>
<script>
  self.addEventListener('message', function(event) {
    try {
      var msg = JSON.parse(event.data);
      if (!msg.__quanitya_js_executor) return;

      // Evaluate libraries for side effects (defines globals like ss, jStat)
      var libs = msg.libraries || [];
      for (var i = 0; i < libs.length; i++) {
        new Function(libs[i])();
      }

      // Use eval for the main script — it returns the last expression's value,
      // which is how the shell script (mvs_shell.js.j2) communicates results.
      // new Function() would require explicit return statements.
      var result = eval(msg.script);

      // Pass the raw result back — if it's already a JSON string (from
      // JSON.stringify in the shell script), keep it as-is so the Dart
      // side can jsonDecode it the same way as the native executor.
      var payload;
      if (typeof result === 'string') {
        payload = JSON.stringify({
          __quanitya_js_executor: true,
          resultString: result
        });
      } else {
        payload = JSON.stringify({
          __quanitya_js_executor: true,
          result: result
        });
      }
      parent.postMessage(payload, '*');
    } catch (e) {
      parent.postMessage(JSON.stringify({
        __quanitya_js_executor: true,
        error: e.message || String(e)
      }), '*');
    }
  });
</script>
</body>
</html>
''';
  }
}

/// Factory function used by conditional import.
IJsExecutor createPlatformJsExecutor() => WebJsExecutor();
