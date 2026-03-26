import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:quanitya_flutter/features/notices/cubits/notices_cubit.dart';
import 'package:quanitya_flutter/data/repositories/notification_repository.dart';
import 'package:quanitya_flutter/data/db/app_database.dart';
import 'package:cubit_ui_flow/cubit_ui_flow.dart';

class MockNotificationRepository extends Mock implements NotificationRepository {}

void main() {
  late MockNotificationRepository mockRepository;

  setUp(() {
    mockRepository = MockNotificationRepository();
  });

  group('NoticesCubit - Happy Path', () {
    test('initial state is correct', () {
      final cubit = NoticesCubit(mockRepository);

      expect(cubit.state.notifications, isEmpty);
      expect(cubit.state.status, equals(UiFlowStatus.idle));
      expect(cubit.state.error, isNull);
      expect(cubit.state.lastOperation, isNull);

      cubit.close();
    });

    blocTest<NoticesCubit, NoticesState>(
      'markAsReceived updates state correctly',
      build: () {
        when(() => mockRepository.markAsReceived(any())).thenAnswer((_) async {});
        return NoticesCubit(mockRepository);
      },
      act: (cubit) => cubit.markAsReceived('notif-1'),
      expect: () => [
        predicate<NoticesState>((state) {
          return state.status == UiFlowStatus.success &&
                 state.lastOperation == NotificationOperation.markAsReceived;
        }),
      ],
      verify: (_) {
        verify(() => mockRepository.markAsReceived('notif-1')).called(1);
      },
    );

    blocTest<NoticesCubit, NoticesState>(
      'dismiss updates state correctly',
      build: () {
        when(() => mockRepository.dismiss(any())).thenAnswer((_) async {});
        return NoticesCubit(mockRepository);
      },
      act: (cubit) => cubit.dismiss('notif-1'),
      expect: () => [
        predicate<NoticesState>((state) {
          return state.status == UiFlowStatus.success &&
                 state.lastOperation == NotificationOperation.dismiss;
        }),
      ],
      verify: (_) {
        verify(() => mockRepository.dismiss('notif-1')).called(1);
      },
    );

  });
}
