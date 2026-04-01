import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:cubit_ui_flow/cubit_ui_flow.dart';
import 'package:permission_handler/permission_handler.dart' show openAppSettings;

import '../../../infrastructure/permissions/permission_service.dart';
import '../../../design_system/primitives/app_spacings.dart';
import '../../../design_system/primitives/app_sizes.dart';
import '../../../design_system/primitives/quanitya_palette.dart';
import '../../../design_system/structures/column.dart';
import '../../../design_system/widgets/quanitya/general/quanitya_text_button.dart';
import '../../../design_system/widgets/quanitya_confirmation_dialog.dart';
import '../../../design_system/widgets/quanitya_text_field.dart';
import '../../../design_system/widgets/quanitya/general/loose_insert_sheet.dart';
import '../../../design_system/widgets/ui_flow_listener.dart';
import '../../../support/extensions/context_extensions.dart';
import '../cubits/pairing_scan_cubit.dart';
import '../cubits/pairing_scan_state.dart';
import '../services/pairing_message_mapper.dart';

/// Bottom sheet for scanning a pairing QR code to add a new device.
///
/// Replaces the full-page ScanPairingQrPage with a 95% height sheet.
/// Caller should refresh the device list after this sheet closes.
class ScanPairingSheet {
  ScanPairingSheet._();

  static Future<void> show(BuildContext context) {
    return LooseInsertSheet.show(
      context: context,
      title: context.l10n.addDevice,
      maxHeightFraction: 0.95,
      builder: (sheetContext) => BlocProvider(
        create: (_) => GetIt.instance<PairingScanCubit>()..startScanning(),
        child: _ScanPairingContent(sheetContext: sheetContext),
      ),
    );
  }
}

class _ScanPairingContent extends StatefulWidget {
  final BuildContext sheetContext;

  const _ScanPairingContent({required this.sheetContext});

  @override
  State<_ScanPairingContent> createState() => _ScanPairingContentState();
}

class _ScanPairingContentState extends State<_ScanPairingContent>
    with WidgetsBindingObserver {
  final MobileScannerController _scannerController = MobileScannerController();
  bool _hasScanned = false;
  bool? _cameraGranted;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkPermission();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkPermission();
    }
  }

  Future<void> _checkPermission() async {
    final granted = await GetIt.instance<PermissionService>().ensureCamera();
    if (mounted) {
      setState(() => _cameraGranted = granted);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scannerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return UiFlowListener<PairingScanCubit, PairingScanState>(
      mapper: context.read<PairingScanMessageMapper>(),
      child: BlocConsumer<PairingScanCubit, PairingScanState>(
        listener: (context, state) {
          if (state.scanStatus == ScanStatus.confirmationRequired) {
            _showConfirmationDialog(context, state);
          } else if (state.scanStatus == ScanStatus.success) {
            _scannerController.stop();
            Navigator.of(widget.sheetContext).pop();
          }
        },
        builder: (context, state) {
          if (_cameraGranted == null) {
            return const SizedBox(
              height: 300,
              child: Center(child: CircularProgressIndicator()),
            );
          }
          if (!_cameraGranted!) {
            return _buildPermissionDenied(context);
          }
          if (state.scanStatus == ScanStatus.registering) {
            return _buildRegistering(context);
          }
          return _buildScanner(context, state);
        },
      ),
    );
  }

  Widget _buildScanner(BuildContext context, PairingScanState state) {
    return Column(
      children: [
        // Camera view
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
            child: MobileScanner(
              controller: _scannerController,
              onDetect: (capture) {
                if (_hasScanned) return;
                final barcodes = capture.barcodes;
                for (final barcode in barcodes) {
                  final rawValue = barcode.rawValue;
                  if (rawValue != null &&
                      rawValue.contains('"action":"pair"')) {
                    _hasScanned = true;
                    context.read<PairingScanCubit>().processQrCode(rawValue);
                    break;
                  }
                }
              },
            ),
          ),
        ),
        VSpace.x2,
        Text(
          context.l10n.pairingScanInstructions,
          style: context.text.bodyMedium,
          textAlign: TextAlign.center,
        ),
        VSpace.x2,
        QuanityaTextButton(
          text: context.l10n.enterPairingData,
          onPressed: () => _showManualEntryDialog(context),
        ),
        if (state.status == UiFlowStatus.failure && state.error != null) ...[
          VSpace.x1,
          Text(
            state.error.toString(),
            style: context.text.bodySmall?.copyWith(
              color: context.colors.errorColor,
            ),
            textAlign: TextAlign.center,
          ),
        ],
        VSpace.x2,
      ],
    );
  }

  void _showManualEntryDialog(BuildContext context) {
    final controller = TextEditingController();
    LooseInsertSheet.show(
      context: context,
      title: context.l10n.enterPairingData,
      builder: (sheetContext) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.pairingDataManualInstructions,
            style: context.text.bodyMedium,
          ),
          VSpace.x2,
          QuanityaTextField(
            controller: controller,
            maxLines: 5,
            hintText: context.l10n.pairingDataHint,
          ),
          VSpace.x3,
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              QuanityaTextButton(
                text: context.l10n.actionCancel,
                onPressed: () => Navigator.pop(sheetContext),
              ),
              QuanityaTextButton(
                text: context.l10n.pairingConfirmAdd,
                onPressed: () {
                  final text = controller.text.trim();
                  if (text.isNotEmpty) {
                    context.read<PairingScanCubit>().processQrCode(text);
                    Navigator.pop(sheetContext);
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRegistering(BuildContext context) {
    return SizedBox(
      height: 300,
      child: Center(
        child: QuanityaColumn(
          mainAlignment: MainAxisAlignment.center,
          spacing: VSpace.x3,
          children: [
            CircularProgressIndicator(color: context.colors.interactableColor),
            Text(context.l10n.pairingRegistering, style: context.text.bodyLarge),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionDenied(BuildContext context) {
    return SizedBox(
      height: 300,
      child: Center(
        child: QuanityaColumn(
          mainAlignment: MainAxisAlignment.center,
          spacing: VSpace.x3,
          children: [
            Icon(
              Icons.camera_alt_outlined,
              size: AppSizes.size48,
              color: context.colors.destructiveColor,
            ),
            Text(
              context.l10n.cameraPermissionDeniedTitle,
              style: context.text.headlineSmall,
              textAlign: TextAlign.center,
            ),
            Text(
              context.l10n.cameraPermissionDeniedMessage,
              style: context.text.bodyLarge,
              textAlign: TextAlign.center,
            ),
            VSpace.x2,
            QuanityaTextButton(
              text: context.l10n.actionOpenSettings,
              onPressed: () => openAppSettings(),
            ),
            QuanityaTextButton(
              text: context.l10n.enterPairingData,
              onPressed: () => _showManualEntryDialog(context),
            ),
          ],
        ),
      ),
    );
  }

  void _showConfirmationDialog(BuildContext context, PairingScanState state) {
    final pending = state.pendingDevice;
    if (pending == null) return;

    final cubit = context.read<PairingScanCubit>();

    QuanityaConfirmationDialog.show(
      context: context,
      title: context.l10n.pairingConfirmTitle,
      message: context.l10n.pairingConfirmMessage(pending.label),
      confirmText: context.l10n.pairingConfirmAdd,
      onConfirm: () {
        cubit.confirmAddDevice();
      },
    ).then((confirmed) {
      if (confirmed != true) {
        _hasScanned = false;
        cubit.cancelAddDevice();
      }
    });
  }
}
