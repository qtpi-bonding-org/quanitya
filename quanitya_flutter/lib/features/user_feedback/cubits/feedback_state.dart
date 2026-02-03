import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:cubit_ui_flow/cubit_ui_flow.dart';

part 'feedback_state.freezed.dart';

/// Operations for feedback submission.
enum FeedbackOperation {
  submit,
}

/// State for feedback submission.
@freezed
class FeedbackState with _$FeedbackState implements IUiFlowState {
  const factory FeedbackState({
    @Default(UiFlowStatus.idle) UiFlowStatus status,
    Object? error,
    FeedbackOperation? lastOperation,
  }) = _FeedbackState;
  
  // IUiFlowState implementations
  const FeedbackState._();
  
  @override
  bool get isIdle => status == UiFlowStatus.idle;
  
  @override
  bool get isLoading => status == UiFlowStatus.loading;
  
  @override
  bool get isSuccess => status == UiFlowStatus.success;
  
  @override
  bool get isFailure => status == UiFlowStatus.failure;
  
  @override
  bool get hasError => error != null;
}
