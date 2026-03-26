import 'package:intl/intl.dart';
import '../models/import_item.dart';

/// Resolves per-item timestamps and strips the designated date field.
///
/// Priority (highest wins):
/// 1. perItemTimestamps — user per-item overrides
/// 2. Designated date field value (parsed from dateFieldId)
/// 3. batchTimestamp — one date for all items
/// 4. DateTime.now() — fallback
class TimestampResolver {
  TimestampResolver._();

  static final _dateFormats = [
    DateFormat('yyyy-MM-dd'),
    DateFormat("yyyy-MM-dd'T'HH:mm:ss"),
    DateFormat('MM/dd/yyyy'),
    DateFormat('dd/MM/yyyy'),
    DateFormat('yyyy/MM/dd'),
    DateFormat('MM-dd-yyyy'),
    DateFormat('dd-MM-yyyy'),
  ];

  static List<ImportItem> resolve({
    required List<Map<String, dynamic>> items,
    String? dateFieldId,
    DateTime? batchTimestamp,
    Map<int, DateTime>? perItemTimestamps,
  }) {
    if (items.isEmpty) return [];
    final now = DateTime.now();

    return items.asMap().entries.map((entry) {
      final index = entry.key;
      final item = entry.value;
      final data = Map<String, dynamic>.of(item);

      DateTime? fieldDate;
      if (dateFieldId != null) {
        final dateValue = data.remove(dateFieldId);
        if (dateValue != null) {
          fieldDate = _parseDate(dateValue.toString());
        }
      }

      final occurredAt = perItemTimestamps?[index]
          ?? fieldDate
          ?? batchTimestamp
          ?? now;

      return ImportItem(data: data, occurredAt: occurredAt);
    }).toList();
  }

  static DateTime? _parseDate(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;
    final iso = DateTime.tryParse(trimmed);
    if (iso != null) return iso;
    for (final format in _dateFormats) {
      try {
        return format.parseStrict(trimmed);
      } catch (_) {
        continue;
      }
    }
    return null;
  }
}
