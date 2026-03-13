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

  Future<void> selectQuanitya() async {
    await tryOperation(() async {
      await _configRepo.saveQuanityaSelection();
      final configs = await _configRepo.getAll();
      return state.copyWith(
        configs: configs,
        activeConfig: configs.first,
        status: UiFlowStatus.success,
        lastOperation: LlmProviderOperation.load,
      );
    }, emitLoading: false);
  }

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

  Future<void> fetchOpenRouterModels() async {
    await tryOperation(() async {
      final response = await _httpClient.get(
        Uri.parse(
          'https://openrouter.ai/api/v1/models?supported_parameters=structured_outputs',
        ),
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

  Future<void> testConnection(String configId) async {
    await tryOperation(() async {
      final config = state.configs.firstWhere((c) => c.id == configId);

      switch (config.provider) {
        case LlmProvider.quanitya:
          // Quanitya connection is managed server-side — no client test needed
          break;
        case LlmProvider.openRouter:
          final apiKeyId = config.apiKeyId;
          if (apiKeyId == null) {
            throw Exception('No API key configured');
          }
          final keyValue = await _apiKeyRepo.getKeyValue(apiKeyId);
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
        case LlmProvider.ollama:
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

  Future<LlmConfig?> buildLlmConfig() async {
    final config = state.activeConfig ?? await _configRepo.getActive();
    if (config == null) return null;

    return switch (config.provider) {
      LlmProvider.quanitya => LlmConfig.quanitya(),
      LlmProvider.openRouter => LlmConfig.openRouter(
          apiKey: await _resolveApiKey(config.apiKeyId),
          model: config.modelId,
        ),
      LlmProvider.ollama => LlmConfig.ollama(
          model: config.modelId,
          url: config.baseUrl,
        ),
    };
  }

  Future<String> _resolveApiKey(String? apiKeyId) async {
    if (apiKeyId == null) return '';
    return await _apiKeyRepo.getKeyValue(apiKeyId) ?? '';
  }
}
