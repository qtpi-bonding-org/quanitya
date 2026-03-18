import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:javascript_flutter/javascript_flutter.dart';
import 'package:injectable/injectable.dart';
import 'package:jinja/jinja.dart' as jinja;
import '../models/analysis_script.dart';
import '../models/analysis_output.dart';
import '../models/matrix_vector_scalar/time_series_matrix.dart';
import '../models/matrix_vector_scalar/field_value.dart';
import '../enums/analysis_output_mode.dart';
import '../../../data/interfaces/analysis_script_interface.dart';
import '../exceptions/analysis_exceptions.dart';

/// Hardened WASM Analysis Service with:
/// - Asset caching (eliminates disk I/O bottleneck)
/// - Epoch time optimization (faster date math)
/// - NaN/Infinity handling (prevents crashes)
/// - Aggregation support (output timestamps)
/// - Argument shadowing security (prevents scope chain attacks)
abstract class IWasmAnalysisService {
  Future<AnalysisOutput> execute(AnalysisScriptModel script);
}

@Injectable(as: IWasmAnalysisService)
class WasmAnalysisService implements IWasmAnalysisService {
  final IAnalysisScriptRepository _repo;

  // Performance: Cache heavy library strings in memory
  static String? _cachedShell;
  static String? _cachedStatsLib;

  WasmAnalysisService(this._repo);

  @override
  Future<AnalysisOutput> execute(AnalysisScriptModel script) async {
    try {
      // 1. Parallel: Fetch data + ensure assets loaded
      final dataFuture = _repo.fetchFieldTimeSeries(
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

      // 2. Execute JS via platform channel (already native/off-thread)
      final resultData = await _executeInIsolate(
        shellContent: _cachedShell!,
        simpleStats: _cachedStatsLib!,
        values: data.values,
        timestampsEpoch: data.timestamps.map((e) => e.millisecondsSinceEpoch).toList(),
        snippet: script.snippet,
        outputMode: script.outputMode,
      );

      // 3. Box into AnalysisOutput (main thread)
      return _boxResult(script, resultData, data.timestamps);
    } catch (e, stack) {
      if (e is AnalysisException) rethrow;
      // ignore: avoid_print
      debugPrint('WasmAnalysisService ERROR: $e\n$stack');
      throw AnalysisException('Analysis Engine Error: $e');
    }
  }

  /// Ensures assets are loaded and cached in memory
  Future<void> _ensureAssetsLoaded() async {
    if (_cachedShell != null && _cachedStatsLib != null) return;

    final results = await Future.wait([
      rootBundle.loadString('assets/scripts/mvs_shell.js.j2'),
      rootBundle.loadString('assets/scripts/simple_statistics.js'),
    ]);

    _cachedShell = results[0];
    _cachedStatsLib = results[1];
  }

  /// Executes user script in isolated JS runtime
  static Future<dynamic> _executeInIsolate({
    required String shellContent,
    required String simpleStats,
    required List<double> values,
    required List<int> timestampsEpoch,
    required String snippet,
    required AnalysisOutputMode outputMode,
  }) async {
    final env = jinja.Environment(filters: {
      'to_json': (dynamic value) => jsonEncode(value),
    });
    final template = env.fromString(shellContent);

    final fullScript = template.render({
      'values': values,
      'timestamps_epoch': timestampsEpoch,
      'logic_fragment': snippet,
      'output_mode': outputMode.name,
    });

    // Initialize JS runtime (no network access by default)
    final javascript = await JavaScript.createNew();

    try {
      // Inject simple-statistics library
      await javascript.runJavaScriptReturningResult(simpleStats);

      // Execute rendered script
      final jsResult = await javascript.runJavaScriptReturningResult(fullScript);

      // Parse result (javascript_flutter returns decoded JSON or string)
      if (jsResult is String) {
        final Map<String, dynamic> rawResult = jsonDecode(jsResult);

        if (rawResult['status'] == 'error') {
          throw AnalysisException('Logic Error: ${rawResult['message']}');
        }

        return rawResult['result'];
      } else if (jsResult is Map) {
        if (jsResult['status'] == 'error') {
          throw AnalysisException('Logic Error: ${jsResult['message']}');
        }
        return jsResult['result'];
      }

      return jsResult;
    } catch (e, stack) {
      if (e is AnalysisException) rethrow;
      // ignore: avoid_print
      debugPrint('JS Runtime ERROR: $e\n$stack');
      throw AnalysisException('JS Runtime Error: $e');
    } finally {
      await javascript.dispose();
    }
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
