/// Container geometry styles for template field styling.
///
/// Defines the "stencil shape" - border radius, border width, fill opacity,
/// dashed borders, and which sides have borders.
///
/// Decoupled from font and color - users can mix any style with any font/color.
/// Philosophy: "Stationery, not software" - the style is the paper shape.
enum TemplateContainerStyle {
  // TIER 1: The Basics
  /// Invisible - no borders, no fill. Pure zen.
  zen,

  /// Rounded corners, subtle fill. Standard app feel.
  soft,

  /// Slightly rounded, thin border all sides. Engineering feel.
  tech,

  // TIER 2: The Sharp Edges
  /// Sharp corners, thin border, faint fill. Terminal/sysadmin aesthetic.
  console,

  /// Sharp corners, dashed border. Blueprint/maker aesthetic.
  drafting,

  /// Left bar only. Documentation/diff aesthetic.
  diff,

  // TIER 3: The Stylized
  /// Bottom line only. Accounting/ledger aesthetic.
  ledger,

  /// Thick borders, sharp corners. Bold/brutalist aesthetic.
  brutal,

  /// Fully rounded pills. Playful/bubble aesthetic.
  bubble,
}

/// Geometry recipe for a style - pure data, no Flutter dependencies.
///
/// Contains all the geometric properties needed to render a container:
/// - Border radius, width, and which sides have borders
/// - Fill opacity
/// - Whether borders are dashed
class StyleRecipe {
  final double borderRadius;
  final double borderWidth;
  final double fillOpacity;
  final bool isDashed;
  final bool top;
  final bool bottom;
  final bool left;
  final bool right;

  const StyleRecipe({
    this.borderRadius = 0.0,
    this.borderWidth = 0.0,
    this.fillOpacity = 0.0,
    this.isDashed = false,
    this.top = false,
    this.bottom = false,
    this.left = false,
    this.right = false,
  });

  factory StyleRecipe.fromContainerStyle(TemplateContainerStyle style) {
    return switch (style) {
      TemplateContainerStyle.zen => const StyleRecipe(),
      TemplateContainerStyle.soft => const StyleRecipe(
          borderRadius: 12.0,
          fillOpacity: 0.08,
        ),
      TemplateContainerStyle.tech => const StyleRecipe(
          top: true,
          bottom: true,
          left: true,
          right: true,
          borderRadius: 6.0,
          borderWidth: 1.0,
        ),
      TemplateContainerStyle.console => const StyleRecipe(
          top: true,
          bottom: true,
          left: true,
          right: true,
          borderRadius: 0.0,
          borderWidth: 1.0,
          fillOpacity: 0.04,
        ),
      TemplateContainerStyle.drafting => const StyleRecipe(
          top: true,
          bottom: true,
          left: true,
          right: true,
          borderRadius: 0.0,
          borderWidth: 1.5,
          isDashed: true,
        ),
      TemplateContainerStyle.diff => const StyleRecipe(
          left: true,
          borderWidth: 4.0,
          fillOpacity: 0.02,
        ),
      TemplateContainerStyle.ledger => const StyleRecipe(
          bottom: true,
          borderWidth: 1.0,
        ),
      TemplateContainerStyle.brutal => const StyleRecipe(
          top: true,
          bottom: true,
          left: true,
          right: true,
          borderRadius: 0.0,
          borderWidth: 2.5,
        ),
      TemplateContainerStyle.bubble => const StyleRecipe(
          borderRadius: 50.0,
          fillOpacity: 0.10,
        ),
    };
  }

  /// Whether this recipe has any visible borders
  bool get hasBorder => (top || bottom || left || right) && borderWidth > 0;

  /// Whether this recipe has any visible fill
  bool get hasFill => fillOpacity > 0;
}

/// Extension methods for TemplateContainerStyle enum.
extension TemplateContainerStyleX on TemplateContainerStyle {
  /// Display name for UI
  String get displayName => switch (this) {
        TemplateContainerStyle.zen => 'Zen',
        TemplateContainerStyle.soft => 'Soft',
        TemplateContainerStyle.tech => 'Tech',
        TemplateContainerStyle.console => 'Console',
        TemplateContainerStyle.drafting => 'Drafting',
        TemplateContainerStyle.diff => 'Diff',
        TemplateContainerStyle.ledger => 'Ledger',
        TemplateContainerStyle.brutal => 'Brutal',
        TemplateContainerStyle.bubble => 'Bubble',
      };

  /// Short description for UI tooltips
  String get description => switch (this) {
        TemplateContainerStyle.zen => 'Invisible, minimal',
        TemplateContainerStyle.soft => 'Rounded, subtle fill',
        TemplateContainerStyle.tech => 'Bordered, engineering',
        TemplateContainerStyle.console => 'Sharp, terminal',
        TemplateContainerStyle.drafting => 'Dashed, blueprint',
        TemplateContainerStyle.diff => 'Left bar, documentation',
        TemplateContainerStyle.ledger => 'Bottom line, accounting',
        TemplateContainerStyle.brutal => 'Thick borders, bold',
        TemplateContainerStyle.bubble => 'Pill shaped, playful',
      };

  /// Get all style names as list (for JSON schema enum)
  static List<String> get allStyleNames =>
      TemplateContainerStyle.values.map((s) => s.name).toList();

  /// Find style by name (case-insensitive)
  static TemplateContainerStyle? fromName(String name) {
    final lowerName = name.toLowerCase();
    for (final style in TemplateContainerStyle.values) {
      if (style.name.toLowerCase() == lowerName) {
        return style;
      }
    }
    return null;
  }
}
