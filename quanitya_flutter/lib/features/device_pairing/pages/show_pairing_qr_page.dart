import 'dart:convert';
import 'package:flutter/services.dart';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:cubit_ui_flow/cubit_ui_flow.dart';

import '../../../app_router.dart';
import '../../../design_system/primitives/app_spacings.dart';
import '../../../design_system/primitives/app_sizes.dart';
import '../../../design_system/primitives/quanitya_palette.dart';
import '../../../design_system/structures/column.dart';
import '../../../design_system/widgets/device_name_display.dart';
import '../../../design_system/widgets/quanitya/general/post_it_toast.dart';
import '../../../design_system/widgets/quanitya/general/quanitya_text_button.dart';
import '../../../design_system/widgets/quanitya_icon_button.dart';
import '../../../design_system/widgets/ui_flow_listener.dart';
import '../../../infrastructure/device/device_info_service.dart';
import '../../../support/extensions/context_extensions.dart';
import '../cubits/pairing_qr_cubit.dart';
import '../cubits/pairing_qr_state.dart';
import '../services/pairing_message_mapper.dart';

/// Page for Device B - shows QR code for pairing with existing device.
///
/// Flow:
/// 1. User enters device name
/// 2. Generate keys and show QR
/// 3. Wait for Device A to scan
/// 4. On success, navigate to home
class ShowPairingQrPage extends StatelessWidget {
  const ShowPairingQrPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => GetIt.instance<PairingQrCubit>(),
      child: const _ShowPairingQrView(),
    );
  }
}

class _ShowPairingQrView extends StatefulWidget {
  const _ShowPairingQrView();

  @override
  State<_ShowPairingQrView> createState() => _ShowPairingQrViewState();
}

class _ShowPairingQrViewState extends State<_ShowPairingQrView> {
  @override
  void initState() {
    super.initState();
    _loadDeviceName();
  }

  Future<void> _loadDeviceName() async {
    final deviceName = await GetIt.instance<DeviceInfoService>()
        .getDeviceName();
    if (mounted) {
      context.read<PairingQrCubit>().setDeviceLabel(deviceName);
    }
  }

  @override
  Widget build(BuildContext context) {
    return UiFlowListener<PairingQrCubit, PairingQrState>(
      mapper: GetIt.instance<PairingQrMessageMapper>(),
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            context.l10n.addToExistingAccount,
            style: context.text.headlineMedium,
          ),
          leading: QuanityaIconButton(
            icon: Icons.arrow_back,
            onPressed: () {
              context.read<PairingQrCubit>().cancelPairing();
              Navigator.of(context).pop();
            },
          ),
        ),
        body: BlocConsumer<PairingQrCubit, PairingQrState>(
          listener: (context, state) {
            if (state.pairingStatus == PairingStatus.success) {
              // Navigate to home on success
              AppRouter.resetKeyCheck();
              AppNavigation.toHome(context);
            }
          },
          builder: (context, state) {
            return LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: Padding(
                      padding: AppPadding.page,
                      child: state.hasQrData
                          ? _buildQrDisplay(context, state)
                          : _buildLabelInput(context, state),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildLabelInput(BuildContext context, PairingQrState state) {
    return QuanityaColumn(
      mainAlignment: MainAxisAlignment.center,
      crossAlignment: CrossAxisAlignment.stretch,
      spacing: VSpace.x3,
      children: [
        DeviceNameDisplay(
          label: context.l10n.pairingDeviceNameLabel,
          deviceName: state.deviceLabel,
        ),
        VSpace.x4,
        QuanityaTextButton(
          text: context.l10n.pairingGenerateQr,
          onPressed:
              state.deviceLabel.isEmpty || state.status == UiFlowStatus.loading
              ? null
              : () => _generateQr(context),
        ),
      ],
    );
  }

  void _generateQr(BuildContext context) {
    context.read<PairingQrCubit>().generatePairingQr();
  }

  Widget _buildQrDisplay(BuildContext context, PairingQrState state) {
    final qrData = state.qrData;
    if (qrData == null) return const SizedBox.shrink();
    final qrJson = jsonEncode(qrData.toJson());

    return QuanityaColumn(
      mainAlignment: MainAxisAlignment.center,
      crossAlignment: CrossAxisAlignment.center,
      spacing: VSpace.x3,
      children: [
        Text(
          context.l10n.pairingScanWithOtherDevice,
          style: context.text.bodyLarge,
          textAlign: TextAlign.center,
        ),
        // QR Code
        Container(
          padding: AppPadding.allDouble,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
          ),
          child: QrImageView(
            data: qrJson,
            version: QrVersions.auto,
            size: AppSizes.qrCodeSize,
            backgroundColor: Colors.white,
            errorCorrectionLevel: QrErrorCorrectLevel.M,
          ),
        ),
        // Status indicator
        if (state.pairingStatus == PairingStatus.waitingForScan) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: AppSizes.iconSmall,
                height: AppSizes.iconSmall,
                child: CircularProgressIndicator(
                  strokeWidth: AppSizes.borderWidthThick,
                  color: context.colors.interactableColor,
                ),
              ),
              HSpace.x2,
              Text(
                context.l10n.pairingWaitingForScan,
                style: context.text.bodyMedium?.copyWith(
                  color: context.colors.textSecondary,
                ),
              ),
            ],
          ),
        ] else if (state.pairingStatus == PairingStatus.completing) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: AppSizes.iconSmall,
                height: AppSizes.iconSmall,
                child: CircularProgressIndicator(
                  strokeWidth: AppSizes.borderWidthThick,
                  color: context.colors.successColor,
                ),
              ),
              HSpace.x2,
              Text(
                context.l10n.pairingCompleting,
                style: context.text.bodyMedium?.copyWith(
                  color: context.colors.successColor,
                ),
              ),
            ],
          ),
        ],
        QuanityaTextButton(
          text: context.l10n.copyPairingData,
          onPressed: () {
            final data = jsonEncode(state.qrData!.toJson());
            Clipboard.setData(ClipboardData(text: data));
            PostItToast.show(context,
                message: context.l10n.pairingDataCopied,
                type: PostItType.success);
          },
        ),
        // Cancel button
        QuanityaTextButton(
          text: context.l10n.actionCancel,
          onPressed: () {
            context.read<PairingQrCubit>().cancelPairing();
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }
}
