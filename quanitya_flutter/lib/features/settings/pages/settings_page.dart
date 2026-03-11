import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:quanitya_cloud_client/quanitya_cloud_client.dart' as cloud;

import '../../../../app_router.dart';
import '../../../../support/extensions/context_extensions.dart';
import '../../../../design_system/widgets/ui_flow_listener.dart';
import '../../../../design_system/primitives/app_sizes.dart';
import '../../../../design_system/primitives/app_spacings.dart';
import '../../../../design_system/primitives/quanitya_palette.dart';
import '../../../../design_system/primitives/quanitya_fonts.dart';
import '../../../../design_system/widgets/quanitya_icon_button.dart';
import '../../../../design_system/widgets/quanitya/general/notebook_fold.dart';
import '../../../design_system/widgets/quanitya/general/quanitya_text_button.dart';
import '../../../design_system/widgets/quanitya/generatable/quanitya_toggle.dart';
import '../../../../data/repositories/template_with_aesthetics_repository.dart';
import '../../../../infrastructure/crypto/crypto_key_repository.dart';
import '../../../../infrastructure/webhooks/models/api_key_model.dart';
import '../../../../infrastructure/webhooks/models/webhook_model.dart';
import '../../../design_system/widgets/quanitya_confirmation_dialog.dart';
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
import '../widgets/import_recovery_key_sheet.dart';
import '../widgets/device_list_section.dart';
import '../widgets/webhook_sheet.dart';
import '../cubits/llm_provider/llm_provider_cubit.dart';
import '../cubits/llm_provider/llm_provider_state.dart';
import '../cubits/llm_provider/llm_provider_message_mapper.dart';
import '../widgets/llm_provider_section.dart';
import '../widgets/api_key_sheet.dart';
import '../widgets/table_selection_sheet.dart';

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
        BlocProvider(create: (_) => GetIt.instance<LlmProviderCubit>()..load()),
        BlocProvider.value(value: GetIt.instance<AppOperatingCubit>()),
      ],
      child: const SettingsView(),
    );
  }
}

/// Standalone page with Scaffold — used for deep-link / push navigation.
class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    return UiFlowListener<LlmProviderCubit, LlmProviderState>(
      mapper: GetIt.instance<LlmProviderMessageMapper>(),
      child: UiFlowListener<DataExportCubit, DataExportState>(
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
              body: const SettingsContent(),
            ),
          ),
        ),
      ),
    );
  }
}

/// The content body, usable standalone or embedded in [NotebookShell].
///
/// Expects [DataExportCubit], [RecoveryKeyCubit], [DeviceManagementCubit],
/// [WebhookCubit], and [AppOperatingCubit] to be available above.
class SettingsContent extends StatelessWidget {
  const SettingsContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: AppPadding.page,
      child: ListView(
        children: [
          NotebookFold(
            header: Row(children: [
              Icon(Icons.devices, size: AppSizes.iconMedium, color: context.colors.textPrimary),
              HSpace.x2,
              Text(context.l10n.settingsDevicesSection, style: context.text.titleMedium),
            ]),
            child: const DeviceListSection(),
          ),
          VSpace.x3,

          NotebookFold(
            header: Row(children: [
              Icon(Icons.import_export, size: AppSizes.iconMedium, color: context.colors.textPrimary),
              HSpace.x2,
              Text(context.l10n.settingsDataSection, style: context.text.titleMedium),
            ]),
            child: _DataSection(),
          ),
          VSpace.x3,

          NotebookFold(
            header: Row(children: [
              Icon(Icons.smart_toy, size: AppSizes.iconMedium, color: context.colors.textPrimary),
              HSpace.x2,
              Text(context.l10n.settingsLlmSection, style: context.text.titleMedium),
            ]),
            child: const LlmProviderSection(),
          ),
          VSpace.x3,

          NotebookFold(
            header: Row(children: [
              Icon(Icons.vpn_key, size: AppSizes.iconMedium, color: context.colors.textPrimary),
              HSpace.x2,
              Text(context.l10n.apiKeysTitle, style: context.text.titleMedium),
            ]),
            child: const _ApiKeysSection(),
          ),
          VSpace.x3,

          NotebookFold(
            header: Row(children: [
              Icon(Icons.webhook, size: AppSizes.iconMedium, color: context.colors.textPrimary),
              HSpace.x2,
              Text(context.l10n.webhooksTitle, style: context.text.titleMedium),
            ]),
            child: const _WebhooksSection(),
          ),
          VSpace.x3,

          NotebookFold(
            header: Row(children: [
              Icon(Icons.shopping_bag, size: AppSizes.iconMedium, color: context.colors.textPrimary),
              HSpace.x2,
              Text(context.l10n.settingsPurchase, style: context.text.titleMedium),
            ]),
            child: Center(
              child: QuanityaTextButton(
                text: context.l10n.settingsPurchase,
                onPressed: () => AppNavigation.toPurchase(context),
              ),
            ),
          ),
          VSpace.x3,

          NotebookFold(
            header: Row(children: [
              Icon(Icons.delete_forever, size: AppSizes.iconMedium, color: context.colors.destructiveColor),
              HSpace.x2,
              Text(context.l10n.deleteAccountTitle, style: context.text.titleMedium?.copyWith(
                color: context.colors.destructiveColor,
              )),
            ]),
            child: const _DeleteAccountButton(),
          ),
          VSpace.x2,
        ],
      ),
    );
  }
}

class _DataSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        QuanityaTextButton(
          text: context.l10n.exportData,
          onPressed: () => _startExport(context),
        ),
        VSpace.x3,
        QuanityaTextButton(
          text: context.l10n.importData,
          onPressed: () => _startImport(context),
        ),
        VSpace.x3,
        QuanityaTextButton(
          text: context.l10n.importRecoveryKey,
          onPressed: () => _showImportRecoveryKeyDialog(context),
        ),
      ],
    );
  }

  Future<void> _startExport(BuildContext context) async {
    final cubit = context.read<DataExportCubit>();
    final tableNames = cubit.getExportableTableNames();

    final selected = await TableSelectionSheet.show(
      context,
      tableNames: tableNames,
      title: context.l10n.selectTablesTitle,
      confirmButtonText: context.l10n.selectTablesExportButton,
    );

    if (selected == null || !context.mounted) return;
    cubit.exportData(selected);
  }

  Future<void> _startImport(BuildContext context) async {
    final cubit = context.read<DataExportCubit>();

    // 1. Pick file and get available table names.
    final availableTables = await cubit.pickImportFile();
    if (availableTables == null || !context.mounted) return;

    // 2. Let user select which tables to import.
    final selected = await TableSelectionSheet.show(
      context,
      tableNames: availableTables,
      title: context.l10n.selectTablesTitle,
      confirmButtonText: context.l10n.selectTablesImportButton,
    );
    if (selected == null || !context.mounted) return;

    // 3. Confirm destructive operation.
    final confirmed = await QuanityaConfirmationDialog.show(
      context: context,
      title: context.l10n.importDataConfirmTitle,
      message: context.l10n.importDataConfirmMessage,
      confirmText: context.l10n.importDataConfirmButton,
      isDestructive: true,
      onConfirm: () {},
    );
    if (confirmed != true || !context.mounted) return;

    // 4. Execute import.
    cubit.importData(selected);
  }

  void _showImportRecoveryKeyDialog(BuildContext context) {
    ImportRecoveryKeySheet.show(
      context: context,
      cubit: context.read<RecoveryKeyCubit>(),
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
              padding: AppPadding.verticalSingle,
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
    ApiKeySheet.show(
      context: context,
      cubit: context.read<WebhookCubit>(),
      apiKey: apiKey,
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
              color: context.colors.textPrimary,
            ),
            HSpace.x2,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    apiKey.name,
                    style: context.text.bodyLarge?.copyWith(
                      color: context.colors.interactableColor,
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
              Icons.chevron_right,
              size: AppSizes.iconSmall,
              color: context.colors.interactableColor,
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
  bool _templateLoadFailed = false;

  @override
  void initState() {
    super.initState();
    _loadTemplates();
  }

  Future<void> _loadTemplates() async {
    try {
      final repo = GetIt.instance<TemplateWithAestheticsRepository>();
      final templates = await repo.find(isArchived: false);
      if (mounted) {
        setState(() {
          _templates = templates;
          _templateLoadFailed = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _templateLoadFailed = true);
      }
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
              final match = _templates?.cast<TemplateWithAesthetics?>().firstWhere(
                    (t) => t!.template.id == webhook.templateId,
                    orElse: () => null,
                  );
              final templateName = match?.template.name ?? 'Unknown';
              
              return Padding(
                padding: AppPadding.verticalSingle,
                child: _WebhookRow(
                  webhook: webhook,
                  templateName: templateName,
                  onTap: () => _showWebhookDialog(context, webhook),
                  onRetry: () => context.read<WebhookCubit>().retryWebhook(webhook.id),
                  onToggle: (enabled) => context.read<WebhookCubit>().toggleWebhook(webhook.id, enabled),
                ),
              );
            }),

            if (_templateLoadFailed)
              Center(
                child: QuanityaTextButton(
                  text: context.l10n.addWebhook,
                  onPressed: _loadTemplates,
                ),
              )
            else if (_templates == null)
              Center(
                child: Padding(
                  padding: AppPadding.allDouble,
                  child: SizedBox(
                    width: AppSizes.iconMedium,
                    height: AppSizes.iconMedium,
                    child: const CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              )
            else
              Center(
                child: QuanityaTextButton(
                  text: context.l10n.addWebhook,
                  onPressed: _templates!.isNotEmpty
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

    WebhookSheet.show(
      context: context,
      cubit: context.read<WebhookCubit>(),
      templates: _templates!.map((t) => t.template).toList(),
      webhook: webhook,
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
                          color: context.colors.interactableColor,
                        ),
                      ),
                      VSpace.x025,
                      Text(
                        templateName,
                        style: context.text.bodySmall?.copyWith(
                          color: context.colors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                QuanityaToggle(
                  value: webhook.isEnabled,
                  onChanged: onToggle,
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

class _DeleteAccountButton extends StatefulWidget {
  const _DeleteAccountButton();

  @override
  State<_DeleteAccountButton> createState() => _DeleteAccountButtonState();
}

class _DeleteAccountButtonState extends State<_DeleteAccountButton> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Center(
      child: QuanityaTextButton(
        text: context.l10n.deleteAccountTitle,
        isDestructive: true,
        onPressed: () => _confirmDelete(context),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final goRouter = GoRouter.of(context);

    QuanityaConfirmationDialog.show(
      context: context,
      title: context.l10n.deleteAccountTitle,
      message: context.l10n.deleteAccountMessage,
      confirmText: context.l10n.deleteAccountConfirm,
      isDestructive: true,
      onConfirm: () async {
        if (!mounted) return;
        setState(() => _isLoading = true);

        try {
          // Delete server-side data if client is available
          if (GetIt.instance.isRegistered<cloud.Client>()) {
            try {
              final client = GetIt.instance<cloud.Client>();
              await client.accountDeletion.deleteAccount();
            } catch (_) {
              // Server deletion may fail if offline or local-only mode.
              // Still proceed with local wipe so the user can reset.
            }
          }

          // Wipe local keys (this also clears secure storage)
          final keyRepo = GetIt.instance<ICryptoKeyRepository>();
          await keyRepo.clearKeys();

          AppRouter.resetKeyCheck();

          if (mounted) {
            goRouter.goNamed(RouteNames.onboarding);
          }
        } finally {
          if (mounted) setState(() => _isLoading = false);
        }
      },
    );
  }
}
