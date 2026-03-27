import 'package:injectable/injectable.dart';

import '../../../infrastructure/config/debug_log.dart';

import '../../../data/dao/template_query_dao.dart';
import '../../templates/enums/field_enum.dart';
import '../../templates/models/shared/template_field.dart';
import '../exceptions/analysis_exceptions.dart';

const _tag = 'logic/analysis/services/field_shape_resolver';

/// Resolves the data shape of a field for AI prompts and WASM context.
///
/// Returns only structural metadata (field names, types, sub-field shapes).
/// Never returns actual user data.
@injectable
class FieldShapeResolver {
  final TemplateQueryDao _templateDao;

  const FieldShapeResolver(this._templateDao);

  /// Resolve the shape description for a field's `data.values`.
  ///
  /// [fieldId] format: "templateId:fieldLabel"
  ///
  /// Returns a string like `number[]`, `string[]`,
  /// or `{exercise: string, weight: number, reps: number}[][]` for groups.
  Future<FieldShapeResult> resolve(String fieldId) async {
    Log.d(_tag,'🔍 FieldShapeResolver.resolve: fieldId="$fieldId"');
    final parts = fieldId.split(':');
    if (parts.length != 2) {
      Log.d(_tag,'🔍 FieldShapeResolver.resolve: INVALID format');
      throw AnalysisException('Invalid fieldId format: $fieldId');
    }
    final templateId = parts[0];
    final fieldLabel = parts[1];

    final template = await _templateDao.findById(templateId);
    if (template == null) {
      Log.d(_tag,'🔍 FieldShapeResolver.resolve: template NOT FOUND');
      throw AnalysisException('Template not found: $templateId');
    }
    Log.d(_tag,'🔍 FieldShapeResolver.resolve: template="${template.name}", fields=${template.fields.map((f) => f.label).toList()}');

    final field = template.fields.where((f) => f.label == fieldLabel).firstOrNull;
    if (field == null) {
      Log.d(_tag,'🔍 FieldShapeResolver.resolve: field "$fieldLabel" NOT FOUND');
      throw AnalysisException(
        'Field "$fieldLabel" not found in template "${template.name}"',
      );
    }

    final shape = _describeShape(field);
    Log.d(_tag,'🔍 FieldShapeResolver.resolve: field="${field.label}" type=${field.type} shape=$shape');
    return FieldShapeResult(
      fieldName: field.label,
      fieldType: field.type,
      valueShape: shape,
    );
  }

  String _describeShape(TemplateField field) {
    return switch (field.type) {
      FieldEnum.integer => 'number[] (integers)',
      FieldEnum.float => 'number[] (decimals)',
      FieldEnum.dimension => 'number[] (measurements)',
      FieldEnum.boolean => 'boolean[]',
      FieldEnum.text => 'string[]',
      FieldEnum.enumerated => 'string[] (one of predefined options)',
      FieldEnum.datetime => 'string[] (ISO date strings)',
      FieldEnum.multiEnum => 'string[][] (arrays of selected option strings)',
      FieldEnum.reference => 'string[] (reference IDs)',
      FieldEnum.location => '{latitude: number, longitude: number}[]',
      FieldEnum.group => _describeGroupShape(field),
    };
  }

  /// Builds a concrete shape string from actual sub-field definitions.
  ///
  /// e.g. `{exercise: string, weight: number, reps: number}[][]`
  /// The outer `[]` is per-entry, inner `[]` is the list of sets.
  String _describeGroupShape(TemplateField field) {
    final subFields = field.subFields;
    if (subFields == null || subFields.isEmpty) {
      return 'object[][] (group field — sub-fields unknown)';
    }

    final props = subFields.map((sf) {
      final tsType = switch (sf.type) {
        FieldEnum.integer || FieldEnum.float || FieldEnum.dimension => 'number',
        FieldEnum.boolean => 'boolean',
        _ => 'string',
      };
      return '${sf.label}: $tsType';
    }).join(', ');

    return '{$props}[][]';
  }
}

/// Result of resolving a field's data shape.
class FieldShapeResult {
  final String fieldName;
  final FieldEnum fieldType;

  /// Human-readable shape of `data.values` for the AI prompt.
  final String valueShape;

  const FieldShapeResult({
    required this.fieldName,
    required this.fieldType,
    required this.valueShape,
  });
}
