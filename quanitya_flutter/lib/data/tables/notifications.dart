import 'package:drift/drift.dart';

/// Notifications table - synced via PowerSync
/// 
/// Receives notifications from server (broadcast or user-specific).
/// Users can mark as received or dismiss.
@DataClassName('NotificationData')
class Notifications extends Table {
  /// UUID primary key (synced from server)
  TextColumn get id => text()();
  
  /// Account ID for user-specific notifications (nullable for broadcast)
  TextColumn get accountId => text().named('account_id').nullable()();
  
  /// Notification title
  TextColumn get title => text()();
  
  /// Notification message (plain text)
  TextColumn get message => text()();
  
  /// Notification type: 'inform', 'warning', 'failure', 'success', 'announcement'
  TextColumn get type => text()();
  
  /// When notification was created on server
  DateTimeColumn get createdAt => dateTime().named('created_at')();
  
  /// When notification expires (auto-filtered by PowerSync)
  DateTimeColumn get expiresAt => dateTime().named('expires_at')();
  
  /// Optional deep link or web URL
  TextColumn get actionUrl => text().named('action_url').nullable()();
  
  /// Optional button text for action
  TextColumn get actionLabel => text().named('action_label').nullable()();
  
  /// When user marked as received (nullable = not marked yet)
  DateTimeColumn get markedAt => dateTime().named('marked_at').nullable()();
  
  /// Last updated timestamp
  DateTimeColumn get updatedAt => dateTime().named('updated_at')();
  
  @override
  Set<Column> get primaryKey => {id};
}
