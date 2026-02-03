import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart' hide isNotNull;
import 'package:drift/native.dart';
import 'package:quanitya_flutter/data/db/app_database.dart';
import 'package:quanitya_flutter/data/dao/notification_dao.dart';
import 'package:quanitya_flutter/data/repositories/notification_repository.dart';

void main() {
  late AppDatabase database;
  late NotificationDao dao;
  late NotificationRepository repository;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    dao = NotificationDao(database);
    repository = NotificationRepository(dao);
  });

  tearDown(() async {
    await database.close();
  });

  group('NotificationRepository - Happy Path', () {
    test('watchUnmarkedNotifications - streams notifications', () async {
      // Insert test notification
      await database.into(database.notifications).insert(
        NotificationsCompanion.insert(
          id: 'notif-1',
          title: 'Test Notification',
          message: 'Test message',
          type: 'inform',
          createdAt: DateTime.now(),
          expiresAt: DateTime.now().add(Duration(days: 7)),
          updatedAt: DateTime.now(),
        ),
      );
      
      final stream = repository.watchUnmarkedNotifications();
      
      await expectLater(
        stream.first,
        completion(predicate<List<NotificationData>>((list) {
          return list.length == 1 && list.first.title == 'Test Notification';
        })),
      );
    });

    test('markAsReceived - delegates to DAO', () async {
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
      
      await repository.markAsReceived('notif-1');
      
      final notification = await repository.getNotificationById('notif-1');
      expect(notification!.markedAt, isNotNull);
    });

    test('watchUnmarkedCount - streams count updates', () async {
      final stream = repository.watchUnmarkedCount();
      
      // Collect stream values
      final values = <int>[];
      final subscription = stream.listen(values.add);
      
      // Wait for initial value
      await Future.delayed(Duration(milliseconds: 100));
      expect(values.last, equals(0));
      
      // Add a notification
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
      
      // Wait for stream to update
      await Future.delayed(Duration(milliseconds: 100));
      expect(values.last, equals(1));
      
      await subscription.cancel();
    });
  });
}
