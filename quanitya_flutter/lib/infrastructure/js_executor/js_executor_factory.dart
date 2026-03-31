import 'i_js_executor.dart';
import 'native_js_executor.dart'
    if (dart.library.js_interop) 'web_js_executor.dart';

/// Creates the platform-appropriate JS executor.
///
/// Uses conditional import to select:
/// - Native: `NativeJsExecutor` (javascript_flutter)
/// - Web: `WebJsExecutor` (sandboxed iframe)
IJsExecutor createJsExecutor() => createPlatformJsExecutor();
