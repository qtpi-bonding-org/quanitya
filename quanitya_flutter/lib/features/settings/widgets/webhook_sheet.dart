import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../design_system/primitives/app_sizes.dart';
import '../../../design_system/primitives/app_spacings.dart';
import '../../../design_system/primitives/quanitya_palette.dart';
import '../../../design_system/widgets/quanitya_text_form_field.dart';
import '../../../design_system/widgets/quanitya/general/quanitya_text_button.dart';
import '../../../infrastructure/webhooks/models/webhook_model.dart';
import '../../../logic/templates/models/shared/tracker_template.dart';
import '../../../support/extensions/context_extensions.dart';
import '../cubits/webhook/webhook_cubit.dart';
import '../cubits/webhook/webhook_state.dart';

/// Dialog for creating/editing a webhook
class WebhookDialog extends StatefulWidget {
  final WebhookModel? webhook;
  final List<TrackerTemplateModel> templates;

  const WebhookDialog({
    super.key,
    this.webhook,
    required this.templates,
  });

  @override
  State<WebhookDialog> createState() => _WebhookDialogState();
}

class _WebhookDialogState extends State<WebhookDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _urlController;
  String? _selectedTemplateId;
  String? _selectedApiKeyId;
  bool _isEnabled = true;

  bool get _isEditing => widget.webhook != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.webhook?.name ?? '');
    _urlController = TextEditingController(text: widget.webhook?.url ?? '');
    _selectedTemplateId = widget.webhook?.templateId;
    _selectedApiKeyId = widget.webhook?.apiKeyId;
    _isEnabled = widget.webhook?.isEnabled ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WebhookCubit, WebhookState>(
      builder: (context, state) {
        return AlertDialog(
          title: Text(
            _isEditing ? context.l10n.editWebhook : context.l10n.addWebhook,
            style: context.text.titleLarge,
          ),
          content: SizedBox(
            width: 400,
            child: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                  // Name field
                  QuanityaTextFormField(
                    controller: _nameController,
                    labelText: context.l10n.webhookName,
                    hintText: context.l10n.webhookNameHint,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return context.l10n.validationRequired;
                      }
                      return null;
                    },
                  ),
                  VSpace.x3,

                  // URL field
                  QuanityaTextFormField(
                    controller: _urlController,
                    labelText: context.l10n.webhookUrl,
                    hintText: context.l10n.webhookUrlHint,
                    keyboardType: TextInputType.url,
                    validator: (value) {
                      final error = WebhookUrlValidator.validate(value ?? '');
                      if (error != null) {
                        if (error.contains('required')) return context.l10n.webhookUrlRequired;
                        if (error.contains('HTTPS')) return context.l10n.webhookUrlHttpsRequired;
                        return context.l10n.webhookUrlInvalid;
                      }
                      return null;
                    },
                  ),
                  VSpace.x3,

                  // Template dropdown
                  Text(
                    context.l10n.webhookTemplate,
                    style: context.text.bodyMedium?.copyWith(
                      color: context.colors.textSecondary,
                    ),
                  ),
                  VSpace.x1,
                  DropdownButtonFormField<String>(
                    value: _selectedTemplateId,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
                      ),
                      contentPadding: AppPadding.allSingle,
                    ),
                    hint: Text(context.l10n.webhookSelectTemplate),
                    items: widget.templates.map((t) => DropdownMenuItem(
                      value: t.id,
                      child: Text(t.name),
                    )).toList(),
                    onChanged: (value) => setState(() => _selectedTemplateId = value),
                    validator: (value) {
                      if (value == null) return context.l10n.validationRequired;
                      return null;
                    },
                  ),
                  VSpace.x3,

                  // API Key dropdown (required, 1:1 with webhook)
                  Text(
                    context.l10n.webhookApiKey,
                    style: context.text.bodyMedium?.copyWith(
                      color: context.colors.textSecondary,
                    ),
                  ),
                  VSpace.x1,
                  Builder(
                    builder: (context) {
                      // Filter to keys not already used by other webhooks
                      final usedKeyIds = state.webhooks
                          .where((w) => w.apiKeyId != null && w.id != widget.webhook?.id)
                          .map((w) => w.apiKeyId!)
                          .toSet();
                      final availableKeys = state.apiKeys
                          .where((k) => !usedKeyIds.contains(k.id) || k.id == _selectedApiKeyId)
                          .toList();

                      return DropdownButtonFormField<String>(
                        value: _selectedApiKeyId,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
                          ),
                          contentPadding: AppPadding.allSingle,
                        ),
                        hint: Text(context.l10n.webhookSelectApiKey),
                        items: availableKeys.map((k) => DropdownMenuItem(
                          value: k.id,
                          child: Text(k.name),
                        )).toList(),
                        onChanged: (value) => setState(() => _selectedApiKeyId = value),
                        validator: (value) {
                          if (value == null) return context.l10n.validationRequired;
                          return null;
                        },
                      );
                    },
                  ),
                  VSpace.x3,

                  // Enabled toggle
                  Row(
                    children: [
                      Text(
                        context.l10n.webhookEnabled,
                        style: context.text.bodyMedium,
                      ),
                      const Spacer(),
                      Switch(
                        value: _isEnabled,
                        onChanged: (value) => setState(() => _isEnabled = value),
                        activeTrackColor: context.colors.successColor,
                      ),
                    ],
                  ),
                  ],
                ),
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
      },
    );
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final cubit = context.read<WebhookCubit>();
    
    if (_isEditing) {
      cubit.updateWebhook(
        id: widget.webhook!.id,
        name: _nameController.text,
        url: _urlController.text,
        apiKeyId: _selectedApiKeyId,
        isEnabled: _isEnabled,
      );
    } else {
      cubit.createWebhook(
        templateId: _selectedTemplateId!,
        name: _nameController.text,
        url: _urlController.text,
        apiKeyId: _selectedApiKeyId,
        isEnabled: _isEnabled,
      );
    }
    
    Navigator.of(context).pop();
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.l10n.deleteWebhookTitle),
        content: Text(context.l10n.deleteWebhookMessage),
        actions: [
          QuanityaTextButton(
            text: context.l10n.actionCancel,
            onPressed: () => Navigator.of(dialogContext).pop(),
          ),
          QuanityaTextButton(
            text: context.l10n.actionDelete,
            isDestructive: true,
            onPressed: () {
              context.read<WebhookCubit>().deleteWebhook(widget.webhook!.id);
              Navigator.of(dialogContext).pop();
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }
}
