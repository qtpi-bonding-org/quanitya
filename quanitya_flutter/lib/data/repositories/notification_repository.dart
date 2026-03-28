import 'package:injectable/injectable.dart';

import '../../infrastructure/core/try_operation.dart';
import '../dao/notification_dao.dart';
import '../db/app_database.dart';

/// Exception type for notification operations.
class NotificationException implements Exception {
  final String message;
  final Object? cause;

  const NotificationException(this.message, [this.cause]);

  @override
  String toString() => 'NotificationException: $message';
}

/// Repository for notification operations.
///
/// Provides streaming access to PowerSync-synced notifications.
/// Follows Quanitya pattern: DAO for queries, repository for business logic.
@lazySingleton
class NotificationRepository {
  final NotificationDao _dao;

  NotificationRepository(this._dao);

  // ─────────────────────────────────────────────────────────────────────────
  // Stream-based queries (reactive UI)
  // ─────────────────────────────────────────────────────────────────────────

  Stream<List<NotificationData>> watchUnmarkedNotifications() =>
    _dao.watchUnmarkedNotifications();

  Stream<int> watchUnmarkedCount() =>
    _dao.watchUnmarkedCount();

  Stream<List<NotificationData>> watchNotificationsByType(String type) =>
    _dao.watchNotificationsByType(type);

  // ─────────────────────────────────────────────────────────────────────────
  // Actions (PowerSync syncs to server)
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> markAsReceived(String id) => tryMethod(
    () => _dao.markAsReceived(id),
    NotificationException.new,
    'markAsReceived',
  );

  Future<void> dismiss(String id) => tryMethod(
    () => _dao.dismiss(id),
    NotificationException.new,
    'dismiss',
  );

  Future<void> markAllAsReceived() => tryMethod(
    () => _dao.markAllAsReceived(),
    NotificationException.new,
    'markAllAsReceived',
  );

  // ─────────────────────────────────────────────────────────────────────────
  // Single-shot queries
  // ─────────────────────────────────────────────────────────────────────────

  Future<List<NotificationData>> getUnmarkedNotifications() => tryMethod(
    () => _dao.getUnmarkedNotifications(),
    NotificationException.new,
    'getUnmarkedNotifications',
  );

  Future<NotificationData?> getNotificationById(String id) => tryMethod(
    () => _dao.getNotificationById(id),
    NotificationException.new,
    'getNotificationById',
  );
}
