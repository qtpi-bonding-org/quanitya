import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

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
    return Padding(
      padding: AppPadding.allDouble,
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
                        _formatTimestamp(context, notification.createdAt),
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
                      text: context.l10n.notificationMarkAsRead,
                      onPressed: onMark,
                    ),
                  ),
                  HSpace.x2,
                  Expanded(
                    child: QuanityaTextButton(
                      text: notification.actionLabel ?? context.l10n.notificationOpen,
                      onPressed: () {
                        final url = notification.actionUrl;
                        if (url != null) {
                          final uri = Uri.tryParse(url);
                          if (uri != null) {
                            launchUrl(uri, mode: LaunchMode.externalApplication);
                          }
                        }
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
                  text: context.l10n.notificationMarkAsRead,
                  onPressed: onMark,
                ),
              ),
            ],
          ],
        ),
    );
  }

  String _formatTimestamp(BuildContext context, DateTime timestamp) {
    final now = DateTime.now();
    final diff = now.difference(timestamp);

    if (diff.inMinutes < 1) return context.l10n.notificationJustNow;
    if (diff.inHours < 1) return context.l10n.notificationMinutesAgo(diff.inMinutes);
    if (diff.inDays < 1) return context.l10n.notificationHoursAgo(diff.inHours);
    if (diff.inDays < 7) return context.l10n.notificationDaysAgo(diff.inDays);

    return DateFormat.yMd().add_jm().format(timestamp);
  }
}

class _NotificationIcon extends StatelessWidget {
  final String type;

  const _NotificationIcon({required this.type});

  @override
  Widget build(BuildContext context) {
    final config = _getIconConfig(type, context);
    
    return Icon(config.icon, size: AppSizes.iconMedium, color: config.color);
  }

  ({IconData icon, Color color}) _getIconConfig(String type, BuildContext context) {
    final colors = context.colors;
    return switch (type) {
      'inform' => (icon: Icons.info_outline, color: colors.infoColor),
      'warning' => (icon: Icons.warning_amber_outlined, color: colors.cautionColor),
      'failure' => (icon: Icons.error_outline, color: colors.destructiveColor),
      'success' => (icon: Icons.check_circle_outline, color: colors.successColor),
      'announcement' => (icon: Icons.campaign_outlined, color: colors.interactableColor),
      _ => (icon: Icons.notifications_outlined, color: colors.textPrimary.withValues(alpha: 0.6)),
    };
  }
}
