import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app_router.dart';
import '../../../design_system/primitives/app_spacings.dart';
import '../../../design_system/primitives/app_sizes.dart';
import '../../../design_system/primitives/quanitya_palette.dart';
import '../../../design_system/structures/column.dart';
import '../../../design_system/widgets/quanitya/general/quanitya_page_wrapper.dart';
import '../../../design_system/widgets/quanitya_icon_button.dart';
import '../../../support/extensions/context_extensions.dart';

/// Page for users who already have an account and want to connect this device.
/// Provides two clear paths: pair with another device or use recovery key.
class ConnectDevicePage extends StatelessWidget {
  const ConnectDevicePage({super.key});

  @override
  Widget build(BuildContext context) {
    return QuanityaPageWrapper(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: QuanityaIconButton(
            icon: Icons.arrow_back,
            onPressed: () => context.pop(),
            tooltip: context.l10n.actionCancel,
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: AppPadding.page,
            child: QuanityaColumn(
              spacing: VSpace.x4,
              crossAlignment: CrossAxisAlignment.start,
              children: [
                _HeaderSection(),
                VSpace.x2,
                _ConnectOptionCard(
                  icon: Icons.qr_code_scanner_rounded,
                  title: context.l10n.connectPairWithDeviceTitle,
                  description: context.l10n.connectPairWithDeviceDescription,
                  onTap: () => AppNavigation.toShowPairingQr(context),
                ),
                _ConnectOptionCard(
                  icon: Icons.key_rounded,
                  title: context.l10n.connectUseRecoveryKeyTitle,
                  description: context.l10n.connectUseRecoveryKeyDescription,
                  onTap: () => AppNavigation.toAccountRecovery(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HeaderSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return QuanityaColumn(
      spacing: VSpace.x2,
      crossAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Icon(
            Icons.account_circle_rounded,
            size: AppSizes.iconXLarge * 2,
            color: context.colors.textPrimary,
          ),
        ),
        VSpace.x2,
        Text(
          context.l10n.connectDeviceTitle,
          style: context.text.headlineMedium,
        ),
        Text(
          context.l10n.connectDeviceDescription,
          style: context.text.bodyMedium?.copyWith(
            color: context.colors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _ConnectOptionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  const _ConnectOptionCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: title,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
          child: Padding(
            padding: AppPadding.verticalSingle,
            child: Row(
              children: [
                Icon(
                  icon,
                  size: AppSizes.iconLarge,
                  color: context.colors.interactableColor,
                ),
                HSpace.x2,
                Expanded(
                  child: QuanityaColumn(
                    spacing: VSpace.x05,
                    crossAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: context.text.titleMedium?.copyWith(
                          color: context.colors.textPrimary,
                        ),
                      ),
                      Text(
                        description,
                        style: context.text.bodySmall?.copyWith(
                          color: context.colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                HSpace.x1,
                Icon(
                  Icons.chevron_right_rounded,
                  size: AppSizes.iconMedium,
                  color: context.colors.textSecondary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
