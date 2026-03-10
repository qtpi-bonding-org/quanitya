import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../../design_system/primitives/app_spacings.dart';
import '../../../design_system/primitives/quanitya_palette.dart';
import '../../../design_system/widgets/quanitya/general/loose_insert_sheet.dart';
import '../../../design_system/widgets/quanitya/general/quanitya_text_button.dart';
import '../../../design_system/widgets/quanitya_text_form_field.dart';
import '../../../support/extensions/context_extensions.dart';
import '../cubits/llm_provider/llm_provider_cubit.dart';
import '../models/llm_provider_config_model.dart';
import '../repositories/open_router_model_repository.dart';

const _uuid = Uuid();

class LlmConfigSheet {
  static Future<void> show({
    required BuildContext context,
    required LlmProviderCubit cubit,
    LlmProviderConfigModel? config,
  }) async {
    final baseUrlController =
        TextEditingController(text: config?.baseUrl ?? 'https://openrouter.ai/api/v1');
    final modelController =
        TextEditingController(text: config?.modelId ?? '');
    final formKey = GlobalKey<FormState>();

    final result = await LooseInsertSheet.show<bool>(
      context: context,
      title: config != null
          ? context.l10n.actionEdit
          : context.l10n.llmProviderAddConfig,
      builder: (sheetContext) => _LlmConfigForm(
        formKey: formKey,
        baseUrlController: baseUrlController,
        modelController: modelController,
        cubit: cubit,
        config: config,
      ),
    );

    if (result == true) {
      final newConfig = LlmProviderConfigModel(
        id: config?.id ?? _uuid.v4(),
        baseUrl: baseUrlController.text.trim(),
        modelId: modelController.text.trim(),
        apiKeyId: config?.apiKeyId,
        lastUsedAt: DateTime.now(),
      );
      await cubit.saveConfig(newConfig);
    }

    baseUrlController.dispose();
    modelController.dispose();
  }
}

class _LlmConfigForm extends StatefulWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController baseUrlController;
  final TextEditingController modelController;
  final LlmProviderCubit cubit;
  final LlmProviderConfigModel? config;

  const _LlmConfigForm({
    required this.formKey,
    required this.baseUrlController,
    required this.modelController,
    required this.cubit,
    required this.config,
  });

  @override
  State<_LlmConfigForm> createState() => _LlmConfigFormState();
}

class _LlmConfigFormState extends State<_LlmConfigForm> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final models = widget.cubit.state.availableModels;
    final filtered = _searchQuery.isEmpty
        ? models
        : models
            .where((m) =>
                m.id.toLowerCase().contains(_searchQuery.toLowerCase()))
            .toList();

    return Form(
      key: widget.formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          QuanityaTextFormField(
            controller: widget.baseUrlController,
            labelText: context.l10n.llmProviderBaseUrl,
            hintText: 'https://openrouter.ai/api/v1',
            validator: (v) => (v == null || v.isEmpty)
                ? context.l10n.validationRequired
                : null,
          ),
          VSpace.x2,
          QuanityaTextFormField(
            controller: widget.modelController,
            labelText: context.l10n.llmProviderModel,
            hintText: context.l10n.llmProviderSearchModels,
            onChanged: (v) => setState(() => _searchQuery = v),
            validator: (v) => (v == null || v.isEmpty)
                ? context.l10n.validationRequired
                : null,
          ),
          if (filtered.isNotEmpty) ...[
            VSpace.x1,
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 200),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  final model = filtered[index];
                  return _ModelTile(
                    model: model,
                    onTap: () {
                      widget.modelController.text = model.id;
                      setState(() => _searchQuery = '');
                    },
                  );
                },
              ),
            ),
          ],
          VSpace.x3,
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (widget.config != null)
                QuanityaTextButton(
                  text: context.l10n.actionDelete,
                  isDestructive: true,
                  onPressed: () {
                    widget.cubit.deleteConfig(widget.config!.id);
                    Navigator.of(context).pop(false);
                  },
                ),
              const Spacer(),
              QuanityaTextButton(
                text: context.l10n.llmProviderTestConnection,
                onPressed: widget.config != null
                    ? () => widget.cubit.testConnection(widget.config!.id)
                    : null,
              ),
              QuanityaTextButton(
                text: context.l10n.actionSave,
                onPressed: () {
                  if (widget.formKey.currentState!.validate()) {
                    Navigator.of(context).pop(true);
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ModelTile extends StatelessWidget {
  final OpenRouterModelRecord model;
  final VoidCallback onTap;

  const _ModelTile({required this.model, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: AppPadding.verticalSingle,
        child: Row(
          children: [
            Expanded(
              child: Text(
                model.id,
                style: context.text.bodyMedium?.copyWith(
                  color: context.colors.textPrimary,
                ),
              ),
            ),
            if (model.tested)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.check_circle,
                    size: 14,
                    color: context.colors.successColor,
                  ),
                  HSpace.x05,
                  Text(
                    context.l10n.llmProviderModelTested,
                    style: context.text.bodySmall?.copyWith(
                      color: context.colors.successColor,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
