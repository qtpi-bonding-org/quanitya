import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:uuid/uuid.dart';
import 'template_field.dart';

part 'tracker_template.freezed.dart';
part 'tracker_template.g.dart';

/// Represents a tracker template - a user-defined form blueprint.
/// 
/// TrackerTemplateModel defines the structure and validation rules for data entry forms.
/// They contain a list of TemplateField objects that specify individual form fields.
@freezed
class TrackerTemplateModel with _$TrackerTemplateModel {
  const factory TrackerTemplateModel({
    /// Unique identifier for this template (UUID format)
    required String id,
    
    /// Display name for the template (e.g., "Leg Workout", "Daily Mood")
    required String name,
    
    /// List of field definitions that make up this template
    required List<TemplateField> fields,
    
    /// Timestamp of last modification
    required DateTime updatedAt,
    
    /// Soft delete flag - when true, template is hidden but preserved
    @Default(false) bool isArchived,
    
    /// Hidden flag - when true, template requires authentication to view
    /// Similar to iOS Hidden Photos or Locked Notes feature
    /// Hidden templates and their entries are excluded from normal queries
    @Default(false) bool isHidden,
  }) = _TrackerTemplateModel;
  
  /// Creates a TrackerTemplateModel from JSON map
  factory TrackerTemplateModel.fromJson(Map<String, dynamic> json) => 
      _$TrackerTemplateModelFromJson(json);
  
  /// Factory constructor that generates a new TrackerTemplateModel with UUID
  factory TrackerTemplateModel.create({
    required String name,
    required List<TemplateField> fields,
    bool isArchived = false,
    bool isHidden = false,
  }) {
    return TrackerTemplateModel(
      id: const Uuid().v4(),
      name: name,
      fields: fields,
      updatedAt: DateTime.now(),
      isArchived: isArchived,
      isHidden: isHidden,
    );
  }
  
  /// Factory constructor for creating an empty template
  factory TrackerTemplateModel.empty({
    required String name,
  }) {
    return TrackerTemplateModel(
      id: const Uuid().v4(),
      name: name,
      fields: [],
      updatedAt: DateTime.now(),
      isArchived: false,
      isHidden: false,
    );
  }
}

