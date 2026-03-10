import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:drift/native.dart';
import 'package:quanitya_flutter/data/db/app_database.dart';
import 'package:quanitya_flutter/features/settings/models/llm_provider_config_model.dart';
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

  http.Client mockClient(Map<String, dynamic> responseBody,
      {int statusCode = 200}) {
    return MockClient((request) async {
      return http.Response(jsonEncode(responseBody), statusCode);
    });
  }

  http.Client failingClient() {
    return MockClient((request) async {
      throw Exception('Network error');
    });
  }

  group('syncOnStartup', () {
    test('upserts tested models and creates default config', () async {
      final client = mockClient({
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
      await configRepo.save(LlmProviderConfigModel(
        id: 'existing',
        baseUrl: 'http://localhost:11434/v1',
        modelId: 'llama3',
        lastUsedAt: DateTime.now(),
      ));

      final client = mockClient({
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
      final client = failingClient();
      final service = TestedModelsService(modelRepo, configRepo, client);

      await service.syncOnStartup();

      final tested = await modelRepo.getTested();
      expect(tested, isEmpty);
    });
  });

  group('refreshTestedModels', () {
    test('refreshes tested models without creating config', () async {
      final client = mockClient({
        'tested_models': ['openai/gpt-4o-mini', 'google/gemini-pro'],
        'recommended_default': 'openai/gpt-4o-mini',
      });

      final service = TestedModelsService(modelRepo, configRepo, client);
      await service.refreshTestedModels();

      final tested = await modelRepo.getTested();
      expect(tested.length, 2);

      final active = await configRepo.getActive();
      expect(active, isNull);
    });
  });
}
