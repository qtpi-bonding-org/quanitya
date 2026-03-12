# Postage Tab Merge — Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Merge the Inbox (notifications) and Outbox tabs into a single "Postage" tab, reducing bottom nav from 5 to 4 tabs.

**Architecture:** Move the NotificationInboxContent into the OutboxPage as a 4th sub-tab (first position: "Notices"). Remove the standalone Inbox tab from NotebookShell. Rename Outbox → Postage throughout. Adapt notification content to use the OutboxTabContent layout shell for visual consistency.

**Tech Stack:** Flutter, BLoC/Cubit, GoRouter, l10n ARB

---

## File Structure

| Action | File | Responsibility |
|--------|------|----------------|
| Modify | `lib/features/home/pages/notebook_shell.dart` | Remove Inbox tab, rename Outbox → Postage, move notification cubit provider into postage page |
| Modify | `lib/features/outbox/pages/outbox_page.dart` | Add Notices sub-tab, add notification cubit/listener, rename to PostagePage |
| Modify | `lib/features/notifications/pages/notification_inbox_page.dart` | Adapt NotificationInboxContent to use OutboxTabContent + OutboxEmptyState |
| Modify | `lib/l10n/app_en.arb` | Add postage/notices l10n keys, keep outbox keys for now |
| Modify | `lib/l10n/app_es.arb` | Add postage/notices l10n keys (Spanish) |
| Modify | `lib/l10n/app_fr.arb` | Add postage/notices l10n keys (French) |
| Modify | `lib/l10n/app_pt.arb` | Add postage/notices l10n keys (Portuguese) |
| Keep | `lib/app_router.dart` | Keep standalone notification route for deep-link/push navigation |
| Keep | `lib/features/notifications/` | All notification feature code stays in place — only the content widget is adapted |
| Keep | `lib/features/outbox/widgets/` | OutboxTabContent, OutboxEmptyState, FolderTabBar unchanged |

---

## Chunk 1: Adapt Notification Content & Add L10n Keys

### Task 1: Add l10n keys

**Files:**
- Modify: `lib/l10n/app_en.arb`
- Modify: `lib/l10n/app_es.arb`
- Modify: `lib/l10n/app_fr.arb`
- Modify: `lib/l10n/app_pt.arb`

- [ ] **Step 1: Add English l10n keys**

Add these keys to `app_en.arb` near the existing outbox keys:

```json
"postageTabNotices": "Notices",
"noticesEmpty": "No Notices",
"noticesEmptyDescription": "Notifications will appear here when there's something to review."
```

- [ ] **Step 2: Add Spanish l10n keys**

Add to `app_es.arb`:

```json
"postageTabNotices": "Avisos",
"noticesEmpty": "Sin avisos",
"noticesEmptyDescription": "Las notificaciones aparecerán aquí cuando haya algo que revisar."
```

- [ ] **Step 3: Add French l10n keys**

Add to `app_fr.arb`:

```json
"postageTabNotices": "Avis",
"noticesEmpty": "Aucun avis",
"noticesEmptyDescription": "Les notifications apparaîtront ici quand il y aura quelque chose à examiner."
```

- [ ] **Step 4: Add Portuguese l10n keys**

Add to `app_pt.arb`:

```json
"postageTabNotices": "Avisos",
"noticesEmpty": "Sem avisos",
"noticesEmptyDescription": "As notificações aparecerão aqui quando houver algo para revisar."
```

- [ ] **Step 5: Commit**

```bash
git add lib/l10n/app_en.arb lib/l10n/app_es.arb lib/l10n/app_fr.arb lib/l10n/app_pt.arb
git commit -m "feat: add postage/notices l10n keys"
```

---

### Task 2: Adapt NotificationInboxContent to use OutboxTabContent

**Files:**
- Modify: `lib/features/notifications/pages/notification_inbox_page.dart`

The current `NotificationInboxContent` has its own layout (Column with Mark All TextButton + ListView). We need to adapt it to use `OutboxTabContent` + `OutboxEmptyState` for visual consistency with the other sub-tabs, while keeping the standalone `NotificationInboxPage` working for deep-link navigation.

- [ ] **Step 1: Refactor NotificationInboxContent to use OutboxTabContent**

Replace the current `NotificationInboxContent` build method. The "Mark All" button moves to `bottomAction`. The empty state uses `OutboxEmptyState` with `notifications_none` icon in `textSecondary`.

```dart
import '../../outbox/widgets/outbox_tab_content.dart';
```

Replace `NotificationInboxContent.build`:

```dart
@override
Widget build(BuildContext context) {
  return BlocBuilder<NotificationInboxCubit, NotificationInboxState>(
    builder: (context, state) {
      return OutboxTabContent(
        isEmpty: state.notifications.isEmpty,
        emptyState: OutboxEmptyState(
          icon: Icons.notifications_none,
          title: context.l10n.noticesEmpty,
          description: context.l10n.noticesEmptyDescription,
        ),
        content: ListView.separated(
          padding: AppPadding.page,
          itemCount: state.notifications.length,
          separatorBuilder: (context, index) => VSpace.x3,
          itemBuilder: (context, index) {
            final notification = state.notifications[index];
            return NotificationCard(
              notification: notification,
              onMark: () => context.read<NotificationInboxCubit>()
                .markAsReceived(notification.id),
              onDismiss: () => context.read<NotificationInboxCubit>()
                .dismiss(notification.id),
            );
          },
        ),
        bottomAction: state.notifications.isNotEmpty
            ? _MarkAllAction()
            : null,
      );
    },
  );
}
```

Extract the Mark All button to a private widget:

```dart
class _MarkAllAction extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: AppPadding.page,
      child: Align(
        alignment: Alignment.centerRight,
        child: QuanityaTextButton(
          text: context.l10n.notificationsMarkAll,
          onPressed: () => context.read<NotificationInboxCubit>().markAllAsReceived(),
        ),
      ),
    );
  }
}
```

Remove the old `_EmptyState` widget class entirely.

Update imports — add:
```dart
import '../../../design_system/primitives/app_spacings.dart';
import '../../../design_system/widgets/quanitya/general/quanitya_text_button.dart';
import '../../outbox/widgets/outbox_tab_content.dart';
```

Remove unused imports:
```dart
// Remove these if no longer used after refactor:
import '../../../design_system/primitives/quanitya_palette.dart';  // check if still needed
```

The `TextButton` for Mark All becomes `QuanityaTextButton` for design system consistency.

- [ ] **Step 2: Verify standalone NotificationInboxPage still works**

The standalone page wraps `NotificationInboxContent` with its own `BlocProvider` and `Scaffold`. Since we only changed the content widget's internal layout, the standalone page should work unchanged.

Run: `dart analyze lib/features/notifications/`
Expected: No issues

- [ ] **Step 3: Commit**

```bash
git add lib/features/notifications/pages/notification_inbox_page.dart
git commit -m "refactor: adapt NotificationInboxContent to use OutboxTabContent layout"
```

---

## Chunk 2: Merge Into Postage Tab

### Task 3: Add Notices sub-tab to OutboxPage and rename to PostagePage

**Files:**
- Modify: `lib/features/outbox/pages/outbox_page.dart`

- [ ] **Step 1: Add notification imports and cubit provider**

Add imports:
```dart
import 'package:cubit_ui_flow/cubit_ui_flow.dart';
import '../../notifications/cubits/notification_inbox_cubit.dart';
import '../../notifications/mappers/notification_message_mapper.dart';
import '../../notifications/pages/notification_inbox_page.dart';
```

Add `NotificationInboxCubit` to `MultiBlocProvider.providers`:
```dart
BlocProvider(
  create: (_) => GetIt.instance<NotificationInboxCubit>()..loadNotifications(),
),
```

Add `UiFlowStateListener` for notifications wrapping the existing listeners:
```dart
child: UiFlowStateListener<NotificationInboxCubit, NotificationInboxState>(
  mapper: GetIt.instance<NotificationMessageMapper>(),
  uiService: GetIt.instance<IUiFlowService>(),
  child: UiFlowListener<AnalyticsInboxCubit, AnalyticsInboxState>(
    // ... existing chain
  ),
),
```

Note: Notifications uses `UiFlowStateListener` (not `UiFlowListener`) — match the pattern from notebook_shell.dart.

- [ ] **Step 2: Add NotificationInboxContent as first page**

Update the PageView children (Notices first, then existing tabs):
```dart
children: const [
  NotificationInboxContent(),  // Index 0 — Notices
  FeedbackTabContent(),        // Index 1
  AnalyticsTabContent(),       // Index 2
  ErrorsTabContent(),          // Index 3
],
```

- [ ] **Step 3: Update page labels**

Add the Notices label and update indices:
```dart
_PageLabel(
  label: l10n.postageTabNotices,
  isActive: _currentIndex == 0,
  onTap: () => _pageController.animateToPage(0, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut),
),
_PageLabel(
  label: l10n.outboxTabFeedback,
  isActive: _currentIndex == 1,
  onTap: () => _pageController.animateToPage(1, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut),
),
_PageLabel(
  label: l10n.outboxTabAnalytics,
  isActive: _currentIndex == 2,
  onTap: () => _pageController.animateToPage(2, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut),
),
_PageLabel(
  label: l10n.outboxTabErrors,
  isActive: _currentIndex == 3,
  onTap: () => _pageController.animateToPage(3, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut),
),
```

- [ ] **Step 4: Rename class OutboxPage → PostagePage**

Rename:
- `OutboxPage` → `PostagePage`
- `_OutboxPageState` → `_PostagePageState`
- Update the doc comment: `/// Unified Postage page with swipeable pages for Notices, Feedback, Analytics, and Errors.`

- [ ] **Step 5: Verify**

Run: `dart analyze lib/features/outbox/pages/outbox_page.dart`
Expected: No issues (there will be a reference error from notebook_shell — that's fixed in Task 4)

- [ ] **Step 6: Commit**

```bash
git add lib/features/outbox/pages/outbox_page.dart
git commit -m "feat: add Notices sub-tab to Postage page (renamed from Outbox)"
```

---

### Task 4: Update NotebookShell — remove Inbox tab, wire Postage

**Files:**
- Modify: `lib/features/home/pages/notebook_shell.dart`

- [ ] **Step 1: Update tab definitions**

Remove Inbox tab, rename Outbox → Postage. Use `Icons.mail_outline` for Postage:

```dart
static const _tabs = [
  FolderTab(icon: Icons.auto_stories, label: 'Logbook'),
  FolderTab(icon: Icons.insights, label: 'Results'),
  FolderTab(icon: Icons.mail_outline, label: 'Postage'),
  FolderTab(icon: Icons.settings, label: 'Settings'),
];
```

- [ ] **Step 2: Update IndexedStack children**

Remove the Inbox BlocProvider block (index 2). Replace `OutboxPage()` with `PostagePage()`. The notification cubit is now provided inside PostagePage, not here.

```dart
children: [
  const TemporalHomePage(),
  const ResultsSection(),
  // Postage (Notices + Feedback + Analytics + Errors)
  const PostagePage(),
  // Settings
  MultiBlocProvider(
    providers: [
      BlocProvider(create: (_) => GetIt.instance<DataExportCubit>()),
      BlocProvider(create: (_) => GetIt.instance<RecoveryKeyCubit>()),
      BlocProvider(create: (_) => GetIt.instance<DeviceManagementCubit>()),
      BlocProvider(create: (_) => GetIt.instance<WebhookCubit>()..load()),
      BlocProvider(create: (_) => GetIt.instance<LlmProviderCubit>()..load()),
      BlocProvider.value(value: GetIt.instance<AppOperatingCubit>()),
    ],
    child: const SettingsContent(),
  ),
],
```

- [ ] **Step 3: Remove unused imports**

Remove:
```dart
import '../../notifications/cubits/notification_inbox_cubit.dart';
import '../../notifications/mappers/notification_message_mapper.dart';
import '../../notifications/pages/notification_inbox_page.dart';
```

Remove (if no longer needed):
```dart
import 'package:cubit_ui_flow/cubit_ui_flow.dart';
```

Keep the `OutboxPage` import but update it — since the class was renamed to `PostagePage`, the import path stays the same (`outbox_page.dart`) but the reference changes.

- [ ] **Step 4: Verify full app compiles**

Run: `dart analyze lib/features/home/pages/notebook_shell.dart`
Expected: No issues

- [ ] **Step 5: Commit**

```bash
git add lib/features/home/pages/notebook_shell.dart
git commit -m "feat: merge Inbox into Postage tab, reduce bottom nav to 4 tabs"
```

---

### Task 5: Full analysis pass

- [ ] **Step 1: Run full analysis**

Run: `dart analyze lib/`
Expected: No issues

If there are unused import warnings or references to `OutboxPage` elsewhere, fix them.

- [ ] **Step 2: Check for any other references to OutboxPage class name**

Search for `OutboxPage` across the codebase. The app_router.dart has an outbox route — update it if it references the old class name. Any test files referencing `OutboxPage` need updating too.

- [ ] **Step 3: Commit any cleanup**

```bash
git add -A
git commit -m "chore: fix references after Outbox → Postage rename"
```
