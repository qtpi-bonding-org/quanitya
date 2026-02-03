import 'package:injectable/injectable.dart';
import 'package:cubit_ui_flow/cubit_ui_flow.dart';

import '../cubits/feedback_state.dart';

/// Maps feedback state to user messages.
@injectable
class FeedbackMessageMapper implements IStateMessageMapper<FeedbackState> {
  @override
  MessageKey? map(FeedbackState state) {
    if (state.status.isSuccess && state.lastOperation != null) {
      return switch (state.lastOperation!) {
        FeedbackOperation.submit => MessageKey.success('feedback.submitted'),
      };
    }
    return null; // Use global exception mapping for errors
  }
}
