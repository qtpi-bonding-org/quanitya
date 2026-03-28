import 'package:injectable/injectable.dart';
import '../../ingestion/adapters/import_data_source_adapter.dart';
import '../../ingestion/services/data_ingestion_service.dart';
import '../../ocr/models/extraction_field.dart';
import '../../templates/models/shared/tracker_template.dart';
import '../models/import_item.dart';

/// Executes the final import step — writes ImportItems to the database.
///
/// The only component in the import pipeline with a side effect.
/// Bridges [ImportItem] list to [DataIngestionService.syncJson] by
/// injecting `_occurredAt` metadata into each item's data map.
@injectable
class ImportExecutor {
  final DataIngestionService _ingestionService;

  ImportExecutor(this._ingestionService);

  /// Imports resolved items as log entries.
  Future<int> execute({
    required String templateId,
    required TrackerTemplateModel template,
    required List<ImportItem> items,
    required List<ExtractionField> extractionFields,
  }) async {
    if (items.isEmpty) return 0;

    final sourceData = items.map((item) => <String, dynamic>{
      ...item.data,
      '_occurredAt': item.occurredAt.toIso8601String(),
    }).toList();

    final adapter = ImportDataSourceAdapter(template, extractionFields);

    return _ingestionService.syncJson(
      adapter: adapter,
      templateId: templateId,
      sourceData: sourceData,
    );
  }
}
