import 'package:drift/drift.dart';
import 'package:injectable/injectable.dart';

import '../../../data/db/app_database.dart';
import '../../../infrastructure/core/try_operation.dart';
import '../exceptions/llm_provider_exception.dart';

/// Record representing a cached OpenRouter model.
class OpenRouterModelRecord {
  final String id;
  final int contextLength;
  final String promptPrice;
  final String completionPrice;
  final bool tested;

  const OpenRouterModelRecord({
    required this.id,
    this.contextLength = 0,
    this.promptPrice = '0',
    this.completionPrice = '0',
    this.tested = false,
  });
}

@lazySingleton
class OpenRouterModelRepository {
  final AppDatabase _db;
  OpenRouterModelRepository(this._db);

  Future<List<OpenRouterModelRecord>> getAll() {
    return tryMethod(
      () async {
        final rows = await (_db.select(_db.openRouterModels)
              ..orderBy([
                (t) => OrderingTerm.desc(t.tested),
                (t) => OrderingTerm.asc(t.id),
              ]))
            .get();
        return rows.map(_rowToRecord).toList();
      },
      LlmProviderException.new,
      'getAll',
    );
  }

  Future<List<OpenRouterModelRecord>> getTested() {
    return tryMethod(
      () async {
        final rows = await (_db.select(_db.openRouterModels)
              ..where((t) => t.tested.equals(true))
              ..orderBy([(t) => OrderingTerm.asc(t.id)]))
            .get();
        return rows.map(_rowToRecord).toList();
      },
      LlmProviderException.new,
      'getTested',
    );
  }

  Future<void> upsertTested(List<String> modelIds) {
    return tryMethod(
      () async {
        await _db.batch((batch) {
          for (final id in modelIds) {
            batch.insert(
              _db.openRouterModels,
              OpenRouterModelsCompanion.insert(
                id: id,
                tested: const Value(true),
              ),
              onConflict: DoUpdate(
                (old) => OpenRouterModelsCompanion(
                  tested: const Value(true),
                ),
                target: [_db.openRouterModels.id],
              ),
            );
          }
        });
      },
      LlmProviderException.new,
      'upsertTested',
    );
  }

  Future<void> upsertFromApi(List<OpenRouterModelRecord> models) {
    return tryMethod(
      () async {
        await _db.batch((batch) {
          for (final model in models) {
            batch.insert(
              _db.openRouterModels,
              OpenRouterModelsCompanion.insert(
                id: model.id,
                contextLength: Value(model.contextLength),
                promptPrice: Value(model.promptPrice),
                completionPrice: Value(model.completionPrice),
              ),
              onConflict: DoUpdate(
                (old) => OpenRouterModelsCompanion(
                  contextLength: Value(model.contextLength),
                  promptPrice: Value(model.promptPrice),
                  completionPrice: Value(model.completionPrice),
                ),
                target: [_db.openRouterModels.id],
              ),
            );
          }
        });
      },
      LlmProviderException.new,
      'upsertFromApi',
    );
  }

  Future<bool> hasTestedModels() {
    return tryMethod(
      () async {
        final count = await (_db.select(_db.openRouterModels)
              ..where((t) => t.tested.equals(true)))
            .get();
        return count.isNotEmpty;
      },
      LlmProviderException.new,
      'hasTestedModels',
    );
  }

  OpenRouterModelRecord _rowToRecord(OpenRouterModel row) {
    return OpenRouterModelRecord(
      id: row.id,
      contextLength: row.contextLength,
      promptPrice: row.promptPrice,
      completionPrice: row.completionPrice,
      tested: row.tested,
    );
  }
}
