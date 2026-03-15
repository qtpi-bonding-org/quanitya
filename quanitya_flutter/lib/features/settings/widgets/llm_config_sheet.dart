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
import '../../../infrastructure/llm/models/llm_types.dart';
import '../../../support/extensions/context_extensions.dart';
import '../cubits/llm_provider/llm_provider_cubit.dart';
import '../models/llm_provider_config_model.dart';
import '../repositories/open_router_model_repository.dart';

const _uuid = Uuid();

class LlmConfigSheet {
  static const openRouterBaseUrl = 'https://openrouter.ai/api/v1';
  static const ollamaBaseUrl = 'http://localhost:11434/v1';

  static Future<void> show({
    required BuildContext context,
    required LlmProviderCubit cubit,
    LlmProviderConfigModel? config,
    String? defaultBaseUrl,
    LlmProvider provider = LlmProvider.openRouter,
  }) async {
    final result = await LooseInsertSheet.show<LlmProviderConfigModel>(
      context: context,
      title: config != null
          ? context.l10n.actionEdit
          : context.l10n.llmProviderAddConfig,
      builder: (sheetContext) => _LlmConfigForm(
        cubit: cubit,
        config: config,
        defaultBaseUrl: defaultBaseUrl,
        provider: config?.provider ?? provider,
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
  final String? defaultBaseUrl;
  final LlmProvider provider;

  const _LlmConfigForm({
    required this.cubit,
    required this.config,
    this.defaultBaseUrl,
    required this.provider,
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

  bool get _isOpenRouter => widget.provider == LlmProvider.openRouter;

  @override
  void initState() {
    super.initState();
    _baseUrlController = TextEditingController(
      text: widget.config?.baseUrl ??
          widget.defaultBaseUrl ??
          LlmConfigSheet.openRouterBaseUrl,
    );
    _modelController = TextEditingController(
      text: widget.config?.modelId ?? '',
    );
    if (_isOpenRouter) {
      _loadModels();
    }
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
    final isOpenRouter = _isOpenRouter;
    final byProvider = _selectedProvider != null
        ? _models.where((m) => m.id.startsWith('$_selectedProvider/'))
        : _models;
    final filtered = !isOpenRouter || _searchQuery.isEmpty
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
                hintText: isOpenRouter
                    ? LlmConfigSheet.openRouterBaseUrl
                    : LlmConfigSheet.ollamaBaseUrl,
                validator: (v) => (v == null || v.isEmpty)
                    ? context.l10n.validationRequired
                    : null,
              ),
              VSpace.x2,
              if (isOpenRouter && _providers.isNotEmpty) ...[
                Wrap(
                  spacing: AppSizes.spaceHalf,
                  runSpacing: AppSizes.spaceHalf,
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
                hintText: isOpenRouter
                    ? context.l10n.llmProviderSearchModels
                    : 'llama3, mistral, gemma...',
                onChanged: isOpenRouter
                    ? (v) => setState(() => _searchQuery = v)
                    : null,
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
                      provider: widget.provider,
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
