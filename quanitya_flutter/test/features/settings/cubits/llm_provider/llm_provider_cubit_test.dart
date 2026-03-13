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
import 'package:quanitya_flutter/infrastructure/llm/models/llm_types.dart';

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
    final testedService =
        TestedModelsService(modelRepo, configRepo, httpClient);
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

      await cubit.close();
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

      await cubit.close();
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

      await cubit.close();
    });
  });

  group('buildLlmConfig', () {
    test('returns null when no active config', () async {
      final cubit = buildCubit();
      await cubit.load();

      final config = await cubit.buildLlmConfig();
      expect(config, isNull);

      await cubit.close();
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

      await cubit.close();
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

      await cubit.close();
    });
  });
}
