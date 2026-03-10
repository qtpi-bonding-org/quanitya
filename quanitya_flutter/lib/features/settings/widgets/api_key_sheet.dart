import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../design_system/primitives/app_sizes.dart';
import '../../../design_system/primitives/app_spacings.dart';
import '../../../design_system/primitives/quanitya_palette.dart';
import '../../../design_system/widgets/quanitya_text_form_field.dart';
import '../../../design_system/widgets/quanitya/general/quanitya_text_button.dart';
import '../../../infrastructure/webhooks/models/api_key_model.dart';
import '../../../support/extensions/context_extensions.dart';
import '../cubits/webhook/webhook_cubit.dart';

/// Dialog for creating/editing an API key
class ApiKeyDialog extends StatefulWidget {
  final ApiKeyModel? apiKey;

  const ApiKeyDialog({
    super.key,
    this.apiKey,
  });

  @override
  State<ApiKeyDialog> createState() => _ApiKeyDialogState();
}

class _ApiKeyDialogState extends State<ApiKeyDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _headerNameController;
  late final TextEditingController _keyValueController;
  AuthType _authType = AuthType.bearer;

  bool get _isEditing => widget.apiKey != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.apiKey?.name ?? '');
    _headerNameController = TextEditingController(text: widget.apiKey?.headerName ?? 'X-API-Key');
    _keyValueController = TextEditingController();
    _authType = widget.apiKey?.authType ?? AuthType.bearer;
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
    return AlertDialog(
      title: Text(
        _isEditing ? context.l10n.editApiKey : context.l10n.addApiKey,
        style: context.text.titleLarge,
      ),
      content: SizedBox(
        width: 400,
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
              DropdownButtonFormField<AuthType>(
                initialValue: _authType,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
                  ),
                  contentPadding: AppPadding.allSingle,
                ),
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
                hintText: _isEditing ? '••••••••' : context.l10n.apiKeyValueHint,
                obscureText: true,
                validator: (value) {
                  // Only required for new keys
                  if (!_isEditing && (value == null || value.isEmpty)) {
                    return context.l10n.validationRequired;
                  }
                  return null;
                },
              ),
              if (_isEditing)
                Padding(
                  padding: EdgeInsets.only(top: AppSizes.space),
                  child: Text(
                    'Leave empty to keep existing key',
                    style: context.text.bodySmall?.copyWith(
                      color: context.colors.textSecondary,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
      actions: [
        if (_isEditing)
          QuanityaTextButton(
            text: context.l10n.actionDelete,
            isDestructive: true,
            onPressed: () => _confirmDelete(context),
          ),
        QuanityaTextButton(
          text: context.l10n.actionCancel,
          onPressed: () => Navigator.of(context).pop(),
        ),
        QuanityaTextButton(
          text: context.l10n.actionSave,
          onPressed: _save,
        ),
      ],
    );
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final cubit = context.read<WebhookCubit>();
    final keyValue = _keyValueController.text.isNotEmpty ? _keyValueController.text : null;
    
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
        keyValue: keyValue!,
      );
    }
    
    Navigator.of(context).pop();
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.l10n.deleteApiKeyTitle),
        content: Text(context.l10n.deleteApiKeyMessage),
        actions: [
          QuanityaTextButton(
            text: context.l10n.actionCancel,
            onPressed: () => Navigator.of(dialogContext).pop(),
          ),
          QuanityaTextButton(
            text: context.l10n.actionDelete,
            isDestructive: true,
            onPressed: () {
              context.read<WebhookCubit>().deleteApiKey(widget.apiKey!.id);
              Navigator.of(dialogContext).pop();
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }
}
