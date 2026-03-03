import 'package:flutter/material.dart';
import 'package:anonaccred_client/anonaccred_client.dart'
    show AccountEntitlement;

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
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  hasSyncAccess ? Icons.cloud_done : Icons.cloud_off,
                  color: hasSyncAccess
                      ? theme.colorScheme.primary
                      : theme.colorScheme.error,
                ),
                const SizedBox(width: 8),
                Text(
                  hasSyncAccess ? 'Cloud Sync Active' : 'No Sync Access',
                  style: theme.textTheme.titleMedium,
                ),
              ],
            ),
            if (entitlements.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 8),
              ...entitlements.map((e) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Entitlement #${e.entitlementId}',
                          style: theme.textTheme.bodyMedium,
                        ),
                        Text(
                          e.balance.toStringAsFixed(1),
                          style: theme.textTheme.bodyMedium?.copyWith(
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
