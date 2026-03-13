import 'package:injectable/injectable.dart';
import '../models/analysis_script.dart';
import '../models/matrix_vector_scalar/mvs_union.dart';
import '../models/matrix_vector_scalar/stat_scalar.dart';
import '../models/matrix_vector_scalar/value_vector.dart';
import '../models/analysis_output.dart';
import '../services/wasm_analysis_service.dart';

/// Matrix-Vector-Scalar Analysis Engine.
///
/// Core execution engine that delegates to [IWasmAnalysisService] for
/// JavaScript execution and provides MVS type conversion utilities.
@injectable
class AnalysisEngine {
  final IWasmAnalysisService _wasmService;

  const AnalysisEngine(this._wasmService);

  /// Execute an analysis script using the WASM engine.
  Future<AnalysisOutput> execute(AnalysisScriptModel script) {
    return _wasmService.execute(script);
  }

  Future<Map<String, MvsUnion>> executeScriptWithContext(
    AnalysisScriptModel script,
  ) async {
    final result = await execute(script);

    final mvs = result.when(
      scalar: (scalars) => scalars.isNotEmpty
          ? MvsUnion.statScalar(StatScalar(scalars.first.value))
          : MvsUnion.statScalar(const StatScalar(0)),
      vector: (vectors) => vectors.isNotEmpty
          ? MvsUnion.valueVector(ValueVector(vectors.first.values))
          : MvsUnion.valueVector(const ValueVector([])),
      matrix: (matrices) => matrices.isNotEmpty
          ? MvsUnion.timeSeriesMatrix(matrices.first)
          : MvsUnion.valueVector(const ValueVector([])), // Fallback
    );

    return {script.name: mvs};
  }

  /// @deprecated Use executeScriptWithContext
  Future<MvsUnion> executeScript(AnalysisScriptModel script) async {
    final map = await executeScriptWithContext(script);
    return map.values.first;
  }
}
