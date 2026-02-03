import 'package:quanitya_flutter/logic/log_entries/models/log_entry.dart';
import 'package:quanitya_flutter/logic/templates/models/shared/tracker_template.dart';

/// Base interface for all data source adapters.
///
/// Adapters transform external source data into Quanitya's TrackerTemplateModel
/// and LogEntryModel. Generic over the source data type [TSource].
///
/// Two concrete implementations exist:
/// - [FlutterDataSourceAdapter]: For typed Flutter plugin data (no JSON validation)
/// - [JsonDataSourceAdapter]: For raw JSON requiring schema validation
abstract class IDataSourceAdapter<TSource> {
  /// Unique identifier for this adapter (e.g., 'health.steps', 'notion.database')
  String get adapterId;

  /// Human-readable name for UI display
  String get displayName;

  /// Derives a TrackerTemplateModel from source metadata.
  ///
  /// Called once when setting up the import to create or match
  /// the template that will hold the imported data.
  TrackerTemplateModel deriveTemplate();

  /// Maps a single source record to a LogEntryModel.
  ///
  /// The returned entry's data map will include adapter metadata:
  /// - `_sourceAdapter`: The adapter's ID
  /// - `_dedupKey`: Unique identifier from source for deduplication
  LogEntryModel mapToEntry(TSource sourceData, String templateId);

  /// Extracts a unique deduplication key from source data.
  ///
  /// Used to prevent duplicate imports. The key should be stable
  /// across multiple imports of the same source record.
  String extractDedupKey(TSource sourceData);

  /// Extracts the timestamp from source data.
  ///
  /// Used for sync cursor tracking and entry ordering.
  DateTime extractTimestamp(TSource sourceData);
}
