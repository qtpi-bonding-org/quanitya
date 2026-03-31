import 'package:injectable/injectable.dart';
import 'i_js_executor.dart';
import 'js_executor_factory.dart';

@module
abstract class JsExecutorModule {
  @injectable
  IJsExecutor get jsExecutor => createJsExecutor();
}
