import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'page_configuration.freezed.dart';

/// Font configuration for runtime UI rendering.
///
/// Converted from FontConfigData (DB storage) via extension method.
@freezed
class FontsConfig with _$FontsConfig {
  const FontsConfig._();

  const factory FontsConfig({
    String? titleFontFamily,
    String? subtitleFontFamily,
    String? bodyFontFamily,
    @Default(600) int titleWeight,
    @Default(400) int subtitleWeight,
    @Default(400) int bodyWeight,
  }) = _FontsConfig;

  /// Convert titleWeight int to FontWeight
  FontWeight get titleFontWeight => FontWeight.values.firstWhere(
        (fw) => fw.value == titleWeight,
        orElse: () => FontWeight.w600,
      );

  /// Convert subtitleWeight int to FontWeight
  FontWeight get subtitleFontWeight => FontWeight.values.firstWhere(
        (fw) => fw.value == subtitleWeight,
        orElse: () => FontWeight.w400,
      );

  /// Convert bodyWeight int to FontWeight
  FontWeight get bodyFontWeight => FontWeight.values.firstWhere(
        (fw) => fw.value == bodyWeight,
        orElse: () => FontWeight.w400,
      );
}

/// Page template configuration for runtime UI rendering.
///
/// Converted from TrackerTemplateModel.name + TemplateAestheticsModel.emoji
/// via ModelRuntimeConverter.
@freezed
class PageTemplateConfig with _$PageTemplateConfig {
  const factory PageTemplateConfig({
    /// Page title (from TrackerTemplateModel.name)
    required String title,

    /// Optional emoji icon (from TemplateAestheticsModel.emoji)
    String? iconEmoji,
  }) = _PageTemplateConfig;
}
