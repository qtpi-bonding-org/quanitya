import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app_router.dart';
import '../../../design_system/primitives/app_sizes.dart';
import '../../../design_system/primitives/app_spacings.dart';
import '../../../design_system/primitives/quanitya_palette.dart';
import '../../../design_system/structures/column.dart';
import '../../../design_system/widgets/quanitya_icon_button.dart';
import '../../../support/extensions/context_extensions.dart';

class AppInfoPage extends StatelessWidget {
  const AppInfoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(context.l10n.information, style: context.text.headlineMedium),
        leading: QuanityaIconButton(
          icon: Icons.arrow_back,
          onPressed: () => AppNavigation.back(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: AppPadding.page,
        child: QuanityaColumn(
          crossAlignment: CrossAxisAlignment.start,
          spacing: VSpace.x3,
          children: [
            _InfoLinkItem(
              icon: Icons.privacy_tip_outlined,
              title: context.l10n.privacyPolicy,
              onTap: () => _launchUrl('https://quanitya.com/#privacy'),
            ),
            _InfoLinkItem(
              icon: Icons.description_outlined,
              title: context.l10n.termsOfService,
              onTap: () => _launchUrl('https://quanitya.com/#terms'),
            ),
            _InfoLinkItem(
              icon: Icons.code,
              title: context.l10n.sourceCode,
              subtitle: context.l10n.sourceCodeSubtitle,
              onTap: () => _launchUrl('https://codeberg.org/qtpi-bonding-org/quanitya'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

class _InfoLinkItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  const _InfoLinkItem({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
        child: Padding(
          padding: AppPadding.verticalSingle,
          child: Row(
            children: [
              Icon(
                icon,
                size: AppSizes.iconMedium,
                color: context.colors.textPrimary,
              ),
              HSpace.x2,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: context.text.bodyLarge),
                    if (subtitle != null)
                      Text(
                        subtitle!,
                        style: context.text.bodySmall?.copyWith(
                          color: context.colors.textSecondary,
                        ),
                      ),
                  ],
                ),
              ),
              Icon(
                Icons.open_in_new,
                size: AppSizes.iconSmall,
                color: context.colors.interactableColor,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
