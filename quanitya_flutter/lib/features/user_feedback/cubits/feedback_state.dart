import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:cubit_ui_flow/cubit_ui_flow.dart';

part 'feedback_state.freezed.dart';

/// Operations for feedback submission.
enum FeedbackOperation {
  submit,
}

/// State for feedback submission.
@freezed
abstract class FeedbackState with _$FeedbackState, UiFlowStateMixin implements IUiFlowState {
  const factory FeedbackState({
    @Default(UiFlowStatus.idle) UiFlowStatus status,
    Object? error,
    FeedbackOperation? lastOperation,
  }) = _FeedbackState;
  
  const FeedbackState._();
}
