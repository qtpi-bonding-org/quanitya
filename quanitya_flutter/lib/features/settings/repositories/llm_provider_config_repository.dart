import 'package:drift/drift.dart';
import 'package:injectable/injectable.dart';
import 'package:uuid/uuid.dart';

import '../../../data/db/app_database.dart';
import '../../../infrastructure/core/try_operation.dart';
import '../../../infrastructure/llm/models/llm_types.dart';
import '../exceptions/llm_provider_exception.dart';
import '../models/llm_provider_config_model.dart';

@lazySingleton
class LlmProviderConfigRepository {
  final AppDatabase _db;
  static const _uuid = Uuid();

  LlmProviderConfigRepository(this._db);

  Future<List<LlmProviderConfigModel>> getAll() {
    return tryMethod(
      () async {
        final rows = await (_db.select(_db.llmProviderConfigs)
              ..orderBy([(t) => OrderingTerm.desc(t.lastUsedAt)]))
            .get();
        return rows.map(_rowToModel).toList();
      },
      LlmProviderException.new,
      'getAll',
    );
  }

  Future<LlmProviderConfigModel?> getActive() {
    return tryMethod(
      () async {
        final rows = await (_db.select(_db.llmProviderConfigs)
              ..orderBy([(t) => OrderingTerm.desc(t.lastUsedAt)])
              ..limit(1))
            .get();
        return rows.isEmpty ? null : _rowToModel(rows.first);
      },
      LlmProviderException.new,
      'getActive',
    );
  }

  Future<void> save(LlmProviderConfigModel model) {
    return tryMethod(
      () async {
        final id = model.id.isEmpty ? _uuid.v4() : model.id;
        await _db.into(_db.llmProviderConfigs).insertOnConflictUpdate(
              LlmProviderConfigsCompanion.insert(
                id: id,
                provider: Value(model.provider.name),
                baseUrl: model.baseUrl,
                modelId: model.modelId,
                apiKeyId: Value(model.apiKeyId),
                lastUsedAt: model.lastUsedAt,
              ),
            );
      },
      LlmProviderException.new,
      'save',
    );
  }

  Future<void> delete(String id) {
    return tryMethod(
      () async {
        await (_db.delete(_db.llmProviderConfigs)
              ..where((t) => t.id.equals(id)))
            .go();
      },
      LlmProviderException.new,
      'delete',
    );
  }

  /// Persists the Quanitya provider as the active selection.
  /// Uses a stable sentinel row so it participates in the
  /// "most recently used = active" ordering naturally.
  static const quanityaSentinelId = 'quanitya-builtin';

  Future<void> saveQuanityaSelection() {
    return tryMethod(
      () async {
        await _db.into(_db.llmProviderConfigs).insertOnConflictUpdate(
              LlmProviderConfigsCompanion.insert(
                id: quanityaSentinelId,
                provider: const Value('quanitya'),
                baseUrl: '',
                modelId: '',
                lastUsedAt: DateTime.now(),
              ),
            );
      },
      LlmProviderException.new,
      'saveQuanityaSelection',
    );
  }

  Future<void> touchLastUsed(String id) {
    return tryMethod(
      () async {
        await (_db.update(_db.llmProviderConfigs)
              ..where((t) => t.id.equals(id)))
            .write(LlmProviderConfigsCompanion(
          lastUsedAt: Value(DateTime.now()),
        ));
      },
      LlmProviderException.new,
      'touchLastUsed',
    );
  }

  LlmProviderConfigModel _rowToModel(LlmProviderConfig row) {
    return LlmProviderConfigModel(
      id: row.id,
      provider: LlmProvider.values.byName(row.provider),
      baseUrl: row.baseUrl,
      modelId: row.modelId,
      apiKeyId: row.apiKeyId,
      lastUsedAt: row.lastUsedAt,
    );
  }
}
