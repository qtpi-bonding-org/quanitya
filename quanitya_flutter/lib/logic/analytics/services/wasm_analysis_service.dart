import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:javascript_flutter/javascript_flutter.dart';
import 'package:injectable/injectable.dart';
import 'package:jinja/jinja.dart' as jinja;
import '../models/analysis_pipeline.dart';
import '../models/analysis_output.dart';
import '../models/matrix_vector_scalar/time_series_matrix.dart';
import '../models/matrix_vector_scalar/field_value.dart';
import '../enums/analysis_output_mode.dart';
import '../../../data/dao/log_entry_query_dao.dart';
import '../exceptions/analysis_exceptions.dart';

/// Hardened WASM Analysis Service with:
/// - Asset caching (eliminates disk I/O bottleneck)
/// - Epoch time optimization (faster date math)
/// - NaN/Infinity handling (prevents crashes)
/// - Aggregation support (output timestamps)
/// - Argument shadowing security (prevents scope chain attacks)
abstract class IWasmAnalysisService {
  Future<AnalysisOutput> execute(AnalysisPipelineModel pipeline);
}

@Injectable(as: IWasmAnalysisService)
class WasmAnalysisService implements IWasmAnalysisService {
  final LogEntryQueryDao _logEntryDao;

  // Performance: Cache heavy library strings in memory
  static String? _cachedShell;
  static String? _cachedStatsLib;

  WasmAnalysisService(this._logEntryDao);

  @override
  Future<AnalysisOutput> execute(AnalysisPipelineModel pipeline) async {
    try {
      // 1. Parallel: Fetch data + ensure assets loaded
      final dataFuture = _fetchFieldData(pipeline.fieldId);
      await _ensureAssetsLoaded();

      final data = await dataFuture;

      // Early return if no data — avoid JS errors on empty arrays
      if (data.values.isEmpty) {
        throw AnalysisException('No data found for this field. Log some entries first.');
      }

      // 2. Execute JS via platform channel (already native/off-thread)
      final resultData = await _executeInIsolate(
        shellContent: _cachedShell!,
        simpleStats: _cachedStatsLib!,
        values: data.values,
        timestampsEpoch: data.timestamps.map((e) => e.millisecondsSinceEpoch).toList(),
        snippet: pipeline.snippet,
        outputMode: pipeline.outputMode,
      );

      // 3. Box into AnalysisOutput (main thread)
      return _boxResult(pipeline, resultData, data.timestamps);
    } catch (e, stack) {
      if (e is AnalysisException) rethrow;
      // ignore: avoid_print
      print('WasmAnalysisService ERROR: $e\n$stack');
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
      print('JS Runtime ERROR: $e\n$stack');
      throw AnalysisException('JS Runtime Error: $e');
    } finally {
      await javascript.dispose();
    }
  }

  Future<({List<double> values, List<DateTime> timestamps})> _fetchFieldData(
    String fieldId,
  ) async {
    // Parse fieldId format: "templateId:fieldName"
    final parts = fieldId.split(':');
    if (parts.length != 2) {
      throw AnalysisException('Invalid fieldId format: $fieldId');
    }

    final templateId = parts[0];
    final fieldName = parts[1];

    // Fetch log entries from last 90 days
    final endDate = DateTime.now();
    final startDate = endDate.subtract(const Duration(days: 90));
    final entries = await _logEntryDao.findByTemplateIdInRange(
      templateId,
      startDate,
      endDate,
    );

    // ignore: avoid_print
    print('WasmAnalysis: fieldId=$fieldId, templateId=$templateId, fieldName=$fieldName, entries=${entries.length}');

    if (entries.isEmpty) {
      return (values: <double>[], timestamps: <DateTime>[]);
    }

    final values = <double>[];
    final timestamps = <DateTime>[];

    for (final entry in entries) {
      final ts = entry.occurredAt ?? entry.scheduledFor;
      if (ts == null) continue;

      final val = _extractNumericValue(entry.data, fieldName);
      if (val != null) {
        values.add(val);
        timestamps.add(ts);
      }
    }

    return (values: values, timestamps: timestamps);
  }

  double? _extractNumericValue(Map<String, dynamic> data, String fieldName) {
    final value = data[fieldName];
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    if (value is Map && value.containsKey('value')) {
      final v = value['value'];
      if (v is num) return v.toDouble();
    }
    return null;
  }

  AnalysisOutput _boxResult(
    AnalysisPipelineModel pipeline,
    dynamic resultData,
    List<DateTime> inputTimestamps,
  ) {
    if (resultData is! List) resultData = [resultData];
    final listData = resultData;

    switch (pipeline.outputMode) {
      case AnalysisOutputMode.scalar:
        final scalars = listData.map((item) {
          if (item is Map) {
            return AnalysisScalar(
              label: item['label']?.toString() ?? pipeline.name,
              value: _parseSafeDouble(item['value']),
              unit: item['unit']?.toString(),
            );
          } else if (item is num || item is String) {
            // Handle raw numbers or special strings ("Infinity", "NaN")
            return AnalysisScalar(
              label: pipeline.name,
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
              label: item['label']?.toString() ?? pipeline.name,
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
          final label = map['label']?.toString() ?? pipeline.name;

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
