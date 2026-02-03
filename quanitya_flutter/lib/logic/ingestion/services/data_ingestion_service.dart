import 'package:injectable/injectable.dart';

import '../../../data/interfaces/log_entry_interface.dart';
import '../adapters/adapter_registry.dart';
import '../adapters/flutter_data_source_adapter.dart';
import '../adapters/json_data_source_adapter.dart';
import '../exceptions/ingestion_exception.dart';
import '../exceptions/validation_exception.dart';

/// Orchestrates data import from external sources into Quanitya's model.
///
/// Supports two sync paths:
/// - [syncFlutter]: For typed Flutter plugin data (no JSON validation)
/// - [syncJson]: For raw JSON requiring schema validation
///
/// Both paths handle deduplication via `_dedupKey` metadata and use
/// bulk insert for efficient E2EE-compliant writes via Dual DAO.
///
/// Example:
/// ```dart
/// final service = getIt&lt;DataIngestionService&gt;();
///
/// // Sync from Health plugin
/// final count = await service.syncFlutter(
///   adapter: healthStepsAdapter,
///   templateId: 'template-uuid',
///   sourceData: healthDataPoints,
/// );
/// print('Imported $count entries');
/// ```
@lazySingleton
class DataIngestionService {
  final AdapterRegistry _registry;
  final ILogEntryRepository _logEntryRepo;

  DataIngestionService(this._registry, this._logEntryRepo);

  /// Provides access to the adapter registry for discovery.
  AdapterRegistry get registry => _registry;

  /// Syncs data from a Flutter typed source.
  ///
  /// This method:
  /// 1. Retrieves existing dedup keys for the template
  /// 2. Filters source data to exclude duplicates
  /// 3. Maps remaining items to LogEntryModels with adapter metadata
  /// 4. Bulk inserts via repository (E2EE compliant)
  ///
  /// Returns the count of newly imported entries.
  ///
  /// Throws [IngestionException] if the operation fails.
  Future<int> syncFlutter<TSource>({
    required FlutterDataSourceAdapter<TSource> adapter,
    required String templateId,
    required List<TSource> sourceData,
  }) async {
    if (sourceData.isEmpty) return 0;

    try {
      // 1. Get existing dedup keys for this template
      final existingKeys = await _logEntryRepo.getDedupKeysForTemplate(templateId);

      // 2. Filter out duplicates
      final newItems = sourceData.where((item) {
        final dedupKey = adapter.extractDedupKey(item);
        return !existingKeys.contains(dedupKey);
      }).toList();

      if (newItems.isEmpty) return 0;

      // 3. Map to LogEntryModels with adapter metadata
      final entries = newItems.map((item) {
        return adapter.mapToEntry(item, templateId);
      }).toList();

      // 4. Bulk insert via repository
      await _logEntryRepo.bulkInsert(entries);

      return entries.length;
    } catch (e) {
      if (e is IngestionException) rethrow;
      throw IngestionException('Failed to sync Flutter data', e);
    }
  }

  /// Syncs data from a JSON-based source.
  ///
  /// This method:
  /// 1. Validates ALL items against the adapter's schema first
  /// 2. Throws [ValidationException] if any validation errors exist
  /// 3. Retrieves existing dedup keys for the template
  /// 4. Filters source data to exclude duplicates
  /// 5. Maps remaining items to LogEntryModels with adapter metadata
  /// 6. Bulk inserts via repository (E2EE compliant)
  ///
  /// Returns the count of newly imported entries.
  ///
  /// Throws [ValidationException] if schema validation fails.
  /// Throws [IngestionException] if the operation fails for other reasons.
  Future<int> syncJson({
    required JsonDataSourceAdapter adapter,
    required String templateId,
    required List<Map<String, dynamic>> sourceData,
  }) async {
    if (sourceData.isEmpty) return 0;

    try {
      // 1. Validate ALL items first (fail fast)
      final validationErrors = <String, List<String>>{};
      
      for (var i = 0; i < sourceData.length; i++) {
        final item = sourceData[i];
        final errors = adapter.validate(item);
        if (errors.isNotEmpty) {
          // Use index-based key to avoid collisions, include ID if available for context
          final itemId = item['id']?.toString();
          final itemKey = itemId != null ? '[$i] $itemId' : '[$i]';
          validationErrors[itemKey] = errors;
        }
      }

      // 2. Throw if any validation errors
      if (validationErrors.isNotEmpty) {
        throw ValidationException(validationErrors);
      }

      // 3. Get existing dedup keys for this template
      final existingKeys = await _logEntryRepo.getDedupKeysForTemplate(templateId);

      // 4. Filter out duplicates
      final newItems = sourceData.where((item) {
        final dedupKey = adapter.extractDedupKey(item);
        return !existingKeys.contains(dedupKey);
      }).toList();

      if (newItems.isEmpty) return 0;

      // 5. Map to LogEntryModels with adapter metadata
      final entries = newItems.map((item) {
        return adapter.mapToEntry(item, templateId);
      }).toList();

      // 6. Bulk insert via repository
      await _logEntryRepo.bulkInsert(entries);

      return entries.length;
    } catch (e) {
      if (e is ValidationException || e is IngestionException) rethrow;
      throw IngestionException('Failed to sync JSON data', e);
    }
  }
}
