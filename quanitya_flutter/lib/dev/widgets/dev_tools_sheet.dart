import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:cubit_ui_flow/cubit_ui_flow.dart' as cubit_ui_flow;

import '../../app_router.dart';
import '../../design_system/primitives/app_sizes.dart';
import '../../design_system/primitives/app_spacings.dart';
import '../../design_system/primitives/quanitya_palette.dart';
import '../../design_system/widgets/quanitya/general/quanitya_text_button.dart';
import '../../design_system/widgets/quanitya_confirmation_dialog.dart';
import '../../infrastructure/crypto/crypto_key_repository.dart';
import '../../support/extensions/context_extensions.dart';
import '../../features/app_operating_mode/cubits/app_operating_cubit.dart';
import '../../infrastructure/auth/auth_service.dart';
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

              // Seed fake data (includes analysis scripts)
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

              // Wipe crypto keys
              _DevToolRow(
                label: l10n.devWipeCryptoKeys,
                child: _DevWipeKeysButton(),
              ),
              VSpace.x2,

              // Connect to cloud
              _DevToolRow(
                label: l10n.devConnectToCloud,
                child: _DevActionButton(
                  text: l10n.devConnect,
                  onPressed: () async {
                    final appOperatingCubit = GetIt.instance<AppOperatingCubit>();
                    await appOperatingCubit.switchToCloud();
                  },
                ),
              ),
              VSpace.x2,

              // Create account
              _DevToolRow(
                label: l10n.devCreateAccount,
                child: _DevActionButton(
                  text: l10n.devCreate,
                  onPressed: () async {
                    final authService = GetIt.instance<AuthService>();
                    await authService.createAccount(deviceLabel: 'Dev Test Device');
                  },
                  successMessage: l10n.devAccountCreated,
                ),
              ),
              VSpace.x2,

              // Register account
              _DevToolRow(
                label: l10n.devRegisterAccount,
                child: _DevActionButton(
                  text: l10n.devRegister,
                  onPressed: () async {
                    final authService = GetIt.instance<AuthService>();
                    await authService.registerAccountWithServer(deviceLabel: 'Dev Test Device');
                  },
                  successMessage: l10n.devAccountRegistered,
                ),
              ),
              VSpace.x2,

              // Test local notification
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

              // Navigation shortcuts
              const Divider(),
              VSpace.x2,
              Text(
                'NAVIGATION',
                style: context.text.titleMedium?.copyWith(
                  color: context.colors.textPrimary,
                ),
              ),
              VSpace.x2,
              Wrap(
                spacing: AppSizes.space,
                runSpacing: AppSizes.space,
                children: [
                  _NavChip(label: 'Onboarding', route: AppRoutes.onboarding),
                  _NavChip(label: 'About', route: AppRoutes.about),
                  _NavChip(label: 'Settings', route: AppRoutes.settings),
                  _NavChip(label: 'Template Editor', route: AppRoutes.templateEditor),
                  _NavChip(label: 'Script Builder', route: AppRoutes.scriptBuilder),
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
    switch (route) {
      case AppRoutes.onboarding:
        context.go(route); // Use go for onboarding to reset stack
      case AppRoutes.about:
        AppNavigation.toAbout(context);
      case AppRoutes.settings:
        AppNavigation.toSettings(context);
      case AppRoutes.templateEditor:
        AppNavigation.toTemplateDesigner(context);
      case AppRoutes.scriptBuilder:
        AppNavigation.toAnalysisBuilder(context);
      default:
        context.go(route);
    }
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

/// Wipe keys needs special handling (confirmation dialog + navigation).
class _DevWipeKeysButton extends StatefulWidget {
  @override
  State<_DevWipeKeysButton> createState() => _DevWipeKeysButtonState();
}

class _DevWipeKeysButtonState extends State<_DevWipeKeysButton> {
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

    final l10n = context.l10n;
    return QuanityaTextButton(
      text: l10n.devWipe,
      isDestructive: true,
      onPressed: () async {
        final navigator = Navigator.of(context);
        final goRouter = GoRouter.of(context);

        final confirmed = await showDialog<bool>(
          context: context,
          builder: (c) => QuanityaConfirmationDialog(
            title: l10n.devWipeKeysTitle,
            message: l10n.devWipeKeysMessage,
            onConfirm: () {},
            isDestructive: true,
            confirmText: l10n.devWipeKeysConfirm,
          ),
        );

        if (confirmed != true || !mounted) return;

        setState(() => _isLoading = true);
        try {
          final keyRepo = GetIt.instance<ICryptoKeyRepository>();
          await keyRepo.clearKeys();
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
