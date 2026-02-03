import 'package:injectable/injectable.dart';

import '../models/type_transition_group.dart';
import '../models/matrix_vector_scalar/analysis_data_type.dart';
import '../models/matrix_vector_scalar/operation_registry.dart';
import '../enums/calculation.dart';

/// Registry of all valid type transitions, built from OperationRegistry.
/// Single source of truth for both AI schema generation and UI operation pickers.
///
/// Groups operations by their (fromType → toType) pairs and provides
/// methods for querying valid transitions from any given type.
@lazySingleton
class TypeTransitionRegistry {
  final OperationRegistry _operationRegistry;

  /// All transition groups
  late final List<TypeTransitionGroup> _allGroups;

  /// Groups indexed by fromType for fast lookup
  late final Map<AnalysisDataType, List<TypeTransitionGroup>> _groupsByFromType;

  /// Singleton instance
  static final TypeTransitionRegistry _instance = TypeTransitionRegistry._(
    OperationRegistry.instance,
  );
  static TypeTransitionRegistry get instance => _instance;

  TypeTransitionRegistry._(this._operationRegistry) {
    _buildTransitionGroups();
  }

  @factoryMethod
  factory TypeTransitionRegistry.create(OperationRegistry operationRegistry) {
    return TypeTransitionRegistry._(operationRegistry);
  }

  /// For testing - allows creating new instances
  factory TypeTransitionRegistry.forTesting([OperationRegistry? registry]) {
    return TypeTransitionRegistry._(registry ?? OperationRegistry.instance);
  }

  /// Build all transition groups from the operation registry
  void _buildTransitionGroups() {
    final groupMap = <String, List<Calculation>>{};
    final registry = _operationRegistry;

    // Group operations by (fromType, toType) pairs
    for (final calc in Calculation.values) {
      final def = registry.getDefinition(calc);
      if (def == null) continue;

      // Skip combiners (inputCount > 1) - they require multiple inputs
      if (def.inputCount > 1) continue;

      final key = '${def.inputType.name}_to_${def.outputType.name}';
      groupMap.putIfAbsent(key, () => []).add(calc);
    }

    // Convert to TypeTransitionGroup objects
    _allGroups = groupMap.entries.map((entry) {
      final parts = entry.key.split('_to_');
      return TypeTransitionGroup(
        fromType: AnalysisDataType.values.byName(parts[0]),
        toType: AnalysisDataType.values.byName(parts[1]),
        operations: entry.value,
      );
    }).toList();

    // Index by fromType for fast lookup
    _groupsByFromType = {};
    for (final group in _allGroups) {
      _groupsByFromType.putIfAbsent(group.fromType, () => []).add(group);
    }
  }

  /// Get all transition groups
  List<TypeTransitionGroup> get allGroups => List.unmodifiable(_allGroups);

  /// Get transition groups that start from a specific type
  List<TypeTransitionGroup> getGroupsFromType(AnalysisDataType fromType) {
    return _groupsByFromType[fromType] ?? [];
  }

  /// Get all valid operations from a specific type
  List<Calculation> getValidOperationsFromType(AnalysisDataType fromType) {
    return getGroupsFromType(fromType).expand((g) => g.operations).toList();
  }

  /// Get the transition group for a specific operation
  TypeTransitionGroup? getGroupForOperation(Calculation operation) {
    for (final group in _allGroups) {
      if (group.contains(operation)) return group;
    }
    return null;
  }

  /// Get all groups reachable from a start type.
  /// Traverses until reaching scalar endpoints or exhausting all paths.
  /// Used for generating AI schema with all valid operations.
  ///
  /// [startType] The type to start from (typically timeSeriesMatrix)
  List<TypeTransitionGroup> getReachableGroups(AnalysisDataType startType) {
    final reachableGroups = <TypeTransitionGroup>{};
    final visitedTypes = <AnalysisDataType>{startType};
    var currentTypes = {startType};

    // Traverse until we run out of new types to explore
    while (currentTypes.isNotEmpty) {
      final nextTypes = <AnalysisDataType>{};

      for (final type in currentTypes) {
        for (final group in getGroupsFromType(type)) {
          reachableGroups.add(group);

          // Only continue if we haven't visited this output type
          if (!visitedTypes.contains(group.toType)) {
            nextTypes.add(group.toType);
            visitedTypes.add(group.toType);
          }
        }
      }

      currentTypes = nextTypes;
    }

    return reachableGroups.toList();
  }

  /// Get operations grouped by category for UI display.
  /// Returns a map where keys are category names and values are lists of operations.
  Map<String, List<Calculation>> getOperationsByCategory(
    AnalysisDataType fromType,
  ) {
    final registry = _operationRegistry;
    final result = <String, List<Calculation>>{};

    for (final group in getGroupsFromType(fromType)) {
      for (final operation in group.operations) {
        final def = registry.getDefinition(operation);
        if (def == null) continue;

        result.putIfAbsent(def.category, () => []).add(operation);
      }
    }

    return result;
  }
}
