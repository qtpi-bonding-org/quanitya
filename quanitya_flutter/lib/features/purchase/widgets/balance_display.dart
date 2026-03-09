import 'package:flutter/material.dart';
import 'package:anonaccred_client/anonaccred_client.dart'
    show AccountEntitlement;

import '../../../design_system/primitives/app_spacings.dart';
import '../../../design_system/primitives/quanitya_palette.dart';
import '../../../support/extensions/context_extensions.dart';

/// Displays the user's entitlement balances (sync days, credits, etc.)
class BalanceDisplay extends StatelessWidget {
  const BalanceDisplay({
    super.key,
    required this.entitlements,
    required this.hasSyncAccess,
  });

  final List<AccountEntitlement> entitlements;
  final bool hasSyncAccess;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: AppPadding.listItem,
      child: Padding(
        padding: AppPadding.allDouble,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  hasSyncAccess ? Icons.cloud_done : Icons.cloud_off,
                  color: hasSyncAccess
                      ? context.colors.successColor
                      : context.colors.errorColor,
                ),
                HSpace.x1,
                Text(
                  hasSyncAccess
                      ? context.l10n.syncActive
                      : context.l10n.syncInactive,
                  style: context.text.titleMedium,
                ),
              ],
            ),
            if (entitlements.isNotEmpty) ...[
              VSpace.x2,
              const Divider(),
              VSpace.x1,
              ...entitlements.map((e) => Padding(
                    padding: AppPadding.verticalSingle,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          context.l10n.entitlementLabel(e.entitlementId),
                          style: context.text.bodyMedium,
                        ),
                        Text(
                          e.balance.toStringAsFixed(1),
                          style: context.text.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  )),
            ],
          ],
        ),
      ),
    );
  }
}
