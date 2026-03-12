# Office Tab — Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Rename the Settings bottom nav tab to "Office" with 3 swipeable sub-tabs (Preferences, Purchases, Info), matching the Postage tab pattern.

**Architecture:** Create an `OfficePage` using the same swipeable `PageView` + `_PageLabel` pattern as `PostagePage`. Extract embeddable content widgets from `PurchasePage` and `AppInfoPage`. Move cubit providers into `OfficePage`. Remove the purchases NotebookFold from `SettingsContent` and the info icon from `SettingsView`.

**Tech Stack:** Flutter, BLoC/Cubit, GoRouter, l10n ARB

---

## File Structure

| Action | File | Responsibility |
|--------|------|----------------|
| Create | `lib/features/office/pages/office_page.dart` | OfficePage with PageView: Preferences, Purchases, Info sub-tabs |
| Modify | `lib/features/settings/pages/settings_page.dart` | Remove purchases NotebookFold from SettingsContent. Remove info icon from SettingsView. |
| Modify | `lib/features/purchase/pages/purchase_page.dart` | Extract `PurchaseTabContent` embeddable widget (no Scaffold) |
| Modify | `lib/features/settings/pages/app_info_page.dart` | Extract `AppInfoTabContent` embeddable widget (no Scaffold) |
| Modify | `lib/features/home/pages/notebook_shell.dart` | Replace Settings tab with Office tab, replace SettingsContent with OfficePage, move settings cubits into OfficePage |
| Modify | `lib/l10n/app_en.arb` | Add office/preferences l10n keys |
| Modify | `lib/app_router.dart` | Update settings route if needed |
| Keep | Standalone `SettingsPage`, `PurchasePage`, `AppInfoPage` | Keep working for deep-link / push navigation |

---

## Chunk 1: Extract Embeddable Content Widgets

### Task 1: Add l10n keys

**Files:**
- Modify: `lib/l10n/app_en.arb`

- [ ] **Step 1: Add English l10n keys**

Add near the existing settings/purchase keys:

```json
"officeTabPreferences": "Preferences",
"officeTabPurchases": "Purchases",
"officeTabInfo": "Info"
```

- [ ] **Step 2: Run `flutter gen-l10n`**

Run: `flutter gen-l10n`
Expected: Generates updated localization files

- [ ] **Step 3: Commit**

```bash
git add lib/l10n/app_en.arb
git commit -m "feat(l10n): add office tab keys"
```

---

### Task 2: Extract PurchaseTabContent from PurchasePage

**Files:**
- Modify: `lib/features/purchase/pages/purchase_page.dart`

The current `PurchasePage` wraps everything in a `MultiBlocProvider` + `Scaffold`. We need an embeddable content widget (no Scaffold, no BlocProviders — those will be provided by OfficePage).

- [ ] **Step 1: Extract PurchaseTabContent**

The current `_PurchaseView` has a Scaffold wrapping a `RefreshIndicator > ListView`. Extract the body content (everything inside the Scaffold body) into a new public `PurchaseTabContent` widget.

```dart
/// Embeddable purchase content — used in both standalone PurchasePage
/// and the unified OfficePage tab.
///
/// Expects [PurchaseCubit] and [EntitlementCubit] to be available via
/// [BlocProvider] above.
class PurchaseTabContent extends StatelessWidget {
  const PurchaseTabContent({super.key});

  @override
  Widget build(BuildContext context) {
    // Move the RefreshIndicator + ListView content from _PurchaseView here
    // Keep the _onBuy method as a static or move into widget
  }
}
```

The standalone `PurchasePage` and `_PurchaseView` stay working — `_PurchaseView` just uses `PurchaseTabContent` inside its Scaffold body.

Update `_PurchaseView`:
```dart
class _PurchaseView extends StatelessWidget {
  const _PurchaseView();

  @override
  Widget build(BuildContext context) {
    return UiFlowListener<PurchaseCubit, PurchaseState>(
      mapper: GetIt.instance<PurchaseMessageMapper>(),
      child: UiFlowListener<EntitlementCubit, EntitlementState>(
        mapper: GetIt.instance<EntitlementMessageMapper>(),
        child: Scaffold(
          appBar: AppBar(title: Text(context.l10n.purchaseTitle)),
          body: const PurchaseTabContent(),
        ),
      ),
    );
  }
}
```

Note: The `_onBuy` method needs to move into `PurchaseTabContent` since it references `context.read<PurchaseCubit>()`. Make it a private method of `PurchaseTabContent`.

Note: `_ProductSections` and `_PeriodColumn` are private widgets in the same file — they stay as-is since `PurchaseTabContent` is in the same file.

- [ ] **Step 2: Verify standalone PurchasePage still works**

Run: `dart analyze lib/features/purchase/pages/purchase_page.dart`
Expected: No issues

- [ ] **Step 3: Commit**

```bash
git add lib/features/purchase/pages/purchase_page.dart
git commit -m "refactor: extract PurchaseTabContent for embedding in OfficePage"
```

---

### Task 3: Extract AppInfoTabContent from AppInfoPage

**Files:**
- Modify: `lib/features/settings/pages/app_info_page.dart`

Similar extraction — pull out the body content into an embeddable widget.

- [ ] **Step 1: Extract AppInfoTabContent**

```dart
/// Embeddable app info content — used in both standalone AppInfoPage
/// and the unified OfficePage tab.
class AppInfoTabContent extends StatelessWidget {
  const AppInfoTabContent({super.key});

  @override
  Widget build(BuildContext context) {
    // Move the SingleChildScrollView + QuanityaColumn content here
    // Include the _launchUrl method
  }
}
```

Update `AppInfoPage` to use `AppInfoTabContent`:
```dart
class AppInfoPage extends StatelessWidget {
  const AppInfoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(context.l10n.information, style: context.text.headlineMedium),
        leading: QuanityaIconButton(
          icon: Icons.arrow_back,
          onPressed: () => AppNavigation.back(context),
        ),
      ),
      body: const AppInfoTabContent(),
    );
  }
}
```

Note: `_InfoLinkItem` is a private widget in the same file — it stays as-is.

Note: The `_launchUrl` method is currently an instance method on `AppInfoPage`. Move it to be a static/standalone function or a method on `AppInfoTabContent`.

- [ ] **Step 2: Verify standalone AppInfoPage still works**

Run: `dart analyze lib/features/settings/pages/app_info_page.dart`
Expected: No issues

- [ ] **Step 3: Commit**

```bash
git add lib/features/settings/pages/app_info_page.dart
git commit -m "refactor: extract AppInfoTabContent for embedding in OfficePage"
```

---

## Chunk 2: Create OfficePage and Wire Navigation

### Task 4: Create OfficePage

**Files:**
- Create: `lib/features/office/pages/office_page.dart`

Follow the exact same pattern as `PostagePage` in `lib/features/outbox/pages/outbox_page.dart`. The OfficePage provides all cubits and has 3 swipeable sub-tabs.

- [ ] **Step 1: Create office_page.dart**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:cubit_ui_flow/cubit_ui_flow.dart';

import '../../../design_system/primitives/app_sizes.dart';
import '../../../design_system/primitives/quanitya_palette.dart';
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
import '../../settings/pages/settings_page.dart'; // SettingsContent
// Purchase cubits
import '../../purchase/cubits/purchase_cubit.dart';
import '../../purchase/cubits/purchase_state.dart';
import '../../purchase/cubits/purchase_message_mapper.dart';
import '../../purchase/cubits/entitlement_cubit.dart';
import '../../purchase/cubits/entitlement_state.dart';
import '../../purchase/cubits/entitlement_message_mapper.dart';
import '../../purchase/pages/purchase_page.dart'; // PurchaseTabContent
// App info
import '../../settings/pages/app_info_page.dart'; // AppInfoTabContent

/// Unified Office page with swipeable pages for Preferences, Purchases, and Info.
class OfficePage extends StatefulWidget {
  const OfficePage({super.key});

  @override
  State<OfficePage> createState() => _OfficePageState();
}

class _OfficePageState extends State<OfficePage> {
  int _currentIndex = 0;
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return MultiBlocProvider(
      providers: [
        // Settings cubits
        BlocProvider(create: (_) => GetIt.instance<DataExportCubit>()),
        BlocProvider(create: (_) => GetIt.instance<RecoveryKeyCubit>()),
        BlocProvider(create: (_) => GetIt.instance<DeviceManagementCubit>()),
        BlocProvider(create: (_) => GetIt.instance<WebhookCubit>()..load()),
        BlocProvider(create: (_) => GetIt.instance<LlmProviderCubit>()..load()),
        BlocProvider.value(value: GetIt.instance<AppOperatingCubit>()),
        // Purchase cubits
        BlocProvider(create: (_) => GetIt.instance<PurchaseCubit>()..loadProducts()),
        BlocProvider(create: (_) => GetIt.instance<EntitlementCubit>()
          ..loadEntitlements()
          ..checkSyncAccess()),
      ],
      child: UiFlowListener<LlmProviderCubit, LlmProviderState>(
        mapper: GetIt.instance<LlmProviderMessageMapper>(),
        child: UiFlowListener<DataExportCubit, DataExportState>(
          mapper: GetIt.instance<DataExportMessageMapper>(),
          child: UiFlowListener<RecoveryKeyCubit, RecoveryKeyState>(
            mapper: GetIt.instance<RecoveryKeyMessageMapper>(),
            child: UiFlowListener<WebhookCubit, WebhookState>(
              mapper: GetIt.instance<WebhookMessageMapper>(),
              child: UiFlowListener<PurchaseCubit, PurchaseState>(
                mapper: GetIt.instance<PurchaseMessageMapper>(),
                child: UiFlowListener<EntitlementCubit, EntitlementState>(
                  mapper: GetIt.instance<EntitlementMessageMapper>(),
                  child: SafeArea(
                    bottom: false,
                    child: Column(
                      children: [
                        Expanded(
                          child: PageView(
                            controller: _pageController,
                            physics: const ClampingScrollPhysics(),
                            onPageChanged: (index) => setState(() => _currentIndex = index),
                            children: const [
                              SettingsContent(),
                              PurchaseTabContent(),
                              AppInfoTabContent(),
                            ],
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(vertical: AppSizes.space * 0.25),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _PageLabel(
                                label: l10n.officeTabPreferences,
                                isActive: _currentIndex == 0,
                                onTap: () => _pageController.animateToPage(0, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut),
                              ),
                              _PageLabel(
                                label: l10n.officeTabPurchases,
                                isActive: _currentIndex == 1,
                                onTap: () => _pageController.animateToPage(1, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut),
                              ),
                              _PageLabel(
                                label: l10n.officeTabInfo,
                                isActive: _currentIndex == 2,
                                onTap: () => _pageController.animateToPage(2, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Copy _PageLabel from PostagePage (outbox_page.dart) — same widget.
// Consider extracting to shared widget later if needed.
class _PageLabel extends StatelessWidget {
  const _PageLabel({
    required this.label,
    required this.isActive,
    this.onTap,
  });

  final String label;
  final bool isActive;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final palette = QuanityaPalette.primary;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: AppSizes.space * 1.5,
          vertical: AppSizes.space * 0.5,
        ),
        child: Text(
          label,
          style: context.text.bodySmall?.copyWith(
            fontWeight: isActive ? FontWeight.w900 : FontWeight.w500,
            color: isActive ? palette.textPrimary : palette.interactableColor,
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Verify it compiles**

Run: `dart analyze lib/features/office/pages/office_page.dart`
Expected: No issues

- [ ] **Step 3: Commit**

```bash
git add lib/features/office/pages/office_page.dart
git commit -m "feat: create OfficePage with Preferences, Purchases, Info sub-tabs"
```

---

### Task 5: Update SettingsContent — remove purchases fold and info icon

**Files:**
- Modify: `lib/features/settings/pages/settings_page.dart`

- [ ] **Step 1: Remove purchases NotebookFold from SettingsContent**

Remove the entire purchases fold block (lines ~167-179 in current file):
```dart
// DELETE THIS BLOCK:
NotebookFold(
  header: Row(children: [
    Icon(Icons.shopping_bag, ...),
    HSpace.x2,
    Text(context.l10n.settingsPurchase, ...),
  ]),
  child: Center(
    child: QuanityaTextButton(
      text: context.l10n.settingsPurchase,
      onPressed: () => AppNavigation.toPurchase(context),
    ),
  ),
),
VSpace.x3,
```

- [ ] **Step 2: Remove info icon from SettingsView app bar**

In `SettingsView.build`, remove the `actions` list from AppBar:
```dart
// DELETE THIS:
actions: [
  QuanityaIconButton(
    icon: Icons.info,
    onPressed: () => AppNavigation.toAppInfo(context),
  ),
],
```

- [ ] **Step 3: Clean up unused imports**

Check if `AppNavigation` / `app_router.dart` import is still needed in this file (it may still be used by SettingsView's back button). Remove if unused.

- [ ] **Step 4: Verify**

Run: `dart analyze lib/features/settings/pages/settings_page.dart`
Expected: No issues

- [ ] **Step 5: Commit**

```bash
git add lib/features/settings/pages/settings_page.dart
git commit -m "refactor: remove purchases fold and info icon from settings (moved to Office)"
```

---

### Task 6: Update NotebookShell — replace Settings with Office

**Files:**
- Modify: `lib/features/home/pages/notebook_shell.dart`

- [ ] **Step 1: Update tab definition**

Rename Settings → Office, use `Icons.work_outline` (or `Icons.business_center_outlined`):
```dart
static const _tabs = [
  FolderTab(icon: Icons.auto_stories, label: 'Logbook'),
  FolderTab(icon: Icons.insights, label: 'Results'),
  FolderTab(icon: Icons.mail_outline, label: 'Postage'),
  FolderTab(icon: Icons.work_outline, label: 'Office'),
];
```

- [ ] **Step 2: Replace Settings IndexedStack child with OfficePage**

Remove the `MultiBlocProvider` block wrapping `SettingsContent`. Replace with just `const OfficePage()` — all cubit providers are now inside OfficePage.

```dart
children: [
  const TemporalHomePage(),
  const ResultsSection(),
  const PostagePage(),
  const OfficePage(),
],
```

- [ ] **Step 3: Update imports**

Remove settings cubit imports that are no longer used here:
```dart
// Remove these (cubits now provided inside OfficePage):
import '../../settings/cubits/data_export/data_export_cubit.dart';
import '../../settings/cubits/recovery_key/recovery_key_cubit.dart';
import '../../settings/cubits/device_management/device_management_cubit.dart';
import '../../settings/cubits/webhook/webhook_cubit.dart';
import '../../settings/cubits/llm_provider/llm_provider_cubit.dart';
import '../../app_operating_mode/cubits/app_operating_cubit.dart';
import '../../settings/pages/settings_page.dart';
```

Add:
```dart
import '../../office/pages/office_page.dart';
```

Also check if `flutter_bloc` and `get_it` imports are still needed — they may not be if no more BlocProvider usage in this file.

- [ ] **Step 4: Verify**

Run: `dart analyze lib/features/home/pages/notebook_shell.dart`
Expected: No issues

- [ ] **Step 5: Commit**

```bash
git add lib/features/home/pages/notebook_shell.dart
git commit -m "feat: replace Settings tab with Office tab in bottom nav"
```

---

### Task 7: Full analysis pass and cleanup

- [ ] **Step 1: Run full analysis**

Run: `dart analyze lib/`
Expected: No errors (warnings from pre-existing code are OK)

- [ ] **Step 2: Check for stale references**

Search for any remaining references to the old settings tab or patterns that need updating:
- `SettingsContent` references in doc comments
- Any widget that navigates to settings expecting the old tab index

- [ ] **Step 3: Commit any cleanup**

```bash
git add -A
git commit -m "chore: fix references after Settings → Office rename"
```
