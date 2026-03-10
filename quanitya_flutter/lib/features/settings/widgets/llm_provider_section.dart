import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../design_system/primitives/app_sizes.dart';
import '../../../design_system/primitives/app_spacings.dart';
import '../../../design_system/primitives/quanitya_palette.dart';
import '../../../design_system/widgets/quanitya/general/quanitya_text_button.dart';
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

            if (state.configs.isEmpty)
              Text(
                context.l10n.llmProviderNoConfigsDescription,
                style: context.text.bodyMedium?.copyWith(
                  color: context.colors.textSecondary,
                ),
              )
            else
              ...state.configs.map((config) => Padding(
                    padding: AppPadding.verticalSingle,
                    child: _ConfigRow(
                      config: config,
                      isActive: config.id == state.activeConfig?.id,
                      onTap: () => context
                          .read<LlmProviderCubit>()
                          .selectConfig(config.id),
                      onEdit: () => _showConfigSheet(context, config),
                    ),
                  )),

            VSpace.x2,
            Center(
              child: QuanityaTextButton(
                text: context.l10n.llmProviderAddConfig,
                onPressed: () => _showConfigSheet(context, null),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showConfigSheet(BuildContext context, LlmProviderConfigModel? config) {
    LlmConfigSheet.show(
      context: context,
      cubit: context.read<LlmProviderCubit>(),
      config: config,
    );
  }
}

class _ConfigRow extends StatelessWidget {
  final LlmProviderConfigModel config;
  final bool isActive;
  final VoidCallback onTap;
  final VoidCallback onEdit;

  const _ConfigRow({
    required this.config,
    required this.isActive,
    required this.onTap,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final displayUrl = config.baseUrl.contains('openrouter')
        ? 'openrouter.ai'
        : config.baseUrl.replaceAll('http://', '').replaceAll('/v1', '');

    return InkWell(
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
              config.baseUrl.contains('openrouter')
                  ? Icons.cloud
                  : Icons.computer,
              size: AppSizes.iconMedium,
              color: isActive
                  ? context.colors.interactableColor
                  : context.colors.textSecondary,
            ),
            HSpace.x2,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$displayUrl — ${config.modelId}',
                    style: context.text.bodyLarge?.copyWith(
                      color: context.colors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            if (isActive)
              Icon(
                Icons.check_circle,
                size: AppSizes.iconSmall,
                color: context.colors.successColor,
              ),
            HSpace.x1,
            Icon(
              Icons.chevron_right,
              size: AppSizes.iconSmall,
              color: context.colors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}
