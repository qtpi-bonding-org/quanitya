import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart' hide isNotNull;
import 'package:drift/native.dart';
import 'package:quanitya_flutter/data/db/app_database.dart';
import 'package:quanitya_flutter/data/dao/notification_dao.dart';
import 'package:quanitya_flutter/data/repositories/notification_repository.dart';
import 'package:quanitya_flutter/features/notifications/cubits/notification_inbox_cubit.dart';
import 'package:cubit_ui_flow/cubit_ui_flow.dart';

void main() {
  late AppDatabase database;
  late NotificationDao dao;
  late NotificationRepository repository;
  late NotificationInboxCubit cubit;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    dao = NotificationDao(database);
    repository = NotificationRepository(dao);
    cubit = NotificationInboxCubit(repository);
  });

  tearDown(() async {
    await cubit.close();
    await database.close();
  });

  group('Notification Flow Integration - Happy Path', () {
    test('complete flow: load → mark → verify state update', () async {
      // Insert test notifications
      await database.into(database.notifications).insert(
        NotificationsCompanion.insert(
          id: 'notif-1',
          title: 'Test Notification 1',
          message: 'First test message',
          type: 'inform',
          createdAt: DateTime.now(),
          expiresAt: DateTime.now().add(Duration(days: 7)),
          updatedAt: DateTime.now(),
        ),
      );
      
      await database.into(database.notifications).insert(
        NotificationsCompanion.insert(
          id: 'notif-2',
          title: 'Test Notification 2',
          message: 'Second test message',
          type: 'success',
          createdAt: DateTime.now(),
          expiresAt: DateTime.now().add(Duration(days: 7)),
          updatedAt: DateTime.now(),
        ),
      );
      
      // Load notifications
      cubit.loadNotifications();
      
      // Wait for state to update
      await Future.delayed(Duration(milliseconds: 100));
      
      expect(cubit.state.notifications.length, equals(2));
      expect(cubit.state.status, equals(UiFlowStatus.success));
      
      // Mark one notification
      await cubit.markAsReceived('notif-1');
      
      // Wait for state to update
      await Future.delayed(Duration(milliseconds: 100));
      
      expect(cubit.state.status, equals(UiFlowStatus.success));
      expect(cubit.state.lastOperation, equals(NotificationOperation.markAsReceived));
      
      // Verify notification was marked in database
      final notification = await dao.getNotificationById('notif-1');
      expect(notification!.markedAt, isNotNull);
    });

    test('dismiss notification updates state correctly', () async {
      await database.into(database.notifications).insert(
        NotificationsCompanion.insert(
          id: 'notif-1',
          title: 'Test',
          message: 'Test message',
          type: 'warning',
          createdAt: DateTime.now(),
          expiresAt: DateTime.now().add(Duration(days: 7)),
          updatedAt: DateTime.now(),
        ),
      );
      
      cubit.loadNotifications();
      await Future.delayed(Duration(milliseconds: 100));
      
      expect(cubit.state.notifications.length, equals(1));
      
      await cubit.dismiss('notif-1');
      await Future.delayed(Duration(milliseconds: 100));
      
      expect(cubit.state.status, equals(UiFlowStatus.success));
      expect(cubit.state.lastOperation, equals(NotificationOperation.dismiss));
      
      // Verify notification was marked
      final notification = await dao.getNotificationById('notif-1');
      expect(notification!.markedAt, isNotNull);
    });

    test('markAllAsReceived marks all notifications', () async {
      // Insert 3 notifications
      for (var i = 1; i <= 3; i++) {
        await database.into(database.notifications).insert(
          NotificationsCompanion.insert(
            id: 'notif-$i',
            title: 'Test $i',
            message: 'Message $i',
            type: 'inform',
            createdAt: DateTime.now(),
            expiresAt: DateTime.now().add(Duration(days: 7)),
            updatedAt: DateTime.now(),
          ),
        );
      }
      
      cubit.loadNotifications();
      await Future.delayed(Duration(milliseconds: 100));
      
      expect(cubit.state.notifications.length, equals(3));
      
      await cubit.markAllAsReceived();
      await Future.delayed(Duration(milliseconds: 100));
      
      expect(cubit.state.status, equals(UiFlowStatus.success));
      expect(cubit.state.lastOperation, equals(NotificationOperation.markAllAsReceived));
      
      // Verify all notifications were marked
      final unmarked = await dao.getUnmarkedNotifications();
      expect(unmarked, isEmpty);
    });

    test('reactive updates: marking notification updates stream', () async {
      await database.into(database.notifications).insert(
        NotificationsCompanion.insert(
          id: 'notif-1',
          title: 'Test',
          message: 'Test message',
          type: 'inform',
          createdAt: DateTime.now(),
          expiresAt: DateTime.now().add(Duration(days: 7)),
          updatedAt: DateTime.now(),
        ),
      );
      
      cubit.loadNotifications();
      await Future.delayed(Duration(milliseconds: 100));
      
      expect(cubit.state.notifications.length, equals(1));
      
      // Mark the notification
      await repository.markAsReceived('notif-1');
      
      // Wait for stream to update
      await Future.delayed(Duration(milliseconds: 200));
      
      // Cubit should receive the update via stream
      expect(cubit.state.notifications.length, equals(0));
    });
  });
}
