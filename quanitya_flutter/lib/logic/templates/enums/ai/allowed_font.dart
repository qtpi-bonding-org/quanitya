/// Curated list of Google Fonts allowed for AI template generation.
///
/// These fonts are chosen to work well with Quanitya's zen aesthetic
/// and are all available via the `google_fonts` package.
///
/// The enum name matches the Google Fonts API name exactly.
enum AllowedFont {
  /// Atkinson Hyperlegible Mono - Quanitya's header font, designed for legibility
  atkinsonHyperlegibleMono('Atkinson Hyperlegible Mono'),

  /// Noto Sans Mono - Quanitya's body font, excellent language support
  notoSansMono('Noto Sans Mono'),

  /// Playfair Display - Elegant serif for sophisticated templates
  playfairDisplay('Playfair Display'),

  /// Bebas Neue - Bold condensed sans-serif for impactful headers
  bebasNeue('Bebas Neue'),

  /// Pacifico - Playful script font for casual templates
  pacifico('Pacifico'),

  /// Cormorant Garamond - Classic serif with a modern twist
  cormorantGaramond('Cormorant Garamond'),

  /// Righteous - Retro-futuristic display font
  righteous('Righteous'),

  /// Quicksand - Rounded sans-serif, friendly and approachable
  quicksand('Quicksand'),

  /// Space Grotesk - Modern geometric sans-serif
  spaceGrotesk('Space Grotesk'),

  /// Lora - Well-balanced serif for comfortable reading
  lora('Lora'),

  /// Inter - Highly legible sans-serif designed for screens
  inter('Inter'),

  /// Nunito - Rounded sans-serif, warm and friendly
  nunito('Nunito'),

  /// Source Serif 4 - Adobe's open-source serif, professional
  sourceSerif4('Source Serif 4'),

  /// Karla - Grotesque sans-serif with character
  karla('Karla'),

  /// Cabin - Humanist sans-serif, modern and readable
  cabin('Cabin'),

  /// Space Mono - Monospace font for technical templates
  spaceMono('Space Mono');

  /// The Google Fonts API name (used with GoogleFonts.getFont())
  final String googleFontName;

  const AllowedFont(this.googleFontName);

  /// Get all font names as a list (for JSON schema enum)
  static List<String> get allFontNames =>
      values.map((f) => f.googleFontName).toList();

  /// Find font by Google Fonts name (case-insensitive)
  static AllowedFont? fromName(String name) {
    final lowerName = name.toLowerCase();
    for (final font in values) {
      if (font.googleFontName.toLowerCase() == lowerName) {
        return font;
      }
    }
    return null;
  }

  /// Check if a font name is allowed
  static bool isAllowed(String name) => fromName(name) != null;
}
