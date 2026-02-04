import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../data/db/app_database.dart';
import '../../../support/extensions/context_extensions.dart';
import '../../../design_system/primitives/app_sizes.dart';
import '../../../design_system/primitives/app_spacings.dart';
import '../../../design_system/primitives/quanitya_palette.dart';
import '../../../design_system/widgets/quanitya/general/quanitya_text_button.dart';
import '../../../design_system/widgets/quanitya_icon_button.dart';

class NotificationCard extends StatelessWidget {
  final NotificationData notification;
  final VoidCallback onMark;
  final VoidCallback onDismiss;

  const NotificationCard({
    super.key,
    required this.notification,
    required this.onMark,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppPadding.allDouble,
      decoration: BoxDecoration(
        color: QuanityaPalette.primary.backgroundPrimary,
        borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
      ),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _NotificationIcon(type: notification.type),
                HSpace.x2,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(notification.title, style: context.text.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      )),
                      VSpace.x025,
                      Text(
                        _formatTimestamp(notification.createdAt),
                        style: context.text.bodySmall?.copyWith(
                          color: context.colors.textPrimary.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                QuanityaIconButton(
                  icon: Icons.close,
                  onPressed: onDismiss,
                  iconSize: AppSizes.iconSmall,
                ),
              ],
            ),
            VSpace.x2,
            Text(notification.message, style: context.text.bodyMedium),
            if (notification.actionUrl != null) ...[
              VSpace.x3,
              Row(
                children: [
                  Expanded(
                    child: QuanityaTextButton(
                      text: 'Mark as Read',
                      onPressed: onMark,
                    ),
                  ),
                  HSpace.x2,
                  Expanded(
                    child: QuanityaTextButton(
                      text: notification.actionLabel ?? 'Open',
                      onPressed: () {
                        // TODO: Handle deep link navigation
                        onMark();
                      },
                    ),
                  ),
                ],
              ),
            ] else ...[
              VSpace.x3,
              SizedBox(
                width: double.infinity,
                child: QuanityaTextButton(
                  text: 'Mark as Read',
                  onPressed: onMark,
                ),
              ),
            ],
          ],
        ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final diff = now.difference(timestamp);
    
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    
    return DateFormat.yMd().add_jm().format(timestamp);
  }
}

class _NotificationIcon extends StatelessWidget {
  final String type;

  const _NotificationIcon({required this.type});

  @override
  Widget build(BuildContext context) {
    final config = _getIconConfig(type, context);
    
    return Container(
      padding: EdgeInsets.all(AppSizes.space * 0.75),
      decoration: BoxDecoration(
        color: config.color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
      ),
      child: Icon(config.icon, size: AppSizes.iconMedium, color: config.color),
    );
  }

  ({IconData icon, Color color}) _getIconConfig(String type, BuildContext context) {
    final primary = context.colors.textPrimary;
    return switch (type) {
      'inform' => (icon: Icons.info_outline, color: Colors.blue),
      'warning' => (icon: Icons.warning_amber_outlined, color: Colors.orange),
      'failure' => (icon: Icons.error_outline, color: Colors.red),
      'success' => (icon: Icons.check_circle_outline, color: Colors.green),
      'announcement' => (icon: Icons.campaign_outlined, color: Colors.purple),
      _ => (icon: Icons.notifications_outlined, color: primary.withValues(alpha: 0.6)),
    };
  }
}
