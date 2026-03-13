import 'package:injectable/injectable.dart';

import '../../infrastructure/core/try_operation.dart';
import '../../logic/templates/enums/field_enum.dart';
import '../../logic/templates/models/shared/template_field.dart';
import '../../logic/templates/models/shared/tracker_template.dart';
import '../../logic/calculations/services/calculation_service.dart';
import '../../logic/analytics/models/matrix_vector_scalar/mvs_union.dart';
import '../../logic/analytics/exceptions/analysis_exceptions.dart';
import '../dao/log_entry_query_dao.dart';
import 'template_with_aesthetics_repository.dart';

/// Time-series data for a numeric field.
class NumericFieldData {
  final TemplateField field;
  final List<({DateTime date, num value})> points;

  const NumericFieldData({required this.field, required this.points});

  bool get isEmpty => points.isEmpty;
  List<num> get values => points.map((p) => p.value).toList();
}

/// Time-series data for a boolean field.
class BooleanFieldData {
  final TemplateField field;
  final List<({DateTime date, bool value})> points;

  const BooleanFieldData({required this.field, required this.points});

  bool get isEmpty => points.isEmpty;
  List<DateTime> get trueDates =>
      points.where((p) => p.value).map((p) => p.date).toList();
}

/// Time-series data for a categorical/enumerated field.
class CategoricalFieldData {
  final TemplateField field;
  final List<String> categories;
  final List<({DateTime date, String category})> points;

  const CategoricalFieldData({
    required this.field,
    required this.categories,
    required this.points,
  });

  bool get isEmpty => points.isEmpty;
  List<String> get values => points.map((p) => p.category).toList();
}

/// Aggregated data for a template, organized by field type.
class TemplateAggregatedData {
  final TrackerTemplateModel template;
  final List<NumericFieldData> numericFields;
  final List<BooleanFieldData> booleanFields;
  final List<CategoricalFieldData> categoricalFields;
  final int totalEntries;
  final int completedEntries;
  final DateTime startDate;
  final DateTime endDate;

  const TemplateAggregatedData({
    required this.template,
    required this.numericFields,
    required this.booleanFields,
    required this.categoricalFields,
    required this.totalEntries,
    required this.completedEntries,
    required this.startDate,
    required this.endDate,
  });

  List<DateTime> get loggedDates {
    final dates = <DateTime>{};
    for (final field in numericFields) {
      dates.addAll(field.points.map((p) => _dateOnly(p.date)));
    }
    for (final field in booleanFields) {
      dates.addAll(field.points.map((p) => _dateOnly(p.date)));
    }
    for (final field in categoricalFields) {
      dates.addAll(field.points.map((p) => _dateOnly(p.date)));
    }
    return dates.toList()..sort();
  }

  static DateTime _dateOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);
}


/// Service for fetching and organizing log entry data by field type.
///
/// Architecture:
/// - DataRetrievalService: Data extraction (templateId → raw data / MVS)
/// - CalculationService: MVS packaging (primitives → MVS types)
/// - AnalysisEngine: Pipeline orchestration (MVS → MVS)
@lazySingleton
class DataRetrievalService {
  final LogEntryQueryDao _entryDao;
  final TemplateWithAestheticsRepository _templateRepo;
  final CalculationService _calc;

  DataRetrievalService(this._entryDao, this._templateRepo, this._calc);

  // ═══════════════════════════════════════════════════════════════════════════
  // HIGH-LEVEL MVS OPERATIONS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Extract categorical data and return as MVS CategoryVector.
  Future<MvsUnion> extractCategoricalDataAsMvs(
    String templateId,
    String fieldName, {
    int days = 30,
  }) {
    return tryMethod(
      () async {
        final data = await getAggregatedData(templateId, days: days);
        if (data == null) {
          throw AnalysisException('Template not found: $templateId');
        }

        final field = data.categoricalFields
            .where((f) => f.field.label == fieldName)
            .firstOrNull;
        if (field == null) {
          throw AnalysisException('Categorical field not found: $fieldName');
        }

        return _calc.categoriesToMvs(field.values);
      },
      AnalysisException.new,
      'extractCategoricalDataAsMvs',
    );
  }

  /// Extract numeric data and return as MVS ValueVector.
  Future<MvsUnion> extractNumericDataAsMvs(
    String templateId,
    String fieldName, {
    int days = 30,
  }) {
    return tryMethod(
      () async {
        final data = await getAggregatedData(templateId, days: days);
        if (data == null) {
          throw AnalysisException('Template not found: $templateId');
        }

        final field = data.numericFields
            .where((f) => f.field.label == fieldName)
            .firstOrNull;
        if (field == null) {
          throw AnalysisException('Numeric field not found: $fieldName');
        }

        return _calc.valuesToMvs(field.values.map((v) => v.toDouble()).toList());
      },
      AnalysisException.new,
      'extractNumericDataAsMvs',
    );
  }

  /// Extract event dates and return as MVS TimestampVector.
  Future<MvsUnion> extractEventDatesAsMvs(
    String templateId,
    String fieldName, {
    int days = 90,
  }) {
    return tryMethod(
      () async {
        final data = await getAggregatedData(templateId, days: days);
        if (data == null) {
          throw AnalysisException('Template not found: $templateId');
        }

        final field = data.categoricalFields
            .where((f) => f.field.label == fieldName)
            .firstOrNull;
        if (field == null) {
          throw AnalysisException('Categorical field not found: $fieldName');
        }

        return _calc.datesToMvs(field.points.map((p) => p.date).toList());
      },
      AnalysisException.new,
      'extractEventDatesAsMvs',
    );
  }

  /// Calculate frequency distribution and return as MVS ValueVector.
  Future<MvsUnion> calculateFrequencyDistributionAsMvs(
    String templateId,
    String fieldName, {
    int days = 30,
  }) {
    return tryMethod(
      () async {
        final data = await getAggregatedData(templateId, days: days);
        if (data == null) {
          throw AnalysisException('Template not found: $templateId');
        }

        final field = data.categoricalFields
            .where((f) => f.field.label == fieldName)
            .firstOrNull;
        if (field == null) {
          throw AnalysisException('Categorical field not found: $fieldName');
        }

        return _calc.frequencyDistributionToMvs(field.values);
      },
      AnalysisException.new,
      'calculateFrequencyDistributionAsMvs',
    );
  }

  /// Calculate cycle lengths and return as MVS ValueVector.
  Future<MvsUnion> calculateCycleLengthsAsMvs(
    String templateId,
    String fieldName, {
    int days = 90,
  }) {
    return tryMethod(
      () async {
        final data = await getAggregatedData(templateId, days: days);
        if (data == null) {
          throw AnalysisException('Template not found: $templateId');
        }

        final field = data.categoricalFields
            .where((f) => f.field.label == fieldName)
            .firstOrNull;
        if (field == null) {
          throw AnalysisException('Categorical field not found: $fieldName');
        }

        return _calc.cycleLengthsToMvs(field.points.map((p) => p.date).toList());
      },
      AnalysisException.new,
      'calculateCycleLengthsAsMvs',
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // RAW DATA EXTRACTION (using LogEntryQueryDao)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Get aggregated data for a template over a date range.
  Future<TemplateAggregatedData?> getAggregatedData(
    String templateId, {
    int days = 30,
  }) {
    return tryMethod(
      () async {
        final templateWithAesthetics = await _templateRepo.findById(templateId);
        if (templateWithAesthetics == null) {
          return null; // Allow null return for internal use
        }

        final template = templateWithAesthetics.template;
        final endDate = DateTime.now();
        final startDate = endDate.subtract(Duration(days: days));
        
        // Use LogEntryQueryDao for reading
        final entries = await _entryDao.findByTemplateIdInRangeWithContext(
          templateId,
          startDate,
          endDate,
        );

        final numericFields = <NumericFieldData>[];
        final booleanFields = <BooleanFieldData>[];
        final categoricalFields = <CategoricalFieldData>[];

        for (final field in template.fields) {
          switch (field.type) {
            case FieldEnum.integer:
            case FieldEnum.float:
            case FieldEnum.dimension:
              numericFields.add(_extractNumericData(field, entries));
            case FieldEnum.boolean:
              booleanFields.add(_extractBooleanData(field, entries));
            case FieldEnum.enumerated:
              categoricalFields.add(_extractCategoricalData(field, entries));
            case FieldEnum.text:
            case FieldEnum.datetime:
            case FieldEnum.reference:
            case FieldEnum.location:
              break; // Not aggregatable
          }
        }

        return TemplateAggregatedData(
          template: template,
          numericFields: numericFields.where((f) => !f.isEmpty).toList(),
          booleanFields: booleanFields.where((f) => !f.isEmpty).toList(),
          categoricalFields: categoricalFields.where((f) => !f.isEmpty).toList(),
          totalEntries: entries.length,
          completedEntries: entries.where((e) => e.entry.isCompleted).length,
          startDate: startDate,
          endDate: endDate,
        );
      },
      AnalysisException.new,
      'getAggregatedData',
    );
  }

  NumericFieldData _extractNumericData(
    TemplateField field,
    List<LogEntryWithContext> entries,
  ) {
    final points = <({DateTime date, num value})>[];
    for (final entry in entries) {
      final raw = entry.entry.data[field.id];
      final value = _parseNumeric(raw);
      if (value != null) {
        points.add((date: entry.entry.displayTimestamp, value: value));
      }
    }
    points.sort((a, b) => a.date.compareTo(b.date));
    return NumericFieldData(field: field, points: points);
  }

  BooleanFieldData _extractBooleanData(
    TemplateField field,
    List<LogEntryWithContext> entries,
  ) {
    final points = <({DateTime date, bool value})>[];
    for (final entry in entries) {
      final value = entry.entry.data[field.id];
      if (value is bool) {
        points.add((date: entry.entry.displayTimestamp, value: value));
      }
    }
    points.sort((a, b) => a.date.compareTo(b.date));
    return BooleanFieldData(field: field, points: points);
  }

  CategoricalFieldData _extractCategoricalData(
    TemplateField field,
    List<LogEntryWithContext> entries,
  ) {
    final points = <({DateTime date, String category})>[];
    for (final entry in entries) {
      final value = entry.entry.data[field.id];
      if (value is String && value.isNotEmpty) {
        points.add((date: entry.entry.displayTimestamp, category: value));
      }
    }
    points.sort((a, b) => a.date.compareTo(b.date));
    return CategoricalFieldData(
      field: field,
      categories: field.options ?? [],
      points: points,
    );
  }

  num? _parseNumeric(dynamic value) {
    if (value == null) return null;
    if (value is num) return value;
    if (value is Map && value.containsKey('value')) {
      final v = value['value'];
      if (v is num) return v;
    }
    if (value is String) return num.tryParse(value);
    return null;
  }
}
