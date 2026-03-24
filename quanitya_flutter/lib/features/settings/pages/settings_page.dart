import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:quanitya_flutter/design_system/primitives/quanitya_date_format.dart';

import '../../../../infrastructure/auth/delete_service.dart';
import '../../../../support/extensions/context_extensions.dart';
import '../../../../design_system/primitives/app_sizes.dart';
import '../../../../design_system/primitives/app_spacings.dart';
import '../../../../design_system/primitives/quanitya_palette.dart';
import '../../../../design_system/primitives/quanitya_fonts.dart';
import '../../../../design_system/widgets/quanitya/general/notebook_fold.dart';
import '../../../design_system/widgets/quanitya/general/quanitya_text_button.dart';
import '../../../design_system/widgets/quanitya/generatable/quanitya_toggle.dart';
import '../../guided_tour/guided_tour_service.dart';
import '../../sync_status/widgets/sync_status_indicator.dart';
import '../../../../data/repositories/template_with_aesthetics_repository.dart';
import '../../../../infrastructure/webhooks/models/api_key_model.dart';
import '../../../../infrastructure/webhooks/models/webhook_model.dart';
import '../../../design_system/widgets/quanitya_confirmation_dialog.dart';
import '../../../design_system/widgets/quanitya/general/post_it_toast.dart';
import '../../app_syncing_mode/cubits/app_syncing_cubit.dart';
import '../cubits/data_export/data_export_cubit.dart';
import '../cubits/recovery_key/recovery_key_cubit.dart';
import '../cubits/device_management/device_management_cubit.dart';
import '../cubits/webhook/webhook_cubit.dart';
import '../cubits/webhook/webhook_state.dart';
import '../widgets/import_recovery_key_sheet.dart';
import '../widgets/device_list_section.dart';
import '../widgets/webhook_sheet.dart';
import '../widgets/llm_provider_section.dart';
import '../widgets/api_key_sheet.dart';
import '../widgets/table_selection_sheet.dart';
import 'package:cubit_ui_flow/cubit_ui_flow.dart';
import '../../../integrations/flutter/health/health_sync_cubit.dart';
import '../../../integrations/flutter/health/health_sync_service.dart'
    show defaultHealthTypes;
import '../../../integrations/flutter/health/health_sync_state.dart';

bool get _supportsHealthData => !kIsWeb && (Platform.isIOS || Platform.isAndroid);

/// Settings content — embedded in [NotebookShell] via OfficePage.
///
/// Expects [DataExportCubit], [RecoveryKeyCubit], [DeviceManagementCubit],
/// [WebhookCubit], and [AppSyncingCubit] to be available above.
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
              Icon(Icons.person_outline, size: AppSizes.iconMedium, color: context.colors.textPrimary),
              HSpace.x2,
              Text(context.l10n.settingsAccountSection, style: context.text.titleMedium),
            ]),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SyncStatusIndicator(),
                VSpace.x2,
                const DeviceListSection(),
                VSpace.x3,
                QuanityaTextButton(
                  text: context.l10n.validateRecoveryKey,
                  onPressed: () => _showValidateRecoveryKeyDialog(context),
                ),
              ],
            ),
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

          if (_supportsHealthData) ...[
            NotebookFold(
              header: Row(children: [
                Icon(Icons.monitor_heart, size: AppSizes.iconMedium, color: context.colors.textPrimary),
                HSpace.x2,
                Text(context.l10n.settingsHealthData, style: context.text.titleMedium),
              ]),
              child: const _HealthConnectSection(),
            ),
            VSpace.x3,
          ],

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
              Icon(Icons.school_outlined, size: AppSizes.iconMedium, color: context.colors.textPrimary),
              HSpace.x2,
              Text(context.l10n.settingsTutorialSection, style: context.text.titleMedium),
            ]),
            child: const _TutorialSection(),
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

void _showValidateRecoveryKeyDialog(BuildContext context) {
  ImportRecoveryKeySheet.show(
    context: context,
    cubit: context.read<RecoveryKeyCubit>(),
  );
}

class _TutorialSection extends StatefulWidget {
  const _TutorialSection();

  @override
  State<_TutorialSection> createState() => _TutorialSectionState();
}

class _TutorialSectionState extends State<_TutorialSection> {
  bool _showTours = false;

  @override
  void initState() {
    super.initState();
    _loadState();
  }

  Future<void> _loadState() async {
    final tourService = GetIt.instance<GuidedTourService>();
    final shouldShow = await tourService.shouldShowTour(GuidedTourService.homeKey);
    if (mounted) setState(() => _showTours = shouldShow);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            context.l10n.settingsShowTour,
            style: context.text.bodyMedium,
          ),
        ),
        QuanityaToggle(
          value: _showTours,
          onChanged: (enabled) async {
            final tourService = GetIt.instance<GuidedTourService>();
            if (enabled) {
              await tourService.resetAllTours();
            } else {
              await tourService.markTourSeen(GuidedTourService.homeKey);
              await tourService.markTourSeen(GuidedTourService.designerKey);
            }
            if (mounted) setState(() => _showTours = enabled);
          },
        ),
      ],
    );
  }
}

class _HealthConnectSection extends StatelessWidget {
  const _HealthConnectSection();

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) {
        final cubit = GetIt.instance<HealthSyncCubit>();
        cubit.loadEnabled();
        return cubit;
      },
      child: BlocBuilder<HealthSyncCubit, HealthSyncState>(
        builder: (context, state) {
          final cubit = context.read<HealthSyncCubit>();
          final isLoading = state.status == UiFlowStatus.loading;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      context.l10n.healthImportData,
                      style: context.text.bodyMedium,
                    ),
                  ),
                  if (isLoading)
                    SizedBox(
                      width: AppSizes.iconSmall,
                      height: AppSizes.iconSmall,
                      child: CircularProgressIndicator(strokeWidth: AppSizes.borderWidthThick),
                    )
                  else
                    QuanityaToggle(
                      value: state.enabled,
                      onChanged: (enabled) => cubit.toggle(enabled, defaultHealthTypes),
                    ),
                ],
              ),
              if (state.lastImportCount > 0) ...[
                VSpace.x2,
                Text(
                  context.l10n.healthEntriesImported(state.lastImportCount),
                  style: context.text.bodySmall?.copyWith(
                    color: context.colors.textSecondary,
                  ),
                ),
              ],
              if (state.status == UiFlowStatus.failure && state.error != null) ...[
                VSpace.x2,
                Text(
                  state.error.toString(),
                  style: context.text.bodySmall?.copyWith(
                    color: context.colors.errorColor,
                  ),
                ),
              ],
            ],
          );
        },
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
    await cubit.pickImportFile();
    if (!context.mounted) return;
    final availableTables = cubit.state.pickedTableNames;
    if (availableTables.isEmpty || cubit.state.status == UiFlowStatus.failure) return;

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

    return Semantics(
      button: true,
      label: context.l10n.settingsEditApiKey(apiKey.name),
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
              final match = _templates?.where(
                    (t) => t.template.id == webhook.templateId,
                  ).firstOrNull;
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
                    child: CircularProgressIndicator(strokeWidth: AppSizes.borderWidthThick),
                  ),
                ),
              )
            else ...[
              Center(
                child: QuanityaTextButton(
                  text: context.l10n.addWebhook,
                  onPressed: _templates!.isNotEmpty
                      ? () => _showWebhookDialog(context, null)
                      : null,
                ),
              ),
              if (_templates!.isEmpty) ...[
                VSpace.x1,
                Center(
                  child: Text(
                    context.l10n.webhooksCreateTemplateFirst,
                    style: context.text.bodySmall?.copyWith(
                      color: context.colors.textSecondary,
                    ),
                  ),
                ),
              ],
            ],
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
        ? QuanityaDateFormat.timestamp(webhook.lastTriggeredAt!)
        : context.l10n.webhookNeverTriggered;

    return Semantics(
      button: true,
      label: context.l10n.settingsEditWebhook,
      child: InkWell(
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
          // Delete server-side account and clean up all local state
          await GetIt.instance<DeleteService>().deleteAccount();

          // Switch back to local mode (UI state — not owned by DeleteService)
          if (GetIt.instance.isRegistered<AppSyncingCubit>()) {
            await GetIt.instance<AppSyncingCubit>().switchToLocal();
          }

          if (mounted) {
            PostItToast.show(
              context,
              message: context.l10n.deleteAccountSuccess,
              type: PostItType.info,
            );
          }
        } catch (e) {
          if (mounted) {
            PostItToast.show(
              context,
              message: context.l10n.deleteAccountFailed,
              type: PostItType.error,
            );
          }
        } finally {
          if (mounted) setState(() => _isLoading = false);
        }
      },
    );
  }
}
