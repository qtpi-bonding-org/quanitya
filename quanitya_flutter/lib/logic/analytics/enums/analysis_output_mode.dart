/// The structural commitment of the analysis output.
///
/// Defines how the UI should interpret and render the result
/// of a WASM-based analysis script.
enum AnalysisOutputMode {
  /// A single numeric value (e.g., KPI card, big number)
  scalar,

  /// A series of values with timestamps (e.g., line chart, sparkline)
  vector,

  /// A complex multi-dimensional structure (e.g., heatmap, data table)
  matrix,
}
