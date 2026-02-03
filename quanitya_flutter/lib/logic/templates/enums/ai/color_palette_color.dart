/// Enumeration of customizable colors in AI-generated templates.
///
/// These are the colors AI/users can customize. App constants (Washi White
/// background, Sumi Black text) are NOT included here - they're fixed.
///
/// Naming convention:
/// - `accent*` → interactive element colors (buttons, sliders, checkboxes)
/// - `tone*` → text/subtle variation colors
enum ColorPaletteColor {
  /// Primary accent - main interactive elements (slider thumb, checkbox active)
  accent1,

  /// Secondary accent - supporting elements (track, inactive states)
  accent2,

  /// Tertiary accent (optional) - additional highlight color
  accent3,

  /// Quaternary accent (optional) - fourth accent if needed
  accent4,

  /// Primary tone - secondary text color (labels, metadata)
  tone1,

  /// Secondary tone - subtle/tertiary text or borders
  tone2,
}