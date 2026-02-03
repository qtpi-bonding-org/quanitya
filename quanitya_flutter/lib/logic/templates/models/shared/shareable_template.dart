import 'package:freezed_annotation/freezed_annotation.dart';
import 'tracker_template.dart';
import 'template_aesthetics.dart';
import '../../../analytics/models/analysis_pipeline.dart';

part 'shareable_template.freezed.dart';
part 'shareable_template.g.dart';

/// Shareable template format for decentralized template sharing.
///
/// This model wraps a TrackerTemplate with optional aesthetics and analysis
/// pipelines for sharing via GitHub Gists, repositories, or direct URLs.
/// 
/// All templates are MIT licensed by default.
@freezed
class ShareableTemplate with _$ShareableTemplate {
  const factory ShareableTemplate({
    /// Schema version for compatibility checking (e.g., "1.0")
    required String version,
    
    /// Creator attribution information
    required AuthorCredit author,
    
    /// Core template structure (REQUIRED)
    required TrackerTemplateModel template,
    
    /// Visual styling (OPTIONAL - users can apply their own)
    TemplateAestheticsModel? aesthetics,
    
    /// Analysis configurations (OPTIONAL - charts, insights, aggregations)
    List<AnalysisPipelineModel>? analysisPipelines,
    
    /// Optional template description for sharing
    String? description,
    
    /// Creation timestamp
    DateTime? createdAt,
  }) = _ShareableTemplate;

  /// Creates from JSON map
  factory ShareableTemplate.fromJson(Map<String, dynamic> json) =>
      _$ShareableTemplateFromJson(json);

  /// Factory constructor for creating a shareable template
  factory ShareableTemplate.create({
    required AuthorCredit author,
    required TrackerTemplateModel template,
    TemplateAestheticsModel? aesthetics,
    List<AnalysisPipelineModel>? analysisPipelines,
    String? description,
  }) {
    return ShareableTemplate(
      version: '1.0',
      author: author,
      template: template,
      aesthetics: aesthetics,
      analysisPipelines: analysisPipelines,
      description: description,
      createdAt: DateTime.now(),
    );
  }
}

/// Author attribution for shared templates.
@freezed
class AuthorCredit with _$AuthorCredit {
  const factory AuthorCredit({
    /// Author name or handle (e.g., "@PrivacyQueen", "John Doe")
    required String name,
    
    /// Optional link to author profile or website
    String? url,
  }) = _AuthorCredit;

  /// Creates from JSON map
  factory AuthorCredit.fromJson(Map<String, dynamic> json) =>
      _$AuthorCreditFromJson(json);

  /// Factory constructor for creating author credit
  factory AuthorCredit.create({
    required String name,
    String? url,
  }) {
    return AuthorCredit(
      name: name,
      url: url,
    );
  }
}