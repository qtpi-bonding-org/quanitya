import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart' hide isNotNull;
import 'package:drift/native.dart';
import 'package:quanitya_flutter/data/db/app_database.dart';
import 'package:quanitya_flutter/data/dao/notification_dao.dart';

void main() {
  late AppDatabase database;
  late NotificationDao dao;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    dao = NotificationDao(database);
  });

  tearDown(() async {
    await database.close();
  });

  group('NotificationDao - Happy Path', () {
    test('getUnmarkedNotifications - returns only unmarked', () async {
      // Insert marked notification
      await database.into(database.notifications).insert(
        NotificationsCompanion.insert(
          id: 'notif-1',
          title: 'Marked',
          message: 'This is marked',
          type: 'inform',
          createdAt: DateTime.now(),
          expiresAt: DateTime.now().add(Duration(days: 7)),
          markedAt: Value(DateTime.now()),
          updatedAt: DateTime.now(),
        ),
      );
      
      // Insert unmarked notification
      await database.into(database.notifications).insert(
        NotificationsCompanion.insert(
          id: 'notif-2',
          title: 'Unmarked',
          message: 'This is unmarked',
          type: 'inform',
          createdAt: DateTime.now(),
          expiresAt: DateTime.now().add(Duration(days: 7)),
          updatedAt: DateTime.now(),
        ),
      );
      
      final unmarked = await dao.getUnmarkedNotifications();
      
      expect(unmarked.length, equals(1));
      expect(unmarked.first.id, equals('notif-2'));
      expect(unmarked.first.title, equals('Unmarked'));
    });

    test('markAsReceived - updates markedAt timestamp', () async {
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
      
      await dao.markAsReceived('notif-1');
      
      final notification = await dao.getNotificationById('notif-1');
      expect(notification, isNotNull);
      expect(notification!.markedAt, isNotNull);
    });

    test('watchUnmarkedCount - streams correct count', () async {
      // Insert 3 unmarked notifications
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
      
      final stream = dao.watchUnmarkedCount();
      
      await expectLater(
        stream.first,
        completion(equals(3)),
      );
    });

    test('markAllAsReceived - marks all unmarked notifications', () async {
      // Insert 3 unmarked notifications
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
      
      await dao.markAllAsReceived();
      
      final unmarked = await dao.getUnmarkedNotifications();
      expect(unmarked, isEmpty);
    });
  });
}
