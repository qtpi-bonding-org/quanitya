import 'package:injectable/injectable.dart';
import 'package:cubit_ui_flow/cubit_ui_flow.dart';

import '../../../support/extensions/cubit_ui_flow_extension.dart';
import '../../../infrastructure/user_feedback/feedback_submission_service.dart';
import 'feedback_state.dart';

/// Cubit for feedback submission.
@injectable
class FeedbackCubit extends QuanityaCubit<FeedbackState> {
  final FeedbackSubmissionService _feedbackService;
  
  FeedbackCubit(this._feedbackService) : super(const FeedbackState());
  
  /// Submit feedback to server.
  Future<void> submitFeedback({
    required String feedbackText,
    required String feedbackType,
  }) async {
    await tryOperation(() async {
      await _feedbackService.submitFeedback(
        feedbackText: feedbackText,
        feedbackType: feedbackType,
      );
      
      return state.copyWith(
        status: UiFlowStatus.success, // ⚠️ REQUIRED - must set explicitly!
        lastOperation: FeedbackOperation.submit,
      );
    }, emitLoading: true);
  }
}
