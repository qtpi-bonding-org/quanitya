import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:cubit_ui_flow/cubit_ui_flow.dart';
import 'package:quanitya_flutter/l10n/l10n_key_resolver.g.dart';

/// Reusable listener wrapper that handles global UI concerns for async operations.
/// 
/// This widget wraps your screen content and automatically handles:
/// - Loading overlays (via ILoadingService)
/// - Error toasts (#B33B28) - from state.error via exception mapper or mapper
/// - Warning toasts (#BF5900) - from mapper
/// - Success toasts (#2E7D32) - from mapper
/// - Info toasts (#1565C0) - from mapper
/// 
/// Usage with mapper (recommended):
/// ```dart
/// UiFlowListener&lt;TemplateCubit, TemplateState&gt;(
///   mapper: getIt&lt;TemplateMessageMapper&gt;(),
///   child: BlocBuilder&lt;TemplateCubit, TemplateState&gt;(
///     builder: (context, state) =&gt; ListView.builder(/* ... */),
///   ),
/// )
/// ```
/// 
/// Usage without mapper (basic):
/// ```dart
/// UiFlowListener&lt;TrackerCubit, TrackerState&gt;(
///   showSuccessToasts: true,
///   successMessage: 'Saved!',
///   child: TrackerScreen(),
/// )
/// ```
class UiFlowListener<B extends StateStreamable<S>, S extends IUiFlowState>
    extends StatelessWidget {
  /// The child widget to wrap with async listening behavior.
  final Widget child;

  /// Optional specific bloc instance to listen to.
  final B? bloc;

  /// Optional mapper to convert state to MessageKey for feedback.
  /// When provided, handles all message types (info, success, warning, error).
  /// This is the recommended approach per cubit_ui_flow pattern.
  final IStateMessageMapper<S>? mapper;

  /// Optional custom listener for additional state-specific logic.
  final void Function(BuildContext context, S state)? listener;

  /// Whether to show success toasts when operations complete successfully.
  /// Only used when mapper is not provided.
  final bool showSuccessToasts;

  /// Custom success message. Only used when mapper is not provided.
  final String? successMessage;

  /// Whether to automatically manage loading overlay.
  final bool autoDismissLoading;

  const UiFlowListener({
    super.key,
    required this.child,
    this.bloc,
    this.mapper,
    this.listener,
    this.showSuccessToasts = false,
    this.successMessage,
    this.autoDismissLoading = true,
  });

  @override
  Widget build(BuildContext context) {
    return BlocListener<B, S>(
      bloc: bloc,
      listenWhen: (previous, current) {
        return previous.status != current.status ||
               previous.error != current.error;
      },
      listener: (context, state) {
        _handleLoadingState(state);
        
        if (mapper != null) {
          // Use mapper for all message types (info, success, warning, error)
          _handleMappedState(state);
        } else {
          // Fallback to basic error/success handling
          _handleErrorState(state);
          _handleSuccessState(state);
        }
        
        listener?.call(context, state);
      },
      child: child,
    );
  }

  /// Handles loading overlay display based on state.
  void _handleLoadingState(S state) {
    if (!autoDismissLoading) return;
    
    final loadingService = GetIt.instance<ILoadingService>();
    
    if (state.isLoading) {
      loadingService.show();
    } else {
      loadingService.hide();
    }
  }

  /// Handles state via mapper - supports all MessageTypes.
  /// Falls back to global exception mapper if domain mapper returns null for errors.
  void _handleMappedState(S state) {
    var messageKey = mapper!.map(state);
    
    // If mapper returns null but state has error, use global exception mapper
    if (messageKey == null && state.hasError && state.error != null) {
      try {
        final exceptionMapper = GetIt.instance<IExceptionKeyMapper>();
        messageKey = exceptionMapper.map(state.error!);
        
        // If exception mapper also returns null, use generic error
        messageKey ??= MessageKey.error(
          L10nKeys.errorGeneric,
          {'message': state.error.toString()},
        );
      } catch (_) {
        // No exception mapper registered, use generic error
        messageKey = MessageKey.error(
          L10nKeys.errorGeneric,
          {'message': state.error.toString()},
        );
      }
    }
    
    if (messageKey == null) return;
    
    // Translate the key if localization service is available
    String message;
    try {
      final localization = GetIt.instance<ILocalizationService>();
      message = localization.translate(messageKey.key, args: messageKey.args);
    } catch (_) {
      // Fallback to raw key if no localization service
      message = messageKey.key;
    }
    
    final feedbackService = GetIt.instance<IFeedbackService>();
    feedbackService.show(FeedbackMessage(
      message: message,
      type: messageKey.type,
    ));
  }

  /// Handles error toast display (fallback when no mapper).
  void _handleErrorState(S state) {
    if (state.error == null) return;
    
    // Try to use global exception mapper first
    String message;
    try {
      final exceptionMapper = GetIt.instance<IExceptionKeyMapper>();
      final messageKey = exceptionMapper.map(state.error!);
      
      if (messageKey != null) {
        try {
          final localization = GetIt.instance<ILocalizationService>();
          message = localization.translate(messageKey.key, args: messageKey.args);
        } catch (_) {
          message = messageKey.key;
        }
      } else {
        message = state.error.toString();
      }
    } catch (_) {
      message = state.error.toString();
    }
    
    final feedbackService = GetIt.instance<IFeedbackService>();
    feedbackService.show(FeedbackMessage(
      message: message,
      type: MessageType.error,
    ));
  }

  /// Handles success toast display (fallback when no mapper).
  void _handleSuccessState(S state) {
    if (!showSuccessToasts || !state.isSuccess) return;

    final feedbackService = GetIt.instance<IFeedbackService>();
    feedbackService.show(FeedbackMessage(
      message: successMessage ?? _getDefaultSuccessMessage(),
      type: MessageType.success,
    ));
  }

  String _getDefaultSuccessMessage() {
    try {
      final localization = GetIt.instance<ILocalizationService>();
      return localization.translate('operation.completed.successfully');
    } catch (_) {
      return 'Operation completed successfully';
    }
  }
}

/// Convenience widget for screens that only need basic async listening.
class SimpleUiFlowListener<B extends StateStreamable<S>, S extends IUiFlowState>
    extends StatelessWidget {
  final Widget child;
  final B? bloc;
  final bool showSuccessToasts;
  final String? successMessage;

  const SimpleUiFlowListener({
    super.key,
    required this.child,
    this.bloc,
    this.showSuccessToasts = false,
    this.successMessage,
  });

  @override
  Widget build(BuildContext context) {
    return UiFlowListener<B, S>(
      bloc: bloc,
      showSuccessToasts: showSuccessToasts,
      successMessage: successMessage,
      child: child,
    );
  }
}

/// Builder widget that provides async state information to its child.
class AsyncStateBuilder<B extends StateStreamable<S>, S extends IUiFlowState>
    extends StatelessWidget {
  final Widget Function(BuildContext context, S state, Widget? child) builder;
  final Widget? child;
  final B? bloc;

  const AsyncStateBuilder({
    super.key,
    required this.builder,
    this.child,
    this.bloc,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<B, S>(
      bloc: bloc,
      builder: (context, state) => builder(context, state, child),
    );
  }
}
