import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cubit_ui_flow/cubit_ui_flow.dart';

import '../../../app_router.dart';
import '../../../app/bootstrap.dart';
import '../../../design_system/primitives/app_spacings.dart';
import '../../../design_system/primitives/app_sizes.dart';
import '../../../design_system/primitives/quanitya_palette.dart';
import '../../../design_system/primitives/quanitya_fonts.dart';
import '../../../design_system/structures/column.dart';
import '../../../design_system/widgets/device_name_display.dart';
import '../../../design_system/widgets/quanitya/general/quanitya_text_button.dart';
import '../../../design_system/widgets/quanitya_text_form_field.dart';
import '../../../infrastructure/crypto/crypto_key_repository.dart';
import '../../../infrastructure/device/device_info_service.dart';
import '../../../infrastructure/feedback/base_state_message_mapper.dart';
import '../../../support/extensions/context_extensions.dart';
import '../../settings/cubits/recovery_key/recovery_key_cubit.dart';
import '../../settings/cubits/recovery_key/recovery_key_state.dart';
import '../../settings/cubits/recovery_key/recovery_key_message_mapper.dart';

/// Page for recovering an account using the ultimate recovery key.
/// User enters their recovery key JWK and device label to restore access.
class AccountRecoveryPage extends StatefulWidget {
  const AccountRecoveryPage({super.key});

  @override
  State<AccountRecoveryPage> createState() => _AccountRecoveryPageState();
}

class _AccountRecoveryPageState extends State<AccountRecoveryPage> {
  final _recoveryKeyController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String _deviceName = '';
  bool _hasExistingKeys = false;
  bool _confirmEraseKeys = false;
  bool _checkingKeys = true;

  @override
  void initState() {
    super.initState();
    _loadDeviceName();
    _checkExistingKeys();
  }

  Future<void> _loadDeviceName() async {
    final deviceName = await getIt<DeviceInfoService>().getDeviceName();
    if (mounted) {
      setState(() => _deviceName = deviceName);
    }
  }

  Future<void> _checkExistingKeys() async {
    final keyRepo = getIt<ICryptoKeyRepository>();
    final hasKeys = await keyRepo.hasExistingKeys();
    if (mounted) {
      setState(() {
        _hasExistingKeys = hasKeys;
        _checkingKeys = false;
      });
    }
  }

  @override
  void dispose() {
    _recoveryKeyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<RecoveryKeyCubit>(),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(context.l10n.accountRecoveryTitle),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: SafeArea(
          child: _RecoveryForm(
            formKey: _formKey,
            recoveryKeyController: _recoveryKeyController,
            deviceName: _deviceName,
            hasExistingKeys: _hasExistingKeys,
            confirmEraseKeys: _confirmEraseKeys,
            checkingKeys: _checkingKeys,
            onConfirmEraseChanged: (value) {
              setState(() => _confirmEraseKeys = value);
            },
          ),
        ),
      ),
    );
  }
}

class _RecoveryForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController recoveryKeyController;
  final String deviceName;
  final bool hasExistingKeys;
  final bool confirmEraseKeys;
  final bool checkingKeys;
  final ValueChanged<bool> onConfirmEraseChanged;

  const _RecoveryForm({
    required this.formKey,
    required this.recoveryKeyController,
    required this.deviceName,
    required this.hasExistingKeys,
    required this.confirmEraseKeys,
    required this.checkingKeys,
    required this.onConfirmEraseChanged,
  });

  @override
  Widget build(BuildContext context) {
    return UiFlowStateListener<RecoveryKeyCubit, RecoveryKeyState>(
      mapper: BaseStateMessageMapper<RecoveryKeyState>(
        exceptionMapper: getIt<IExceptionKeyMapper>(),
        domainMapper: getIt<RecoveryKeyMessageMapper>(),
      ),
      uiService: getIt<IUiFlowService>(),
      child: BlocListener<RecoveryKeyCubit, RecoveryKeyState>(
        listenWhen: (prev, curr) =>
            prev.status != curr.status &&
            curr.status.isSuccess &&
            curr.lastOperation == RecoveryKeyOperation.recover,
        listener: (context, state) {
          AppRouter.resetKeyCheck();
          AppNavigation.toHome(context);
        },
        child: BlocBuilder<RecoveryKeyCubit, RecoveryKeyState>(
          builder: (context, state) {
            return SingleChildScrollView(
              padding: AppPadding.page,
              child: Form(
                key: formKey,
                child: QuanityaColumn(
                  spacing: VSpace.x2,
                  crossAlignment: CrossAxisAlignment.start,
                  children: [
                    _HeaderSection(),
                    _RecoveryKeyInput(controller: recoveryKeyController),
                    DeviceNameDisplay(
                      label: context.l10n.deviceLabelLabel,
                      deviceName: deviceName,
                    ),
                    // Show warning and checkbox if keys exist
                    if (hasExistingKeys && !checkingKeys)
                      _ExistingKeysWarning(
                        confirmEraseKeys: confirmEraseKeys,
                        onChanged: onConfirmEraseChanged,
                      ),
                    _RecoverButton(
                      formKey: formKey,
                      recoveryKeyController: recoveryKeyController,
                      deviceName: deviceName,
                      isLoading: state.isLoading || checkingKeys,
                      hasExistingKeys: hasExistingKeys,
                      confirmEraseKeys: confirmEraseKeys,
                    ),
                  ],
                ),
              ),
            );
          },
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
        Center(
          child: Icon(
            Icons.restore_rounded,
            size: AppSizes.iconXLarge,
            color: context.colors.textPrimary,
          ),
        ),
        VSpace.x1,
        Text(
          context.l10n.accountRecoveryDescription,
          style: context.text.bodyMedium?.copyWith(
            color: context.colors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _RecoveryKeyInput extends StatelessWidget {
  final TextEditingController controller;

  const _RecoveryKeyInput({required this.controller});

  @override
  Widget build(BuildContext context) {
    return QuanityaColumn(
      spacing: VSpace.x1,
      crossAlignment: CrossAxisAlignment.start,
      children: [
        Text(context.l10n.recoveryKeyLabel, style: context.text.labelLarge),
        QuanityaTextFormField(
          controller: controller,
          maxLines: 5,
          hintText: context.l10n.importRecoveryKeyHint,
          style: context.text.bodySmall?.copyWith(
            fontFamily: QuanityaFonts.bodyFamily,
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return context.l10n.recoveryKeyRequired;
            }
            if (!value.trim().startsWith('{')) {
              return context.l10n.recoveryKeyInvalidFormat;
            }
            return null;
          },
        ),
      ],
    );
  }
}

/// Warning shown when keys already exist on this device
class _ExistingKeysWarning extends StatelessWidget {
  final bool confirmEraseKeys;
  final ValueChanged<bool> onChanged;

  const _ExistingKeysWarning({
    required this.confirmEraseKeys,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final destructive = context.colors.destructiveColor;

    return Container(
      padding: AppPadding.allSingle,
      decoration: BoxDecoration(
        color: destructive.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
        border: Border.all(
          color: destructive.withValues(alpha: 0.3),
          width: AppSizes.borderWidth,
        ),
      ),
      child: QuanityaColumn(
        spacing: VSpace.x05,
        crossAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: destructive,
                size: AppSizes.iconSmall,
              ),
              HSpace.x1,
              Expanded(
                child: Text(
                  context.l10n.recoveryKeysExistWarning,
                  style: context.text.bodyMedium?.copyWith(
                    color: destructive,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          Row(
            children: [
              SizedBox(
                width: AppSizes.iconMedium,
                height: AppSizes.iconMedium,
                child: Checkbox(
                  value: confirmEraseKeys,
                  onChanged: (value) => onChanged(value ?? false),
                  activeColor: destructive,
                ),
              ),
              HSpace.x1,
              Expanded(
                child: GestureDetector(
                  onTap: () => onChanged(!confirmEraseKeys),
                  child: Text(
                    context.l10n.recoveryConfirmEraseKeys,
                    style: context.text.bodySmall?.copyWith(
                      color: context.colors.textSecondary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RecoverButton extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController recoveryKeyController;
  final String deviceName;
  final bool isLoading;
  final bool hasExistingKeys;
  final bool confirmEraseKeys;

  const _RecoverButton({
    required this.formKey,
    required this.recoveryKeyController,
    required this.deviceName,
    required this.isLoading,
    required this.hasExistingKeys,
    required this.confirmEraseKeys,
  });

  @override
  Widget build(BuildContext context) {
    // Button is enabled when:
    // - Not loading
    // - Either no existing keys OR user confirmed to erase them
    final canRecover = !isLoading && (!hasExistingKeys || confirmEraseKeys);

    return SizedBox(
      width: double.infinity,
      child: QuanityaTextButton(text: 
        text: isLoading ? context.l10n.recovering : context.l10n.recoverAccount,
        onPressed: canRecover
            ? () async {
                if (formKey.currentState?.validate() ?? false) {
                  // If keys exist, clear them first
                  if (hasExistingKeys) {
                    final keyRepo = getIt<ICryptoKeyRepository>();
                    await keyRepo.clearKeys();
                  }

                  if (context.mounted) {
                    context.read<RecoveryKeyCubit>().recoverAccount(
                      jwk: recoveryKeyController.text.trim(),
                      deviceLabel: deviceName,
                    );
                  }
                }
              }
            : null,
      ),
    );
  }
}
