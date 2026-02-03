/// Type-safe identifiers for Jinja-based analysis shells.
///
/// Each shell provides a different sandboxed environment and
/// validation logic for the AI-generated logic fragments.
enum AnalysisShell {
  /// Standard scalar shell for single-number insights
  scalar,

  /// Vector shell for time-series data analysis
  vector,

  /// Matrix shell for multi-field or complex transformations
  matrix,
}
