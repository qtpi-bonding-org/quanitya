import 'package:freezed_annotation/freezed_annotation.dart';
import 'value_vector.dart';

part 'timestamp_vector.freezed.dart';
part 'timestamp_vector.g.dart';

/// Array of timestamps: [DateTime, DateTime, ...]
///
/// Represents temporal data extracted from time series matrices.
/// Provides time-specific operations and pattern analysis.
@freezed
class TimestampVector with _$TimestampVector {
  const factory TimestampVector(List<DateTime> timestamps) = _TimestampVector;
  
  factory TimestampVector.fromJson(Map<String, dynamic> json) => 
      _$TimestampVectorFromJson(json);
}

/// Extension methods for TimestampVector temporal operations.
extension TimestampVectorExt on TimestampVector {
  /// Number of timestamps in the vector
  int get length => timestamps.length;
  
  /// Check if vector is empty
  bool get isEmpty => timestamps.isEmpty;
  
  /// Check if vector is not empty
  bool get isNotEmpty => timestamps.isNotEmpty;
  
  /// First timestamp (throws if empty)
  DateTime get first => timestamps.first;
  
  /// Last timestamp (throws if empty)
  DateTime get last => timestamps.last;
  
  /// Time span from first to last timestamp
  Duration get timeSpan => isEmpty ? Duration.zero : last.difference(first);
  
  /// Get timestamp at index (throws if out of bounds)
  DateTime operator [](int index) => timestamps[index];
  
  /// Extract day-of-week numbers (1=Monday, 7=Sunday)
  ValueVector get dayOfWeekVector => ValueVector(
    timestamps.map((t) => t.weekday).toList()
  );
  
  /// Extract hour-of-day numbers (0-23)
  ValueVector get hourOfDayVector => ValueVector(
    timestamps.map((t) => t.hour).toList()
  );
  
  /// Extract day-of-month numbers (1-31)
  ValueVector get dayOfMonthVector => ValueVector(
    timestamps.map((t) => t.day).toList()
  );
  
  /// Extract month numbers (1-12)
  ValueVector get monthVector => ValueVector(
    timestamps.map((t) => t.month).toList()
  );
  
  /// Extract year numbers
  ValueVector get yearVector => ValueVector(
    timestamps.map((t) => t.year).toList()
  );
  
  /// Convert to milliseconds since epoch
  ValueVector get millisecondsVector => ValueVector(
    timestamps.map((t) => t.millisecondsSinceEpoch).toList()
  );
  
  /// Create new vector with timestamps that satisfy predicate
  TimestampVector where(bool Function(DateTime) test) => 
      TimestampVector(timestamps.where(test).toList());
  
  /// Create new vector with timestamps in range [start, end)
  TimestampVector sublist(int start, [int? end]) => 
      TimestampVector(timestamps.sublist(start, end));
  
  /// Check if timestamps are sorted in ascending order
  bool get isSorted {
    for (int i = 1; i < length; i++) {
      if (timestamps[i].isBefore(timestamps[i - 1])) {
        return false;
      }
    }
    return true;
  }
  
  /// Sort timestamps in ascending order
  TimestampVector sorted() {
    final sortedList = List<DateTime>.from(timestamps)..sort();
    return TimestampVector(sortedList);
  }
}