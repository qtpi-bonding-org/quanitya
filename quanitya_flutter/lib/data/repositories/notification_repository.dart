import 'package:injectable/injectable.dart';

import '../dao/notification_dao.dart';
import '../db/app_database.dart';

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
  
  Future<void> markAsReceived(String id) => _dao.markAsReceived(id);
  Future<void> dismiss(String id) => _dao.dismiss(id);
  Future<void> markAllAsReceived() => _dao.markAllAsReceived();
  
  // ─────────────────────────────────────────────────────────────────────────
  // Single-shot queries
  // ─────────────────────────────────────────────────────────────────────────
  
  Future<List<NotificationData>> getUnmarkedNotifications() =>
    _dao.getUnmarkedNotifications();
  
  Future<NotificationData?> getNotificationById(String id) =>
    _dao.getNotificationById(id);
}
