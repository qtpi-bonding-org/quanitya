import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

import '../../../design_system/primitives/quanitya_palette.dart';
import '../../../design_system/widgets/swipeable_page_shell.dart';
import '../../../design_system/widgets/multi_ui_flow_listener.dart';
import '../../../design_system/widgets/ui_flow_listener.dart';
import '../../../support/extensions/context_extensions.dart';
import '../../../l10n/app_localizations.dart';
// Settings cubits
import '../../settings/cubits/data_export/data_export_cubit.dart';
import '../../settings/cubits/data_export/data_export_state.dart';
import '../../settings/cubits/data_export/data_export_message_mapper.dart';
import '../../settings/cubits/recovery_key/recovery_key_cubit.dart';
import '../../settings/cubits/recovery_key/recovery_key_state.dart';
import '../../settings/cubits/recovery_key/recovery_key_message_mapper.dart';
import '../../settings/cubits/device_management/device_management_cubit.dart';
import '../../settings/cubits/webhook/webhook_cubit.dart';
import '../../settings/cubits/webhook/webhook_state.dart';
import '../../settings/cubits/webhook/webhook_message_mapper.dart';
import '../../settings/cubits/llm_provider/llm_provider_cubit.dart';
import '../../settings/cubits/llm_provider/llm_provider_state.dart';
import '../../settings/cubits/llm_provider/llm_provider_message_mapper.dart';
import '../../app_operating_mode/cubits/app_operating_cubit.dart';
import '../../settings/pages/settings_page.dart';
// Purchase cubits
import '../../purchase/cubits/purchase_cubit.dart';
import '../../purchase/cubits/purchase_state.dart';
import '../../purchase/cubits/purchase_message_mapper.dart';
import '../../purchase/cubits/entitlement_cubit.dart';
import '../../purchase/cubits/entitlement_state.dart';
import '../../purchase/cubits/entitlement_message_mapper.dart';
import '../../purchase/pages/purchase_page.dart';
// App info
import '../../settings/pages/app_info_page.dart';

/// Unified Office page with swipeable pages for Preferences, Purchases, and Info.
class OfficePage extends StatefulWidget {
  const OfficePage({super.key});

  @override
  State<OfficePage> createState() => _OfficePageState();
}

class _OfficePageState extends State<OfficePage> {
  int _currentIndex = 0;
  bool _purchasesLoaded = false;

  void _onPageChanged(BuildContext context, int index) {
    setState(() => _currentIndex = index);
    if (index == 1 && !_purchasesLoaded) {
      _purchasesLoaded = true;
      context.read<PurchaseCubit>().loadProducts();
      context.read<EntitlementCubit>()
        ..loadEntitlements()
        ..checkSyncAccess()
        ..loadStorageUsage();
    }
  }

  Widget _buildLabel(BuildContext context, String label, bool isActive) {
    final palette = QuanityaPalette.primary;
    return Text(
      label,
      style: context.text.bodySmall?.copyWith(
        fontWeight: isActive ? FontWeight.w900 : FontWeight.w500,
        color: isActive ? palette.textPrimary : palette.interactableColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => GetIt.instance<DataExportCubit>()),
        BlocProvider(create: (_) => GetIt.instance<RecoveryKeyCubit>()),
        BlocProvider(create: (_) => GetIt.instance<DeviceManagementCubit>()),
        BlocProvider(create: (_) => GetIt.instance<WebhookCubit>()..load()),
        BlocProvider(create: (_) => GetIt.instance<LlmProviderCubit>()..load()),
        BlocProvider.value(value: GetIt.instance<AppOperatingCubit>()),
        BlocProvider(create: (_) => GetIt.instance<PurchaseCubit>()),
        BlocProvider(create: (_) => GetIt.instance<EntitlementCubit>()),
      ],
      child: MultiUiFlowListener(
        listeners: [
          (child) => UiFlowListener<LlmProviderCubit, LlmProviderState>(
            mapper: GetIt.instance<LlmProviderMessageMapper>(),
            child: child,
          ),
          (child) => UiFlowListener<DataExportCubit, DataExportState>(
            mapper: GetIt.instance<DataExportMessageMapper>(),
            child: child,
          ),
          (child) => UiFlowListener<RecoveryKeyCubit, RecoveryKeyState>(
            mapper: GetIt.instance<RecoveryKeyMessageMapper>(),
            child: child,
          ),
          (child) => UiFlowListener<WebhookCubit, WebhookState>(
            mapper: GetIt.instance<WebhookMessageMapper>(),
            child: child,
          ),
          (child) => UiFlowListener<PurchaseCubit, PurchaseState>(
            mapper: GetIt.instance<PurchaseMessageMapper>(),
            child: child,
          ),
          (child) => UiFlowListener<EntitlementCubit, EntitlementState>(
            mapper: GetIt.instance<EntitlementMessageMapper>(),
            child: child,
          ),
        ],
        child: Builder(
          builder: (innerContext) => SwipeablePageShell(
            onPageChanged: (index) =>
                _onPageChanged(innerContext, index),
            pages: const [
              SettingsContent(),
              PurchaseTabContent(),
              AppInfoTabContent(),
            ],
            labels: [
              _buildLabel(
                  context, l10n.officeTabPreferences, _currentIndex == 0),
              _buildLabel(
                  context, l10n.officeTabPurchases, _currentIndex == 1),
              _buildLabel(
                  context, l10n.officeTabInfo, _currentIndex == 2),
            ],
          ),
        ),
      ),
    );
  }
}
