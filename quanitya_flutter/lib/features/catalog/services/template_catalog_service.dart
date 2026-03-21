import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:injectable/injectable.dart';

import '../models/catalog_data.dart';
import '../../../logic/templates/models/shared/shareable_template.dart';

@injectable
class TemplateCatalogService {
  final http.Client _client;

  static const _baseUrl =
      'https://raw.githubusercontent.com/qtpi-bonding-org/quanitya-templates/main';

  CatalogData? _cachedCatalog;
  final Map<String, ShareableTemplate> _templateCache = {};

  TemplateCatalogService(this._client);

  Future<CatalogData> fetchCatalog() async {
    if (_cachedCatalog != null) return _cachedCatalog!;
    final response = await _client
        .get(Uri.parse('$_baseUrl/catalog.json'))
        .timeout(const Duration(seconds: 15));
    if (response.statusCode != 200) {
      throw Exception('Failed to fetch catalog: ${response.statusCode}');
    }
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    _cachedCatalog = CatalogData.fromJson(json);
    return _cachedCatalog!;
  }

  Future<ShareableTemplate> fetchTemplate(String slug) async {
    if (_templateCache.containsKey(slug)) return _templateCache[slug]!;
    final response = await _client
        .get(Uri.parse('$_baseUrl/templates/$slug/template.json'))
        .timeout(const Duration(seconds: 15));
    if (response.statusCode != 200) {
      throw Exception(
          'Failed to fetch template "$slug": ${response.statusCode}');
    }
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final template = ShareableTemplate.fromJson(json);
    _templateCache[slug] = template;
    return template;
  }

  String getTemplateUrl(String slug) =>
      '$_baseUrl/templates/$slug/template.json';
}
