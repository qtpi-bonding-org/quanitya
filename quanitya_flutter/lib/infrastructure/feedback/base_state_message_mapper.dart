import 'package:cubit_ui_flow/cubit_ui_flow.dart';
import 'package:quanitya_flutter/l10n/l10n_key_resolver.g.dart';

/// Base implementation of [IStateMessageMapper] that combines exception and domain mappers.
///
/// This mapper first checks for errors using the exception mapper, then falls back
/// to the domain mapper for success/info messages.
///
/// Usage:
/// ```dart
/// final mapper = BaseStateMessageMapper&lt;TemplateEditorState&gt;(
///   exceptionMapper: getIt&lt;IExceptionKeyMapper&gt;(),
///   domainMapper: getIt&lt;TemplateEditorMessageMapper&gt;(),
/// );
/// ```
class BaseStateMessageMapper<S extends IUiFlowState>
    implements IStateMessageMapper<S> {
  final IExceptionKeyMapper exceptionMapper;
  final IStateMessageMapper<S> domainMapper;

  const BaseStateMessageMapper({
    required this.exceptionMapper,
    required this.domainMapper,
  });

  @override
  MessageKey? map(S state) {
    // First, try domain mapper for success/info messages
    final domainKey = domainMapper.map(state);
    if (domainKey != null) {
      return domainKey;
    }

    // If state has error, try exception mapping
    if (state.hasError && state.error != null) {
      final exceptionKey = exceptionMapper.map(state.error!);
      if (exceptionKey != null) {
        return exceptionKey;
      }
      
      // Fallback: return generic error with the exception message
      return MessageKey.error(
        L10nKeys.errorGeneric,
        {'message': state.error.toString()},
      );
    }

    return null;
  }
}
