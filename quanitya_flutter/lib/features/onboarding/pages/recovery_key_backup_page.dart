import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cubit_ui_flow/cubit_ui_flow.dart';
import 'package:get_it/get_it.dart';

import '../../../app_router.dart';
import '../../../app/bootstrap.dart';
import '../../../design_system/primitives/app_spacings.dart';
import '../../../design_system/primitives/app_sizes.dart';
import '../../../design_system/primitives/quanitya_palette.dart';
import '../../../design_system/structures/column.dart';
import '../../../design_system/structures/row.dart';
import '../../../design_system/widgets/quanitya/general/quanitya_text_button.dart';
import '../../../infrastructure/feedback/base_state_message_mapper.dart';
import '../../../infrastructure/platform/platform_capability_service.dart';
import '../../../support/extensions/context_extensions.dart';
import '../cubits/onboarding_cubit.dart';
import '../cubits/onboarding_state.dart';
import '../services/onboarding_message_mapper.dart';

/// Page for backing up the recovery key after account creation.
/// Shows a checklist of backup methods - user must complete at least one.
class RecoveryKeyBackupPage extends StatefulWidget {
  const RecoveryKeyBackupPage({super.key});

  @override
  State<RecoveryKeyBackupPage> createState() => _RecoveryKeyBackupPageState();
}

class _RecoveryKeyBackupPageState extends State<RecoveryKeyBackupPage> {
  @override
  void initState() {
    super.initState();
    context.read<OnboardingCubit>().initBackupPage();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: UiFlowStateListener<OnboardingCubit, OnboardingState>(
          mapper: BaseStateMessageMapper<OnboardingState>(
            exceptionMapper: getIt<IExceptionKeyMapper>(),
            domainMapper: getIt<OnboardingMessageMapper>(),
          ),
          uiService: getIt<IUiFlowService>(),
          child: BlocBuilder<OnboardingCubit, OnboardingState>(
            builder: (context, state) {
              return SingleChildScrollView(
                padding: AppPadding.page,
                child: QuanityaColumn(
                  spacing: VSpace.x4,
                  crossAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header section
                    _HeaderSection(),
                    // Backup methods list
                    _BackupMethodsList(state: state),
                    // Continue section
                    _ContinueSection(state: state),
                  ],
                ),
              );
            },
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
      spacing: VSpace.x1,
      crossAlignment: CrossAxisAlignment.start,
      children: [
        // Title
        Text(
          context.l10n.recoveryKeyTitle,
          style: context.text.headlineSmall,
        ),
        VSpace.x05,
        // Key icon - large, centered
        Center(
          child: Icon(
            Icons.key_rounded,
            size: AppSizes.iconXLarge * 2,
            color: context.colors.textPrimary,
          ),
        ),
        VSpace.x1,
        // Description
        Text(
          context.l10n.recoveryKeyDescription,
          style: context.text.bodyMedium?.copyWith(
            color: context.colors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _BackupMethodsList extends StatelessWidget {
  final OnboardingState state;

  const _BackupMethodsList({required this.state});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<OnboardingCubit>();

    return QuanityaColumn(
      spacing: VSpace.x3,
      crossAlignment: CrossAxisAlignment.start,
      children: [
        // Section label
        Text(
          context.l10n.backupMethodsTitle,
          style: context.text.labelLarge?.copyWith(
            color: context.colors.textSecondary,
          ),
        ),
        // iCloud Keychain (iOS only)
        if (GetIt.instance<PlatformCapabilityService>().supportsICloudKeychain)
          _BackupMethodTile(
            icon: Icons.cloud_outlined,
            title: context.l10n.exportToICloud,
            subtitle: context.l10n.backupICloudSubtitle,
            isCompleted: state.completedBackupMethods.contains(BackupMethod.iCloud),
            onTap: state.isLoading ? null : cubit.exportToICloud,
          ),
        // Export to file
        _BackupMethodTile(
          icon: Icons.file_download_outlined,
          title: context.l10n.exportToFile,
          subtitle: context.l10n.backupFileSubtitle,
          isCompleted: state.completedBackupMethods.contains(BackupMethod.file),
          onTap: state.isLoading ? null : cubit.exportToFile,
        ),
        // Copy to clipboard
        _BackupMethodTile(
          icon: Icons.copy_outlined,
          title: context.l10n.copyToClipboard,
          subtitle: context.l10n.backupClipboardSubtitle,
          isCompleted: state.completedBackupMethods.contains(BackupMethod.clipboard),
          onTap: state.isLoading ? null : cubit.copyToClipboard,
        ),
        // Device authentication (if available)
        if (state.deviceAuthAvailable)
          _BackupMethodTile(
            icon: Icons.phonelink_lock_outlined,
            title: context.l10n.backupDeviceAuthTitle,
            subtitle: context.l10n.backupDeviceAuthSubtitle,
            isCompleted: state.completedBackupMethods.contains(BackupMethod.biometrics),
            onTap: state.isLoading ? null : cubit.storeWithBiometrics,
            warning: context.l10n.backupDeviceAuthWarning,
          ),
      ],
    );
  }
}

/// A single backup method row - no card, just icon + text + status
class _BackupMethodTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isCompleted;
  final VoidCallback? onTap;
  final String? warning;

  const _BackupMethodTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isCompleted,
    this.onTap,
    this.warning,
  });

  @override
  Widget build(BuildContext context) {
    final interactable = context.colors.interactableColor;
    final textSecondary = context.colors.textSecondary;

    return Semantics(
      button: true,
      label: title,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: QuanityaRow(
          alignment: CrossAxisAlignment.start,
          spacing: HSpace.x2,
          start: Icon(
            isCompleted ? Icons.check : icon,
            size: AppSizes.iconMedium,
            color: isCompleted ? interactable : textSecondary,
          ),
          middle: QuanityaColumn(
            spacing: VSpace.x025,
            crossAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: context.text.bodyLarge?.copyWith(
                  color: isCompleted ? interactable : context.colors.textPrimary,
                ),
              ),
              Text(
                subtitle,
                style: context.text.bodySmall?.copyWith(
                  color: textSecondary,
                ),
              ),
              if (warning != null) ...[
                VSpace.x025,
                Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      size: AppSizes.iconSmall,
                      color: context.colors.warningColor,
                    ),
                    HSpace.x05,
                    Expanded(
                      child: Text(
                        warning!,
                        style: context.text.bodySmall?.copyWith(
                          color: context.colors.warningColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
          end: isCompleted
              ? null
              : Icon(
                  Icons.chevron_right,
                  size: AppSizes.iconMedium,
                  color: context.colors.interactableColor,
                ),
        ),
      ),
    );
  }
}

class _ContinueSection extends StatelessWidget {
  final OnboardingState state;

  const _ContinueSection({required this.state});

  @override
  Widget build(BuildContext context) {
    final hasBackup = state.hasCompletedBackup;

    return QuanityaColumn(
      spacing: VSpace.x2,
      crossAlignment: CrossAxisAlignment.stretch,
      children: [
        // Status message
        if (hasBackup)
          Row(
            children: [
              Icon(
                Icons.check_circle,
                color: context.colors.interactableColor,
                size: AppSizes.iconMedium,
              ),
              HSpace.x1,
              Text(
                context.l10n.backupCompleteMessage(state.completedBackupMethods.length),
                style: context.text.bodyMedium?.copyWith(
                  color: context.colors.interactableColor,
                ),
              ),
            ],
          )
        else
          Text(
            context.l10n.backupRequiredMessage,
            style: context.text.bodyMedium?.copyWith(
              color: context.colors.textSecondary,
            ),
          ),
        VSpace.x1,
        // Continue button
        QuanityaTextButton(
          text: context.l10n.continueAction,
          onPressed: state.canContinue
              ? () => AppNavigation.toHome(context)
              : null,
        ),
      ],
    );
  }
}
