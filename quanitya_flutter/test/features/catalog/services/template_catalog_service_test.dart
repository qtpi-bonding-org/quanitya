import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:quanitya_flutter/features/catalog/services/template_catalog_service.dart';
import 'package:quanitya_flutter/infrastructure/config/app_config.dart';

http.Response _utf8Response(String body, int statusCode) {
  return http.Response.bytes(
    utf8.encode(body),
    statusCode,
    headers: {'content-type': 'application/json; charset=utf-8'},
  );
}

void main() {
  final catalogJson = {
    'version': 1,
    'categories': [
      {'id': 'health', 'name': 'Health'},
    ],
    'templates': [
      {
        'slug': 'daily-mood',
        'name': 'Daily Mood',
        'description': 'Track your daily mood',
        'emoji': '\u{1F60A}',
        'category': 'health',
        'tags': ['mood'],
        'fields_count': 3,
        'author': 'quanitya',
        'featured': true,
      },
    ],
  };

  group('TemplateCatalogService', () {
    test('fetchCatalog parses response correctly', () async {
      final client = MockClient((request) async {
        return _utf8Response(jsonEncode(catalogJson), 200);
      });
      final service = TemplateCatalogService(client, AppConfig());

      final catalog = await service.fetchCatalog();

      expect(catalog.version, 1);
      expect(catalog.categories, hasLength(1));
      expect(catalog.templates, hasLength(1));
      expect(catalog.templates[0].slug, 'daily-mood');
      expect(catalog.templates[0].fieldsCount, 3);
    });

    test('fetchCatalog caches result (only 1 HTTP call for 2 fetches)',
        () async {
      var callCount = 0;
      final client = MockClient((request) async {
        callCount++;
        return _utf8Response(jsonEncode(catalogJson), 200);
      });
      final service = TemplateCatalogService(client, AppConfig());

      final first = await service.fetchCatalog();
      final second = await service.fetchCatalog();

      expect(callCount, 1);
      expect(identical(first, second), isTrue);
    });

    test('fetchCatalog throws on error status', () async {
      final client = MockClient((request) async {
        return http.Response('Not Found', 404);
      });
      final service = TemplateCatalogService(client, AppConfig());

      expect(
        () => service.fetchCatalog(),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('404'),
        )),
      );
    });

    test('getTemplateUrl builds correct URL', () {
      final client = MockClient((request) async {
        return http.Response('', 200);
      });
      final service = TemplateCatalogService(client, AppConfig());

      final url = service.getTemplateUrl('daily-mood');

      expect(
        url,
        'https://raw.githubusercontent.com/qtpi-bonding-org/quanitya-templates/main/templates/daily-mood/template.json',
      );
    });
  });
}
