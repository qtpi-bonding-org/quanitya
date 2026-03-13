import 'package:flutter/material.dart';
import 'package:anonaccred_client/anonaccred_client.dart'
    show AccountEntitlement;

import '../../../design_system/primitives/app_sizes.dart';
import '../../../design_system/primitives/app_spacings.dart';
import '../../../design_system/primitives/quanitya_palette.dart';
import '../../../support/extensions/context_extensions.dart';

/// Displays the user's entitlement balances (sync days, credits, etc.)
///
/// Manuscript style: no card wrapper, just pen-styled text and icon.
class BalanceDisplay extends StatelessWidget {
  const BalanceDisplay({
    super.key,
    required this.entitlements,
    required this.hasSyncAccess,
    this.storageBytes,
    this.entryCount,
  });

  final List<AccountEntitlement> entitlements;
  final bool hasSyncAccess;
  final int? storageBytes;
  final int? entryCount;

  @override
  Widget build(BuildContext context) {
    final palette = QuanityaPalette.primary;
    final statusColor =
        hasSyncAccess ? palette.successColor : palette.errorColor;

    return Padding(
      padding: AppPadding.pageHorizontal,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                hasSyncAccess ? Icons.cloud_done : Icons.cloud_off,
                color: statusColor,
                size: AppSizes.iconMedium,
              ),
              HSpace.x1,
              Expanded(
                child: Text(
                  hasSyncAccess
                      ? context.l10n.syncActive
                      : context.l10n.syncInactive,
                  style: context.text.titleMedium?.copyWith(
                    color: statusColor,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),

          // Storage usage
          if (storageBytes != null || entryCount != null) ...[
            VSpace.x1,
            _buildStorageRow(context),
          ],

          if (entitlements.isNotEmpty) ...[
            VSpace.x2,
            // Pen-drawn divider
            CustomPaint(
              size: Size(AppSizes.space * 8, AppSizes.borderWidth),
              painter: _PenDividerPainter(
                color: palette.textSecondary.withValues(alpha: 0.3),
              ),
            ),
            VSpace.x1,
            ...entitlements.map((e) {
              final name = e.entitlement?.name ??
                  context.l10n.entitlementLabel(e.entitlementId);
              final isSyncTier =
                  e.entitlement?.tag.startsWith('sync_') ?? false;
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
                    if (isSyncTier)
                      Text(
                        e.balance > 0
                            ? context.l10n.entitlementActive
                            : context.l10n.entitlementInactive,
                        style: context.text.bodyMedium?.copyWith(
                          color: e.balance > 0
                              ? palette.successColor
                              : palette.textSecondary,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    else
                      Text(
                        e.balance.truncateToDouble() == e.balance
                            ? e.balance.toInt().toString()
                            : e.balance.toStringAsFixed(1),
                        style: context.text.bodyMedium?.copyWith(
                          color: palette.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                  ],
                ),
              );
            }),
          ],
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
      parts.add('$count entries');
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
