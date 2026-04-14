# Entitlement → Sync Reactive Listener Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Reactively connect/disconnect sync when entitlement state changes (after purchase, app resume, or server refresh), using a BlocListener in NotebookShell.

**Architecture:** `EntitlementCubit` is the single source of truth for sync access. A `BlocListener` in `NotebookShell` watches `hasSyncAccess` and tells `AppSyncingCubit` to connect or disconnect. Entitlements auto-refresh on startup (if cache is empty) and on app resume. No orchestrator — this is a reactive/eventual side effect, not an inline dependency.

**Tech Stack:** Flutter BLoC, GetIt/Injectable, WidgetsBindingObserver

---

## File Structure

| File | Responsibility |
|------|---------------|
| `lib/features/home/pages/notebook_shell.dart` | Add `EntitlementCubit` provider + `BlocListener` for sync access changes |
| `lib/features/purchase/cubits/entitlement_cubit.dart` | Add `refreshIfStale()` for app resume; fix `_initialize` to fetch from server when cache is empty |
| `lib/features/office/pages/office_page.dart` | Remove `EntitlementCubit` from local providers (hoisted to shell) |
| `lib/features/purchase/pages/purchase_page.dart` | Remove post-purchase `checkSyncAccess()` call (listener handles it now) |
| `lib/infrastructure/sync/sync_service.dart` | Already cleaned — no changes needed |
| `lib/features/app_syncing_mode/cubits/app_syncing_cubit.dart` | Already has `retryConnection()` — no changes needed |

---

### Task 1: Add `refreshIfStale()` to EntitlementCubit

The cubit needs a method that refreshes entitlements from the server and re-checks sync access. This is called on app resume and can be called from the listener. Also fix `_initialize` to fetch from server when the user has purchased but the cache might be empty.

**Files:**
- Modify: `lib/features/purchase/cubits/entitlement_cubit.dart`
- Modify: `lib/features/purchase/cubits/entitlement_state.dart`
- Test: `test/features/purchase/cubits/entitlement_cubit_test.dart`

- [ ] **Step 1: Write test for `refreshIfStale`**

Add to `test/features/purchase/cubits/entitlement_cubit_test.dart`:

```dart
test('refreshIfStale fetches entitlements and updates sync access', () async {
  // Start with no sync access
  when(() => mockService.hasSyncAccess())
      .thenAnswer((_) async => false);

  final cubit = EntitlementCubit(mockService, mockRepo, mockDb);
  await waitForInit();
  expect(cubit.state.hasSyncAccess, isFalse);

  // Now simulate a purchase happened — server has sync entitlement
  when(() => mockService.getEntitlements()).thenAnswer(
    (_) async => [
      AccountEntitlement(
        accountUuid: UuidValue.fromString(
            '00000000-0000-0000-0000-000000000001'),
        entitlementId: 1,
        balance: 30.0,
      ),
    ],
  );
  when(() => mockService.hasSyncAccess())
      .thenAnswer((_) async => true);

  await cubit.refreshIfStale();

  expect(cubit.state.hasSyncAccess, isTrue);
  expect(cubit.state.entitlements.length, 1);
  expect(cubit.state.lastOperation, EntitlementOperation.refreshIfStale);
  verify(() => mockService.getEntitlements()).called(greaterThanOrEqualTo(2)); // init + refresh

  await cubit.close();
});

test('refreshIfStale skips when not purchased', () async {
  stubInitDefaults(hasPurchased: false);

  final cubit = EntitlementCubit(mockService, mockRepo, mockDb);
  await waitForInit();

  await cubit.refreshIfStale();

  // getEntitlements should not have been called (init skips it, refresh skips it)
  verifyNever(() => mockService.getEntitlements());

  await cubit.close();
});
```

- [ ] **Step 2: Run test to verify it fails**

```bash
flutter test --no-pub test/features/purchase/cubits/entitlement_cubit_test.dart 2>&1 > /tmp/test_results.txt
```

Expected: FAIL — `refreshIfStale` does not exist yet.

- [ ] **Step 3: Add `refreshIfStale` operation to state enum**

In `lib/features/purchase/cubits/entitlement_state.dart`, add to the `EntitlementOperation` enum:

```dart
enum EntitlementOperation { loadEntitlements, checkSyncAccess, loadStorageUsage, markPurchased, reset, refreshIfStale }
```

- [ ] **Step 4: Implement `refreshIfStale` in EntitlementCubit**

Add a `DateTime? _lastRefresh` field and `refreshIfStale` method to `lib/features/purchase/cubits/entitlement_cubit.dart`:

```dart
DateTime? _lastRefresh;

/// Refresh entitlements from server and re-check sync access.
///
/// Called on app resume and by the reactive sync listener.
/// No-op if the user has never purchased or if refreshed within the last 60s
/// (debounce to avoid spamming server on rapid app switches).
Future<void> refreshIfStale() async {
  if (!state.hasPurchased) return;

  final now = DateTime.now();
  if (_lastRefresh != null &&
      now.difference(_lastRefresh!).inSeconds < 60) {
    return;
  }

  await tryOperation(() async {
    _lastRefresh = now;
    final entitlements = await _entitlementService.getEntitlements();
    final hasAccess = await _entitlementService.hasSyncAccess();
    return state.copyWith(
      status: UiFlowStatus.success,
      lastOperation: EntitlementOperation.refreshIfStale,
      entitlements: entitlements,
      hasSyncAccess: hasAccess,
    );
  }, emitLoading: false);
}
```

Note: `emitLoading: false` — this is a background refresh, no loading spinner. The 60-second debounce prevents spamming on rapid app resume cycles (notification center swipe, quick app switch).

- [ ] **Step 5: Run test to verify it passes**

```bash
flutter test --no-pub test/features/purchase/cubits/entitlement_cubit_test.dart 2>&1 > /tmp/test_results.txt
```

Expected: All tests PASS.

- [ ] **Step 6: Run full test suite**

```bash
flutter test --no-pub 2>&1 > /tmp/test_results.txt
```

Expected: All 716+ tests pass.

- [ ] **Step 7: Commit**

```bash
git add lib/features/purchase/cubits/entitlement_cubit.dart lib/features/purchase/cubits/entitlement_state.dart test/features/purchase/cubits/entitlement_cubit_test.dart
git commit -m "feat: add refreshIfStale to EntitlementCubit for reactive sync"
```

---

### Task 2: Hoist EntitlementCubit to NotebookShell and add BlocListener

Move `EntitlementCubit` provider from `OfficePage` up to `NotebookShell` so the reactive listener has access to both `EntitlementCubit` and `AppSyncingCubit`. Add a `BlocListener` that watches `hasSyncAccess` and tells `AppSyncingCubit` to connect or disconnect.

**Files:**
- Modify: `lib/features/home/pages/notebook_shell.dart`
- Modify: `lib/features/office/pages/office_page.dart`

- [ ] **Step 1: Add EntitlementCubit provider to NotebookShell**

In `lib/features/home/pages/notebook_shell.dart`, add import:

```dart
import '../../purchase/cubits/entitlement_cubit.dart';
import '../../purchase/cubits/entitlement_state.dart';
```

Add to the `MultiBlocProvider.providers` list (after `AppSyncingCubit`):

```dart
BlocProvider.value(value: GetIt.instance<EntitlementCubit>()),
```

- [ ] **Step 2: Add the reactive BlocListener**

In `lib/features/home/pages/notebook_shell.dart`, wrap the `Builder` widget inside the `MultiBlocProvider.child` with the reactive listener:

```dart
child: BlocListener<EntitlementCubit, EntitlementState>(
  listenWhen: (prev, curr) => prev.hasSyncAccess != curr.hasSyncAccess,
  listener: (context, state) {
    final syncCubit = context.read<AppSyncingCubit>();
    if (state.hasSyncAccess && syncCubit.state.mode.supportsSync) {
      syncCubit.retryConnection();
    }
  },
  child: Builder(
    // ... existing builder code ...
  ),
),
```

The listener:
- Only fires when `hasSyncAccess` actually changes (not on every emit)
- Only connects if the user is in a sync-capable mode (cloud/selfHosted)
- Does NOT disconnect when access is lost — that would be disruptive. The existing entitlement gate in `SyncService.connect()` prevents reconnection. PowerSync will naturally fail on next `fetchCredentials()` and the user sees the error via `SyncStatusCubit`.

- [ ] **Step 3: Remove EntitlementCubit provider from OfficePage**

In `lib/features/office/pages/office_page.dart`, remove this line from the `MultiBlocProvider.providers` list:

```dart
BlocProvider.value(value: GetIt.instance<EntitlementCubit>()),
```

Remove the import if it becomes unused:
```dart
import '../../purchase/cubits/entitlement_cubit.dart';
```

**Keep the import** — `OfficePage._onPageChanged` still calls `context.read<EntitlementCubit>()`. The cubit is now provided by `NotebookShell` above, so `context.read` still works. But remove the duplicate `BlocProvider.value` line only.

Also verify: `PurchaseTabContent` uses `context.read<EntitlementCubit>()` — this still works because `NotebookShell` provides it.

- [ ] **Step 4: Run full test suite**

```bash
flutter test --no-pub 2>&1 > /tmp/test_results.txt
```

Expected: All tests pass. Widget tests may not cover this path (no `NotebookShell` tests exist), but unit tests should be unaffected.

- [ ] **Step 5: Commit**

```bash
git add lib/features/home/pages/notebook_shell.dart lib/features/office/pages/office_page.dart
git commit -m "feat: hoist EntitlementCubit to NotebookShell, add reactive sync listener"
```

---

### Task 3: Add app resume entitlement refresh

When the app returns to foreground, refresh entitlements from the server so the cache stays fresh and the reactive listener can respond to server-side changes (subscription cancellations, balance updates).

**Files:**
- Modify: `lib/features/home/pages/notebook_shell.dart`

- [ ] **Step 1: Add WidgetsBindingObserver mixin to _NotebookShellState**

In `lib/features/home/pages/notebook_shell.dart`, change the state class:

```dart
class _NotebookShellState extends State<NotebookShell>
    with WidgetsBindingObserver {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      GetIt.instance<EntitlementCubit>().refreshIfStale();
    }
  }

  // ... existing build method ...
}
```

Note: Uses `GetIt.instance` directly rather than `context.read` because `didChangeAppLifecycleState` fires outside the build context. This is safe because `EntitlementCubit` is a `@lazySingleton`.

- [ ] **Step 2: Run full test suite**

```bash
flutter test --no-pub 2>&1 > /tmp/test_results.txt
```

Expected: All tests pass.

- [ ] **Step 3: Commit**

```bash
git add lib/features/home/pages/notebook_shell.dart
git commit -m "feat: refresh entitlements on app resume via WidgetsBindingObserver"
```

---

### Task 4: Remove redundant post-purchase sync access check from PurchaseTabContent

The purchase page currently calls `checkSyncAccess()` after a successful purchase. This is now handled by the reactive listener — the purchase updates the cache, `loadEntitlements()` refreshes the cubit, the listener reacts. Remove the redundant call.

**Files:**
- Modify: `lib/features/purchase/pages/purchase_page.dart`

- [ ] **Step 1: Simplify post-purchase listener in PurchaseTabContent**

In `lib/features/purchase/pages/purchase_page.dart`, the `BlocListener<PurchaseCubit, PurchaseState>` listener (around line 54) currently calls:

```dart
context.read<EntitlementCubit>()
  ..loadEntitlements()
  ..checkSyncAccess()
  ..loadStorageUsage();
```

Change to:

```dart
context.read<EntitlementCubit>()
  ..loadEntitlements()
  ..loadStorageUsage();
```

Remove `..checkSyncAccess()`. The `loadEntitlements()` call fetches from server and updates the cache. The listener in `NotebookShell` does NOT react to `loadEntitlements` directly — it reacts to `hasSyncAccess` changing. So we need `checkSyncAccess()` to still be called somewhere after `loadEntitlements()` completes.

**Wait — reconsider.** `loadEntitlements()` fetches entitlements but does NOT update `hasSyncAccess` in the state. `checkSyncAccess()` is what reads the cache and sets `hasSyncAccess`. The reactive listener watches `hasSyncAccess`.

Two options:
1. Keep `checkSyncAccess()` call here (simplest, works now)
2. Make `loadEntitlements()` also update `hasSyncAccess` (better — one call does both)

**Go with option 2.** Modify `loadEntitlements()` in `EntitlementCubit` to also check sync access:

In `lib/features/purchase/cubits/entitlement_cubit.dart`, change `loadEntitlements()`:

```dart
Future<void> loadEntitlements() async {
  await tryOperation(() async {
    final entitlements = await _entitlementService.getEntitlements();
    final purchased = await _repo.hasEverPurchased();
    final hasAccess = await _entitlementService.hasSyncAccess();
    return state.copyWith(
      status: UiFlowStatus.success,
      lastOperation: EntitlementOperation.loadEntitlements,
      entitlements: entitlements,
      hasPurchased: purchased,
      hasSyncAccess: hasAccess,
    );
  }, emitLoading: true);
}
```

This means every `loadEntitlements()` call also updates `hasSyncAccess`, which triggers the listener if it changed.

Then in `purchase_page.dart`, simplify the listener:

```dart
context.read<EntitlementCubit>()
  ..loadEntitlements()
  ..loadStorageUsage();
```

And in `office_page.dart` `_onPageChanged`, simplify similarly:

```dart
if (context.read<EntitlementCubit>().hasPurchased) {
  context.read<EntitlementCubit>()
    ..loadEntitlements()
    ..loadStorageUsage();
}
```

Remove standalone `checkSyncAccess()` calls from both files.

Also update `_initialize` in `entitlement_cubit.dart` to remove the now-redundant `await checkSyncAccess()` call (since `loadEntitlements` handles it):

```dart
Future<void> _initialize() async {
  try {
    final purchased = await _repo.hasEverPurchased();
    emit(state.copyWith(hasPurchased: purchased));

    if (purchased) {
      await loadEntitlements();
      await loadStorageUsage();
    }
    debugPrint('EntitlementCubit: Initialization complete (hasPurchased=$purchased)');
  } catch (e) {
    debugPrint('EntitlementCubit: Initialization failed (non-critical): $e');
  }
}
```

- [ ] **Step 2: Write test for updated loadEntitlements**

Add to `test/features/purchase/cubits/entitlement_cubit_test.dart`:

```dart
test('loadEntitlements also updates hasSyncAccess', () async {
  when(() => mockService.hasSyncAccess())
      .thenAnswer((_) async => true);

  final cubit = EntitlementCubit(mockService, mockRepo, mockDb);
  await waitForInit();

  // Init already ran loadEntitlements which now includes hasSyncAccess
  expect(cubit.state.hasSyncAccess, isTrue);
  expect(cubit.state.lastOperation, isNotNull);

  await cubit.close();
});
```

- [ ] **Step 3: Run tests**

```bash
flutter test --no-pub 2>&1 > /tmp/test_results.txt
```

Expected: All tests pass.

- [ ] **Step 4: Commit**

```bash
git add lib/features/purchase/cubits/entitlement_cubit.dart lib/features/purchase/pages/purchase_page.dart lib/features/office/pages/office_page.dart test/features/purchase/cubits/entitlement_cubit_test.dart
git commit -m "refactor: loadEntitlements includes sync access check, remove redundant calls"
```

---

### Task 5: Verify end-to-end and run full suite

Verify the complete reactive flow works: purchase → cache update → loadEntitlements → hasSyncAccess changes → listener fires → AppSyncingCubit connects.

**Files:**
- No new files — verification only

- [ ] **Step 1: Run full test suite**

```bash
flutter test --no-pub 2>&1 > /tmp/test_results.txt
```

Expected: All 716+ tests pass, 57 skipped (live API).

- [ ] **Step 2: Run static analysis**

```bash
dart analyze lib/features/home/pages/notebook_shell.dart lib/features/purchase/cubits/entitlement_cubit.dart lib/features/purchase/cubits/entitlement_state.dart lib/features/purchase/pages/purchase_page.dart lib/features/office/pages/office_page.dart lib/infrastructure/sync/sync_service.dart
```

Expected: No issues.

- [ ] **Step 3: Verify no remaining references to `checkSyncAccess` outside the cubit itself**

```bash
grep -r "checkSyncAccess" lib/ --include="*.dart" | grep -v "entitlement_cubit.dart" | grep -v "entitlement_state.dart" | grep -v ".freezed.dart" | grep -v ".g.dart"
```

Expected: No results (all external callers have been removed or use `loadEntitlements` instead).

- [ ] **Step 4: Final commit if any cleanup needed**

```bash
git add -A && git commit -m "chore: cleanup after entitlement-sync listener implementation"
```

Only if there are changes to commit.
