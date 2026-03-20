import 'package:flutter/material.dart';
import '../primitives/app_spacings.dart';
import '../primitives/quanitya_palette.dart';
import '../../support/extensions/context_extensions.dart';

/// Compact read-only table for displaying group field data in log entries.
///
/// Renders a header row of sub-field labels followed by value rows.
/// Designed for dense data display (e.g., lifting sets, medication doses).
///
/// Monospace fonts ensure natural column alignment without fixed widths.
///
/// **Usage:**
/// ```dart
/// QuanityaGroupTable(
///   headers: ['Weight', 'Reps', 'RPE'],
///   rows: [
///     ['185', '8', '7'],
///     ['185', '8', '8'],
///     ['175', '6', '9'],
///   ],
/// )
/// ```
class QuanityaGroupTable extends StatelessWidget {
  /// Column headers (sub-field labels).
  final List<String> headers;

  /// Data rows. Each row must have the same length as [headers].
  final List<List<String>> rows;

  /// Header text color. Defaults to [QuanityaPalette.primary.textSecondary].
  final Color? headerColor;

  /// Value text color. Defaults to [QuanityaPalette.primary.textPrimary].
  final Color? valueColor;

  /// Header text style override. Defaults to [context.text.bodySmall].
  final TextStyle? headerStyle;

  /// Value text style override. Defaults to [context.text.bodyMedium].
  final TextStyle? valueStyle;

  const QuanityaGroupTable({
    super.key,
    required this.headers,
    required this.rows,
    this.headerColor,
    this.valueColor,
    this.headerStyle,
    this.valueStyle,
  });

  @override
  Widget build(BuildContext context) {
    if (headers.isEmpty || rows.isEmpty) return const SizedBox.shrink();

    final effectiveHeaderColor =
        headerColor ?? QuanityaPalette.primary.textSecondary;
    final effectiveValueColor =
        valueColor ?? QuanityaPalette.primary.textPrimary;

    final effectiveHeaderStyle = (headerStyle ?? context.text.bodySmall)
        ?.copyWith(color: effectiveHeaderColor);
    final effectiveValueStyle = (valueStyle ?? context.text.bodyMedium)
        ?.copyWith(color: effectiveValueColor);

    return Semantics(
      label: 'Data table with ${rows.length} '
          '${rows.length == 1 ? 'row' : 'rows'}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header row
          _buildRow(headers, effectiveHeaderStyle),
          VSpace.x05,
          // Data rows
          for (int i = 0; i < rows.length; i++) ...[
            _buildRow(rows[i], effectiveValueStyle),
            if (i < rows.length - 1) VSpace.x05,
          ],
        ],
      ),
    );
  }

  Widget _buildRow(List<String> cells, TextStyle? style) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 0; i < cells.length; i++) ...[
          Text(cells[i], style: style),
          if (i < cells.length - 1) HSpace.x2,
        ],
      ],
    );
  }
}
