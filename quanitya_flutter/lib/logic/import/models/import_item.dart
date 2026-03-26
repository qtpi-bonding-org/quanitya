/// An item ready for import: field data + resolved timestamp.
///
/// Created by [TimestampResolver] after date resolution and
/// date field stripping. Consumed by [ImportExecutor].
class ImportItem {
  /// Field-ID-keyed data values (no date metadata field).
  final Map<String, dynamic> data;

  /// Resolved occurredAt timestamp for this item's LogEntry.
  final DateTime occurredAt;

  const ImportItem({required this.data, required this.occurredAt});
}
