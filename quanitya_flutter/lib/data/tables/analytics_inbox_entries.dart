import 'package:drift/drift.dart';

/// Local-only table for storing analytics events before sending.
///
/// Events always accumulate locally. When auto-send is enabled,
/// unsent events are batch-sent on app startup. Users can also
/// review and send manually from the analytics inbox UI.
@DataClassName('AnalyticsInboxEntryData')
class AnalyticsInboxEntries extends Table {
  /// Auto-increment primary key
  IntColumn get id => integer().autoIncrement()();

  /// Event name (e.g., 'template_created', 'entry_logged')
  TextColumn get eventName => text().named('event_name')();

  /// When the event occurred on the client
  DateTimeColumn get clientTimestamp => dateTime().named('client_timestamp')();

  /// Client platform (iOS, Android, macOS, etc.)
  TextColumn get platform => text().nullable()();

  /// Optional JSON-encoded properties
  TextColumn get props => text().nullable()();

  /// Whether this event has been sent to the server
  BoolColumn get isSent => boolean().named('is_sent').withDefault(const Constant(false))();
}
