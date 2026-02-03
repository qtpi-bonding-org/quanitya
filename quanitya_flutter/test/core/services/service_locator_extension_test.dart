import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';

import 'package:quanitya_flutter/logic/templates/services/ai/ai_template_generator.dart';
import 'package:quanitya_flutter/logic/templates/services/engine/symbolic_combination_generator.dart';
import 'package:quanitya_flutter/logic/templates/services/engine/unified_schema_generator.dart';

void main() {
  group('Service Locator Extension Tests', () {
    late GetIt testGetIt;

    setUpAll(() {
      testGetIt = GetIt.asNewInstance();
      
      testGetIt.registerLazySingleton<SymbolicCombinationGenerator>(
        () => SymbolicCombinationGenerator(),
      );
      
      testGetIt.registerFactory<UnifiedSchemaGenerator>(
        () => UnifiedSchemaGenerator(),
      );
      
      testGetIt.registerFactory<AiTemplateGenerator>(
        () => AiTemplateGenerator(
          testGetIt<SymbolicCombinationGenerator>(),
          testGetIt<UnifiedSchemaGenerator>(),
        ),
      );
    });

    tearDownAll(() {
      testGetIt.reset();
    });

    test('AiTemplateGenerator can be retrieved via extension method pattern', () {
      final generator = testGetIt.get<AiTemplateGenerator>();
      
      expect(generator, isNotNull);
      expect(generator, isA<AiTemplateGenerator>());
      
      expect(() => generator.generateSchema(), returnsNormally);
      
      final schema = generator.generateSchema();
      expect(schema, isA<Map<String, dynamic>>());
      expect(schema['\$schema'], equals('http://json-schema.org/draft-07/schema#'));
    });

    test('Service registration follows @injectable patterns', () {
      expect(() => testGetIt<AiTemplateGenerator>(), returnsNormally);
      expect(() => testGetIt<SymbolicCombinationGenerator>(), returnsNormally);
      expect(() => testGetIt<UnifiedSchemaGenerator>(), returnsNormally);
      
      final generator1 = testGetIt<AiTemplateGenerator>();
      final generator2 = testGetIt<AiTemplateGenerator>();
      
      expect(identical(generator1, generator2), isFalse);
      
      final schema1 = generator1.generateSchema();
      final schema2 = generator2.generateSchema();
      
      expect(schema1['\$schema'], equals(schema2['\$schema']));
      expect(schema1['type'], equals(schema2['type']));
    });
  });
}
