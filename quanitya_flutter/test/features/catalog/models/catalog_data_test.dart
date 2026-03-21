import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:quanitya_flutter/features/catalog/models/catalog_data.dart';

void main() {
  group('CatalogData', () {
    final sampleJson = {
      'version': 1,
      'categories': [
        {'id': 'health', 'name': 'Health'},
        {'id': 'fitness', 'name': 'Fitness'},
      ],
      'templates': [
        {
          'slug': 'daily-mood',
          'name': 'Daily Mood',
          'description': 'Track your daily mood',
          'emoji': '\u{1F60A}',
          'category': 'health',
          'tags': ['mood', 'mental-health'],
          'fields_count': 3,
          'author': 'quanitya',
          'featured': true,
        },
        {
          'slug': 'water-intake',
          'name': 'Water Intake',
          'description': 'Track daily water consumption',
          'emoji': '\u{1F4A7}',
          'category': 'health',
          'tags': ['hydration'],
          'fields_count': 1,
          'author': 'community',
        },
      ],
    };

    test('parses from JSON correctly', () {
      final catalog = CatalogData.fromJson(sampleJson);

      expect(catalog.version, 1);
      expect(catalog.categories, hasLength(2));
      expect(catalog.categories[0].id, 'health');
      expect(catalog.categories[0].name, 'Health');
      expect(catalog.templates, hasLength(2));
    });

    test('parses CatalogEntry with fields_count mapping', () {
      final catalog = CatalogData.fromJson(sampleJson);
      final entry = catalog.templates[0];

      expect(entry.slug, 'daily-mood');
      expect(entry.name, 'Daily Mood');
      expect(entry.fieldsCount, 3);
      expect(entry.featured, true);
      expect(entry.tags, ['mood', 'mental-health']);
    });

    test('defaults featured to false when not present', () {
      final catalog = CatalogData.fromJson(sampleJson);
      final entry = catalog.templates[1];

      expect(entry.featured, false);
    });

    test('JSON round-trip preserves data', () {
      final catalog = CatalogData.fromJson(sampleJson);
      final jsonString = jsonEncode(catalog.toJson());
      final restored = CatalogData.fromJson(
        jsonDecode(jsonString) as Map<String, dynamic>,
      );

      expect(restored.version, catalog.version);
      expect(restored.categories.length, catalog.categories.length);
      expect(restored.templates.length, catalog.templates.length);
      expect(restored.templates[0].slug, catalog.templates[0].slug);
      expect(restored.templates[0].fieldsCount, catalog.templates[0].fieldsCount);
      expect(restored.templates[0].featured, catalog.templates[0].featured);
    });
  });
}
