import 'package:injectable/injectable.dart';

import 'i_data_source_adapter.dart';

/// Central registry for data source adapters.
///
/// Provides discovery and retrieval of adapters by ID or category.
/// Registered as a lazy singleton via Injectable.
///
/// Example:
/// ```dart
/// final registry = getIt&lt;AdapterRegistry&gt;();
///
/// // Register adapters
/// registry.register(HealthStepsAdapter());
/// registry.register(NotionDatabaseAdapter());
///
/// // Retrieve by ID
/// final adapter = registry.get('health.steps');
///
/// // Get all health adapters
/// final healthAdapters = registry.getByCategory('health');
/// ```
@lazySingleton
class AdapterRegistry {
  final Map<String, IDataSourceAdapter<dynamic>> _adapters = {};

  /// Registers an adapter in the registry.
  ///
  /// If an adapter with the same ID already exists, it will be replaced.
  void register(IDataSourceAdapter<dynamic> adapter) {
    _adapters[adapter.adapterId] = adapter;
  }

  /// Retrieves an adapter by its unique ID.
  ///
  /// Returns null if no adapter with the given ID is registered.
  IDataSourceAdapter<dynamic>? get(String adapterId) {
    return _adapters[adapterId];
  }

  /// Returns all registered adapters.
  List<IDataSourceAdapter<dynamic>> get all => _adapters.values.toList();

  /// Returns adapters whose ID starts with the given category prefix.
  ///
  /// Category matching uses dot notation: `getByCategory('health')`
  /// matches adapters with IDs like 'health.steps', 'health.heart_rate'.
  List<IDataSourceAdapter<dynamic>> getByCategory(String category) {
    return _adapters.values
        .where((adapter) => adapter.adapterId.startsWith('$category.'))
        .toList();
  }
}
