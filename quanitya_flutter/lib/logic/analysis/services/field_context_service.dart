import 'package:injectable/injectable.dart';
import '../../templates/enums/field_enum.dart';
import '../models/field_analysis_context.dart';
import '../models/matrix_vector_scalar/analysis_data_type.dart';
import '../../../infrastructure/core/try_operation.dart';
import '../exceptions/analysis_exceptions.dart';

/// Service for gathering field context for AI script suggestions
@injectable
class FieldContextService {
  const FieldContextService();

  /// Get analysis context for a specific field
  Future<FieldAnalysisContext> getFieldContext({
    required String templateId,
    required String fieldId,
  }) {
    return tryMethod(
      () async {
        // Using mock data for AI script suggestions
        // This provides field context to help AI suggest relevant operations
        final field = await _getFieldInfo(templateId, fieldId);
        final sampleData = await _getSampleData(templateId, fieldId, limit: 3);
        final dataCount = await _getDataCount(templateId, fieldId);

        return FieldAnalysisContextExt.create(
          fieldId: fieldId,
          fieldName: field['name'] as String,
          fieldType: field['type'] as FieldEnum,
          startType: AnalysisDataType.timeSeriesMatrix, // Always start with matrix
          sampleValues: _anonymizeSamples(sampleData),
          dataPointCount: dataCount,
          description: field['description'] as String?,
          metadata: field['metadata'] as Map<String, dynamic>?,
        );
      },
      AnalysisException.new,
      'getFieldContext',
    );
  }

  /// Get field information from template (mock data for AI suggestions)
  Future<Map<String, dynamic>> _getFieldInfo(String templateId, String fieldId) async {
    return switch (fieldId) {
      'mood' => {
        'name': 'Mood',
        'type': FieldEnum.integer,
        'description': 'Daily mood rating (1-10)',
        'metadata': {'min': 1, 'max': 10},
      },
      'sleep_hours' => {
        'name': 'Sleep Hours',
        'type': FieldEnum.float,
        'description': 'Hours of sleep per night',
        'metadata': {'min': 0, 'max': 24},
      },
      'exercise_type' => {
        'name': 'Exercise Type',
        'type': FieldEnum.enumerated,
        'description': 'Type of exercise performed',
        'metadata': {'options': ['cardio', 'strength', 'yoga', 'walking']},
      },
      'energy_level' => {
        'name': 'Energy Level',
        'type': FieldEnum.integer,
        'description': 'Energy level rating (1-10)',
        'metadata': {'min': 1, 'max': 10},
      },
      _ => {
        'name': 'Unknown Field',
        'type': FieldEnum.text,
        'description': 'Field description not available',
        'metadata': <String, dynamic>{},
      },
    };
  }

  /// Get sample data for the field (mock data for AI suggestions)
  Future<List<dynamic>> _getSampleData(String templateId, String fieldId, {int limit = 3}) async {
    return switch (fieldId) {
      'mood' => [7, 8, 6],
      'sleep_hours' => [7.5, 8.2, 6.8],
      'exercise_type' => ['cardio', 'yoga', 'strength'],
      'energy_level' => [6, 8, 7],
      _ => ['sample1', 'sample2', 'sample3'],
    };
  }

  /// Get total data point count for the field (mock data for AI suggestions)
  Future<int> _getDataCount(String templateId, String fieldId) async {
    return switch (fieldId) {
      'mood' => 45,
      'sleep_hours' => 38,
      'exercise_type' => 42,
      'energy_level' => 40,
      _ => 25,
    };
  }

  /// Anonymize sample values for AI consumption
  List<String> _anonymizeSamples(List<dynamic> samples) {
    return samples.map((sample) {
      if (sample is num) {
        return sample.toString();
      } else if (sample is String) {
        // Keep categorical values as-is for pattern recognition
        return sample;
      } else {
        return sample.toString();
      }
    }).toList();
  }

  /// Get field type characteristics for AI prompting
  Map<String, dynamic> getFieldTypeCharacteristics(FieldEnum fieldType) {
    return switch (fieldType) {
      FieldEnum.integer => {
        'dataType': 'numeric',
        'operations': ['mean', 'min', 'max', 'trend'],
        'insights': ['averages', 'patterns', 'extremes'],
        'examples': ['mood ratings', 'counts', 'scores'],
      },
      FieldEnum.float => {
        'dataType': 'numeric',
        'operations': ['mean', 'min', 'max', 'trend', 'precision'],
        'insights': ['averages', 'patterns', 'precision tracking'],
        'examples': ['sleep hours', 'measurements', 'durations'],
      },
      FieldEnum.enumerated => {
        'dataType': 'categorical',
        'operations': ['mode', 'frequency', 'distribution'],
        'insights': ['most common', 'variety', 'patterns'],
        'examples': ['exercise types', 'categories', 'choices'],
      },
      FieldEnum.text => {
        'dataType': 'text',
        'operations': ['length', 'frequency', 'patterns'],
        'insights': ['content analysis', 'length patterns'],
        'examples': ['notes', 'descriptions', 'comments'],
      },
      FieldEnum.boolean => {
        'dataType': 'binary',
        'operations': ['frequency', 'streaks', 'patterns'],
        'insights': ['success rate', 'consistency', 'trends'],
        'examples': ['habits', 'yes/no tracking', 'completion'],
      },
      FieldEnum.datetime => {
        'dataType': 'temporal',
        'operations': ['intervals', 'patterns', 'frequency'],
        'insights': ['timing patterns', 'intervals', 'regularity'],
        'examples': ['event dates', 'milestones', 'occurrences'],
      },
      FieldEnum.dimension => {
        'dataType': 'measurement',
        'operations': ['mean', 'min', 'max', 'trend'],
        'insights': ['averages', 'patterns', 'unit conversion'],
        'examples': ['weight', 'distance', 'temperature'],
      },
      FieldEnum.reference => {
        'dataType': 'reference',
        'operations': ['count', 'frequency', 'relationships'],
        'insights': ['connections', 'references', 'relationships'],
        'examples': ['linked entries', 'references', 'connections'],
      },
      FieldEnum.location => {
        'dataType': 'geospatial',
        'operations': ['distance', 'clustering', 'frequency'],
        'insights': ['places visited', 'movement patterns', 'distances'],
        'examples': ['check-ins', 'workout locations', 'travel logs'],
      },
    };
  }
}