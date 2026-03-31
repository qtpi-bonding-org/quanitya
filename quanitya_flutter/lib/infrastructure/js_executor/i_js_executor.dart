/// Platform-agnostic JavaScript execution interface.
///
/// Native: uses `javascript_flutter` (JavaScriptCore/V8 via platform channels).
/// Web: uses sandboxed iframe + postMessage (no DOM/cookie/storage access).
abstract class IJsExecutor {
  /// Evaluates [libraries] in order (for side effects like defining globals),
  /// then evaluates [script] and returns the result.
  ///
  /// Returns the JS result as a decoded JSON string or Map.
  /// Throws on timeout or runtime error.
  Future<dynamic> evaluate({
    required List<String> libraries,
    required String script,
    Duration timeout,
  });
}
