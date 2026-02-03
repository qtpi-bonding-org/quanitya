import 'i_data_source_adapter.dart';

/// Abstract adapter for JSON-based data sources requiring schema validation.
///
/// Use this base class when importing from APIs, files, or user input
/// where the source data arrives as raw JSON (Map&lt;String, dynamic&gt;).
///
/// Unlike [FlutterDataSourceAdapter], this requires schema validation
/// before processing to ensure data integrity.
///
/// Example:
/// ```dart
/// class NotionDatabaseAdapter extends JsonDataSourceAdapter {
///   @override
///   String get adapterId => 'notion.database';
///
///   @override
///   Map&lt;String, dynamic&gt; get inputSchema =&gt; {
///     'type': 'object',
///     'required': ['id', 'properties'],
///     'properties': {
///       'id': {'type': 'string'},
///       'properties': {'type': 'object'},
///     },
///   };
///
///   @override
///   List&lt;String&gt; validate(Map&lt;String, dynamic&gt; json) {
///     final errors = &lt;String&gt;[];
///     if (json['id'] == null) errors.add('Missing required field: id');
///     return errors;
///   }
/// }
/// ```
abstract class JsonDataSourceAdapter
    implements IDataSourceAdapter<Map<String, dynamic>> {
  /// JSON Schema defining the expected input shape.
  ///
  /// Used for documentation and potentially runtime validation.
  /// Should follow JSON Schema specification.
  Map<String, dynamic> get inputSchema;

  /// Validates raw JSON against the adapter's schema.
  ///
  /// Returns an empty list if validation passes.
  /// Returns a list of error strings describing validation failures.
  ///
  /// Called by [DataIngestionService.syncJson] before processing.
  /// If any errors are returned, a [ValidationException] is thrown
  /// and no data is imported.
  List<String> validate(Map<String, dynamic> json);
}
