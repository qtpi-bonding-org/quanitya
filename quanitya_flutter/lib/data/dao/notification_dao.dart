import 'package:drift/drift.dart';
import 'package:injectable/injectable.dart';

import '../db/app_database.dart';

/// DAO for notification operations.
///
/// Queries Drift tables backed by PowerSync-synced data.
/// PowerSync handles sync, Drift provides ORM for app logic.
@lazySingleton
class NotificationDao {
  final AppDatabase _db;
  
  NotificationDao(this._db);
  
  // ─────────────────────────────────────────────────────────────────────────
  // Query Operations
  // ─────────────────────────────────────────────────────────────────────────
  
  /// Get all unmarked notifications
  Future<List<NotificationData>> getUnmarkedNotifications() async {
    return await (_db.select(_db.notifications)
          ..where((n) => n.markedAt.isNull())
          ..orderBy([(n) => OrderingTerm.desc(n.createdAt)]))
        .get();
  }
  
  /// Get notification by ID
  Future<NotificationData?> getNotificationById(String id) async {
    return await (_db.select(_db.notifications)
          ..where((n) => n.id.equals(id)))
        .getSingleOrNull();
  }
  
  // ─────────────────────────────────────────────────────────────────────────
  // Stream Queries (Reactive UI)
  // ─────────────────────────────────────────────────────────────────────────
  
  /// Watch all unmarked notifications
  Stream<List<NotificationData>> watchUnmarkedNotifications() {
    return (_db.select(_db.notifications)
          ..where((n) => n.markedAt.isNull())
          ..orderBy([(n) => OrderingTerm.desc(n.createdAt)]))
        .watch();
  }
  
  /// Watch count of unmarked notifications
  Stream<int> watchUnmarkedCount() {
    final query = _db.selectOnly(_db.notifications)
      ..addColumns([_db.notifications.id.count()])
      ..where(_db.notifications.markedAt.isNull());
    
    return query.watchSingle().map((row) => 
      row.read(_db.notifications.id.count()) ?? 0
    );
  }
  
  /// Watch notifications by type
  Stream<List<NotificationData>> watchNotificationsByType(String type) {
    return (_db.select(_db.notifications)
          ..where((n) => n.type.equals(type) & n.markedAt.isNull())
          ..orderBy([(n) => OrderingTerm.desc(n.createdAt)]))
        .watch();
  }
  
  // ─────────────────────────────────────────────────────────────────────────
  // Write Operations (PowerSync will sync to server)
  // ─────────────────────────────────────────────────────────────────────────
  
  /// Mark notification as received
  Future<void> markAsReceived(String id) async {
    await (_db.update(_db.notifications)
          ..where((n) => n.id.equals(id)))
        .write(NotificationsCompanion(
      markedAt: Value(DateTime.now()),
      updatedAt: Value(DateTime.now()),
    ));
  }
  
  /// Dismiss notification (same as mark as received)
  Future<void> dismiss(String id) async {
    await markAsReceived(id);
  }
  
  /// Mark all as received
  Future<void> markAllAsReceived() async {
    await (_db.update(_db.notifications)
          ..where((n) => n.markedAt.isNull()))
        .write(NotificationsCompanion(
      markedAt: Value(DateTime.now()),
      updatedAt: Value(DateTime.now()),
    ));
  }
}
