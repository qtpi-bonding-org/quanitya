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

  LlmProviderConfigModel makeConfig({
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
      await repository.save(makeConfig());

      final all = await repository.getAll();
      expect(all.length, 1);
      expect(all.first.baseUrl, 'https://openrouter.ai/api/v1');
      expect(all.first.modelId, 'openai/gpt-4o-mini');
    });

    test('getAll returns ordered by lastUsedAt DESC', () async {
      await repository.save(makeConfig(id: 'old', lastUsedAt: DateTime(2026, 1, 1)));
      await repository.save(makeConfig(id: 'new', lastUsedAt: DateTime(2026, 3, 1)));

      final all = await repository.getAll();
      expect(all.first.id, 'new');
      expect(all.last.id, 'old');
    });
  });

  group('getActive', () {
    test('returns most recently used config', () async {
      await repository.save(makeConfig(id: 'old', lastUsedAt: DateTime(2026, 1, 1)));
      await repository.save(makeConfig(id: 'new', modelId: 'google/gemini-pro', lastUsedAt: DateTime(2026, 3, 1)));

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
      await repository.save(makeConfig(id: 'to-delete'));
      await repository.delete('to-delete');

      final all = await repository.getAll();
      expect(all, isEmpty);
    });
  });

  group('touchLastUsed', () {
    test('updates lastUsedAt to now', () async {
      final oldDate = DateTime(2020, 1, 1);
      await repository.save(makeConfig(id: 'touch-me', lastUsedAt: oldDate));

      await repository.touchLastUsed('touch-me');

      final active = await repository.getActive();
      expect(active!.id, 'touch-me');
      expect(active.lastUsedAt.isAfter(oldDate), isTrue);
    });
  });
}
