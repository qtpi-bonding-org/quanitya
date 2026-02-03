import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:anonaccred_client/anonaccred_client.dart' show AccountDevice;
import 'package:cubit_ui_flow/cubit_ui_flow.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/intl.dart';

import '../../../app_router.dart';
import '../../../design_system/primitives/app_spacings.dart';
import '../../../design_system/primitives/app_sizes.dart';
import '../../../design_system/primitives/quanitya_palette.dart';
import '../../../design_system/widgets/quanitya/general/quanitya_text_button.dart';
import '../../../design_system/widgets/quanitya_confirmation_dialog.dart';
import '../../../support/extensions/context_extensions.dart';
import '../../../features/app_operating_mode/cubits/app_operating_cubit.dart';
import '../../../features/app_operating_mode/models/app_operating_mode.dart';
import '../cubits/device_management/device_management_cubit.dart';
import '../cubits/device_management/device_management_state.dart';

/// Section displaying registered devices with revoke functionality
class DeviceListSection extends StatefulWidget {
  const DeviceListSection({super.key});

  @override
  State<DeviceListSection> createState() => _DeviceListSectionState();
}

class _DeviceListSectionState extends State<DeviceListSection> {
  @override
  void initState() {
    super.initState();
    // Only load devices if app is in a mode that supports server features
    final appMode = context.read<AppOperatingCubit>().state.mode;
    if (appMode.requiresServer) {
      context.read<DeviceManagementCubit>().loadDevices();
    }
  }

  /// Check if error is a connection/offline error
  bool _isOfflineError(Object? error) {
    if (error == null) return false;
    final errorStr = error.toString();
    return errorStr.contains('Connection refused') ||
        errorStr.contains('SocketException') ||
        errorStr.contains('Network is unreachable');
  }

  @override
  Widget build(BuildContext context) {
    final appMode = context.watch<AppOperatingCubit>().state.mode;
    
    // If in local mode, show message that device management requires server
    if (!appMode.requiresServer) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            context.l10n.devicesTitle,
            style: context.text.titleMedium,
          ),
          VSpace.x2,
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.info_outline,
                size: AppSizes.iconSmall,
                color: context.colors.textSecondary,
              ),
              HSpace.x1,
              Flexible(
                child: Text(
                  'Device management requires cloud or self-hosted mode',
                  style: context.text.bodyMedium?.copyWith(
                    color: context.colors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ],
      );
    }
    
    return BlocConsumer<DeviceManagementCubit, DeviceManagementState>(
      listener: (context, state) {
        // Only show error toast for non-offline errors
        // Offline is expected for local-first app, so we silently handle it
        if (state.status == UiFlowStatus.failure && 
            state.error != null &&
            !_isOfflineError(state.error)) {
          GetIt.instance<IFeedbackService>().show(
            FeedbackMessage(
              message: state.error.toString(),
              type: MessageType.error,
            ),
          );
        }
      },
      builder: (context, state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Section header with Add Device button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  context.l10n.devicesTitle,
                  style: context.text.titleMedium,
                ),
                QuanityaTextButton(
                  text: context.l10n.addDevice,
                  onPressed: () => AppNavigation.toScanPairingQr(context),
                ),
              ],
            ),
            VSpace.x2,

            // Device list
            if (state.devices.isEmpty && state.status != UiFlowStatus.loading)
              _isOfflineError(state.error)
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.cloud_off_outlined,
                          size: AppSizes.iconSmall,
                          color: context.colors.textSecondary,
                        ),
                        HSpace.x1,
                        Flexible(
                          child: Text(
                            context.l10n.errorOffline,
                            style: context.text.bodyMedium?.copyWith(
                              color: context.colors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    )
                  : Text(
                      context.l10n.noDevices,
                      style: context.text.bodyMedium?.copyWith(
                        color: context.colors.textSecondary,
                      ),
                    )
            else
              ...state.activeDevices.expand((device) => [
                _DeviceCard(
                  device: device,
                  isCurrentDevice: state.isCurrentDevice(device),
                  isRevoking: state.revokingDeviceId == device.id,
                ),
                VSpace.x2,
              ]),

            // Show revoked devices if any
            if (state.revokedDevices.isNotEmpty) ...[
              VSpace.x3,
              Text(
                context.l10n.revokedDevices,
                style: context.text.titleSmall?.copyWith(
                  color: context.colors.textSecondary,
                ),
              ),
              VSpace.x1,
              ...state.revokedDevices.expand((device) => [
                _DeviceCard(
                  device: device,
                  isCurrentDevice: false,
                  isRevoking: false,
                  isRevoked: true,
                ),
                VSpace.x2,
              ]),
            ],
          ],
        );
      },
    );
  }
}

class _DeviceCard extends StatelessWidget {
  final AccountDevice device;
  final bool isCurrentDevice;
  final bool isRevoking;
  final bool isRevoked;

  const _DeviceCard({
    required this.device,
    required this.isCurrentDevice,
    required this.isRevoking,
    this.isRevoked = false,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat.yMMMd().add_jm();
    final lastActive = dateFormat.format(device.lastActive);
    
    // All devices use secondary color (blue-gray), dimmed if revoked
    final iconColor = isRevoked
        ? context.colors.secondaryColor.withValues(alpha: 0.5)
        : context.colors.secondaryColor;

    return Row(
      children: [
        // Device icon
        Icon(
          _getDeviceIcon(device.label),
          size: AppSizes.iconLarge,
          color: iconColor,
        ),
        HSpace.x3,

        // Device info
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      device.label,
                      style: context.text.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        decoration: isRevoked ? TextDecoration.lineThrough : null,
                        color: isRevoked 
                            ? context.colors.textSecondary.withValues(alpha: 0.5)
                            : null,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (isCurrentDevice) ...[
                    HSpace.x1,
                    Text(
                      '(${context.l10n.thisDevice})',
                      style: context.text.bodyMedium?.copyWith(
                        color: context.colors.textSecondary,
                      ),
                    ),
                  ],
                  if (isRevoked) ...[
                    HSpace.x1,
                    Text(
                      '(${context.l10n.revoked})',
                      style: context.text.bodyMedium?.copyWith(
                        color: context.colors.destructiveColor,
                      ),
                    ),
                  ],
                ],
              ),
              VSpace.x05,
              Text(
                '${context.l10n.lastActive}: $lastActive',
                style: context.text.bodySmall?.copyWith(
                  color: isRevoked
                      ? context.colors.textSecondary.withValues(alpha: 0.5)
                      : context.colors.textSecondary,
                ),
              ),
            ],
          ),
        ),

        // Revoke button (not for current device or already revoked)
        if (!isCurrentDevice && !isRevoked)
          isRevoking
              ? SizedBox(
                  width: AppSizes.iconMedium,
                  height: AppSizes.iconMedium,
                  child: CircularProgressIndicator(
                    strokeWidth: AppSizes.borderWidthThick,
                  ),
                )
              : QuanityaTextButton(
                  text: context.l10n.revoke,
                  isDestructive: true,
                  onPressed: () => _confirmRevoke(context),
                ),
      ],
    );
  }

  IconData _getDeviceIcon(String label) {
    final lowerLabel = label.toLowerCase();
    if (lowerLabel.contains('iphone') || lowerLabel.contains('android') || lowerLabel.contains('phone')) {
      return Icons.phone_iphone;
    }
    if (lowerLabel.contains('ipad') || lowerLabel.contains('tablet')) {
      return Icons.tablet_mac;
    }
    if (lowerLabel.contains('mac') || lowerLabel.contains('laptop') || lowerLabel.contains('book')) {
      return Icons.laptop_mac;
    }
    if (lowerLabel.contains('desktop') || lowerLabel.contains('pc') || lowerLabel.contains('windows')) {
      return Icons.desktop_windows;
    }
    if (lowerLabel.contains('web') || lowerLabel.contains('browser')) {
      return Icons.web;
    }
    return Icons.devices;
  }

  void _confirmRevoke(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => QuanityaConfirmationDialog(
        title: context.l10n.revokeDevice,
        message: context.l10n.revokeDeviceConfirmation(device.label),
        confirmText: context.l10n.revoke,
        isDestructive: true,
        onConfirm: () {
          context.read<DeviceManagementCubit>().revokeDevice(device.id!);
        },
      ),
    );
  }
}
