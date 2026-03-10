import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:cubit_ui_flow/cubit_ui_flow.dart';

import '../../../design_system/primitives/app_spacings.dart';
import '../../../design_system/primitives/app_sizes.dart';
import '../../../design_system/primitives/quanitya_palette.dart';
import '../../../design_system/structures/column.dart';
import '../../../design_system/widgets/quanitya_icon_button.dart';
import '../../../design_system/widgets/quanitya/general/quanitya_text_button.dart';
import '../../../design_system/widgets/quanitya_text_field.dart';
import '../../../design_system/widgets/quanitya/general/quanitya_text_button.dart' as btn;
import '../../../design_system/widgets/quanitya_confirmation_dialog.dart';
import '../../../design_system/widgets/quanitya/general/loose_insert_sheet.dart';
import '../../../design_system/widgets/ui_flow_listener.dart';
import '../../../support/extensions/context_extensions.dart';
import '../cubits/pairing_scan_cubit.dart';
import '../cubits/pairing_scan_state.dart';
import '../services/pairing_message_mapper.dart';

/// Page for Device A - scans QR code to add new device.
///
/// Flow:
/// 1. Open camera and scan QR
/// 2. Parse QR and show confirmation
/// 3. On confirm, register device
/// 4. On success, navigate back
class ScanPairingQrPage extends StatelessWidget {
  const ScanPairingQrPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => GetIt.instance<PairingScanCubit>()..startScanning(),
      child: const _ScanPairingQrView(),
    );
  }
}

class _ScanPairingQrView extends StatefulWidget {
  const _ScanPairingQrView();

  @override
  State<_ScanPairingQrView> createState() => _ScanPairingQrViewState();
}

class _ScanPairingQrViewState extends State<_ScanPairingQrView>
    with WidgetsBindingObserver {
  final MobileScannerController _scannerController = MobileScannerController();
  bool _hasScanned = false;
  PermissionStatus? _permissionStatus;

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
    final status = await Permission.camera.request();
    if (mounted) {
      setState(() {
        _permissionStatus = status;
      });
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
      mapper: GetIt.instance<PairingScanMessageMapper>(),
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            context.l10n.addDevice,
            style: context.text.headlineMedium,
          ),
          leading: QuanityaIconButton(
            icon: Icons.arrow_back,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: BlocConsumer<PairingScanCubit, PairingScanState>(
          listener: (context, state) {
            if (state.scanStatus == ScanStatus.confirmationRequired) {
              _showConfirmationDialog(context, state);
            } else if (state.scanStatus == ScanStatus.success) {
              Navigator.of(context).pop(true);
            }
          },
          builder: (context, state) {
            if (_permissionStatus == null) {
              return const Center(child: CircularProgressIndicator());
            }
            if (_permissionStatus!.isDenied || _permissionStatus!.isPermanentlyDenied) {
              return _buildPermissionDenied(context);
            }
            if (state.scanStatus == ScanStatus.registering) {
              return _buildRegistering(context);
            }
            return _buildScanner(context, state);
          },
        ),
      ),
    );
  }

  Widget _buildScanner(BuildContext context, PairingScanState state) {
    return Stack(
      children: [
        // Camera view
        MobileScanner(
          controller: _scannerController,
          onDetect: (capture) {
            if (_hasScanned) return;

            final barcodes = capture.barcodes;
            for (final barcode in barcodes) {
              final rawValue = barcode.rawValue;
              if (rawValue != null && rawValue.contains('"action":"pair"')) {
                _hasScanned = true;
                context.read<PairingScanCubit>().processQrCode(rawValue);
                break;
              }
            }
          },
        ),
        // Overlay with instructions
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: AppPadding.page,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.7),
                ],
              ),
            ),
            child: SafeArea(
              child: QuanityaColumn(
                spacing: VSpace.x2,
                children: [
                  Text(
                    context.l10n.pairingScanInstructions,
                    style: context.text.bodyLarge?.copyWith(
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  QuanityaTextButton(
                    text: context.l10n.enterPairingData,
                    // Use a specific style or color if needed to look good on the dark overlay
                    onPressed: () => _showManualEntryDialog(context),
                  ),
                  if (state.status == UiFlowStatus.failure &&
                      state.error != null)
                    Text(
                      state.error.toString(),
                      style: context.text.bodyMedium?.copyWith(
                        color: context.colors.errorColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                ],
              ),
            ),
          ),
        ),
        // Scan frame overlay
        Center(
          child: Container(
            width: AppSizes.qrCodeSize,
            height: AppSizes.qrCodeSize,
            decoration: BoxDecoration(
              border: Border.all(
                color: context.colors.interactableColor,
                width: AppSizes.borderWidthThick,
              ),
              borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
            ),
          ),
        ),
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
              btn.QuanityaTextButton(
                text: context.l10n.actionCancel,
                onPressed: () => Navigator.pop(sheetContext),
              ),
              btn.QuanityaTextButton(
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
    return Center(
      child: QuanityaColumn(
        mainAlignment: MainAxisAlignment.center,
        spacing: VSpace.x3,
        children: [
          CircularProgressIndicator(color: context.colors.interactableColor),
          Text(context.l10n.pairingRegistering, style: context.text.bodyLarge),
        ],
      ),
    );
  }

  Widget _buildPermissionDenied(BuildContext context) {
    return Center(
      child: Padding(
        padding: AppPadding.page,
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
            QuanityaTextButton(
              text: context.l10n.actionCancel,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }

  void _showConfirmationDialog(BuildContext context, PairingScanState state) {
    final pending = state.pendingDevice;
    if (pending == null) return;

    // Capture cubit before async gap
    final cubit = context.read<PairingScanCubit>();

    QuanityaConfirmationDialog.show(
      context: context,
      title: context.l10n.pairingConfirmTitle,
      message: context.l10n.pairingConfirmMessage(pending.label),
      confirmText: context.l10n.pairingConfirmAdd,
      onConfirm: () {
        cubit.confirmAddDevice();
      },
    ).then((_) {
      // If dialog was dismissed without confirming, cancel
      if (!mounted) return;
      if (cubit.state.scanStatus == ScanStatus.confirmationRequired) {
        _hasScanned = false;
        cubit.cancelAddDevice();
      }
    });
  }
}
