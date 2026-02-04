import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/intl.dart';

import '../../../../app_router.dart';
import '../../../../support/extensions/context_extensions.dart';
import '../../../../design_system/widgets/ui_flow_listener.dart';
import '../../../../design_system/primitives/app_sizes.dart';
import '../../../../design_system/primitives/app_spacings.dart';
import '../../../../design_system/primitives/quanitya_palette.dart';
import '../../../../design_system/primitives/quanitya_fonts.dart';
import '../../../../design_system/widgets/quanitya_icon_button.dart';
import '../../../design_system/widgets/quanitya/general/quanitya_text_button.dart';
import '../../../../data/repositories/template_with_aesthetics_repository.dart';
import '../../../../infrastructure/webhooks/models/api_key_model.dart';
import '../../../../infrastructure/webhooks/models/webhook_model.dart';
import '../../app_operating_mode/cubits/app_operating_cubit.dart';
import '../cubits/data_export/data_export_cubit.dart';
import '../cubits/data_export/data_export_state.dart';
import '../cubits/data_export/data_export_message_mapper.dart';
import '../cubits/recovery_key/recovery_key_cubit.dart';
import '../cubits/recovery_key/recovery_key_state.dart';
import '../cubits/recovery_key/recovery_key_message_mapper.dart';
import '../cubits/device_management/device_management_cubit.dart';
import '../cubits/webhook/webhook_cubit.dart';
import '../cubits/webhook/webhook_state.dart';
import '../cubits/webhook/webhook_message_mapper.dart';
import '../widgets/import_recovery_key_dialog.dart';
import '../widgets/device_list_section.dart';
import '../widgets/webhook_dialog.dart';
import '../widgets/api_key_dialog.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => GetIt.instance<DataExportCubit>()),
        BlocProvider(create: (_) => GetIt.instance<RecoveryKeyCubit>()),
        BlocProvider(create: (_) => GetIt.instance<DeviceManagementCubit>()),
        BlocProvider(create: (_) => GetIt.instance<WebhookCubit>()..load()),
        BlocProvider.value(value: GetIt.instance<AppOperatingCubit>()),
      ],
      child: const SettingsView(),
    );
  }
}

class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    return UiFlowListener<DataExportCubit, DataExportState>(
      mapper: GetIt.instance<DataExportMessageMapper>(),
      child: UiFlowListener<RecoveryKeyCubit, RecoveryKeyState>(
        mapper: GetIt.instance<RecoveryKeyMessageMapper>(),
        child: UiFlowListener<WebhookCubit, WebhookState>(
          mapper: GetIt.instance<WebhookMessageMapper>(),
          child: Scaffold(
            appBar: AppBar(
              title: Text(
                context.l10n.settingsTitle,
                style: context.text.headlineMedium,
              ),
              leading: QuanityaIconButton(
                icon: Icons.arrow_back,
                onPressed: () => AppNavigation.back(context),
              ),
              actions: [
                QuanityaIconButton(
                  icon: Icons.info,
                  onPressed: () => AppNavigation.toAppInfo(context),
                ),
              ],
            ),
            body: Padding(
              padding: AppPadding.page,
              child: _SettingsContent(),
            ),
          ),
        ),
      ),
    );
  }
}

class _SettingsContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        const DeviceListSection(),
        VSpace.x4,

        QuanityaTextButton(
          text: context.l10n.exportData,
          onPressed: () => context.read<DataExportCubit>().exportData(),
        ),
        VSpace.x3,

        QuanityaTextButton(
          text: context.l10n.importRecoveryKey,
          onPressed: () => _showImportRecoveryKeyDialog(context),
        ),
        VSpace.x3,

        QuanityaTextButton(
          text: 'Error Reports',
          onPressed: () => AppNavigation.toErrorBox(context),
        ),
        VSpace.x3,

        QuanityaTextButton(
          text: 'Send Feedback',
          onPressed: () => AppNavigation.toFeedback(context),
        ),
        VSpace.x4,

        const _ApiKeysSection(),
        VSpace.x4,

        const _WebhooksSection(),
        VSpace.x2,
      ],
    );
  }

  void _showImportRecoveryKeyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => BlocProvider.value(
        value: context.read<RecoveryKeyCubit>(),
        child: const ImportRecoveryKeyDialog(),
      ),
    );
  }
}

/// API Keys section
class _ApiKeysSection extends StatelessWidget {
  const _ApiKeysSection();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WebhookCubit, WebhookState>(
      builder: (context, state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.l10n.apiKeysTitle.toUpperCase(),
              style: context.text.titleMedium?.copyWith(
                color: context.colors.textPrimary,
              ),
            ),
            VSpace.x1,
            Text(
              context.l10n.apiKeysDescription,
              style: context.text.bodyMedium?.copyWith(
                color: context.colors.textSecondary,
              ),
            ),
            VSpace.x3,

            ...state.apiKeys.map((apiKey) => Padding(
              padding: EdgeInsets.only(bottom: AppSizes.space * 2),
              child: _ApiKeyRow(
                apiKey: apiKey,
                onTap: () => _showApiKeyDialog(context, apiKey),
              ),
            )),

            Center(
              child: QuanityaTextButton(
                text: context.l10n.addApiKey,
                onPressed: () => _showApiKeyDialog(context, null),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showApiKeyDialog(BuildContext context, ApiKeyModel? apiKey) {
    showDialog(
      context: context,
      builder: (_) => BlocProvider.value(
        value: context.read<WebhookCubit>(),
        child: ApiKeyDialog(apiKey: apiKey),
      ),
    );
  }
}

class _ApiKeyRow extends StatelessWidget {
  final ApiKeyModel apiKey;
  final VoidCallback onTap;

  const _ApiKeyRow({required this.apiKey, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final typeLabel = apiKey.authType == AuthType.bearer
        ? context.l10n.apiKeyTypeBearer
        : '${context.l10n.apiKeyTypeHeader}: ${apiKey.headerName}';

    return InkWell(
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
            Icon(
              apiKey.authType == AuthType.bearer ? Icons.vpn_key : Icons.code,
              size: AppSizes.iconMedium,
              color: context.colors.interactableColor,
            ),
            HSpace.x2,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    apiKey.name,
                    style: context.text.bodyLarge?.copyWith(
                      color: context.colors.textPrimary,
                    ),
                  ),
                  VSpace.x025,
                  Text(
                    typeLabel,
                    style: context.text.bodySmall?.copyWith(
                      color: context.colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.check_circle,
              size: AppSizes.iconSmall,
              color: context.colors.successColor,
            ),
            HSpace.x1,
            Text(
              context.l10n.apiKeyConfigured,
              style: context.text.bodySmall?.copyWith(
                color: context.colors.successColor,
              ),
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

/// Webhooks section
class _WebhooksSection extends StatefulWidget {
  const _WebhooksSection();

  @override
  State<_WebhooksSection> createState() => _WebhooksSectionState();
}

class _WebhooksSectionState extends State<_WebhooksSection> {
  List<TemplateWithAesthetics>? _templates;

  @override
  void initState() {
    super.initState();
    _loadTemplates();
  }

  Future<void> _loadTemplates() async {
    final repo = GetIt.instance<TemplateWithAestheticsRepository>();
    final templates = await repo.find(isArchived: false);
    if (mounted) {
      setState(() => _templates = templates);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WebhookCubit, WebhookState>(
      builder: (context, state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.l10n.webhooksTitle.toUpperCase(),
              style: context.text.titleMedium?.copyWith(
                color: context.colors.textPrimary,
              ),
            ),
            VSpace.x1,
            Text(
              context.l10n.webhooksDescription,
              style: context.text.bodyMedium?.copyWith(
                color: context.colors.textSecondary,
              ),
            ),
            VSpace.x3,

            ...state.webhooks.map((webhook) {
              final templateName = _templates
                  ?.firstWhere(
                    (t) => t.template.id == webhook.templateId,
                    orElse: () => TemplateWithAesthetics(
                      template: _templates!.first.template.copyWith(name: 'Unknown'),
                      aesthetics: _templates!.first.aesthetics,
                    ),
                  )
                  .template
                  .name ?? 'Unknown';
              
              return Padding(
                padding: EdgeInsets.only(bottom: AppSizes.space * 2),
                child: _WebhookRow(
                  webhook: webhook,
                  templateName: templateName,
                  onTap: () => _showWebhookDialog(context, webhook),
                  onRetry: () => context.read<WebhookCubit>().retryWebhook(webhook.id),
                  onToggle: (enabled) => context.read<WebhookCubit>().toggleWebhook(webhook.id, enabled),
                ),
              );
            }),

            Center(
              child: QuanityaTextButton(
                text: context.l10n.addWebhook,
                onPressed: _templates != null && _templates!.isNotEmpty
                    ? () => _showWebhookDialog(context, null)
                    : null,
              ),
            ),
          ],
        );
      },
    );
  }

  void _showWebhookDialog(BuildContext context, WebhookModel? webhook) {
    if (_templates == null) return;
    
    showDialog(
      context: context,
      builder: (_) => BlocProvider.value(
        value: context.read<WebhookCubit>(),
        child: WebhookDialog(
          webhook: webhook,
          templates: _templates!.map((t) => t.template).toList(),
        ),
      ),
    );
  }
}

class _WebhookRow extends StatelessWidget {
  final WebhookModel webhook;
  final String templateName;
  final VoidCallback onTap;
  final VoidCallback onRetry;
  final ValueChanged<bool> onToggle;

  const _WebhookRow({
    required this.webhook,
    required this.templateName,
    required this.onTap,
    required this.onRetry,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final displayUrl = webhook.url.length > 35 
        ? '${webhook.url.substring(0, 35)}...' 
        : webhook.url;
    
    final lastTriggered = webhook.lastTriggeredAt != null
        ? DateFormat.yMd().add_jm().format(webhook.lastTriggeredAt!)
        : context.l10n.webhookNeverTriggered;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
      child: Container(
        padding: AppPadding.allDouble,
        decoration: BoxDecoration(
          color: context.colors.textSecondary.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.webhook,
                  size: AppSizes.iconMedium,
                  color: webhook.isEnabled 
                      ? context.colors.interactableColor 
                      : context.colors.textSecondary,
                ),
                HSpace.x2,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        webhook.name,
                        style: context.text.bodyLarge?.copyWith(
                          color: context.colors.textPrimary,
                        ),
                      ),
                      VSpace.x025,
                      Text(
                        templateName,
                        style: context.text.bodySmall?.copyWith(
                          color: context.colors.interactableColor,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: webhook.isEnabled,
                  onChanged: onToggle,
                  activeThumbColor: context.colors.successColor,
                ),
              ],
            ),
            VSpace.x2,
            Text(
              displayUrl,
              style: context.text.bodySmall?.copyWith(
                color: context.colors.textSecondary,
                fontFamily: QuanityaFonts.bodyFamily,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            VSpace.x1,
            Row(
              children: [
                Text(
                  '${context.l10n.webhookLastTriggered}: $lastTriggered',
                  style: context.text.bodySmall?.copyWith(
                    color: context.colors.textSecondary,
                  ),
                ),
                const Spacer(),
                QuanityaTextButton(
                  text: context.l10n.webhookRetry,
                  onPressed: webhook.isEnabled ? onRetry : null,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
