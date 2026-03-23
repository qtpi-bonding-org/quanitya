import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../design_system/primitives/app_sizes.dart';
import '../../../design_system/primitives/app_spacings.dart';
import '../../../design_system/primitives/quanitya_palette.dart';
import '../../../design_system/widgets/quanitya/general/quanitya_text_button.dart';
import '../../../support/extensions/context_extensions.dart';
import '../../app_syncing_mode/cubits/app_syncing_cubit.dart';
import '../../app_syncing_mode/cubits/app_syncing_state.dart';
import '../../app_syncing_mode/models/app_syncing_mode.dart';
import '../cubits/sync_status_cubit.dart';
import '../cubits/sync_status_state.dart';

/// Unified sync status indicator combining connection mode and PowerSync state.
///
/// Shows icon + label + optional retry button:
/// - **Local**: grey cloud_off — "Local only"
/// - **Connecting**: amber cloud_queue — "Connecting..."
/// - **Connected**: sage green cloud_done — "Synced"
/// - **Syncing**: sage green sync — "Uploading..." / "Downloading..."
/// - **Disconnected**: amber cloud_off — "Offline" + retry
/// - **Error**: red cloud_off — "Sync error" + retry
class SyncStatusIndicator extends StatelessWidget {
  const SyncStatusIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppSyncingCubit, AppSyncingState>(
      buildWhen: (prev, curr) => prev.mode != curr.mode,
      builder: (context, modeState) {
        // Local mode — show grey "Local only" without reading SyncStatusCubit
        if (modeState.mode == AppSyncingMode.local) {
          return _buildRow(
            context,
            icon: Icons.cloud_off,
            color: QuanityaPalette.primary.textSecondary,
            label: context.l10n.syncLocalOnly,
            showRetry: false,
          );
        }

        // Cloud/self-hosted — delegate to PowerSync status
        return BlocBuilder<SyncStatusCubit, SyncStatusState>(
          builder: (context, syncState) {
            final (icon, color, label) = _statusDisplay(context, syncState);
            return _buildRow(
              context,
              icon: icon,
              color: color,
              label: label,
              showRetry: _showRetry(syncState),
              onRetry: syncState.isRetrying
                  ? null
                  : () => context.read<SyncStatusCubit>().retrySync(),
            );
          },
        );
      },
    );
  }

  Widget _buildRow(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String label,
    required bool showRetry,
    VoidCallback? onRetry,
  }) {
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
          if (showRetry) ...[
            HSpace.x1,
            QuanityaTextButton(
              text: context.l10n.actionRetry,
              onPressed: onRetry,
            ),
          ],
        ],
      ),
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
          context.l10n.syncLocalOnly,
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
          state.errorMessage ?? context.l10n.syncError,
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
