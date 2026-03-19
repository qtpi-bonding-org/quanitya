import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../design_system/primitives/app_sizes.dart';
import '../../../design_system/primitives/app_spacings.dart';
import '../../../design_system/primitives/quanitya_palette.dart';
import '../../../design_system/widgets/quanitya_text_form_field.dart';
import '../../../design_system/widgets/quanitya_icon_button.dart';
import '../../../design_system/widgets/quanitya/general/loose_insert_sheet.dart';
import '../../../design_system/widgets/quanitya/general/quanitya_text_button.dart';
import '../../../design_system/widgets/quanitya/generatable/quanitya_dropdown.dart';
import '../../../design_system/widgets/quanitya_confirmation_dialog.dart';
import '../../../infrastructure/webhooks/models/api_key_model.dart';
import '../../../support/extensions/context_extensions.dart';
import '../cubits/webhook/webhook_cubit.dart';

/// Bottom sheet for creating/editing an API key.
class ApiKeySheet extends StatefulWidget {
  final ApiKeyModel? apiKey;

  const ApiKeySheet({
    super.key,
    this.apiKey,
  });

  /// Show the API key sheet as a modal bottom sheet.
  static Future<void> show({
    required BuildContext context,
    required WebhookCubit cubit,
    ApiKeyModel? apiKey,
  }) {
    return LooseInsertSheet.show(
      context: context,
      title: apiKey != null
          ? context.l10n.editApiKey
          : context.l10n.addApiKey,
      builder: (sheetContext) => BlocProvider.value(
        value: cubit,
        child: ApiKeySheet(apiKey: apiKey),
      ),
    );
  }

  @override
  State<ApiKeySheet> createState() => _ApiKeySheetState();
}

class _ApiKeySheetState extends State<ApiKeySheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _headerNameController;
  late final TextEditingController _keyValueController;
  AuthType _authType = AuthType.bearer;
  bool _obscureKey = true;

  bool get _isEditing => widget.apiKey != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.apiKey?.name ?? '');
    _headerNameController = TextEditingController(text: widget.apiKey?.headerName ?? 'X-API-Key');
    _keyValueController = TextEditingController();
    _authType = widget.apiKey?.authType ?? AuthType.bearer;

    if (_isEditing) {
      _loadExistingKeyValue();
    }
  }

  Future<void> _loadExistingKeyValue() async {
    final cubit = context.read<WebhookCubit>();
    final value = await cubit.getApiKeyValue(widget.apiKey!.id);
    if (mounted && value != null) {
      _keyValueController.text = value;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _headerNameController.dispose();
    _keyValueController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Name field
            QuanityaTextFormField(
              controller: _nameController,
              labelText: context.l10n.apiKeyName,
              hintText: context.l10n.apiKeyNameHint,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return context.l10n.validationRequired;
                }
                return null;
              },
            ),
            VSpace.x3,

            // Auth type dropdown
            Text(
              context.l10n.apiKeyType,
              style: context.text.bodyMedium?.copyWith(
                color: context.colors.textSecondary,
              ),
            ),
            VSpace.x1,
            QuanityaDropdown<AuthType>(
              value: _authType,
              items: [
                DropdownMenuItem(
                  value: AuthType.bearer,
                  child: Text(context.l10n.apiKeyTypeBearer),
                ),
                DropdownMenuItem(
                  value: AuthType.apiKeyHeader,
                  child: Text(context.l10n.apiKeyTypeHeader),
                ),
              ],
              onChanged: (value) => setState(() => _authType = value!),
            ),
            VSpace.x3,

            // Header name (only for apiKeyHeader type)
            if (_authType == AuthType.apiKeyHeader) ...[
              QuanityaTextFormField(
                controller: _headerNameController,
                labelText: context.l10n.apiKeyHeaderName,
                hintText: context.l10n.apiKeyHeaderNameHint,
                validator: (value) {
                  if (_authType == AuthType.apiKeyHeader && (value == null || value.isEmpty)) {
                    return context.l10n.validationRequired;
                  }
                  return null;
                },
              ),
              VSpace.x3,
            ],

            // Key value field
            QuanityaTextFormField(
              controller: _keyValueController,
              labelText: context.l10n.apiKeyValue,
              hintText: context.l10n.apiKeyValueHint,
              obscureText: _obscureKey,
              suffixIcon: QuanityaIconButton(
                icon: _obscureKey ? Icons.visibility_off : Icons.visibility,
                iconSize: AppSizes.iconMedium,
                tooltip: context.l10n.actionToggleVisibility,
                onPressed: () => setState(() => _obscureKey = !_obscureKey),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return context.l10n.validationRequired;
                }
                return null;
              },
            ),
            VSpace.x4,

            // Action buttons
            Row(
              children: [
                if (_isEditing)
                  QuanityaTextButton(
                    text: context.l10n.actionDelete,
                    isDestructive: true,
                    onPressed: () => _confirmDelete(context),
                  ),
                const Spacer(),
                QuanityaTextButton(
                  text: context.l10n.actionCancel,
                  onPressed: () => Navigator.of(context).pop(),
                ),
                HSpace.x2,
                QuanityaTextButton(
                  text: context.l10n.actionSave,
                  onPressed: _save,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final cubit = context.read<WebhookCubit>();
    final keyValue = _keyValueController.text;

    if (_isEditing) {
      cubit.updateApiKey(
        id: widget.apiKey!.id,
        name: _nameController.text,
        authType: _authType,
        headerName: _authType == AuthType.apiKeyHeader ? _headerNameController.text : null,
        keyValue: keyValue,
      );
    } else {
      cubit.createApiKey(
        name: _nameController.text,
        authType: _authType,
        headerName: _authType == AuthType.apiKeyHeader ? _headerNameController.text : null,
        keyValue: keyValue,
      );
    }

    Navigator.of(context).pop();
  }

  void _confirmDelete(BuildContext context) {
    QuanityaConfirmationDialog.show(
      context: context,
      title: context.l10n.deleteApiKeyTitle,
      message: context.l10n.deleteApiKeyMessage,
      confirmText: context.l10n.actionDelete,
      isDestructive: true,
      onConfirm: () {
        context.read<WebhookCubit>().deleteApiKey(widget.apiKey!.id);
        Navigator.of(context).pop();
      },
    );
  }
}
