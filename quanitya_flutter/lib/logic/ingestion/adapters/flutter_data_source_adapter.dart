import 'i_data_source_adapter.dart';

/// Abstract adapter for Flutter plugins that provide typed objects.
///
/// Use this base class when importing from Flutter plugins like Health,
/// where the source data arrives as typed Dart objects (e.g., HealthDataPoint).
///
/// Unlike [JsonDataSourceAdapter], this skips JSON schema validation since
/// the data is already typed by the plugin's API.
///
/// Example:
/// ```dart
/// class HealthStepsAdapter extends FlutterDataSourceAdapter&lt;HealthDataPoint&gt; {
///   @override
///   String get adapterId => 'health.steps';
///
///   @override
///   LogEntryModel mapToEntry(HealthDataPoint source, String templateId) {
///     return LogEntryModel.logNow(
///       templateId: templateId,
///       data: {
///         'value': source.value,
///         '_sourceAdapter': adapterId,
///         '_dedupKey': extractDedupKey(source),
///       },
///     );
///   }
/// }
/// ```
abstract class FlutterDataSourceAdapter<TSource>
    implements IDataSourceAdapter<TSource> {
  // Inherits all methods from IDataSourceAdapter.
  // TSource is the typed object from the Flutter plugin.
  //
  // Concrete implementations access typed properties directly
  // from the source object without JSON validation.
}
