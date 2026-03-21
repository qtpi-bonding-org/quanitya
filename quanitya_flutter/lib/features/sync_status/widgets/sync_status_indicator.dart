import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../design_system/primitives/app_sizes.dart';
import '../../../design_system/primitives/app_spacings.dart';
import '../../../design_system/primitives/quanitya_palette.dart';
import '../../../design_system/widgets/quanitya/general/quanitya_text_button.dart';
import '../../../support/extensions/context_extensions.dart';
import '../cubits/sync_status_cubit.dart';
import '../cubits/sync_status_state.dart';

/// Displays PowerSync sync status with a retry action.
///
/// Hidden when sync is disabled (local mode).
/// Shows status icon + label, and a retry button when errored or disconnected.
class SyncStatusIndicator extends StatelessWidget {
  const SyncStatusIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SyncStatusCubit, SyncStatusState>(
      builder: (context, state) {
        if (state.connectionState == SyncConnectionState.disabled) {
          return const SizedBox.shrink();
        }

        final (icon, color, label) = _statusDisplay(context, state);

        return Padding(
          padding: AppPadding.pageHorizontal,
          child: Row(
            children: [
              Icon(icon, color: color, size: AppSizes.iconSmall),
              HSpace.x1,
              Expanded(
                child: Text(
                  label,
                  style: context.text.bodySmall?.copyWith(color: color),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (_showRetry(state)) ...[
                HSpace.x1,
                QuanityaTextButton(
                  text: context.l10n.actionRetry,
                  onPressed: state.isRetrying
                      ? null
                      : () => context.read<SyncStatusCubit>().retrySync(),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  (IconData, Color, String) _statusDisplay(
    BuildContext context,
    SyncStatusState state,
  ) {
    final palette = QuanityaPalette.primary;

    return switch (state.connectionState) {
      SyncConnectionState.disabled => (
          Icons.cloud_off,
          palette.textSecondary,
          '',
        ),
      SyncConnectionState.connecting => (
          Icons.cloud_queue,
          palette.cautionColor,
          context.l10n.syncConnecting,
        ),
      SyncConnectionState.connected => (
          Icons.cloud_done,
          palette.stateOnColor,
          context.l10n.syncConnected,
        ),
      SyncConnectionState.syncing => (
          Icons.sync,
          palette.stateOnColor,
          state.isDownloading
              ? context.l10n.syncDownloading
              : context.l10n.syncUploading,
        ),
      SyncConnectionState.error => (
          Icons.cloud_off,
          palette.destructiveColor,
          context.l10n.syncError,
        ),
      SyncConnectionState.disconnected => (
          Icons.cloud_off,
          palette.cautionColor,
          context.l10n.syncDisconnected,
        ),
    };
  }

  bool _showRetry(SyncStatusState state) {
    return state.connectionState == SyncConnectionState.error ||
        state.connectionState == SyncConnectionState.disconnected;
  }
}
