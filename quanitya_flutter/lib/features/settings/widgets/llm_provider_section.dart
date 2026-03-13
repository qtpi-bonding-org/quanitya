import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../design_system/primitives/app_sizes.dart';
import '../../../design_system/primitives/app_spacings.dart';
import '../../../design_system/primitives/quanitya_palette.dart';
import '../../../design_system/widgets/quanitya/general/quanitya_text_button.dart';
import '../../../infrastructure/llm/models/llm_types.dart';
import '../../../support/extensions/context_extensions.dart';
import '../cubits/llm_provider/llm_provider_cubit.dart';
import '../cubits/llm_provider/llm_provider_state.dart';
import '../models/llm_provider_config_model.dart';
import 'llm_config_sheet.dart';

class LlmProviderSection extends StatelessWidget {
  const LlmProviderSection({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LlmProviderCubit, LlmProviderState>(
      builder: (context, state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.l10n.settingsLlmSection.toUpperCase(),
              style: context.text.titleMedium?.copyWith(
                color: context.colors.textPrimary,
              ),
            ),
            VSpace.x1,

            ..._buildProviderRows(context, state),

            VSpace.x2,
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                QuanityaTextButton(
                  text: 'Add OpenRouter',
                  onPressed: () => _showConfigSheet(
                    context,
                    null,
                    defaultBaseUrl: LlmConfigSheet.openRouterBaseUrl,
                  ),
                ),
                HSpace.x2,
                QuanityaTextButton(
                  text: 'Add Ollama',
                  onPressed: () => _showConfigSheet(
                    context,
                    null,
                    defaultBaseUrl: LlmConfigSheet.ollamaBaseUrl,
                    provider: LlmProvider.ollama,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  List<Widget> _buildProviderRows(
      BuildContext context, LlmProviderState state) {
    final isQuanityaActive = state.activeConfig == null ||
        state.activeConfig?.provider == LlmProvider.quanitya;
    final quanityaRow = Padding(
      padding: AppPadding.verticalSingle,
      child: _QuanityaProviderRow(
        isActive: isQuanityaActive,
        onTap: () =>
            context.read<LlmProviderCubit>().selectQuanitya(),
      ),
    );

    // Filter out the Quanitya sentinel — it has its own dedicated row
    final userConfigs = state.configs
        .where((c) => c.provider != LlmProvider.quanitya)
        .toList();

    final configRows = userConfigs.map((config) {
      final isTested = state.availableModels
          .any((m) => m.id == config.modelId && m.tested);
      return Padding(
        padding: AppPadding.verticalSingle,
        child: _ConfigRow(
          config: config,
          isActive: config.id == state.activeConfig?.id,
          isTested: isTested,
          onTap: () =>
              context.read<LlmProviderCubit>().selectConfig(config.id),
          onEdit: () => _showConfigSheet(context, config),
        ),
      );
    }).toList();

    if (isQuanityaActive) {
      return [quanityaRow, ...configRows];
    } else {
      if (configRows.isNotEmpty) {
        return [configRows.first, quanityaRow, ...configRows.skip(1)];
      }
      return [quanityaRow];
    }
  }

  void _showConfigSheet(
    BuildContext context,
    LlmProviderConfigModel? config, {
    String? defaultBaseUrl,
    LlmProvider provider = LlmProvider.openRouter,
  }) {
    LlmConfigSheet.show(
      context: context,
      cubit: context.read<LlmProviderCubit>(),
      config: config,
      defaultBaseUrl: defaultBaseUrl,
      provider: provider,
    );
  }
}

class _QuanityaProviderRow extends StatelessWidget {
  final bool isActive;
  final VoidCallback onTap;

  const _QuanityaProviderRow({
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Quanitya LLM',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
        child: Container(
          padding: AppPadding.allDouble,
          decoration: BoxDecoration(
            color: context.colors.textSecondary.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
          ),
          child: Row(
            children: [
              Image.asset(
                'assets/quanitya.png',
                width: AppSizes.iconMedium,
                height: AppSizes.iconMedium,
                color: isActive
                    ? context.colors.textPrimary
                    : context.colors.interactableColor,
              ),
              HSpace.x2,
              Expanded(
                child: Text(
                  'Quanitya LLM',
                  style: context.text.bodyLarge?.copyWith(
                    color: context.colors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConfigRow extends StatelessWidget {
  final LlmProviderConfigModel config;
  final bool isActive;
  final bool isTested;
  final VoidCallback onTap;
  final VoidCallback onEdit;

  const _ConfigRow({
    required this.config,
    required this.isActive,
    required this.isTested,
    required this.onTap,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final displayUrl = switch (config.provider) {
      LlmProvider.quanitya => 'Quanitya',
      LlmProvider.openRouter => 'openrouter.ai',
      LlmProvider.ollama =>
        config.baseUrl.replaceAll('http://', '').replaceAll('/v1', ''),
    };

    return Semantics(
      button: true,
      label: '$displayUrl — ${config.modelId}',
      child: InkWell(
        onTap: onTap,
        onLongPress: onEdit,
        borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
        child: Container(
        padding: AppPadding.allDouble,
        decoration: BoxDecoration(
          color: context.colors.textSecondary.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
        ),
        child: Row(
          children: [
            Icon(
              config.provider == LlmProvider.openRouter
                  ? Icons.cloud
                  : Icons.computer,
              size: AppSizes.iconMedium,
              color: isActive
                  ? context.colors.textPrimary
                  : context.colors.interactableColor,
            ),
            HSpace.x2,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text.rich(
                    TextSpan(
                      text: '$displayUrl — ${config.modelId}',
                      children: [
                        if (isTested)
                          TextSpan(
                            text: ' (Quanitya Tested)',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                      ],
                    ),
                    style: context.text.bodyLarge?.copyWith(
                      color: context.colors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }
}
