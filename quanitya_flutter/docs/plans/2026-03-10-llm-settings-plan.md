# LLM Provider Configuration — Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Replace hardcoded `openai/gpt-4o-mini` with user-configurable LLM provider settings (OpenRouter/Ollama) managed from Settings, with tested models fetched from a JSON file in the public repo.

**Architecture:** Two new Drift tables (`OpenRouterModels`, `LlmProviderConfigs`) store cached models and saved provider configs. A `TestedModelsService` fetches known-good models from GitHub on startup. `LlmProviderCubit` manages all state and exposes `buildLlmConfig()` for AI features to consume. Settings UI uses `NotebookFold` + `LooseInsertSheet` pattern.

**Tech Stack:** Drift (DB), Freezed (models/state), Cubit (state management), Injectable/GetIt (DI), http (API calls), flutter_secure_storage (API keys via existing `ApiKeyRepository`)

**Design doc:** `docs/plans/2026-03-10-llm-settings-design.md`

---

## Task 1: Create `tested_models.json` in Public Repo

**Files:**
- Create: `public/tested_models.json`

**Step 1: Create the JSON file**

```json
{
  "tested_models": [
    "openai/gpt-4o-mini"
  ],
  "recommended_default": "openai/gpt-4o-mini"
}
```

Create this at the repo root's `public/` directory (same level as `quanitya_flutter/`). This is the single source of truth for which models are tested and what the default should be.

**Step 2: Verify the file is valid JSON**

Run: `cat public/tested_models.json | python3 -m json.tool`
Expected: Pretty-printed JSON output without errors.

Note: The path relative to the git root is `public/tested_models.json`. The Flutter app will fetch this via raw GitHub URL.

**Step 3: Commit**

```bash
git add public/tested_models.json
git commit -m "feat: add tested_models.json for LLM provider defaults"
```

---

## Task 2: Add `OpenRouterModels` and `LlmProviderConfigs` Drift Tables

**Files:**
- Modify: `lib/data/tables/tables.dart` — add two new table classes
- Modify: `lib/data/db/app_database.dart` — register tables, bump schema, add migration

**Step 1: Add table classes to `lib/data/tables/tables.dart`**

Append at the end of the file (after the `AppOperatingSettings` class, before any closing content):

```dart
/// OpenRouterModels table - cached model list from OpenRouter API
///
/// LOCAL-ONLY - never synced. Populated from two sources:
/// 1. tested_models.json (GitHub) on startup — sets tested: true
/// 2. Full OpenRouter API /models endpoint — sets pricing/context data
///
/// The `tested` flag is preserved across upserts: OpenRouter API fetch
/// never overwrites tested: true with false.
class OpenRouterModels extends Table {
  /// Model ID (e.g., 'openai/gpt-4o-mini')
  TextColumn get id => text()();

  /// Context window length in tokens
  IntColumn get contextLength =>
      integer().named('context_length').withDefault(const Constant(0))();

  /// Price per prompt token as string (to avoid floating point)
  TextColumn get promptPrice =>
      text().named('prompt_price').withDefault(const Constant('0'))();

  /// Price per completion token as string
  TextColumn get completionPrice =>
      text().named('completion_price').withDefault(const Constant('0'))();

  /// Whether this model has been tested/verified with Quanitya
  BoolColumn get tested =>
      boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

/// LlmProviderConfigs table - saved LLM provider configurations
///
/// LOCAL-ONLY - never synced. Users can save multiple configs
/// (OpenRouter, Ollama). Most recently used config is active on app restart.
/// Identified by baseUrl + modelId combo (no name column).
class LlmProviderConfigs extends Table {
  /// Primary key - UUID format string
  TextColumn get id => text()();

  /// Base URL (e.g., 'https://openrouter.ai/api/v1' or 'http://localhost:11434/v1')
  TextColumn get baseUrl => text().named('base_url')();

  /// Model identifier (e.g., 'openai/gpt-4o-mini', 'llama3')
  TextColumn get modelId => text().named('model_id')();

  /// FK to ApiKeys - nullable (Ollama doesn't need one)
  TextColumn get apiKeyId => text().named('api_key_id').nullable()();

  /// Last time this config was actively used - most recent = active config
  DateTimeColumn get lastUsedAt => dateTime().named('last_used_at')();

  @override
  Set<Column> get primaryKey => {id};
}
```

**Step 2: Register tables in `lib/data/db/app_database.dart`**

Add `OpenRouterModels` and `LlmProviderConfigs` to the `@DriftDatabase` tables list (after `AnalyticsInboxEntries`):

```dart
@DriftDatabase(
  tables: [
    TrackerTemplates,
    LogEntries,
    Schedules,
    TemplateAesthetics,
    AnalysisPipelines,
    EncryptedTemplates,
    EncryptedEntries,
    EncryptedSchedules,
    EncryptedAnalysisPipelines,
    ApiKeys,
    Webhooks,
    AppOperatingSettings,
    ErrorBoxEntries,
    Notifications,
    AnalyticsInboxEntries,
    OpenRouterModels,       // ← NEW
    LlmProviderConfigs,     // ← NEW
  ],
)
```

Bump schema version from 4 to 5:

```dart
@override
int get schemaVersion => 5;
```

Add migration case:

```dart
if (from < 5) {
  // Add LLM provider config tables
  await m.createTable(openRouterModels);
  await m.createTable(llmProviderConfigs);
}
```

**Step 3: Run code generation**

Run: `cd /Users/aicoder/Documents/openops/project/quanitya/public/quanitya_flutter && dart run build_runner build --delete-conflicting-outputs`
Expected: Successful build, `app_database.g.dart` regenerated with new table accessors.

**Step 4: Verify generated code compiles**

Run: `cd /Users/aicoder/Documents/openops/project/quanitya/public/quanitya_flutter && dart analyze lib/data/db/app_database.dart`
Expected: No errors.

**Step 5: Commit**

```bash
git add lib/data/tables/tables.dart lib/data/db/app_database.dart lib/data/db/app_database.g.dart
git commit -m "feat: add OpenRouterModels and LlmProviderConfigs Drift tables (schema v5)"
```

---

## Task 3: Create `LlmProviderException` and Register in Exception Mapper

**Files:**
- Create: `lib/features/settings/exceptions/llm_provider_exception.dart`
- Modify: `lib/infrastructure/feedback/exception_mapper.dart`

**Step 1: Create the exception class**

Create `lib/features/settings/exceptions/llm_provider_exception.dart`:

```dart
/// Exception for LLM provider configuration operations.
class LlmProviderException implements Exception {
  final String message;
  final Object? cause;
  const LlmProviderException(this.message, [this.cause]);
}
```

**Step 2: Add to global exception mapper**

In `lib/infrastructure/feedback/exception_mapper.dart`:

Add import at top:
```dart
import '../../features/settings/exceptions/llm_provider_exception.dart';
```

Add case in the `switch` block, before the `// Generic exceptions` comment:
```dart
// LLM provider exceptions
LlmProviderException() => const MessageKey.error(L10nKeys.errorLlmProviderFailed),
```

**Step 3: Verify no compile errors**

Run: `dart analyze lib/infrastructure/feedback/exception_mapper.dart`
Expected: May warn about missing L10nKeys — that's fine, we'll add them in Task 5.

**Step 4: Commit**

```bash
git add lib/features/settings/exceptions/llm_provider_exception.dart lib/infrastructure/feedback/exception_mapper.dart
git commit -m "feat: add LlmProviderException and register in global exception mapper"
```

---

## Task 4: Create `LlmProviderConfigModel` (Freezed)

**Files:**
- Create: `lib/features/settings/models/llm_provider_config_model.dart`

**Step 1: Create the freezed model**

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'llm_provider_config_model.freezed.dart';

@freezed
class LlmProviderConfigModel with _$LlmProviderConfigModel {
  const factory LlmProviderConfigModel({
    required String id,
    required String baseUrl,
    required String modelId,
    String? apiKeyId,
    required DateTime lastUsedAt,
  }) = _LlmProviderConfigModel;
}
```

**Step 2: Run code generation**

Run: `dart run build_runner build --delete-conflicting-outputs`
Expected: `llm_provider_config_model.freezed.dart` generated.

**Step 3: Commit**

```bash
git add lib/features/settings/models/
git commit -m "feat: add LlmProviderConfigModel freezed class"
```

---

## Task 5: Add L10n Keys

**Files:**
- Modify: `lib/l10n/app_en.arb`

**Step 1: Add localization keys**

Add these entries to `lib/l10n/app_en.arb` (inside the JSON object, before the closing `}`):

```json
  "settingsLlmSection": "LLM Provider",
  "llmProviderSaved": "Provider config saved",
  "llmProviderDeleted": "Provider config deleted",
  "llmProviderConnectionSuccess": "Connection successful",
  "errorLlmProviderFailed": "LLM provider operation failed",
  "llmProviderBaseUrl": "Base URL",
  "llmProviderModel": "Model",
  "llmProviderSearchModels": "Search models...",
  "llmProviderTestConnection": "Test Connection",
  "llmProviderAddConfig": "Add Config",
  "llmProviderNoConfigs": "No LLM providers configured",
  "llmProviderNoConfigsDescription": "Add an OpenRouter or Ollama config to use AI features",
  "llmProviderModelTested": "Tested",
  "llmProviderModelUntested": "Untested — may not work with Quanitya",
  "llmProviderConfigureLlm": "Configure LLM in Settings to use AI features",
  "llmProviderFetchingModels": "Fetching models..."
```

**Step 2: Run code generation to regenerate L10n resolver**

Run: `dart run build_runner build --delete-conflicting-outputs`
Expected: `l10n_key_resolver.g.dart` regenerated with new keys.

**Step 3: Verify new keys are accessible**

Run: `grep -c "llmProvider" lib/l10n/l10n_key_resolver.g.dart`
Expected: Multiple matches (one per new key).

**Step 4: Commit**

```bash
git add lib/l10n/app_en.arb lib/l10n/l10n_key_resolver.g.dart
git commit -m "feat: add L10n keys for LLM provider settings"
```

---

## Task 6: Create `OpenRouterModelRepository`

**Files:**
- Create: `lib/features/settings/repositories/open_router_model_repository.dart`
- Test: `test/features/settings/repositories/open_router_model_repository_test.dart`

**Step 1: Write the test**

Create `test/features/settings/repositories/open_router_model_repository_test.dart`:

```dart
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quanitya_flutter/data/db/app_database.dart';
import 'package:quanitya_flutter/features/settings/repositories/open_router_model_repository.dart';

void main() {
  late AppDatabase database;
  late OpenRouterModelRepository repository;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    repository = OpenRouterModelRepository(database);
  });

  tearDown(() async {
    await database.close();
  });

  group('upsertTested', () {
    test('inserts models with tested flag true', () async {
      await repository.upsertTested(['openai/gpt-4o-mini', 'google/gemini-pro']);

      final tested = await repository.getTested();
      expect(tested.length, 2);
      expect(tested.every((m) => m.tested), isTrue);
    });

    test('preserves tested flag on re-upsert', () async {
      await repository.upsertTested(['openai/gpt-4o-mini']);
      await repository.upsertTested(['openai/gpt-4o-mini']);

      final tested = await repository.getTested();
      expect(tested.length, 1);
      expect(tested.first.tested, isTrue);
    });
  });

  group('upsertFromApi', () {
    test('inserts models with pricing data', () async {
      await repository.upsertFromApi([
        OpenRouterModelRecord(
          id: 'openai/gpt-4o',
          contextLength: 128000,
          promptPrice: '0.005',
          completionPrice: '0.015',
          tested: false,
        ),
      ]);

      final all = await repository.getAll();
      expect(all.length, 1);
      expect(all.first.contextLength, 128000);
      expect(all.first.promptPrice, '0.005');
    });

    test('preserves tested flag when upserting from API', () async {
      // First mark as tested
      await repository.upsertTested(['openai/gpt-4o-mini']);

      // Then upsert from API (tested: false in API data)
      await repository.upsertFromApi([
        OpenRouterModelRecord(
          id: 'openai/gpt-4o-mini',
          contextLength: 128000,
          promptPrice: '0.005',
          completionPrice: '0.015',
          tested: false,
        ),
      ]);

      final tested = await repository.getTested();
      expect(tested.length, 1);
      expect(tested.first.id, 'openai/gpt-4o-mini');
      expect(tested.first.tested, isTrue);
      expect(tested.first.contextLength, 128000);
    });
  });

  group('hasTestedModels', () {
    test('returns false when empty', () async {
      final result = await repository.hasTestedModels();
      expect(result, isFalse);
    });

    test('returns true after upserting tested models', () async {
      await repository.upsertTested(['openai/gpt-4o-mini']);
      final result = await repository.hasTestedModels();
      expect(result, isTrue);
    });
  });
}
```

**Step 2: Run test to verify it fails**

Run: `cd /Users/aicoder/Documents/openops/project/quanitya/public/quanitya_flutter && flutter test test/features/settings/repositories/open_router_model_repository_test.dart`
Expected: FAIL — `open_router_model_repository.dart` does not exist.

**Step 3: Create the repository**

Create `lib/features/settings/repositories/open_router_model_repository.dart`:

```dart
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

  /// Get all cached models, ordered by tested first then alphabetically.
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

  /// Get only tested models.
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

  /// Upsert model IDs as tested. Only sets id and tested=true; other fields
  /// get defaults. Existing rows keep their pricing/context data.
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

  /// Upsert models from OpenRouter API. Preserves existing `tested` flag —
  /// never overwrites tested=true with false.
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
                  // Note: tested column NOT included — preserves existing value
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

  /// Check if any tested models exist in the cache.
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
```

**Step 4: Run tests to verify they pass**

Run: `flutter test test/features/settings/repositories/open_router_model_repository_test.dart`
Expected: All 5 tests pass.

**Step 5: Commit**

```bash
git add lib/features/settings/repositories/open_router_model_repository.dart test/features/settings/repositories/open_router_model_repository_test.dart
git commit -m "feat: add OpenRouterModelRepository with tested model support"
```

---

## Task 7: Create `LlmProviderConfigRepository`

**Files:**
- Create: `lib/features/settings/repositories/llm_provider_config_repository.dart`
- Test: `test/features/settings/repositories/llm_provider_config_repository_test.dart`

**Step 1: Write the test**

Create `test/features/settings/repositories/llm_provider_config_repository_test.dart`:

```dart
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quanitya_flutter/data/db/app_database.dart';
import 'package:quanitya_flutter/features/settings/models/llm_provider_config_model.dart';
import 'package:quanitya_flutter/features/settings/repositories/llm_provider_config_repository.dart';

void main() {
  late AppDatabase database;
  late LlmProviderConfigRepository repository;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    repository = LlmProviderConfigRepository(database);
  });

  tearDown(() async {
    await database.close();
  });

  LlmProviderConfigModel _makeConfig({
    String id = 'config-1',
    String baseUrl = 'https://openrouter.ai/api/v1',
    String modelId = 'openai/gpt-4o-mini',
    String? apiKeyId,
    DateTime? lastUsedAt,
  }) {
    return LlmProviderConfigModel(
      id: id,
      baseUrl: baseUrl,
      modelId: modelId,
      apiKeyId: apiKeyId,
      lastUsedAt: lastUsedAt ?? DateTime(2026, 1, 1),
    );
  }

  group('save and getAll', () {
    test('saves and retrieves config', () async {
      final config = _makeConfig();
      await repository.save(config);

      final all = await repository.getAll();
      expect(all.length, 1);
      expect(all.first.baseUrl, 'https://openrouter.ai/api/v1');
      expect(all.first.modelId, 'openai/gpt-4o-mini');
    });

    test('getAll returns ordered by lastUsedAt DESC', () async {
      await repository.save(_makeConfig(
        id: 'old',
        lastUsedAt: DateTime(2026, 1, 1),
      ));
      await repository.save(_makeConfig(
        id: 'new',
        lastUsedAt: DateTime(2026, 3, 1),
      ));

      final all = await repository.getAll();
      expect(all.first.id, 'new');
      expect(all.last.id, 'old');
    });
  });

  group('getActive', () {
    test('returns most recently used config', () async {
      await repository.save(_makeConfig(
        id: 'old',
        lastUsedAt: DateTime(2026, 1, 1),
      ));
      await repository.save(_makeConfig(
        id: 'new',
        modelId: 'google/gemini-pro',
        lastUsedAt: DateTime(2026, 3, 1),
      ));

      final active = await repository.getActive();
      expect(active, isNotNull);
      expect(active!.id, 'new');
    });

    test('returns null when no configs exist', () async {
      final active = await repository.getActive();
      expect(active, isNull);
    });
  });

  group('delete', () {
    test('removes config by id', () async {
      await repository.save(_makeConfig(id: 'to-delete'));
      await repository.delete('to-delete');

      final all = await repository.getAll();
      expect(all, isEmpty);
    });
  });

  group('touchLastUsed', () {
    test('updates lastUsedAt to now', () async {
      final oldDate = DateTime(2020, 1, 1);
      await repository.save(_makeConfig(id: 'touch-me', lastUsedAt: oldDate));

      await repository.touchLastUsed('touch-me');

      final active = await repository.getActive();
      expect(active!.id, 'touch-me');
      expect(active.lastUsedAt.isAfter(oldDate), isTrue);
    });
  });
}
```

**Step 2: Run test to verify it fails**

Run: `flutter test test/features/settings/repositories/llm_provider_config_repository_test.dart`
Expected: FAIL — `llm_provider_config_repository.dart` does not exist.

**Step 3: Create the repository**

Create `lib/features/settings/repositories/llm_provider_config_repository.dart`:

```dart
import 'package:drift/drift.dart';
import 'package:injectable/injectable.dart';
import 'package:uuid/uuid.dart';

import '../../../data/db/app_database.dart';
import '../../../infrastructure/core/try_operation.dart';
import '../exceptions/llm_provider_exception.dart';
import '../models/llm_provider_config_model.dart';

@lazySingleton
class LlmProviderConfigRepository {
  final AppDatabase _db;
  static const _uuid = Uuid();

  LlmProviderConfigRepository(this._db);

  /// Get all configs ordered by lastUsedAt DESC (most recent first).
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

  /// Get the active config (most recently used). Returns null if none exist.
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

  /// Upsert a config. Generates UUID if id is empty.
  Future<void> save(LlmProviderConfigModel model) {
    return tryMethod(
      () async {
        final id = model.id.isEmpty ? _uuid.v4() : model.id;
        await _db.into(_db.llmProviderConfigs).insertOnConflictUpdate(
              LlmProviderConfigsCompanion.insert(
                id: id,
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

  /// Delete a config by id.
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

  /// Update lastUsedAt to now, making this the active config.
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
      baseUrl: row.baseUrl,
      modelId: row.modelId,
      apiKeyId: row.apiKeyId,
      lastUsedAt: row.lastUsedAt,
    );
  }
}
```

**Step 4: Run tests to verify they pass**

Run: `flutter test test/features/settings/repositories/llm_provider_config_repository_test.dart`
Expected: All 6 tests pass.

**Step 5: Commit**

```bash
git add lib/features/settings/repositories/llm_provider_config_repository.dart test/features/settings/repositories/llm_provider_config_repository_test.dart
git commit -m "feat: add LlmProviderConfigRepository with CRUD and active config"
```

---

## Task 8: Create `TestedModelsService`

**Files:**
- Create: `lib/features/settings/services/tested_models_service.dart`
- Test: `test/features/settings/services/tested_models_service_test.dart`

**Step 1: Write the test**

Create `test/features/settings/services/tested_models_service_test.dart`:

```dart
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:drift/native.dart';
import 'package:quanitya_flutter/data/db/app_database.dart';
import 'package:quanitya_flutter/features/settings/repositories/open_router_model_repository.dart';
import 'package:quanitya_flutter/features/settings/repositories/llm_provider_config_repository.dart';
import 'package:quanitya_flutter/features/settings/services/tested_models_service.dart';

void main() {
  late AppDatabase database;
  late OpenRouterModelRepository modelRepo;
  late LlmProviderConfigRepository configRepo;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    modelRepo = OpenRouterModelRepository(database);
    configRepo = LlmProviderConfigRepository(database);
  });

  tearDown(() async {
    await database.close();
  });

  http.Client _mockClient(Map<String, dynamic> responseBody, {int statusCode = 200}) {
    return MockClient((request) async {
      return http.Response(jsonEncode(responseBody), statusCode);
    });
  }

  http.Client _failingClient() {
    return MockClient((request) async {
      throw Exception('Network error');
    });
  }

  group('syncOnStartup', () {
    test('upserts tested models and creates default config', () async {
      final client = _mockClient({
        'tested_models': ['openai/gpt-4o-mini'],
        'recommended_default': 'openai/gpt-4o-mini',
      });

      final service = TestedModelsService(modelRepo, configRepo, client);
      await service.syncOnStartup();

      final tested = await modelRepo.getTested();
      expect(tested.length, 1);
      expect(tested.first.id, 'openai/gpt-4o-mini');

      final active = await configRepo.getActive();
      expect(active, isNotNull);
      expect(active!.modelId, 'openai/gpt-4o-mini');
      expect(active.baseUrl, 'https://openrouter.ai/api/v1');
    });

    test('does not create default config if one already exists', () async {
      // Pre-create a config
      await configRepo.save(LlmProviderConfigModel(
        id: 'existing',
        baseUrl: 'http://localhost:11434/v1',
        modelId: 'llama3',
        lastUsedAt: DateTime.now(),
      ));

      final client = _mockClient({
        'tested_models': ['openai/gpt-4o-mini'],
        'recommended_default': 'openai/gpt-4o-mini',
      });

      final service = TestedModelsService(modelRepo, configRepo, client);
      await service.syncOnStartup();

      final all = await configRepo.getAll();
      expect(all.length, 1);
      expect(all.first.modelId, 'llama3');
    });

    test('fails gracefully on network error', () async {
      final client = _failingClient();
      final service = TestedModelsService(modelRepo, configRepo, client);

      // Should not throw
      await service.syncOnStartup();

      final tested = await modelRepo.getTested();
      expect(tested, isEmpty);
    });
  });

  group('refreshTestedModels', () {
    test('refreshes tested models without creating config', () async {
      final client = _mockClient({
        'tested_models': ['openai/gpt-4o-mini', 'google/gemini-pro'],
        'recommended_default': 'openai/gpt-4o-mini',
      });

      final service = TestedModelsService(modelRepo, configRepo, client);
      await service.refreshTestedModels();

      final tested = await modelRepo.getTested();
      expect(tested.length, 2);

      // Should NOT create a config
      final active = await configRepo.getActive();
      expect(active, isNull);
    });
  });
}
```

**Step 2: Run test to verify it fails**

Run: `flutter test test/features/settings/services/tested_models_service_test.dart`
Expected: FAIL — `tested_models_service.dart` does not exist.

**Step 3: Create the service**

Create `lib/features/settings/services/tested_models_service.dart`:

```dart
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:injectable/injectable.dart';
import 'package:uuid/uuid.dart';

import '../models/llm_provider_config_model.dart';
import '../repositories/llm_provider_config_repository.dart';
import '../repositories/open_router_model_repository.dart';

const _testedModelsUrl =
    'https://raw.githubusercontent.com/user/quanitya/main/public/tested_models.json';

const _uuid = Uuid();

@lazySingleton
class TestedModelsService {
  final OpenRouterModelRepository _modelRepo;
  final LlmProviderConfigRepository _configRepo;
  final http.Client _client;

  TestedModelsService(this._modelRepo, this._configRepo, this._client);

  /// Called on app startup. Fetches tested_models.json, upserts to DB,
  /// creates default config if none exists. Fails silently on network error.
  Future<void> syncOnStartup() async {
    try {
      final json = await _fetchTestedModelsJson();
      if (json == null) return;

      final modelIds = (json['tested_models'] as List).cast<String>();
      await _modelRepo.upsertTested(modelIds);

      // Create default config if none exists
      final existing = await _configRepo.getActive();
      if (existing == null) {
        final defaultModel =
            json['recommended_default'] as String? ?? modelIds.first;
        await _configRepo.save(LlmProviderConfigModel(
          id: _uuid.v4(),
          baseUrl: 'https://openrouter.ai/api/v1',
          modelId: defaultModel,
          lastUsedAt: DateTime.now(),
        ));
      }
    } catch (_) {
      // Fail gracefully — use whatever is already persisted
    }
  }

  /// Re-fetches tested_models.json. Called from Settings if no tested models in DB.
  Future<void> refreshTestedModels() async {
    final json = await _fetchTestedModelsJson();
    if (json == null) return;

    final modelIds = (json['tested_models'] as List).cast<String>();
    await _modelRepo.upsertTested(modelIds);
  }

  Future<Map<String, dynamic>?> _fetchTestedModelsJson() async {
    try {
      final response = await _client.get(Uri.parse(_testedModelsUrl));
      if (response.statusCode != 200) return null;
      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }
}
```

> **Note for implementer:** The `_testedModelsUrl` constant needs to be updated with the actual GitHub raw URL for the repo once known. The URL pattern is `https://raw.githubusercontent.com/{owner}/{repo}/main/public/tested_models.json`.

**Step 4: Run tests to verify they pass**

Run: `flutter test test/features/settings/services/tested_models_service_test.dart`
Expected: All 4 tests pass.

**Step 5: Commit**

```bash
git add lib/features/settings/services/tested_models_service.dart test/features/settings/services/tested_models_service_test.dart
git commit -m "feat: add TestedModelsService for startup sync of tested models"
```

---

## Task 9: Create `LlmProviderCubit`, State, and Message Mapper

**Files:**
- Create: `lib/features/settings/cubits/llm_provider/llm_provider_state.dart`
- Create: `lib/features/settings/cubits/llm_provider/llm_provider_cubit.dart`
- Create: `lib/features/settings/cubits/llm_provider/llm_provider_message_mapper.dart`
- Test: `test/features/settings/cubits/llm_provider/llm_provider_cubit_test.dart`

**Step 1: Create the state**

Create `lib/features/settings/cubits/llm_provider/llm_provider_state.dart`:

```dart
import 'package:cubit_ui_flow/cubit_ui_flow.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../models/llm_provider_config_model.dart';
import '../../repositories/open_router_model_repository.dart';

part 'llm_provider_state.freezed.dart';

enum LlmProviderOperation { load, save, delete, testConnection, fetchModels }

@freezed
class LlmProviderState with _$LlmProviderState implements IUiFlowState {
  const LlmProviderState._();

  const factory LlmProviderState({
    @Default([]) List<LlmProviderConfigModel> configs,
    LlmProviderConfigModel? activeConfig,
    @Default([]) List<OpenRouterModelRecord> availableModels,
    @Default(UiFlowStatus.idle) UiFlowStatus status,
    Object? error,
    LlmProviderOperation? lastOperation,
  }) = _LlmProviderState;

  @override
  bool get isIdle => status == UiFlowStatus.idle;

  @override
  bool get isLoading => status == UiFlowStatus.loading;

  @override
  bool get isSuccess => status == UiFlowStatus.success;

  @override
  bool get isFailure => status == UiFlowStatus.failure;

  @override
  bool get hasError => error != null;
}
```

**Step 2: Create the message mapper**

Create `lib/features/settings/cubits/llm_provider/llm_provider_message_mapper.dart`:

```dart
import 'package:cubit_ui_flow/cubit_ui_flow.dart';
import 'package:injectable/injectable.dart';
import 'package:quanitya_flutter/l10n/l10n_key_resolver.g.dart';

import 'llm_provider_state.dart';

@injectable
class LlmProviderMessageMapper
    implements IStateMessageMapper<LlmProviderState> {
  @override
  MessageKey? map(LlmProviderState state) {
    if (state.status.isSuccess && state.lastOperation != null) {
      return switch (state.lastOperation!) {
        LlmProviderOperation.load => null,
        LlmProviderOperation.save =>
          MessageKey.success(L10nKeys.llmProviderSaved),
        LlmProviderOperation.delete =>
          MessageKey.success(L10nKeys.llmProviderDeleted),
        LlmProviderOperation.testConnection =>
          MessageKey.success(L10nKeys.llmProviderConnectionSuccess),
        LlmProviderOperation.fetchModels => null,
      };
    }
    return null;
  }
}
```

**Step 3: Create the cubit**

Create `lib/features/settings/cubits/llm_provider/llm_provider_cubit.dart`:

```dart
import 'dart:convert';

import 'package:cubit_ui_flow/cubit_ui_flow.dart';
import 'package:http/http.dart' as http;
import 'package:injectable/injectable.dart';

import '../../../../infrastructure/llm/models/llm_types.dart';
import '../../../../infrastructure/webhooks/api_key_repository.dart';
import '../../../../support/extensions/cubit_ui_flow_extension.dart';
import '../../models/llm_provider_config_model.dart';
import '../../repositories/llm_provider_config_repository.dart';
import '../../repositories/open_router_model_repository.dart';
import '../../services/tested_models_service.dart';
import 'llm_provider_state.dart';

@injectable
class LlmProviderCubit extends QuanityaCubit<LlmProviderState> {
  final LlmProviderConfigRepository _configRepo;
  final OpenRouterModelRepository _modelRepo;
  final ApiKeyRepository _apiKeyRepo;
  final TestedModelsService _testedModelsService;
  final http.Client _httpClient;

  LlmProviderCubit(
    this._configRepo,
    this._modelRepo,
    this._apiKeyRepo,
    this._testedModelsService,
    this._httpClient,
  ) : super(const LlmProviderState());

  /// Load all configs and models from DB.
  Future<void> load() async {
    await tryOperation(() async {
      final configs = await _configRepo.getAll();
      final models = await _modelRepo.getAll();
      final active = configs.isNotEmpty ? configs.first : null;
      return state.copyWith(
        configs: configs,
        activeConfig: active,
        availableModels: models,
        status: UiFlowStatus.success,
        lastOperation: LlmProviderOperation.load,
      );
    }, emitLoading: true);
  }

  /// Select a config as active by touching its lastUsedAt.
  Future<void> selectConfig(String id) async {
    await tryOperation(() async {
      await _configRepo.touchLastUsed(id);
      final configs = await _configRepo.getAll();
      return state.copyWith(
        configs: configs,
        activeConfig: configs.first,
        status: UiFlowStatus.success,
        lastOperation: LlmProviderOperation.load,
      );
    }, emitLoading: false);
  }

  /// Save (upsert) a config.
  Future<void> saveConfig(LlmProviderConfigModel config) async {
    await tryOperation(() async {
      await _configRepo.save(config);
      final configs = await _configRepo.getAll();
      return state.copyWith(
        configs: configs,
        activeConfig: configs.first,
        status: UiFlowStatus.success,
        lastOperation: LlmProviderOperation.save,
      );
    }, emitLoading: true);
  }

  /// Delete a config.
  Future<void> deleteConfig(String id) async {
    await tryOperation(() async {
      await _configRepo.delete(id);
      final configs = await _configRepo.getAll();
      return state.copyWith(
        configs: configs,
        activeConfig: configs.isNotEmpty ? configs.first : null,
        status: UiFlowStatus.success,
        lastOperation: LlmProviderOperation.delete,
      );
    }, emitLoading: true);
  }

  /// Fetch models from OpenRouter API (structured_outputs only), upsert to DB.
  Future<void> fetchOpenRouterModels() async {
    await tryOperation(() async {
      final response = await _httpClient.get(
        Uri.parse(
            'https://openrouter.ai/api/v1/models?supported_parameters=structured_outputs'),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to fetch models: ${response.statusCode}');
      }

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final data = (body['data'] as List).cast<Map<String, dynamic>>();

      final records = data.map((m) {
        final pricing = m['pricing'] as Map<String, dynamic>? ?? {};
        return OpenRouterModelRecord(
          id: m['id'] as String,
          contextLength: m['context_length'] as int? ?? 0,
          promptPrice: pricing['prompt']?.toString() ?? '0',
          completionPrice: pricing['completion']?.toString() ?? '0',
        );
      }).toList();

      await _modelRepo.upsertFromApi(records);

      // Check if we need to refresh tested models
      final hasTested = await _modelRepo.hasTestedModels();
      if (!hasTested) {
        await _testedModelsService.refreshTestedModels();
      }

      final models = await _modelRepo.getAll();
      return state.copyWith(
        availableModels: models,
        status: UiFlowStatus.success,
        lastOperation: LlmProviderOperation.fetchModels,
      );
    }, emitLoading: true);
  }

  /// Test connection for a config.
  /// OpenRouter: GET /api/v1/key with bearer token (200 = valid).
  /// Ollama: GET {baseUrl}/api/tags (200 = reachable).
  Future<void> testConnection(String configId) async {
    await tryOperation(() async {
      final config = state.configs.firstWhere((c) => c.id == configId);
      final isOpenRouter =
          config.baseUrl.contains('openrouter.ai');

      if (isOpenRouter) {
        if (config.apiKeyId == null) {
          throw Exception('No API key configured');
        }
        final keyValue = await _apiKeyRepo.getKeyValue(config.apiKeyId!);
        if (keyValue == null || keyValue.isEmpty) {
          throw Exception('API key not found');
        }
        final response = await _httpClient.get(
          Uri.parse('https://openrouter.ai/api/v1/key'),
          headers: {'Authorization': 'Bearer $keyValue'},
        );
        if (response.statusCode != 200) {
          throw Exception('Invalid API key (${response.statusCode})');
        }
      } else {
        // Ollama: just check if reachable
        final baseUrl = config.baseUrl.replaceAll('/v1', '');
        final response = await _httpClient.get(
          Uri.parse('$baseUrl/api/tags'),
        );
        if (response.statusCode != 200) {
          throw Exception('Ollama not reachable (${response.statusCode})');
        }
      }

      return state.copyWith(
        status: UiFlowStatus.success,
        lastOperation: LlmProviderOperation.testConnection,
      );
    }, emitLoading: true);
  }

  /// Resolve active config + API key into an LlmConfig for AI features.
  /// Returns null if no active config.
  Future<LlmConfig?> buildLlmConfig({bool useCloudProxy = false}) async {
    final config = state.activeConfig ?? await _configRepo.getActive();
    if (config == null) return null;

    final isOpenRouter = config.baseUrl.contains('openrouter.ai');

    String apiKey = '';
    if (config.apiKeyId != null) {
      apiKey = await _apiKeyRepo.getKeyValue(config.apiKeyId!) ?? '';
    }

    if (isOpenRouter) {
      return LlmConfig.openRouter(
        apiKey: apiKey,
        model: config.modelId,
        useCloudProxy: useCloudProxy,
      );
    } else {
      return LlmConfig.ollama(
        model: config.modelId,
        url: config.baseUrl,
      );
    }
  }
}
```

**Step 4: Run code generation**

Run: `dart run build_runner build --delete-conflicting-outputs`
Expected: `llm_provider_state.freezed.dart` generated.

**Step 5: Write the cubit test**

Create `test/features/settings/cubits/llm_provider/llm_provider_cubit_test.dart`:

```dart
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:cubit_ui_flow/cubit_ui_flow.dart';
import 'package:quanitya_flutter/data/db/app_database.dart';
import 'package:quanitya_flutter/features/settings/cubits/llm_provider/llm_provider_cubit.dart';
import 'package:quanitya_flutter/features/settings/cubits/llm_provider/llm_provider_state.dart';
import 'package:quanitya_flutter/features/settings/models/llm_provider_config_model.dart';
import 'package:quanitya_flutter/features/settings/repositories/llm_provider_config_repository.dart';
import 'package:quanitya_flutter/features/settings/repositories/open_router_model_repository.dart';
import 'package:quanitya_flutter/features/settings/services/tested_models_service.dart';
import 'package:quanitya_flutter/infrastructure/webhooks/api_key_repository.dart';

@GenerateMocks([ApiKeyRepository])
import 'llm_provider_cubit_test.mocks.dart';

void main() {
  late AppDatabase database;
  late LlmProviderConfigRepository configRepo;
  late OpenRouterModelRepository modelRepo;
  late MockApiKeyRepository mockApiKeyRepo;
  late http.Client httpClient;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    configRepo = LlmProviderConfigRepository(database);
    modelRepo = OpenRouterModelRepository(database);
    mockApiKeyRepo = MockApiKeyRepository();
    httpClient = MockClient((request) async {
      return http.Response('{}', 200);
    });
  });

  tearDown(() async {
    await database.close();
  });

  LlmProviderCubit buildCubit() {
    final testedService = TestedModelsService(modelRepo, configRepo, httpClient);
    return LlmProviderCubit(
      configRepo,
      modelRepo,
      mockApiKeyRepo,
      testedService,
      httpClient,
    );
  }

  group('load', () {
    test('emits loading then success with empty state', () async {
      final cubit = buildCubit();
      final states = <LlmProviderState>[];
      final sub = cubit.stream.listen(states.add);

      await cubit.load();
      await Future.delayed(Duration.zero);

      await sub.cancel();
      await cubit.close();

      expect(states.length, greaterThanOrEqualTo(2));
      expect(states.first.status, UiFlowStatus.loading);
      expect(states.last.status, UiFlowStatus.success);
      expect(states.last.configs, isEmpty);
      expect(states.last.activeConfig, isNull);
    });

    test('loads existing configs and sets active', () async {
      await configRepo.save(LlmProviderConfigModel(
        id: 'test-1',
        baseUrl: 'https://openrouter.ai/api/v1',
        modelId: 'openai/gpt-4o-mini',
        lastUsedAt: DateTime.now(),
      ));

      final cubit = buildCubit();
      await cubit.load();

      expect(cubit.state.configs.length, 1);
      expect(cubit.state.activeConfig?.id, 'test-1');
    });
  });

  group('saveConfig', () {
    test('saves and reloads configs', () async {
      final cubit = buildCubit();
      await cubit.load();

      await cubit.saveConfig(LlmProviderConfigModel(
        id: 'new-config',
        baseUrl: 'http://localhost:11434/v1',
        modelId: 'llama3',
        lastUsedAt: DateTime.now(),
      ));

      expect(cubit.state.configs.length, 1);
      expect(cubit.state.lastOperation, LlmProviderOperation.save);
    });
  });

  group('deleteConfig', () {
    test('removes config and reloads', () async {
      await configRepo.save(LlmProviderConfigModel(
        id: 'to-delete',
        baseUrl: 'https://openrouter.ai/api/v1',
        modelId: 'openai/gpt-4o-mini',
        lastUsedAt: DateTime.now(),
      ));

      final cubit = buildCubit();
      await cubit.load();
      expect(cubit.state.configs.length, 1);

      await cubit.deleteConfig('to-delete');
      expect(cubit.state.configs, isEmpty);
      expect(cubit.state.activeConfig, isNull);
      expect(cubit.state.lastOperation, LlmProviderOperation.delete);
    });
  });

  group('buildLlmConfig', () {
    test('returns null when no active config', () async {
      final cubit = buildCubit();
      await cubit.load();

      final config = await cubit.buildLlmConfig();
      expect(config, isNull);
    });

    test('returns LlmConfig for OpenRouter config', () async {
      await configRepo.save(LlmProviderConfigModel(
        id: 'or-config',
        baseUrl: 'https://openrouter.ai/api/v1',
        modelId: 'openai/gpt-4o-mini',
        apiKeyId: 'key-1',
        lastUsedAt: DateTime.now(),
      ));

      when(mockApiKeyRepo.getKeyValue('key-1'))
          .thenAnswer((_) async => 'sk-test-key');

      final cubit = buildCubit();
      await cubit.load();

      final config = await cubit.buildLlmConfig();
      expect(config, isNotNull);
      expect(config!.model, 'openai/gpt-4o-mini');
      expect(config.apiKey, 'sk-test-key');
      expect(config.provider, LlmProvider.openRouter);
    });

    test('returns LlmConfig for Ollama config', () async {
      await configRepo.save(LlmProviderConfigModel(
        id: 'ollama-config',
        baseUrl: 'http://localhost:11434/v1',
        modelId: 'llama3',
        lastUsedAt: DateTime.now(),
      ));

      final cubit = buildCubit();
      await cubit.load();

      final config = await cubit.buildLlmConfig();
      expect(config, isNotNull);
      expect(config!.model, 'llama3');
      expect(config.provider, LlmProvider.ollama);
    });
  });
}
```

**Step 6: Run code generation for mocks**

Run: `dart run build_runner build --delete-conflicting-outputs`
Expected: `llm_provider_cubit_test.mocks.dart` generated.

**Step 7: Run tests**

Run: `flutter test test/features/settings/cubits/llm_provider/llm_provider_cubit_test.dart`
Expected: All 7 tests pass.

**Step 8: Commit**

```bash
git add lib/features/settings/cubits/llm_provider/ test/features/settings/cubits/llm_provider/
git commit -m "feat: add LlmProviderCubit with state management and buildLlmConfig"
```

---

## Task 10: Wire `TestedModelsService.syncOnStartup()` into App Bootstrap

**Files:**
- Modify: `lib/app/bootstrap.dart` (or wherever app initialization happens)

**Step 1: Find the app initialization point**

Look for where the app initializes after DI setup. Search for `configureDependencies` or `runApp` in `lib/app/bootstrap.dart` or `lib/main.dart`.

**Step 2: Add startup sync call**

After DI is configured and database is ready, add:

```dart
// Sync tested models (fails silently if offline)
await getIt<TestedModelsService>().syncOnStartup();
```

This should be placed after `configureDependencies()` completes and before the app starts rendering.

**Step 3: Verify app starts without crash**

Run: `flutter run` (or hot restart if already running)
Expected: App starts normally. If offline, no errors. If online, tested models synced to DB.

**Step 4: Commit**

```bash
git add lib/app/bootstrap.dart
git commit -m "feat: wire TestedModelsService.syncOnStartup into app bootstrap"
```

---

## Task 11: Add LLM Provider Section to Settings Page

**Files:**
- Modify: `lib/features/settings/pages/settings_page.dart`
- Create: `lib/features/settings/widgets/llm_provider_section.dart`
- Create: `lib/features/settings/widgets/llm_config_sheet.dart`

**Step 1: Create the LLM Provider section widget**

Create `lib/features/settings/widgets/llm_provider_section.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

import '../../../design_system/primitives/app_sizes.dart';
import '../../../design_system/primitives/app_spacings.dart';
import '../../../design_system/widgets/quanitya/general/quanitya_text_button.dart';
import '../../../support/extensions/context_extensions.dart';
import '../cubits/llm_provider/llm_provider_cubit.dart';
import '../cubits/llm_provider/llm_provider_state.dart';
import '../models/llm_provider_config_model.dart';
import 'llm_config_sheet.dart';

class LlmProviderSection extends StatelessWidget {
  const LlmProviderSection({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LlmProviderCubit, LlmProviderState>(
      builder: (context, state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.l10n.settingsLlmSection.toUpperCase(),
              style: context.text.titleMedium?.copyWith(
                color: context.colors.textPrimary,
              ),
            ),
            VSpace.x1,

            if (state.configs.isEmpty)
              Text(
                context.l10n.llmProviderNoConfigsDescription,
                style: context.text.bodyMedium?.copyWith(
                  color: context.colors.textSecondary,
                ),
              )
            else
              ...state.configs.map((config) => Padding(
                    padding: AppPadding.verticalSingle,
                    child: _ConfigRow(
                      config: config,
                      isActive: config.id == state.activeConfig?.id,
                      onTap: () => context
                          .read<LlmProviderCubit>()
                          .selectConfig(config.id),
                      onEdit: () => _showConfigSheet(context, config),
                    ),
                  )),

            VSpace.x2,
            Center(
              child: QuanityaTextButton(
                text: context.l10n.llmProviderAddConfig,
                onPressed: () => _showConfigSheet(context, null),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showConfigSheet(BuildContext context, LlmProviderConfigModel? config) {
    LlmConfigSheet.show(
      context: context,
      cubit: context.read<LlmProviderCubit>(),
      config: config,
    );
  }
}

class _ConfigRow extends StatelessWidget {
  final LlmProviderConfigModel config;
  final bool isActive;
  final VoidCallback onTap;
  final VoidCallback onEdit;

  const _ConfigRow({
    required this.config,
    required this.isActive,
    required this.onTap,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final displayUrl = config.baseUrl.contains('openrouter')
        ? 'openrouter.ai'
        : config.baseUrl.replaceAll('http://', '').replaceAll('/v1', '');

    return InkWell(
      onTap: onTap,
      onLongPress: onEdit,
      borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
      child: Container(
        padding: AppPadding.allDouble,
        decoration: BoxDecoration(
          color: context.colors.textSecondary.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
        ),
        child: Row(
          children: [
            Icon(
              config.baseUrl.contains('openrouter')
                  ? Icons.cloud
                  : Icons.computer,
              size: AppSizes.iconMedium,
              color: isActive
                  ? context.colors.interactableColor
                  : context.colors.textSecondary,
            ),
            HSpace.x2,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$displayUrl — ${config.modelId}',
                    style: context.text.bodyLarge?.copyWith(
                      color: context.colors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            if (isActive) ...[
              Icon(
                Icons.check_circle,
                size: AppSizes.iconSmall,
                color: context.colors.successColor,
              ),
            ],
            HSpace.x1,
            Icon(
              Icons.chevron_right,
              size: AppSizes.iconSmall,
              color: context.colors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}
```

**Step 2: Create the config edit sheet**

Create `lib/features/settings/widgets/llm_config_sheet.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../../design_system/primitives/app_spacings.dart';
import '../../../design_system/widgets/quanitya/general/loose_insert_sheet.dart';
import '../../../design_system/widgets/quanitya/general/quanitya_text_button.dart';
import '../../../design_system/widgets/quanitya_text_form_field.dart';
import '../../../support/extensions/context_extensions.dart';
import '../cubits/llm_provider/llm_provider_cubit.dart';
import '../models/llm_provider_config_model.dart';
import '../repositories/open_router_model_repository.dart';

const _uuid = Uuid();

class LlmConfigSheet {
  static Future<void> show({
    required BuildContext context,
    required LlmProviderCubit cubit,
    LlmProviderConfigModel? config,
  }) async {
    final baseUrlController =
        TextEditingController(text: config?.baseUrl ?? 'https://openrouter.ai/api/v1');
    final modelController =
        TextEditingController(text: config?.modelId ?? '');
    final formKey = GlobalKey<FormState>();

    final result = await LooseInsertSheet.show<bool>(
      context: context,
      title: config != null
          ? context.l10n.actionEdit
          : context.l10n.llmProviderAddConfig,
      builder: (sheetContext) => _LlmConfigForm(
        formKey: formKey,
        baseUrlController: baseUrlController,
        modelController: modelController,
        cubit: cubit,
        config: config,
      ),
    );

    if (result == true) {
      final newConfig = LlmProviderConfigModel(
        id: config?.id ?? _uuid.v4(),
        baseUrl: baseUrlController.text.trim(),
        modelId: modelController.text.trim(),
        apiKeyId: config?.apiKeyId,
        lastUsedAt: DateTime.now(),
      );
      await cubit.saveConfig(newConfig);
    }

    baseUrlController.dispose();
    modelController.dispose();
  }
}

class _LlmConfigForm extends StatefulWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController baseUrlController;
  final TextEditingController modelController;
  final LlmProviderCubit cubit;
  final LlmProviderConfigModel? config;

  const _LlmConfigForm({
    required this.formKey,
    required this.baseUrlController,
    required this.modelController,
    required this.cubit,
    required this.config,
  });

  @override
  State<_LlmConfigForm> createState() => _LlmConfigFormState();
}

class _LlmConfigFormState extends State<_LlmConfigForm> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final models = widget.cubit.state.availableModels;
    final filtered = _searchQuery.isEmpty
        ? models
        : models
            .where((m) =>
                m.id.toLowerCase().contains(_searchQuery.toLowerCase()))
            .toList();

    return Form(
      key: widget.formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          QuanityaTextFormField(
            controller: widget.baseUrlController,
            labelText: context.l10n.llmProviderBaseUrl,
            hintText: 'https://openrouter.ai/api/v1',
            validator: (v) => (v == null || v.isEmpty)
                ? context.l10n.validationRequired
                : null,
          ),
          VSpace.x2,
          QuanityaTextFormField(
            controller: widget.modelController,
            labelText: context.l10n.llmProviderModel,
            hintText: context.l10n.llmProviderSearchModels,
            onChanged: (v) => setState(() => _searchQuery = v),
            validator: (v) => (v == null || v.isEmpty)
                ? context.l10n.validationRequired
                : null,
          ),
          if (filtered.isNotEmpty) ...[
            VSpace.x1,
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 200),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  final model = filtered[index];
                  return _ModelTile(
                    model: model,
                    onTap: () {
                      widget.modelController.text = model.id;
                      setState(() => _searchQuery = '');
                    },
                  );
                },
              ),
            ),
          ],
          VSpace.x3,
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (widget.config != null)
                QuanityaTextButton(
                  text: context.l10n.actionDelete,
                  isDestructive: true,
                  onPressed: () {
                    widget.cubit.deleteConfig(widget.config!.id);
                    Navigator.of(context).pop(false);
                  },
                ),
              const Spacer(),
              QuanityaTextButton(
                text: context.l10n.llmProviderTestConnection,
                onPressed: widget.config != null
                    ? () => widget.cubit.testConnection(widget.config!.id)
                    : null,
              ),
              QuanityaTextButton(
                text: context.l10n.actionSave,
                onPressed: () {
                  if (widget.formKey.currentState!.validate()) {
                    Navigator.of(context).pop(true);
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ModelTile extends StatelessWidget {
  final OpenRouterModelRecord model;
  final VoidCallback onTap;

  const _ModelTile({required this.model, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: AppPadding.verticalSingle,
        child: Row(
          children: [
            Expanded(
              child: Text(
                model.id,
                style: context.text.bodyMedium?.copyWith(
                  color: context.colors.textPrimary,
                ),
              ),
            ),
            if (model.tested)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.check_circle,
                    size: 14,
                    color: context.colors.successColor,
                  ),
                  HSpace.x05,
                  Text(
                    context.l10n.llmProviderModelTested,
                    style: context.text.bodySmall?.copyWith(
                      color: context.colors.successColor,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
```

**Step 3: Wire LLM section into Settings page**

In `lib/features/settings/pages/settings_page.dart`:

Add imports:
```dart
import '../cubits/llm_provider/llm_provider_cubit.dart';
import '../cubits/llm_provider/llm_provider_state.dart';
import '../cubits/llm_provider/llm_provider_message_mapper.dart';
import '../widgets/llm_provider_section.dart';
```

Add `LlmProviderCubit` to `MultiBlocProvider` in `SettingsPage.build()`:
```dart
BlocProvider(create: (_) => GetIt.instance<LlmProviderCubit>()..load()),
```

Add `UiFlowListener` wrapping in `SettingsView.build()`:
```dart
UiFlowListener<LlmProviderCubit, LlmProviderState>(
  mapper: GetIt.instance<LlmProviderMessageMapper>(),
  child: /* existing UiFlowListener chain */,
)
```

Add `NotebookFold` in `SettingsContent.build()` — insert BEFORE the API Keys section:
```dart
NotebookFold(
  header: Row(children: [
    Icon(Icons.smart_toy, size: AppSizes.iconMedium, color: context.colors.textPrimary),
    HSpace.x2,
    Text(context.l10n.settingsLlmSection, style: context.text.titleMedium),
  ]),
  child: const LlmProviderSection(),
),
VSpace.x3,
```

**Step 4: Verify compilation**

Run: `dart analyze lib/features/settings/`
Expected: No errors.

**Step 5: Commit**

```bash
git add lib/features/settings/widgets/llm_provider_section.dart lib/features/settings/widgets/llm_config_sheet.dart lib/features/settings/pages/settings_page.dart
git commit -m "feat: add LLM Provider section to Settings with config sheet"
```

---

## Task 12: Replace Hardcoded LlmConfig in Template Editor and Analysis Builder

**Files:**
- Modify: `lib/features/templates/widgets/editor/template_editor_form.dart`
- Modify: `lib/features/analytics/pages/analysis_builder_page.dart`

**Step 1: Update template_editor_form.dart**

In `lib/features/templates/widgets/editor/template_editor_form.dart`, replace the `_generateFromAi` method.

Remove imports:
```dart
// Remove these:
import '../../../../infrastructure/webhooks/api_key_repository.dart';
```

Add import:
```dart
import '../../../../features/settings/cubits/llm_provider/llm_provider_cubit.dart';
```

Replace the `_generateFromAi` method body. Remove the `ApiKeyRepository` lookup, the `openRouterKey` search, and the `_showAddApiKeyDialog` call. Replace with:

```dart
Future<void> _generateFromAi(BuildContext context, String prompt) async {
  if (prompt.isEmpty || _isGenerating) return;

  final editorCubit = context.read<TemplateEditorCubit>();
  final useCloudProxy =
      context.read<AppOperatingCubit>().state.mode == AppOperatingMode.cloud;

  final llmCubit = GetIt.I<LlmProviderCubit>();
  final config = await llmCubit.buildLlmConfig(useCloudProxy: useCloudProxy);
  if (config == null) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.llmProviderConfigureLlm)),
      );
    }
    return;
  }

  setState(() => _isGenerating = true);

  try {
    final generatorCubit = GetIt.I<TemplateGeneratorCubit>();
    await generatorCubit.generate(prompt, config);

    final preview = generatorCubit.state.preview;
    if (preview != null && mounted) {
      editorCubit.loadTemplate(preview);
    }
  } finally {
    if (mounted) {
      setState(() => _isGenerating = false);
    }
  }
}
```

Also remove the entire `_showAddApiKeyDialog` method if it's no longer used elsewhere in the file.

**Step 2: Update analysis_builder_page.dart**

In `lib/features/analytics/pages/analysis_builder_page.dart`, apply the same pattern.

Remove imports:
```dart
// Remove these:
import '../../../infrastructure/webhooks/api_key_repository.dart';
import '../../../infrastructure/webhooks/models/api_key_model.dart';
```

Add import:
```dart
import '../../settings/cubits/llm_provider/llm_provider_cubit.dart';
```

Replace `_generateFromAi`:

```dart
Future<void> _generateFromAi(BuildContext context, String prompt) async {
  if (prompt.isEmpty || _isGenerating) return;

  final cubit = context.read<AnalysisBuilderCubit>();
  final state = cubit.state;
  final useCloudProxy =
      context.read<AppOperatingCubit>().state.mode == AppOperatingMode.cloud;

  final llmCubit = GetIt.I<LlmProviderCubit>();
  final config = await llmCubit.buildLlmConfig(useCloudProxy: useCloudProxy);
  if (config == null) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.llmProviderConfigureLlm)),
      );
    }
    return;
  }

  setState(() => _isGenerating = true);

  try {
    await cubit.generateAndApplyAiPipeline(
      fieldId: state.fieldId ?? widget.fieldId,
      userIntent: prompt,
      llmConfig: config,
    );
  } finally {
    if (mounted) {
      setState(() => _isGenerating = false);
    }
  }
}
```

Also remove `_showAddApiKeyDialog` if it exists in this file.

**Step 3: Verify compilation**

Run: `dart analyze lib/features/templates/widgets/editor/template_editor_form.dart lib/features/analytics/pages/analysis_builder_page.dart`
Expected: No errors.

**Step 4: Commit**

```bash
git add lib/features/templates/widgets/editor/template_editor_form.dart lib/features/analytics/pages/analysis_builder_page.dart
git commit -m "refactor: replace hardcoded LlmConfig with LlmProviderCubit.buildLlmConfig"
```

---

## Task 13: Register `http.Client` in DI

**Files:**
- Modify: `lib/app/bootstrap.dart` (or DI module file)

**Step 1: Check if http.Client is already registered**

Search for `http.Client` registration in the DI setup. If not registered, add it.

**Step 2: Register http.Client as a singleton**

In the DI module (or create a new module if needed), add:

```dart
@module
abstract class HttpModule {
  @lazySingleton
  http.Client get httpClient => http.Client();
}
```

Or if using manual registration in `bootstrap.dart`:

```dart
getIt.registerLazySingleton<http.Client>(() => http.Client());
```

This is needed because `TestedModelsService` and `LlmProviderCubit` both depend on `http.Client` via DI.

**Step 3: Run code generation**

Run: `dart run build_runner build --delete-conflicting-outputs`
Expected: DI config regenerated with http.Client registration.

**Step 4: Commit**

```bash
git add lib/app/
git commit -m "feat: register http.Client in DI for LLM provider services"
```

---

## Task 14: Final Integration Test

**Step 1: Run all tests**

Run: `flutter test`
Expected: All existing tests still pass. New tests pass.

**Step 2: Run the app and verify Settings page**

Run: `flutter run`

Manual verification checklist:
1. Open Settings
2. See "LLM Provider" section with NotebookFold
3. If first launch with internet: should show default config (openai/gpt-4o-mini @ openrouter.ai)
4. Tap "+ Add Config" — LooseInsertSheet opens with Base URL and Model fields
5. Type in model field — shows filtered model list with tested models marked
6. Save config — toast appears "Provider config saved"
7. Multiple configs visible — tap one to select (active gets checkmark)
8. Go to template generator — AI generation uses the active config
9. Go to analysis builder — AI generation uses the active config
10. If no API key configured, shows "Configure LLM in Settings" snackbar

**Step 3: Commit any final fixes**

```bash
git add -A
git commit -m "fix: final integration adjustments for LLM provider settings"
```

---

## Summary of Files Created/Modified

### Created (9 files):
1. `public/tested_models.json`
2. `lib/features/settings/exceptions/llm_provider_exception.dart`
3. `lib/features/settings/models/llm_provider_config_model.dart`
4. `lib/features/settings/repositories/open_router_model_repository.dart`
5. `lib/features/settings/repositories/llm_provider_config_repository.dart`
6. `lib/features/settings/services/tested_models_service.dart`
7. `lib/features/settings/cubits/llm_provider/llm_provider_state.dart`
8. `lib/features/settings/cubits/llm_provider/llm_provider_cubit.dart`
9. `lib/features/settings/cubits/llm_provider/llm_provider_message_mapper.dart`
10. `lib/features/settings/widgets/llm_provider_section.dart`
11. `lib/features/settings/widgets/llm_config_sheet.dart`

### Modified (6 files):
1. `lib/data/tables/tables.dart` — add 2 table classes
2. `lib/data/db/app_database.dart` — register tables, schema v5, migration
3. `lib/infrastructure/feedback/exception_mapper.dart` — add LlmProviderException case
4. `lib/l10n/app_en.arb` — add 16 new L10n keys
5. `lib/features/settings/pages/settings_page.dart` — add LLM section
6. `lib/features/templates/widgets/editor/template_editor_form.dart` — use LlmProviderCubit
7. `lib/features/analytics/pages/analysis_builder_page.dart` — use LlmProviderCubit
8. `lib/app/bootstrap.dart` — startup sync + http.Client DI

### Tests (4 files):
1. `test/features/settings/repositories/open_router_model_repository_test.dart`
2. `test/features/settings/repositories/llm_provider_config_repository_test.dart`
3. `test/features/settings/services/tested_models_service_test.dart`
4. `test/features/settings/cubits/llm_provider/llm_provider_cubit_test.dart`
