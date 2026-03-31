import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import '../../../infrastructure/config/debug_log.dart';
import '../../../infrastructure/js_executor/i_js_executor.dart';
import 'package:injectable/injectable.dart';
import 'package:jinja/jinja.dart' as jinja;
import '../models/analysis_script.dart';
import '../models/analysis_output.dart';
import '../models/matrix_vector_scalar/time_series_matrix.dart';
import '../models/matrix_vector_scalar/field_value.dart';
import '../enums/analysis_output_mode.dart';
import '../../../data/interfaces/analysis_script_interface.dart';
import '../exceptions/analysis_exceptions.dart';

const _tag = 'logic/analysis/services/wasm_analysis_service';

/// Hardened WASM Analysis Service with:
/// - Asset caching (eliminates disk I/O bottleneck)
/// - Epoch time optimization (faster date math)
/// - NaN/Infinity handling (prevents crashes)
/// - Aggregation support (output timestamps)
/// - Argument shadowing security (prevents scope chain attacks)
/// - Execution timeout (prevents infinite-loop hangs)
abstract class IWasmAnalysisService {
  Future<AnalysisOutput> execute(AnalysisScriptModel script);
}

@Injectable(as: IWasmAnalysisService)
class WasmAnalysisService implements IWasmAnalysisService {
  static const _jsTimeout = Duration(seconds: 30);

  final IAnalysisScriptRepository _repo;
  final IJsExecutor _jsExecutor;

  // Performance: Cache heavy library strings in memory
  static String? _cachedShell;
  static String? _cachedStatsLib;
  static String? _cachedJstat;

  WasmAnalysisService(this._repo, this._jsExecutor);

  @override
  Future<AnalysisOutput> execute(AnalysisScriptModel script) async {
    try {
      // 1. Parallel: Fetch data + ensure assets loaded
      final dataFuture = _repo.fetchFieldTimeSeries(
        script.templateId,
        script.fieldId,
        entryRangeStart: script.entryRangeStart,
        entryRangeEnd: script.entryRangeEnd,
      );
      await _ensureAssetsLoaded();

      final data = await dataFuture;

      // Early return if no data — avoid JS errors on empty arrays
      if (data.values.isEmpty) {
        throw AnalysisException(
          'No numeric values extracted for this field. '
          'Log some entries first, or check the field name matches.',
        );
      }

      // 2. Render the Jinja template
      final env = jinja.Environment(filters: {
        'to_json': (dynamic value) => jsonEncode(value),
      });
      final template = env.fromString(_cachedShell!);
      final fullScript = template.render({
        'values': data.values,
        'timestamps_epoch': data.timestamps.map((e) => e.millisecondsSinceEpoch).toList(),
        'logic_fragment': script.snippet,
        'output_mode': script.outputMode.name,
      });

      // 3. Execute via platform-appropriate JS executor
      final jsResult = await _jsExecutor.evaluate(
        libraries: [_cachedStatsLib!, _cachedJstat!],
        script: fullScript,
        timeout: _jsTimeout,
      );

      // 4. Parse result
      final dynamic resultData;
      if (jsResult is String) {
        final Map<String, dynamic> rawResult = jsonDecode(jsResult);
        if (rawResult['status'] == 'error') {
          throw AnalysisException('Logic Error: ${rawResult['message']}');
        }
        resultData = rawResult['result'];
      } else if (jsResult is Map) {
        if (jsResult['status'] == 'error') {
          throw AnalysisException('Logic Error: ${jsResult['message']}');
        }
        resultData = jsResult['result'];
      } else {
        resultData = jsResult;
      }

      // 5. Box into AnalysisOutput
      return _boxResult(script, resultData, data.timestamps);
    } catch (e, stack) {
      if (e is AnalysisException) rethrow;
      // ignore: avoid_print
      Log.d(_tag, 'WasmAnalysisService ERROR: $e\n$stack');
      throw AnalysisException('Analysis Engine Error: $e');
    }
  }

  /// Ensures assets are loaded and cached in memory
  Future<void> _ensureAssetsLoaded() async {
    if (_cachedShell != null && _cachedStatsLib != null && _cachedJstat != null) return;

    final results = await Future.wait([
      rootBundle.loadString('assets/scripts/mvs_shell.js.j2'),
      rootBundle.loadString('assets/scripts/simple_statistics.js'),
      rootBundle.loadString('assets/scripts/jstat.min.js'),
    ]);

    _cachedShell = results[0];
    _cachedStatsLib = results[1];
    _cachedJstat = results[2];
  }

  AnalysisOutput _boxResult(
    AnalysisScriptModel script,
    dynamic resultData,
    List<DateTime> inputTimestamps,
  ) {
    if (resultData is! List) resultData = [resultData];
    final listData = resultData;

    switch (script.outputMode) {
      case AnalysisOutputMode.scalar:
        final scalars = listData.map((item) {
          if (item is Map) {
            return AnalysisScalar(
              label: item['label']?.toString() ?? script.name,
              value: _parseSafeDouble(item['value']),
              unit: item['unit']?.toString(),
            );
          } else if (item is num || item is String) {
            // Handle raw numbers or special strings ("Infinity", "NaN")
            return AnalysisScalar(
              label: script.name,
              value: _parseSafeDouble(item),
            );
          }
          throw AnalysisException('Invalid scalar format: $item');
        }).toList();
        return AnalysisOutput.scalar(scalars);

      case AnalysisOutputMode.vector:
        final vectors = listData.map((item) {
          if (item is Map) {
            final rawValues = item['values'] as List;
            return AnalysisVector(
              label: item['label']?.toString() ?? script.name,
              values: rawValues.map((v) => _parseSafeDouble(v)).toList(),
            );
          }
          throw AnalysisException('Invalid vector format: $item');
        }).toList();
        return AnalysisOutput.vector(vectors);

      case AnalysisOutputMode.matrix:
        final matrices = listData.map((item) {
          if (item is! Map) {
            throw AnalysisException('Invalid matrix format: expected Map, got ${item.runtimeType}');
          }
          final map = item;
          final values = (map['values'] as List?)
                  ?.map((v) => _parseSafeDouble(v))
                  .toList() ??
              [];
          final label = map['label']?.toString() ?? script.name;

          List<DateTime> outputTimestamps;
          if (map.containsKey('timestamps')) {
            final rawTs = map['timestamps'] as List;
            outputTimestamps = rawTs.map((t) {
              return t is int
                  ? DateTime.fromMillisecondsSinceEpoch(t)
                  : DateTime.parse(t.toString());
            }).toList();
          } else {
            if (values.length != inputTimestamps.length) {
              throw AnalysisException(
                'Output length mismatch: Script modified data length but did not return new timestamps.',
              );
            }
            outputTimestamps = inputTimestamps;
          }

          return TimeSeriesMatrix.fromFieldData(
            timestamps: outputTimestamps,
            fieldData: {
              label: values.map((v) => FieldValue.numeric(v)).toList(),
            },
          );
        }).toList();
        return AnalysisOutput.matrix(matrices);
    }
  }

  /// Safely parses doubles, handling NaN/Infinity strings from JS
  double _parseSafeDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value == "Infinity") return double.infinity;
    if (value == "-Infinity") return double.negativeInfinity;
    if (value == "NaN") return double.nan;
    if (value is String) return double.tryParse(value) ?? double.nan;
    return double.nan;
  }
}
