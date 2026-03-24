import 'package:flutter/material.dart';
import 'package:anonaccred_client/anonaccred_client.dart'
    show AccountEntitlement, EntitlementType;

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

  final List<AccountEntitlement> entitlements;
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
            ...entitlements.map((e) => _buildEntitlementRow(context, e)),
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

  Widget _buildEntitlementRow(BuildContext context, AccountEntitlement e) {
    final palette = QuanityaPalette.primary;
    final name = e.entitlement?.name ??
        context.l10n.entitlementLabel(e.entitlementId);
    final type = e.entitlement?.type;

    // Subscription / onetime → boolean active/inactive
    // Consumable → numeric balance
    final (String label, Color color) = switch (type) {
      EntitlementType.subscription || EntitlementType.onetime =>
        e.balance > 0
            ? (context.l10n.entitlementActive, palette.stateOnColor)
            : (context.l10n.entitlementInactive, palette.textSecondary),
      EntitlementType.consumable || null => (
        e.balance.truncateToDouble() == e.balance
            ? e.balance.toInt().toString()
            : e.balance.toStringAsFixed(1),
        e.balance > 0 ? palette.textPrimary : palette.textSecondary,
      ),
    };

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
