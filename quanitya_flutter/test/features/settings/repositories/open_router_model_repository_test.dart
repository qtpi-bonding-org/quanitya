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
        ),
      ]);

      final all = await repository.getAll();
      expect(all.length, 1);
      expect(all.first.contextLength, 128000);
      expect(all.first.promptPrice, '0.005');
    });

    test('preserves tested flag when upserting from API', () async {
      await repository.upsertTested(['openai/gpt-4o-mini']);

      await repository.upsertFromApi([
        OpenRouterModelRecord(
          id: 'openai/gpt-4o-mini',
          contextLength: 128000,
          promptPrice: '0.005',
          completionPrice: '0.015',
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
