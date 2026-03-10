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

  Future<void> syncOnStartup() async {
    try {
      final json = await _fetchTestedModelsJson();
      if (json == null) return;

      final modelIds = (json['tested_models'] as List).cast<String>();
      await _modelRepo.upsertTested(modelIds);

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
