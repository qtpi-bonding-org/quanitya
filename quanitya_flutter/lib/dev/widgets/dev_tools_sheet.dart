import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:cubit_ui_flow/cubit_ui_flow.dart' as cubit_ui_flow;

import '../../app_router.dart';
import '../../data/db/app_database.dart';
import '../../design_system/primitives/app_sizes.dart';
import '../../design_system/primitives/app_spacings.dart';
import '../../design_system/primitives/quanitya_palette.dart';
import '../../design_system/widgets/quanitya/general/quanitya_text_button.dart';
import '../../design_system/widgets/quanitya_confirmation_dialog.dart';
import '../../support/extensions/context_extensions.dart';
import '../../infrastructure/auth/delete_orchestrator.dart';
import '../../infrastructure/notifications/notification_service.dart';
import '../services/dev_seeder_service.dart';

/// Shows a bottom sheet with dev tools
void showDevToolsSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    isDismissible: true,
    enableDrag: true,
    backgroundColor: context.colors.backgroundPrimary,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(AppSizes.radiusLarge),
      ),
    ),
    builder: (ctx) => ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(ctx).size.height * 0.85,
      ),
      child: const DevToolsSheet(),
    ),
  );
}

/// Dev tools bottom sheet content
class DevToolsSheet extends StatelessWidget {
  const DevToolsSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return SafeArea(
      child: Padding(
        padding: AppPadding.page,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: AppSizes.space * 5,
                  height: AppSizes.space * 0.5,
                  decoration: BoxDecoration(
                    color: context.colors.textSecondary.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
                  ),
                ),
              ),
              VSpace.x3,

              // Title
              Text(
                l10n.devToolsTitle,
                style: context.text.titleLarge?.copyWith(
                  color: context.colors.textPrimary,
                ),
              ),
              VSpace.x3,

              // Seed fake data
              _DevToolRow(
                label: l10n.devSeedFakeData,
                child: _DevActionButton(
                  text: l10n.devSeed,
                  onPressed: () async {
                    final seeder = GetIt.instance<DevSeederService>();
                    await seeder.clearAndSeed();
                  },
                  successMessage: l10n.devSeeded,
                ),
              ),
              VSpace.x2,

              // Clear all data
              _DevToolRow(
                label: l10n.devClearAllData,
                child: _DevActionButton(
                  text: l10n.devClear,
                  isDestructive: true,
                  onPressed: () async {
                    final seeder = GetIt.instance<DevSeederService>();
                    await seeder.clearAll();
                  },
                  successMessage: l10n.devCleared,
                ),
              ),
              VSpace.x2,

              // Factory reset
              _DevToolRow(
                label: 'Factory Reset',
                child: _DevFactoryResetButton(),
              ),
              VSpace.x2,

              // Test notification
              _DevToolRow(
                label: 'Test Notification',
                child: _DevActionButton(
                  text: 'Send',
                  onPressed: () async {
                    final notificationService = GetIt.instance<NotificationService>();
                    await notificationService.showNow(
                      id: 9999,
                      title: 'Quanitya Test',
                      body: 'This is a test notification from dev tools',
                    );
                  },
                  successMessage: 'Notification sent',
                ),
              ),
              VSpace.x2,

              // Pending notifications
              _DevToolRow(
                label: 'Pending Notifications',
                child: _PendingNotificationsButton(),
              ),
              VSpace.x2,

              // Encrypted entry sizes
              _DevToolRow(
                label: 'Encrypted Entry Sizes',
                child: _MeasureEntrySizesButton(),
              ),
              VSpace.x2,

              // Navigation
              const Divider(),
              VSpace.x2,
              Wrap(
                spacing: AppSizes.space,
                runSpacing: AppSizes.space,
                children: [
                  _NavChip(label: 'Onboarding', route: AppRoutes.onboarding),
                  _NavChip(label: 'OCR Test', route: AppRoutes.ocrTest),
                ],
              ),
              VSpace.x4,
            ],
          ),
        ),
      ),
    );
  }
}

class _DevToolRow extends StatelessWidget {
  final String label;
  final Widget child;

  const _DevToolRow({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style: context.text.bodyLarge?.copyWith(
              color: context.colors.textPrimary,
            ),
          ),
        ),
        child,
      ],
    );
  }
}

class _NavChip extends StatelessWidget {
  final String label;
  final String route;

  const _NavChip({required this.label, required this.route});

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(label),
      onPressed: () {
        Navigator.pop(context);
        _navigateToRoute(context, route);
      },
    );
  }

  void _navigateToRoute(BuildContext context, String route) {
    context.go(route);
  }
}

/// Reusable dev action button with loading state and feedback.
class _DevActionButton extends StatefulWidget {
  final String text;
  final Future<void> Function() onPressed;
  final String? successMessage;
  final bool isDestructive;

  const _DevActionButton({
    required this.text,
    required this.onPressed,
    this.successMessage,
    this.isDestructive = false,
  });

  @override
  State<_DevActionButton> createState() => _DevActionButtonState();
}

class _DevActionButtonState extends State<_DevActionButton> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return SizedBox(
        width: AppSizes.iconMedium,
        height: AppSizes.iconMedium,
        child: CircularProgressIndicator(strokeWidth: AppSizes.borderWidthThick),
      );
    }

    return QuanityaTextButton(
      text: widget.text,
      isDestructive: widget.isDestructive,
      onPressed: () async {
        setState(() => _isLoading = true);
        try {
          await widget.onPressed();
          if (mounted && widget.successMessage != null) {
            GetIt.instance<cubit_ui_flow.IFeedbackService>().show(
              cubit_ui_flow.FeedbackMessage(
                message: widget.successMessage!,
                type: cubit_ui_flow.MessageType.success,
              ),
            );
          }
        } catch (e) {
          if (mounted) {
            GetIt.instance<cubit_ui_flow.IFeedbackService>().show(
              cubit_ui_flow.FeedbackMessage(
                message: 'Failed: $e',
                type: cubit_ui_flow.MessageType.error,
              ),
            );
          }
        } finally {
          if (mounted) setState(() => _isLoading = false);
        }
      },
    );
  }
}

/// Factory reset — clears all data, keys, and navigates to onboarding.
/// Simulates a completely fresh app install.
class _DevFactoryResetButton extends StatefulWidget {
  @override
  State<_DevFactoryResetButton> createState() => _DevFactoryResetButtonState();
}

class _DevFactoryResetButtonState extends State<_DevFactoryResetButton> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return SizedBox(
        width: AppSizes.iconMedium,
        height: AppSizes.iconMedium,
        child: CircularProgressIndicator(strokeWidth: AppSizes.borderWidthThick),
      );
    }

    return QuanityaTextButton(
      text: 'Reset',
      isDestructive: true,
      onPressed: () async {
        final navigator = Navigator.of(context);
        final goRouter = GoRouter.of(context);

        final confirmed = await showDialog<bool>(
          context: context,
          builder: (c) => QuanityaConfirmationDialog(
            title: 'Factory Reset',
            message:
                'This will clear ALL data, crypto keys (including iCloud), '
                'and return to onboarding. This simulates a fresh install.',
            onConfirm: () {},
            isDestructive: true,
            confirmText: 'Reset Everything',
          ),
        );

        if (confirmed != true || !mounted) return;

        setState(() => _isLoading = true);
        try {
          // 1. Clear all Drift database tables
          final seeder = GetIt.instance<DevSeederService>();
          await seeder.clearAll();

          // 2. Factory reset (PowerSync, E2EE puller, tours, entitlements, keys, registration flag)
          await GetIt.instance<DeleteOrchestrator>().factoryReset();

          // 3. Reset router key check and navigate to onboarding
          AppRouter.resetKeyCheck();
          if (mounted) {
            navigator.pop();
            goRouter.goNamed(RouteNames.onboarding);
          }
        } finally {
          if (mounted) setState(() => _isLoading = false);
        }
      },
    );
  }
}

/// Measures encrypted entry blob sizes and shows results in a dialog.
class _MeasureEntrySizesButton extends StatefulWidget {
  @override
  State<_MeasureEntrySizesButton> createState() =>
      _MeasureEntrySizesButtonState();
}

class _MeasureEntrySizesButtonState extends State<_MeasureEntrySizesButton> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return SizedBox(
        width: AppSizes.iconMedium,
        height: AppSizes.iconMedium,
        child: CircularProgressIndicator(strokeWidth: AppSizes.borderWidthThick),
      );
    }

    return QuanityaTextButton(
      text: 'Measure',
      onPressed: () async {
        setState(() => _isLoading = true);
        try {
          final db = GetIt.instance<AppDatabase>();
          final result = await db.customSelect(
            'SELECT '
            'COUNT(*) AS cnt, '
            'SUM(LENGTH(encrypted_data)) AS total_bytes, '
            'AVG(LENGTH(encrypted_data)) AS avg_bytes, '
            'MIN(LENGTH(encrypted_data)) AS min_bytes, '
            'MAX(LENGTH(encrypted_data)) AS max_bytes '
            'FROM encrypted_entries',
          ).getSingle();

          final count = result.read<int>('cnt');
          if (count == 0) {
            if (mounted) {
              _showDevDialog(context, title: 'Encrypted Entry Sizes', body: 'No encrypted entries found.');
            }
            return;
          }

          final totalBytes = result.read<int>('total_bytes');
          final avgBytes = result.read<double>('avg_bytes');
          final minBytes = result.read<int>('min_bytes');
          final maxBytes = result.read<int>('max_bytes');

          final report = [
            'Count:  $count',
            'Total:  ${(totalBytes / 1024).toStringAsFixed(1)} KB',
            '',
            'Avg:    ${avgBytes.toStringAsFixed(0)} bytes',
            'Min:    $minBytes bytes',
            'Max:    $maxBytes bytes',
            '',
            '500 MB ≈ ${_formatCount((500 * 1024 * 1024 / avgBytes).round())} entries',
            '1 GB ≈ ${_formatCount((1024 * 1024 * 1024 / avgBytes).round())} entries',
          ].join('\n');

          if (mounted) {
            _showDevDialog(context, title: 'Encrypted Entry Sizes', body: report);
          }
        } catch (e) {
          if (mounted) {
            _showDevDialog(context, title: 'Encrypted Entry Sizes', body: 'Error: $e');
          }
        } finally {
          if (mounted) setState(() => _isLoading = false);
        }
      },
    );
  }

  String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    }
    if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(0)}K';
    }
    return '$count';
  }

}

/// Shows pending OS-level notifications scheduled via flutter_local_notifications.
class _PendingNotificationsButton extends StatefulWidget {
  @override
  State<_PendingNotificationsButton> createState() =>
      _PendingNotificationsButtonState();
}

class _PendingNotificationsButtonState
    extends State<_PendingNotificationsButton> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return SizedBox(
        width: AppSizes.iconMedium,
        height: AppSizes.iconMedium,
        child:
            CircularProgressIndicator(strokeWidth: AppSizes.borderWidthThick),
      );
    }

    return QuanityaTextButton(
      text: 'Show',
      onPressed: () async {
        setState(() => _isLoading = true);
        try {
          final notificationService = GetIt.instance<NotificationService>();
          final pending = await notificationService.getPending();

          if (pending.isEmpty) {
            if (mounted) {
              _showDevDialog(context,
                  title: 'Pending Notifications',
                  body: 'No pending notifications.\n\n'
                      'Create a schedule with a reminder,\n'
                      'then tap "Generate" above.');
            }
            return;
          }

          final lines = pending.map((n) {
            return 'ID: ${n.id}\n'
                '  ${n.title ?? "(no title)"}\n'
                '  ${n.body ?? "(no body)"}\n'
                '  payload: ${n.payload ?? "(none)"}';
          }).join('\n\n');

          final report = '${pending.length} pending notification(s):\n\n$lines';

          if (mounted) {
            _showDevDialog(context,
                title: 'Pending Notifications', body: report);
          }
        } catch (e) {
          if (mounted) {
            _showDevDialog(context,
                title: 'Pending Notifications', body: 'Error: $e');
          }
        } finally {
          if (mounted) setState(() => _isLoading = false);
        }
      },
    );
  }
}

/// Shared dialog for dev tools reports.
void _showDevDialog(BuildContext context,
    {required String title, required String body}) {
  final palette = QuanityaPalette.primary;

  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: palette.backgroundPrimary,
      title: Text(title, style: ctx.text.titleMedium),
      content: SingleChildScrollView(
        child: Text(
          body,
          style: ctx.text.bodyMedium?.copyWith(
            fontFamily: 'monospace',
            height: 1.6,
          ),
        ),
      ),
      actions: [
        QuanityaTextButton(
          text: 'OK',
          onPressed: () => Navigator.pop(ctx),
        ),
      ],
    ),
  );
}
