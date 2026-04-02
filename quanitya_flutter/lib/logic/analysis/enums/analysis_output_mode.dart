import 'package:flutter/material.dart';
import '../../../support/extensions/context_extensions.dart';

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

extension AnalysisOutputModeDisplayName on AnalysisOutputMode {
  /// Returns a localized display name for the output mode.
  String displayName(BuildContext context) {
    return switch (this) {
      AnalysisOutputMode.scalar => context.l10n.outputModeScalar,
      AnalysisOutputMode.vector => context.l10n.outputModeVector,
      AnalysisOutputMode.matrix => context.l10n.outputModeMatrix,
    };
  }
}
