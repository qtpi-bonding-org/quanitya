import 'package:flutter/material.dart';
import 'package:anonaccred_client/anonaccred_client.dart' show EntitlementType;
import 'package:quanitya_cloud_client/quanitya_cloud_client.dart'
    show AccountFeatureEntitlement, Feature;

import '../../../design_system/primitives/app_sizes.dart';
import '../../../design_system/primitives/app_spacings.dart';
import '../../../design_system/primitives/quanitya_palette.dart';
import '../../../design_system/widgets/quanitya_icon_button.dart';
import '../../../support/extensions/context_extensions.dart';

/// Displays the user's entitlements — all types, including zero-balance.
///
/// Display rules by [EntitlementType]:
/// - **subscription**: "Active" (sage green) if balance > 0, "Inactive" (grey) otherwise
/// - **onetime**: same as subscription — boolean active/inactive
/// - **consumable**: numeric balance (e.g. "20", "0")
///
/// Shown only when [EntitlementCubit.hasPurchased] is true.
class EntitlementDisplay extends StatelessWidget {
  const EntitlementDisplay({
    super.key,
    required this.entitlements,
    this.storageBytes,
    this.entryCount,
    this.hasError = false,
    this.onRetry,
  });

  final List<AccountFeatureEntitlement> entitlements;
  final int? storageBytes;
  final int? entryCount;
  final bool hasError;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final palette = QuanityaPalette.primary;

    return Padding(
      padding: AppPadding.pageHorizontal,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Storage usage
          if (storageBytes != null || entryCount != null) ...[
            _buildStorageRow(context),
          ],

          if (entitlements.isNotEmpty) ...[
            VSpace.x2,
            CustomPaint(
              size: Size(AppSizes.space * 8, AppSizes.borderWidth),
              painter: _PenDividerPainter(
                color: palette.textSecondary.withValues(alpha: 0.3),
              ),
            ),
            VSpace.x1,
            ..._buildFeatureRows(context),
          ],

          // Error/retry
          if (hasError) ...[
            VSpace.x1,
            Row(
              children: [
                QuanityaIconButton(
                  icon: Icons.refresh,
                  onPressed: onRetry,
                  iconSize: AppSizes.iconMedium,
                  color: palette.cautionColor,
                  tooltip: context.l10n.entitlementRefreshFailed,
                ),
                HSpace.x05,
                Text(
                  context.l10n.entitlementRefreshFailed,
                  style: context.text.bodySmall?.copyWith(
                    color: palette.cautionColor,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  /// Groups entitlements by [Feature] and renders one row per feature.
  ///
  /// - **cloudSync** (subscription): Active/Inactive based on any balance > 0
  /// - **llm** (consumable): sum of all LLM-tagged balances
  List<Widget> _buildFeatureRows(BuildContext context) {
    final grouped = <Feature, List<AccountFeatureEntitlement>>{};
    for (final e in entitlements) {
      (grouped[e.feature] ??= []).add(e);
    }

    // Stable display order: cloudSync first, then llm.
    const featureOrder = [Feature.cloudSync, Feature.llm];

    return [
      for (final feature in featureOrder)
        if (grouped.containsKey(feature))
          _buildFeatureRow(context, feature, grouped[feature]!),
    ];
  }

  Widget _buildFeatureRow(
    BuildContext context,
    Feature feature,
    List<AccountFeatureEntitlement> entries,
  ) {
    final palette = QuanityaPalette.primary;

    final name = switch (feature) {
      Feature.cloudSync => context.l10n.featureCloudSync,
      Feature.llm => context.l10n.featureLlm,
    };

    // Subscriptions → boolean active/inactive
    // Consumables → sum balances
    final hasSubscription =
        entries.any((e) => e.type == EntitlementType.subscription);

    String label;
    Color color;
    if (hasSubscription) {
      final active = entries.any((e) => e.balance > 0);
      label = active
          ? context.l10n.entitlementActive
          : context.l10n.entitlementInactive;
      color = active ? palette.stateOnColor : palette.textSecondary;
    } else {
      final total = entries.fold<double>(0, (sum, e) => sum + e.balance);
      label = total.truncateToDouble() == total
          ? total.toInt().toString()
          : total.toStringAsFixed(1);
      color = total > 0 ? palette.textPrimary : palette.textSecondary;
    }

    return Padding(
      padding: EdgeInsets.only(bottom: AppSizes.space * 0.5),
      child: Row(
        children: [
          Expanded(
            child: Text(
              name,
              style: context.text.bodyMedium?.copyWith(
                color: palette.textSecondary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          HSpace.x1,
          Text(
            label,
            style: context.text.bodyMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStorageRow(BuildContext context) {
    final parts = <String>[];

    final bytes = storageBytes;
    if (bytes != null) {
      parts.add('~${_formatBytes(bytes)}');
    }

    final count = entryCount;
    if (count != null) {
      parts.add(context.l10n.estimatedEntries(count));
    }

    return Text(
      parts.join(' · '),
      style: context.text.bodySmall?.copyWith(
        color: context.colors.textSecondary,
      ),
    );
  }

  static String _formatBytes(int bytes) {
    if (bytes >= 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
    if (bytes >= 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    if (bytes >= 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '$bytes B';
  }
}

/// Simple hand-drawn horizontal line.
class _PenDividerPainter extends CustomPainter {
  final Color color;

  _PenDividerPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.height
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(0, size.height / 2),
      Offset(size.width, size.height / 2),
      paint,
    );
  }

  @override
  bool shouldRepaint(_PenDividerPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
