import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:quanitya_flutter/features/notifications/cubits/notification_inbox_cubit.dart';
import 'package:quanitya_flutter/data/repositories/notification_repository.dart';
import 'package:quanitya_flutter/data/db/app_database.dart';
import 'package:cubit_ui_flow/cubit_ui_flow.dart';

class MockNotificationRepository extends Mock implements NotificationRepository {}

void main() {
  late MockNotificationRepository mockRepository;

  setUp(() {
    mockRepository = MockNotificationRepository();
  });

  group('NotificationInboxCubit - Happy Path', () {
    test('initial state is correct', () {
      final cubit = NotificationInboxCubit(mockRepository);
      
      expect(cubit.state.notifications, isEmpty);
      expect(cubit.state.status, equals(UiFlowStatus.idle));
      expect(cubit.state.error, isNull);
      expect(cubit.state.lastOperation, isNull);
      
      cubit.close();
    });

    blocTest<NotificationInboxCubit, NotificationInboxState>(
      'loadNotifications emits success with notifications',
      build: () {
        when(() => mockRepository.watchUnmarkedNotifications()).thenAnswer(
          (_) => Stream.value([
            NotificationData(
              id: 'notif-1',
              title: 'Test',
              message: 'Test message',
              type: 'inform',
              createdAt: DateTime.now(),
              expiresAt: DateTime.now().add(Duration(days: 7)),
              updatedAt: DateTime.now(),
            ),
          ]),
        );
        return NotificationInboxCubit(mockRepository);
      },
      act: (cubit) => cubit.loadNotifications(),
      expect: () => [
        predicate<NotificationInboxState>((state) {
          return state.notifications.length == 1 &&
                 state.status == UiFlowStatus.success;
        }),
      ],
    );

    blocTest<NotificationInboxCubit, NotificationInboxState>(
      'markAsReceived updates state correctly',
      build: () {
        when(() => mockRepository.markAsReceived(any())).thenAnswer((_) async {});
        return NotificationInboxCubit(mockRepository);
      },
      act: (cubit) => cubit.markAsReceived('notif-1'),
      expect: () => [
        predicate<NotificationInboxState>((state) {
          return state.status == UiFlowStatus.success &&
                 state.lastOperation == NotificationOperation.markAsReceived;
        }),
      ],
      verify: (_) {
        verify(() => mockRepository.markAsReceived('notif-1')).called(1);
      },
    );

    blocTest<NotificationInboxCubit, NotificationInboxState>(
      'dismiss updates state correctly',
      build: () {
        when(() => mockRepository.dismiss(any())).thenAnswer((_) async {});
        return NotificationInboxCubit(mockRepository);
      },
      act: (cubit) => cubit.dismiss('notif-1'),
      expect: () => [
        predicate<NotificationInboxState>((state) {
          return state.status == UiFlowStatus.success &&
                 state.lastOperation == NotificationOperation.dismiss;
        }),
      ],
      verify: (_) {
        verify(() => mockRepository.dismiss('notif-1')).called(1);
      },
    );

    blocTest<NotificationInboxCubit, NotificationInboxState>(
      'markAllAsReceived emits loading then success',
      build: () {
        when(() => mockRepository.markAllAsReceived()).thenAnswer((_) async {});
        return NotificationInboxCubit(mockRepository);
      },
      act: (cubit) => cubit.markAllAsReceived(),
      expect: () => [
        predicate<NotificationInboxState>((state) => state.status == UiFlowStatus.loading),
        predicate<NotificationInboxState>((state) {
          return state.status == UiFlowStatus.success &&
                 state.lastOperation == NotificationOperation.markAllAsReceived;
        }),
      ],
      verify: (_) {
        verify(() => mockRepository.markAllAsReceived()).called(1);
      },
    );
  });
}
