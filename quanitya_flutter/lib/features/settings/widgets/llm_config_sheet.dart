import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../../design_system/primitives/app_sizes.dart';
import '../../../design_system/primitives/app_spacings.dart';
import '../../../design_system/primitives/quanitya_palette.dart';
import '../../../design_system/widgets/quanitya/general/pen_circled_chip.dart';
import '../../../design_system/structures/group.dart';
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
    final result = await LooseInsertSheet.show<LlmProviderConfigModel>(
      context: context,
      title: config != null
          ? context.l10n.actionEdit
          : context.l10n.llmProviderAddConfig,
      builder: (sheetContext) => _LlmConfigForm(
        cubit: cubit,
        config: config,
      ),
    );

    if (result != null) {
      await cubit.saveConfig(result);
    }
  }
}

class _LlmConfigForm extends StatefulWidget {
  final LlmProviderCubit cubit;
  final LlmProviderConfigModel? config;

  const _LlmConfigForm({
    required this.cubit,
    required this.config,
  });

  @override
  State<_LlmConfigForm> createState() => _LlmConfigFormState();
}

class _LlmConfigFormState extends State<_LlmConfigForm> {
  late final TextEditingController _baseUrlController;
  late final TextEditingController _modelController;
  final _formKey = GlobalKey<FormState>();
  String _searchQuery = '';
  String? _selectedProvider;
  List<OpenRouterModelRecord> _models = [];
  List<String> _providers = [];

  @override
  void initState() {
    super.initState();
    _baseUrlController = TextEditingController(
      text: widget.config?.baseUrl ?? 'https://openrouter.ai/api/v1',
    );
    _modelController = TextEditingController(
      text: widget.config?.modelId ?? '',
    );
    _loadModels();
  }

  Future<void> _loadModels() async {
    await widget.cubit.fetchOpenRouterModels();
    if (mounted) {
      final models = widget.cubit.state.availableModels;
      final providers = models
          .map((m) => m.id.contains('/') ? m.id.split('/').first : null)
          .whereType<String>()
          .toSet()
          .toList()
        ..sort();
      setState(() {
        _models = models;
        _providers = providers;
      });
    }
  }

  @override
  void dispose() {
    _baseUrlController.dispose();
    _modelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final byProvider = _selectedProvider != null
        ? _models.where((m) => m.id.startsWith('$_selectedProvider/'))
        : _models;
    final filtered = _searchQuery.isEmpty
        ? <OpenRouterModelRecord>[]
        : byProvider
            .where((m) =>
                m.id.toLowerCase().contains(_searchQuery.toLowerCase()))
            .take(10)
            .toList();

    return Flexible(
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              QuanityaTextFormField(
                controller: _baseUrlController,
                labelText: context.l10n.llmProviderBaseUrl,
                hintText: 'https://openrouter.ai/api/v1',
                validator: (v) => (v == null || v.isEmpty)
                    ? context.l10n.validationRequired
                    : null,
              ),
              VSpace.x2,
              if (_providers.isNotEmpty) ...[
                Wrap(
                  spacing: AppSizes.space * 0.5,
                  runSpacing: AppSizes.space * 0.5,
                  children: _providers.map((provider) {
                    return PenCircledChip(
                      label: provider,
                      isSelected: _selectedProvider == provider,
                      onTap: () => setState(() {
                        _selectedProvider =
                            _selectedProvider == provider ? null : provider;
                      }),
                    );
                  }).toList(),
                ),
                VSpace.x2,
              ],
              QuanityaTextFormField(
                controller: _modelController,
                labelText: context.l10n.llmProviderModel,
                hintText: context.l10n.llmProviderSearchModels,
                onChanged: (v) => setState(() => _searchQuery = v),
                validator: (v) => (v == null || v.isEmpty)
                    ? context.l10n.validationRequired
                    : null,
              ),
              if (filtered.isNotEmpty) ...[
                VSpace.x1,
                ...filtered.map((model) => _ModelTile(
                      model: model,
                      onTap: () {
                        _modelController.text = model.id;
                        setState(() => _searchQuery = '');
                      },
                    )),
              ],
              VSpace.x3,
              Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (widget.config case final existingConfig?)
                QuanityaTextButton(
                  text: context.l10n.actionDelete,
                  isDestructive: true,
                  onPressed: () {
                    widget.cubit.deleteConfig(existingConfig.id);
                    Navigator.of(context).pop();
                  },
                ),
              const Spacer(),
              if (widget.config case final existingConfig?)
                QuanityaTextButton(
                  text: context.l10n.llmProviderTestConnection,
                  onPressed: () =>
                      widget.cubit.testConnection(existingConfig.id),
                ),
              QuanityaTextButton(
                text: context.l10n.actionSave,
                onPressed: () {
                  if (_formKey.currentState?.validate() ?? false) {
                    final result = LlmProviderConfigModel(
                      id: widget.config?.id ?? _uuid.v4(),
                      baseUrl: _baseUrlController.text.trim(),
                      modelId: _modelController.text.trim(),
                      apiKeyId: widget.config?.apiKeyId,
                      lastUsedAt: DateTime.now(),
                    );
                    Navigator.of(context).pop(result);
                  }
                },
              ),
            ],
          ),
          ],
        ),
      ),
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
    return QuanityaGroup(
      onTap: onTap,
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
            Text(
              context.l10n.llmProviderModelTested,
              style: context.text.bodySmall?.copyWith(
                color: context.colors.textPrimary,
              ),
            ),
        ],
      ),
    );
  }
}
