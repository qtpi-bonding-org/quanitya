import 'dart:convert';

import 'package:drift/drift.dart' as drift;
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:uuid/uuid.dart';

import '../../enums/ai/template_preset.dart';
import '../../../../data/db/app_database.dart';

part 'template_aesthetics.freezed.dart';
part 'template_aesthetics.g.dart';

/// Represents visual styling for a tracker template.
/// 
/// Stores non-PII aesthetic data: colors, fonts, icons, and widget color mappings.
/// Separated from TrackerTemplateModel to decouple content from presentation.
/// 
/// NOT encrypted - contains only styling data, no sensitive information.
@freezed
class TemplateAestheticsModel with _$TemplateAestheticsModel {
  const TemplateAestheticsModel._();
  
  const factory TemplateAestheticsModel({
    /// Unique identifier for this aesthetics record (UUID format)
    required String id,
    
    /// FK to TrackerTemplate - defines which template this styling belongs to
    required String templateId,
    
    /// Optional theme name for user identification (e.g., "Ocean Vibes", "Sunset Warm")
    String? themeName,
    
    /// Icon from flutter_iconpicker in format "packname:iconname"
    /// e.g., "material:fitness_center", "cupertino:heart_fill"
    /// Priority: icon → emoji → default
    String? icon,
    
    /// Fallback emoji icon (e.g., "🏋️", "💊", "😊")
    /// Used when icon is null
    String? emoji,
    
    /// Color palette with hex values
    required ColorPaletteData palette,
    
    /// Font configuration
    required FontConfigData fontConfig,
    
    /// Color mappings by widget type (first unique per type)
    required Map<String, Map<String, String>> colorMappings,
    
    /// Container geometry style for field styling.
    /// Nullable - user must explicitly choose (no default).
    /// Defines the "stencil shape" - borders, radius, fill.
    TemplateContainerStyle? containerStyle,
    
    /// Timestamp of last modification
    required DateTime updatedAt,
  }) = _TemplateAestheticsModel;
  
  /// Creates from JSON map
  factory TemplateAestheticsModel.fromJson(Map<String, dynamic> json) => 
      _$TemplateAestheticsModelFromJson(json);
  
  // ─────────────────────────────────────────────────────────────────────────
  // Factory Constructors
  // ─────────────────────────────────────────────────────────────────────────
  
  /// Create a new aesthetics record with generated UUID
  factory TemplateAestheticsModel.create({
    required String templateId,
    String? themeName,
    String? icon,
    String? emoji,
    required ColorPaletteData palette,
    required FontConfigData fontConfig,
    Map<String, Map<String, String>>? colorMappings,
    TemplateContainerStyle? containerStyle,
  }) {
    return TemplateAestheticsModel(
      id: const Uuid().v4(),
      templateId: templateId,
      themeName: themeName,
      icon: icon,
      emoji: emoji,
      palette: palette,
      fontConfig: fontConfig,
      colorMappings: colorMappings ?? {},
      containerStyle: containerStyle,
      updatedAt: DateTime.now(),
    );
  }
  
  /// Create with default styling
  factory TemplateAestheticsModel.defaults({
    required String templateId,
    String? themeName,
    String? emoji,
  }) {
    return TemplateAestheticsModel.create(
      templateId: templateId,
      themeName: themeName,
      emoji: emoji,
      palette: ColorPaletteData.defaults(),
      fontConfig: FontConfigData.defaults(),
    );
  }
  
  // ─────────────────────────────────────────────────────────────────────────
  // JSON Serialization Helpers (for DB storage)
  // ─────────────────────────────────────────────────────────────────────────
  
  /// Serialize palette to JSON string for DB storage
  String get paletteJson => jsonEncode(palette.toJson());
  
  /// Serialize font config to JSON string for DB storage
  String get fontConfigJson => jsonEncode(fontConfig.toJson());
  
  /// Serialize color mappings to JSON string for DB storage
  String get colorMappingsJson => jsonEncode(colorMappings);
  
  // ─────────────────────────────────────────────────────────────────────────
  // Computed Properties
  // ─────────────────────────────────────────────────────────────────────────
  
  /// Whether this aesthetics has any icon set
  bool get hasIcon => icon != null || emoji != null;
  
  /// Get color mapping for a specific UI element
  Map<String, String>? getColorMapping(String uiElement) => colorMappings[uiElement];
}

// ─────────────────────────────────────────────────────────────────────────
// Database Conversion Extension
// ─────────────────────────────────────────────────────────────────────────

/// Extension for converting between TemplateAestheticsModel and database entities.
/// 
/// Provides type-safe conversion methods that ensure all fields are handled
/// and prevent bugs like missing field conversions.
extension TemplateAestheticsConversion on TemplateAestheticsModel {
  /// Convert model to database companion for saving.
  /// 
  /// All fields are explicitly handled to prevent missing conversions.
  TemplateAestheticsCompanion toCompanion() {
    return TemplateAestheticsCompanion.insert(
      id: id,
      templateId: templateId,
      themeName: drift.Value(themeName),
      icon: drift.Value(icon),
      emoji: drift.Value(emoji),
      paletteJson: paletteJson,
      fontConfigJson: fontConfigJson,
      colorMappingsJson: colorMappingsJson,
      containerStyle: drift.Value(containerStyle?.name), // Convert enum to string
      updatedAt: updatedAt,
    );
  }

  /// Create model from database entity.
  /// 
  /// Handles all JSON deserialization and enum conversion safely.
  static TemplateAestheticsModel fromEntity(TemplateAesthetic entity) {
    return TemplateAestheticsModel(
      id: entity.id,
      templateId: entity.templateId,
      themeName: entity.themeName,
      icon: entity.icon,
      emoji: entity.emoji,
      palette: entity.paletteJson.isNotEmpty
          ? ColorPaletteData.fromJson(jsonDecode(entity.paletteJson))
          : ColorPaletteData.defaults(),
      fontConfig: entity.fontConfigJson.isNotEmpty
          ? FontConfigData.fromJson(jsonDecode(entity.fontConfigJson))
          : FontConfigData.defaults(),
      colorMappings: entity.colorMappingsJson.isNotEmpty
          ? Map<String, Map<String, String>>.from(
              (jsonDecode(entity.colorMappingsJson) as Map).map(
                (k, v) => MapEntry(k as String, Map<String, String>.from(v)),
              ),
            )
          : {},
      containerStyle: entity.containerStyle != null 
          ? TemplateContainerStyleX.fromName(entity.containerStyle!) 
          : null,
      updatedAt: entity.updatedAt,
    );
  }
}

/// Color palette data with customizable accent and tone colors.
///
/// Fixed app constants (Washi White background, Sumi Black text) are NOT stored
/// here - they come from QuanityaPalette. This only stores customizable colors.
@freezed
class ColorPaletteData with _$ColorPaletteData {
  const ColorPaletteData._();

  const factory ColorPaletteData({
    /// Accent colors as hex strings - for interactive elements
    /// [accent1, accent2, accent3, accent4]
    required List<String> accents,

    /// Tone colors as hex strings - for text variations
    /// [tone1, tone2] - secondary text, subtle borders
    required List<String> tones,
  }) = _ColorPaletteData;

  factory ColorPaletteData.fromJson(Map<String, dynamic> json) =>
      _$ColorPaletteDataFromJson(json);

  /// Default color palette (Quanitya brand accents)
  factory ColorPaletteData.defaults() => const ColorPaletteData(
        accents: ['#006280', '#4D5B60'], // Teal accent, Blue-grey
        tones: ['#4D5B60', '#7A8A8F'], // Secondary text, Subtle
      );

  /// Get color by slot name (accent1, accent2, tone1, etc.)
  String? getColor(String slot) {
    if (slot.startsWith('accent')) {
      final index = int.tryParse(slot.substring(6));
      if (index != null && index >= 1 && index <= accents.length) {
        return accents[index - 1];
      }
    } else if (slot.startsWith('tone')) {
      final index = int.tryParse(slot.substring(4));
      if (index != null && index >= 1 && index <= tones.length) {
        return tones[index - 1];
      }
    }
    return null;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Migration helpers (for backward compatibility with old 'colors'/'neutrals')
  // ─────────────────────────────────────────────────────────────────────────

  /// Creates from legacy format (colors/neutrals) for migration
  factory ColorPaletteData.fromLegacy({
    required List<String> colors,
    required List<String> neutrals,
  }) {
    return ColorPaletteData(
      accents: colors,
      tones: neutrals,
    );
  }
}

/// Font configuration data
@freezed
class FontConfigData with _$FontConfigData {
  const FontConfigData._();
  
  const factory FontConfigData({
    /// Font family for titles (null = system default)
    String? titleFontFamily,
    
    /// Font family for subtitles (null = system default)
    String? subtitleFontFamily,
    
    /// Font family for body text (null = system default)
    String? bodyFontFamily,
    
    /// Font weight for titles (100-900)
    @Default(600) int titleWeight,
    
    /// Font weight for subtitles (100-900)
    @Default(400) int subtitleWeight,
    
    /// Font weight for body text (100-900)
    @Default(400) int bodyWeight,
  }) = _FontConfigData;
  
  factory FontConfigData.fromJson(Map<String, dynamic> json) => 
      _$FontConfigDataFromJson(json);
  
  /// Default font configuration
  factory FontConfigData.defaults() => const FontConfigData();
}
