import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:cubit_ui_flow/cubit_ui_flow.dart';

import 'package:quanitya_flutter/features/user_feedback/cubits/feedback_cubit.dart';
import 'package:quanitya_flutter/features/user_feedback/cubits/feedback_state.dart';
import 'package:quanitya_flutter/infrastructure/user_feedback/feedback_submission_service.dart';
import 'package:quanitya_flutter/infrastructure/user_feedback/exceptions/feedback_exceptions.dart';

@GenerateMocks([FeedbackSubmissionService])
import 'feedback_cubit_test.mocks.dart';

void main() {
  late FeedbackCubit cubit;
  late MockFeedbackSubmissionService mockService;
  
  setUp(() {
    mockService = MockFeedbackSubmissionService();
    cubit = FeedbackCubit(mockService);
  });
  
  tearDown(() {
    cubit.close();
  });
  
  group('FeedbackCubit', () {
    test('initial state is idle', () {
      expect(cubit.state.status, UiFlowStatus.idle);
      expect(cubit.state.error, isNull);
      expect(cubit.state.lastOperation, isNull);
    });
    
    blocTest<FeedbackCubit, FeedbackState>(
      'submitFeedback emits loading then success',
      build: () {
        when(mockService.submitFeedback(
          feedbackText: anyNamed('feedbackText'),
          feedbackType: anyNamed('feedbackType'),
          metadata: anyNamed('metadata'),
        )).thenAnswer((_) async {});
        return cubit;
      },
      act: (cubit) => cubit.submitFeedback(
        feedbackText: 'Success feedback',
        feedbackType: 'feature_request',
      ),
      expect: () => [
        const FeedbackState(
          status: UiFlowStatus.loading,
          error: null,
          lastOperation: null,
        ),
        const FeedbackState(
          status: UiFlowStatus.success,
          error: null,
          lastOperation: FeedbackOperation.submit,
        ),
      ],
      verify: (_) {
        verify(mockService.submitFeedback(
          feedbackText: 'Success feedback',
          feedbackType: 'feature_request',
          metadata: null,
        )).called(1);
      },
    );
    
    blocTest<FeedbackCubit, FeedbackState>(
      'submitFeedback emits failure state on error',
      build: () {
        when(mockService.submitFeedback(
          feedbackText: anyNamed('feedbackText'),
          feedbackType: anyNamed('feedbackType'),
          metadata: anyNamed('metadata'),
        )).thenThrow(FeedbackException('Feedback too short'));
        return cubit;
      },
      act: (cubit) => cubit.submitFeedback(
        feedbackText: 'Short',
        feedbackType: 'general',
      ),
      expect: () => [
        const FeedbackState(
          status: UiFlowStatus.loading,
          error: null,
          lastOperation: null,
        ),
        predicate<FeedbackState>((state) {
          return state.status == UiFlowStatus.failure &&
                 state.error != null &&
                 state.lastOperation == null;
        }),
      ],
    );
    
    blocTest<FeedbackCubit, FeedbackState>(
      'handles network errors gracefully',
      build: () {
        when(mockService.submitFeedback(
          feedbackText: anyNamed('feedbackText'),
          feedbackType: anyNamed('feedbackType'),
          metadata: anyNamed('metadata'),
        )).thenThrow(Exception('Network error'));
        return cubit;
      },
      act: (cubit) => cubit.submitFeedback(
        feedbackText: 'Network test feedback',
        feedbackType: 'general',
      ),
      expect: () => [
        const FeedbackState(
          status: UiFlowStatus.loading,
          error: null,
          lastOperation: null,
        ),
        predicate<FeedbackState>((state) {
          return state.status == UiFlowStatus.failure &&
                 state.error != null;
        }),
      ],
    );
  });
}
