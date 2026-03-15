# Purchase UX Cleanup & App-Wide Mode Indicator — Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make the purchase page mode-aware (skip server calls in local mode), clean up loading UX (single overlay instead of per-card spinners), localize purchase errors, and add an app-wide connection indicator.

**Architecture:** Pass `AppOperatingMode` per-call from UI → cubit → service. No cubit-to-cubit coupling. Purchase feedback unified through existing `UiFlowListener` + exception mapper pipeline. Mode indicator is a small reactive widget in the notebook shell.

**Tech Stack:** Flutter, Freezed, Cubit (cubit_ui_flow), Injectable/GetIt, bloc_test/mocktail

**Spec:** `docs/superpowers/specs/2026-03-15-purchase-ux-and-mode-indicator-design.md`

---

## Chunk 1: EntitlementService Mode-Awareness

### Task 1: Update EntitlementService interface and implementation

**Files:**
- Modify: `lib/infrastructure/purchase/i_entitlement_service.dart`
- Modify: `lib/infrastructure/purchase/entitlement_service.dart`

- [ ] **Step 1: Update the interface to accept `AppOperatingMode` on all methods**

```dart
// i_entitlement_service.dart
import 'package:anonaccred_client/anonaccred_client.dart'
    show AccountEntitlement;

import '../../features/app_operating_mode/models/app_operating_mode.dart';

abstract class IEntitlementService {
  Future<List<AccountEntitlement>> getEntitlements(AppOperatingMode mode);
  Future<double> getEntitlementBalance(String tag, AppOperatingMode mode);
  Future<bool> hasSyncAccess(AppOperatingMode mode);
  Future<void> consumeEntitlement(String tag, double quantity, AppOperatingMode mode);
}
```

- [ ] **Step 2: Update EntitlementService to short-circuit in local mode**

Add `import '../../features/app_operating_mode/models/app_operating_mode.dart';` to `entitlement_service.dart`.

Update each method signature to accept `AppOperatingMode mode` and add an early return at the top of each `tryMethod` body:

```dart
// In getEntitlements:
@override
Future<List<AccountEntitlement>> getEntitlements(AppOperatingMode mode) {
  if (!mode.requiresServer) return Future.value([]);
  return tryMethod(
    () async {
      // ... existing implementation unchanged
    },
    EntitlementException.new,
    'getEntitlements',
  );
}

// In getEntitlementBalance:
@override
Future<double> getEntitlementBalance(String tag, AppOperatingMode mode) {
  if (!mode.requiresServer) return Future.value(0);
  // ... existing tryMethod body unchanged
}

// In hasSyncAccess:
@override
Future<bool> hasSyncAccess(AppOperatingMode mode) {
  if (!mode.requiresServer) return Future.value(false);
  return tryMethod(
    () async {
      for (final tag in syncEntitlementTags) {
        final balance = await getEntitlementBalance(tag, mode);
        if (balance > 0) return true;
      }
      return false;
    },
    EntitlementException.new,
    'hasSyncAccess',
  );
}

// In consumeEntitlement:
@override
Future<void> consumeEntitlement(String tag, double quantity, AppOperatingMode mode) {
  if (!mode.requiresServer) return Future.value();
  // ... existing tryMethod body unchanged
}
```

- [ ] **Step 3: Run `dart analyze lib/infrastructure/purchase/`**

Expected: Errors in files that call `IEntitlementService` without the new `mode` parameter (EntitlementCubit, PurchaseService, AppOperatingCubit). This is expected — we fix these in subsequent tasks.

- [ ] **Step 4: Commit**

```bash
git add lib/infrastructure/purchase/i_entitlement_service.dart lib/infrastructure/purchase/entitlement_service.dart
git commit -m "feat: add AppOperatingMode parameter to EntitlementService methods"
```

### Task 2: Update EntitlementCubit to accept mode per-call

**Files:**
- Modify: `lib/features/purchase/cubits/entitlement_cubit.dart`

- [ ] **Step 1: Add mode parameter to all public methods**

```dart
import '../../../features/app_operating_mode/models/app_operating_mode.dart';

@injectable
class EntitlementCubit extends QuanityaCubit<EntitlementState> {
  final IEntitlementService _entitlementService;
  final AppDatabase _db;

  EntitlementCubit(this._entitlementService, this._db)
      : super(const EntitlementState());

  Future<void> loadEntitlements({required AppOperatingMode mode}) async {
    await tryOperation(() async {
      final entitlements = await _entitlementService.getEntitlements(mode);
      return state.copyWith(
        status: UiFlowStatus.success,
        lastOperation: EntitlementOperation.loadEntitlements,
        entitlements: entitlements,
      );
    }, emitLoading: true);
  }

  Future<void> checkSyncAccess({required AppOperatingMode mode}) async {
    await tryOperation(() async {
      final hasAccess = await _entitlementService.hasSyncAccess(mode);
      return state.copyWith(
        status: UiFlowStatus.success,
        lastOperation: EntitlementOperation.checkSyncAccess,
        hasSyncAccess: hasAccess,
      );
    }, emitLoading: true);
  }

  /// Loads storage usage from local encrypted entries.
  /// Multiplies by 4 to estimate server-side PostgreSQL cost.
  /// Mode parameter accepted for interface consistency but not used
  /// (this is a local DB query).
  Future<void> loadStorageUsage({required AppOperatingMode mode}) async {
    await tryOperation(() async {
      final result = await _db.customSelect(
        'SELECT '
        'COUNT(*) AS cnt, '
        'COALESCE(SUM(LENGTH(encrypted_data)), 0) AS total_bytes '
        'FROM encrypted_entries',
      ).getSingle();

      final count = result.read<int>('cnt');
      final rawBytes = result.read<int>('total_bytes');

      return state.copyWith(
        status: UiFlowStatus.success,
        lastOperation: EntitlementOperation.loadStorageUsage,
        entryCount: count,
        storageBytes: rawBytes * 4,
      );
    }, emitLoading: false);
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add lib/features/purchase/cubits/entitlement_cubit.dart
git commit -m "feat: EntitlementCubit accepts AppOperatingMode per-call"
```

### Task 3: Update EntitlementCubit tests

**Files:**
- Modify: `test/features/purchase/cubits/entitlement_cubit_test.dart`

- [ ] **Step 1: Update all test calls to pass mode parameter**

Add import: `import 'package:quanitya_flutter/features/app_operating_mode/models/app_operating_mode.dart';`

Update mock setup — `IEntitlementService` methods now take `AppOperatingMode`:

```dart
// Update mock stubs to match new signatures:
when(() => mockService.getEntitlements(any())).thenAnswer(...)
when(() => mockService.hasSyncAccess(any())).thenAnswer(...)
```

Update `act:` calls:

```dart
// loadEntitlements test:
act: (cubit) => cubit.loadEntitlements(mode: AppOperatingMode.cloud),

// checkSyncAccess tests:
act: (cubit) => cubit.checkSyncAccess(mode: AppOperatingMode.cloud),
```

- [ ] **Step 2: Add test for local mode short-circuit**

```dart
blocTest<EntitlementCubit, EntitlementState>(
  'loadEntitlements in local mode returns empty without server call',
  build: () {
    when(() => mockService.getEntitlements(AppOperatingMode.local))
        .thenAnswer((_) async => []);
    return EntitlementCubit(mockService, mockDb);
  },
  act: (cubit) => cubit.loadEntitlements(mode: AppOperatingMode.local),
  expect: () => [
    predicate<EntitlementState>(
      (s) => s.status == UiFlowStatus.loading,
      'loading state',
    ),
    predicate<EntitlementState>(
      (s) =>
          s.status == UiFlowStatus.success &&
          s.entitlements.isEmpty,
      'success state with empty entitlements',
    ),
  ],
);
```

- [ ] **Step 3: Run tests**

Run: `cd /Users/aicoder/Documents/openops/project/quanitya/public/quanitya_flutter && flutter test test/features/purchase/cubits/entitlement_cubit_test.dart --no-pub 2>&1 > /tmp/entitlement_test.txt && cat /tmp/entitlement_test.txt`
Expected: All tests pass

- [ ] **Step 4: Commit**

```bash
git add test/features/purchase/cubits/entitlement_cubit_test.dart
git commit -m "test: update entitlement cubit tests for mode parameter"
```

### Task 4: Update PurchaseService to pass mode through

**Files:**
- Modify: `lib/infrastructure/purchase/i_purchase_service.dart`
- Modify: `lib/infrastructure/purchase/purchase_service.dart`

- [ ] **Step 1: Update IPurchaseService interface**

Add `AppOperatingMode mode` parameter to `purchase()`:

```dart
import '../../features/app_operating_mode/models/app_operating_mode.dart';

// In IPurchaseService:
Future<PurchaseValidationResult> purchase(PurchaseRequest request, {required AppOperatingMode mode});
```

- [ ] **Step 2: Update PurchaseService.purchase()**

Add import and update the method signature. Forward `mode` to `_entitlementService.getEntitlements()`:

```dart
@override
Future<PurchaseValidationResult> purchase(PurchaseRequest request, {required AppOperatingMode mode}) {
  return tryMethod(
    () async {
      final provider = _providers[request.rail];
      if (provider == null) {
        throw PurchaseException('No provider for ${request.rail}');
      }

      final result = await provider.initiatePurchase(request);
      if (result.status != PurchaseStatus.success) {
        return PurchaseValidationResult(
          success: false,
          errorMessage: result.errorMessage ?? 'Purchase ${result.status.name}',
        );
      }

      final validation = await provider.validateWithServer(result);
      if (validation.success) {
        try {
          await _entitlementService.getEntitlements(mode);
        } catch (e) {
          debugPrint('PurchaseService: Failed to refresh entitlements: $e');
        }
      }
      return validation;
    },
    PurchaseException.new,
    'purchase',
  );
}
```

- [ ] **Step 3: Commit**

```bash
git add lib/infrastructure/purchase/i_purchase_service.dart lib/infrastructure/purchase/purchase_service.dart
git commit -m "feat: PurchaseService.purchase() accepts AppOperatingMode for entitlement refresh"
```

### Task 5: Fix remaining callers (AppOperatingCubit, PurchaseCubit)

**Files:**
- Modify: `lib/features/app_operating_mode/cubits/app_operating_cubit.dart` — update call to `hasSyncAccess()`
- Modify: `lib/features/purchase/cubits/purchase_cubit.dart` — update call to `purchase()`

- [ ] **Step 1: Fix AppOperatingCubit**

Find the call to `_entitlementService.hasSyncAccess()` in `switchToCloud()` and add the mode parameter:

```dart
// The mode being switched TO is cloud, so pass AppOperatingMode.cloud
final hasAccess = await _entitlementService.hasSyncAccess(AppOperatingMode.cloud);
```

- [ ] **Step 2: Fix PurchaseCubit.purchase()**

Add `mode` parameter to `purchase()`:

```dart
import '../../../features/app_operating_mode/models/app_operating_mode.dart';

Future<void> purchase(PurchaseRequest request, {required AppOperatingMode mode}) async {
  await tryOperation(() async {
    await _ensureRegistered();
    final result = await _purchaseService.purchase(request, mode: mode);
    analytics?.trackPurchaseCompleted(productId: request.productId);
    return state.copyWith(
      status: UiFlowStatus.success,
      lastOperation: PurchaseOperation.purchase,
      lastValidation: result,
    );
  }, emitLoading: true);
}
```

- [ ] **Step 3: Fix purchase_page.dart call site for mode parameter**

In `purchase_page.dart`, update `_onBuy` to pass mode (temporary fix — full rewrite in Task 7):

```dart
void _onBuy(BuildContext context, PurchaseProduct product) {
  final mode = context.read<AppOperatingCubit>().state.mode;
  context.read<PurchaseCubit>().purchase(
        PurchaseRequest(
          productId: product.productId,
          rail: product.rail,
        ),
        mode: mode,
      );
}
```

Add import to `purchase_page.dart`:

```dart
import '../../app_operating_mode/cubits/app_operating_cubit.dart';
```

- [ ] **Step 4: Run `dart analyze lib/` to verify no remaining compilation errors**

Run: `cd /Users/aicoder/Documents/openops/project/quanitya/public/quanitya_flutter && dart analyze lib/ 2>&1 > /tmp/analyze.txt && cat /tmp/analyze.txt`
Expected: Clean (0 issues)

- [ ] **Step 4: Commit**

```bash
git add lib/features/app_operating_mode/cubits/app_operating_cubit.dart lib/features/purchase/cubits/purchase_cubit.dart lib/features/purchase/pages/purchase_page.dart
git commit -m "fix: update remaining callers for EntitlementService mode parameter"
```

---

## Chunk 2: Purchase Page Loading Cleanup & Validation Localization

### Task 6: Add PurchaseException kind field and ARB keys

**Files:**
- Modify: `lib/infrastructure/purchase/purchase_exception.dart`
- Modify: `lib/infrastructure/feedback/exception_mapper.dart`
- Modify: `lib/l10n/app_en.arb`

- [ ] **Step 1: Add `status` field to PurchaseException**

```dart
import 'purchase_models.dart' show PurchaseStatus;

/// Exception for purchase-related errors.
class PurchaseException implements Exception {
  const PurchaseException(this.message, [this.cause, this.status]);
  final String message;
  final Object? cause;
  final PurchaseStatus? status;

  @override
  String toString() => 'PurchaseException: $message';
}
```

- [ ] **Step 2: Add ARB keys to `app_en.arb`**

Add these entries (find the purchase-related section):

```json
"purchaseCancelled": "Purchase was cancelled",
"purchasePending": "Purchase is pending — we'll process it shortly",
"purchaseAlreadyOwned": "You already own this item"
```

Note: `purchaseFailed` / `errorPurchaseFailed` should already exist. Verify before adding.

- [ ] **Step 3: Add `_mapPurchaseException` to exception mapper**

In `exception_mapper.dart`, replace:

```dart
PurchaseException() => const MessageKey.error(L10nKeys.errorPurchaseFailed),
```

With:

```dart
PurchaseException e => _mapPurchaseException(e),
```

Add the mapper method:

```dart
MessageKey _mapPurchaseException(PurchaseException e) {
  return switch (e.status) {
    PurchaseStatus.cancelled => const MessageKey.info(L10nKeys.purchaseCancelled),
    PurchaseStatus.pending => const MessageKey.info(L10nKeys.purchasePending),
    PurchaseStatus.alreadyOwned => const MessageKey.info(L10nKeys.purchaseAlreadyOwned),
    PurchaseStatus.failed => const MessageKey.error(L10nKeys.errorPurchaseFailed),
    _ => const MessageKey.error(L10nKeys.errorPurchaseFailed),
  };
}
```

Add import at the top of exception_mapper.dart:

```dart
import '../purchase/purchase_models.dart' show PurchaseStatus;
```

- [ ] **Step 4: Update PurchaseService to throw instead of returning error result**

In `purchase_service.dart`, replace the non-success return block (lines 82-86):

```dart
if (result.status != PurchaseStatus.success) {
  throw PurchaseException(
    result.errorMessage ?? 'Purchase ${result.status.name}',
    null,
    result.status,
  );
}
```

- [ ] **Step 5: Add ARB keys to other language files**

Add the same keys to `lib/l10n/app_es.arb`, `lib/l10n/app_fr.arb`, and `lib/l10n/app_pt.arb`. Use English as placeholder text (to be translated later):

```json
"purchaseCancelled": "Purchase was cancelled",
"purchasePending": "Purchase is pending — we'll process it shortly",
"purchaseAlreadyOwned": "You already own this item"
```

- [ ] **Step 6: Run `dart run build_runner build --delete-conflicting-outputs` to regenerate L10n**

- [ ] **Step 7: Commit**

```bash
git add lib/infrastructure/purchase/purchase_exception.dart lib/infrastructure/feedback/exception_mapper.dart lib/infrastructure/purchase/purchase_service.dart lib/l10n/
git commit -m "feat: localize purchase validation errors through exception mapper"
```

### Task 7: Remove per-card loading and add UiFlowListener to purchase page

**Files:**
- Modify: `lib/features/purchase/widgets/product_card.dart`
- Modify: `lib/features/purchase/widgets/consumable_card.dart`
- Modify: `lib/features/purchase/widgets/balance_display.dart`
- Modify: `lib/features/purchase/pages/purchase_page.dart`
- Modify: `lib/features/purchase/cubits/purchase_state.dart`
- Modify: `lib/features/purchase/cubits/purchase_cubit.dart`

- [ ] **Step 1: Remove `isLoading` from ProductCard**

In `product_card.dart`:

Remove the `isLoading` field and constructor parameter (line 20: `this.isLoading = false,` and line 25: `final bool isLoading;`).

Replace the action section (lines 211-224) — remove the `if (isLoading)` branch, always show the button:

```dart
// Action — always show button (page-level overlay handles loading)
QuanityaTextButton(
  text: buttonLabel,
  onPressed: onBuy,
),
```

Update the Semantics `enabled` (line 121): change `enabled: !isLoading,` to `enabled: true,`.

- [ ] **Step 2: Remove `isLoading` from ConsumableCard**

In `consumable_card.dart`:

Remove the `isLoading` field and constructor parameter (line 21: `this.isLoading = false,` and line 26: `final bool isLoading;`).

Replace the action section (lines 234-247) — remove the `if (isLoading)` branch, always show the button:

```dart
// Action — always show button (page-level overlay handles loading)
QuanityaTextButton(
  text: buttonLabel,
  onPressed: onBuy,
),
```

Update the Semantics `enabled` (line 137): change `enabled: !isLoading,` to `enabled: true,`.

- [ ] **Step 3: Remove `lastValidation` from PurchaseState**

In `purchase_state.dart`, remove line 22: `PurchaseValidationResult? lastValidation,`

Keep the `purchase_models.dart` import — it's still needed for `PurchaseProduct` (line 21).

> **Note:** Steps 3–8 must be done as an atomic batch. Removing `lastValidation` from the Freezed state class means nothing compiles until `build_runner` runs in Step 8. Do not attempt compilation checks between these steps.

- [ ] **Step 4: Update PurchaseCubit.purchase() — remove lastValidation assignment**

In `purchase_cubit.dart`, change the `purchase` method. Since the service now throws on failure (handled by `tryOperation`), and returns `PurchaseValidationResult` on success, we don't need to store it:

```dart
Future<void> purchase(PurchaseRequest request, {required AppOperatingMode mode}) async {
  await tryOperation(() async {
    await _ensureRegistered();
    await _purchaseService.purchase(request, mode: mode);
    analytics?.trackPurchaseCompleted(productId: request.productId);
    return state.copyWith(
      status: UiFlowStatus.success,
      lastOperation: PurchaseOperation.purchase,
    );
  }, emitLoading: true);
}
```

- [ ] **Step 5: Add `hasError` and `onRetry` to BalanceDisplay**

In `balance_display.dart`, add two optional parameters:

```dart
class BalanceDisplay extends StatelessWidget {
  const BalanceDisplay({
    super.key,
    required this.entitlements,
    required this.hasSyncAccess,
    this.storageBytes,
    this.entryCount,
    this.hasError = false,
    this.onRetry,
  });

  final List<AccountEntitlement> entitlements;
  final bool hasSyncAccess;
  final int? storageBytes;
  final int? entryCount;
  final bool hasError;
  final VoidCallback? onRetry;
```

At the end of the `children` list in the `build` method, add an error/retry section (after the entitlements list, before the closing `]`):

```dart
// Error/retry — shown when entitlement fetch failed
if (hasError) ...[
  VSpace.x1,
  GestureDetector(
    onTap: onRetry,
    child: Row(
      children: [
        Icon(
          Icons.refresh,
          color: palette.cautionColor,
          size: AppSizes.iconSmall,
        ),
        HSpace.x05,
        Text(
          context.l10n.entitlementRefreshFailed,
          style: context.text.bodySmall?.copyWith(
            color: palette.cautionColor,
          ),
        ),
      ],
    ),
  ),
],
```

Add `entitlementRefreshFailed` to `app_en.arb` and all other language ARB files (`app_es.arb`, `app_fr.arb`, `app_pt.arb`):

```json
"entitlementRefreshFailed": "Couldn't refresh — tap to retry"
```

- [ ] **Step 6: Rewrite PurchaseTabContent (purchase_page.dart)**

Replace the entire `build` method of `PurchaseTabContent` with:

```dart
@override
Widget build(BuildContext context) {
  return MultiUiFlowListener(
    listeners: [
      (child) => UiFlowListener<PurchaseCubit, PurchaseState>(
        mapper: GetIt.instance<PurchaseMessageMapper>(),
        child: child,
      ),
      (child) => UiFlowListener<EntitlementCubit, EntitlementState>(
        mapper: GetIt.instance<EntitlementMessageMapper>(),
        child: child,
      ),
    ],
    child: RefreshIndicator(
      onRefresh: () async {
        final mode = context.read<AppOperatingCubit>().state.mode;
        context.read<PurchaseCubit>().loadProducts();
        context.read<EntitlementCubit>()
          ..loadEntitlements(mode: mode)
          ..checkSyncAccess(mode: mode)
          ..loadStorageUsage(mode: mode);
      },
      child: ListView(
        padding: AppPadding.verticalSingle,
        children: [
          // Entitlement balance section
          BlocBuilder<EntitlementCubit, EntitlementState>(
            builder: (context, state) {
              final mode = context.read<AppOperatingCubit>().state.mode;
              return BalanceDisplay(
                entitlements: state.entitlements,
                hasSyncAccess: state.hasSyncAccess,
                storageBytes: state.storageBytes,
                entryCount: state.entryCount,
                hasError: state.hasError && mode.requiresServer,
                onRetry: () {
                  context.read<EntitlementCubit>()
                    ..loadEntitlements(mode: mode)
                    ..checkSyncAccess(mode: mode);
                },
              );
            },
          ),

          VSpace.x2,

          // Products section
          BlocBuilder<PurchaseCubit, PurchaseState>(
            builder: (context, state) {
              if (state.status == UiFlowStatus.loading &&
                  state.lastOperation == PurchaseOperation.loadProducts) {
                return Center(
                  child: Padding(
                    padding: AppPadding.allTriple,
                    child: const CircularProgressIndicator(),
                  ),
                );
              }

              if (state.status == UiFlowStatus.failure &&
                  state.lastOperation == PurchaseOperation.loadProducts) {
                return Center(
                  child: Padding(
                    padding: AppPadding.allTriple,
                    child: Column(
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: context.colors.errorColor,
                        ),
                        VSpace.x1,
                        Text(
                          context.l10n.purchaseLoadFailed,
                          style: context.text.bodyMedium?.copyWith(
                            color: context.colors.errorColor,
                          ),
                        ),
                        VSpace.x2,
                        QuanityaTextButton(
                          text: context.l10n.actionRetry,
                          onPressed: () =>
                              context.read<PurchaseCubit>().loadProducts(),
                        ),
                      ],
                    ),
                  ),
                );
              }

              if (state.products.isEmpty) {
                return Center(
                  child: Padding(
                    padding: AppPadding.allTriple,
                    child: Text(context.l10n.purchaseNoProducts),
                  ),
                );
              }

              return _ProductSections(
                products: state.products,
                onBuy: (product) => _onBuy(context, product),
              );
            },
          ),

          VSpace.x2,

          // Restore purchases
          Center(
            child: QuanityaTextButton(
              text: context.l10n.restorePurchases,
              onPressed: () =>
                  context.read<PurchaseCubit>().recoverPurchases(),
            ),
          ),
          VSpace.x3,
        ],
      ),
    ),
  );
}

void _onBuy(BuildContext context, PurchaseProduct product) {
  final mode = context.read<AppOperatingCubit>().state.mode;
  context.read<PurchaseCubit>().purchase(
        PurchaseRequest(
          productId: product.productId,
          rail: product.rail,
        ),
        mode: mode,
      );
}
```

Add these imports to the top of `purchase_page.dart`:

```dart
import 'package:get_it/get_it.dart';
import '../../../design_system/widgets/multi_ui_flow_listener.dart';
import '../../../design_system/widgets/ui_flow_listener.dart';
import '../cubits/purchase_message_mapper.dart';
import '../cubits/entitlement_message_mapper.dart';
import '../../app_operating_mode/cubits/app_operating_cubit.dart';
```

Keep the `quanitya_palette.dart` import — it's still used by `_PeriodColumn`.

- [ ] **Step 7: Remove `isPurchasing` from `_ProductSections` and `_PeriodColumn`**

In `_ProductSections`: remove `isPurchasing` field (line 191), constructor parameter (line 190: `required this.isPurchasing`), and all usages passing `isLoading: isPurchasing` to cards:

- Line 248: `ConsumableCard(product: product, onBuy: () => onBuy(product),)` (remove `isLoading: isPurchasing`)
- Lines 305-308: `ProductCard(product: product, onBuy: () => onBuy(product),)` (remove `isLoading: isPurchasing`)
- Lines 311-314: Same pattern

In `_PeriodColumn`: remove `isPurchasing` field (line 339), constructor parameter (line 333: `required this.isPurchasing`), and line 361: remove `isLoading: isPurchasing` from `ProductCard`.

In `_buildSubscriptionColumns`: remove `isPurchasing: isPurchasing` from both `_PeriodColumn` constructors (lines 292, 298).

- [ ] **Step 8: Run build_runner to regenerate Freezed and L10n**

Run: `cd /Users/aicoder/Documents/openops/project/quanitya/public/quanitya_flutter && dart run build_runner build --delete-conflicting-outputs`

- [ ] **Step 9: Run `dart analyze lib/`**

Expected: Clean (0 issues)

- [ ] **Step 10: Commit**

```bash
git add lib/features/purchase/ lib/infrastructure/purchase/purchase_exception.dart lib/infrastructure/feedback/exception_mapper.dart lib/l10n/app_en.arb
git commit -m "feat: single page-level loading, localized purchase errors, remove per-card spinners"
```

### Task 8: Update PurchaseCubit tests

**Files:**
- Modify: `test/features/purchase/cubits/purchase_cubit_test.dart`

- [ ] **Step 1: Update test calls for new signatures**

Add import: `import 'package:quanitya_flutter/features/app_operating_mode/models/app_operating_mode.dart';`

Update mock stub for `purchase()`:

```dart
when(() => mockService.purchase(any(), mode: any(named: 'mode'))).thenAnswer(...)
```

Update `act:` calls:

```dart
// purchase test:
act: (cubit) => cubit.purchase(
  const PurchaseRequest(
    productId: 'sync_1gb_month',
    rail: PurchaseRail.appleIap,
  ),
  mode: AppOperatingMode.cloud,
),
```

Remove the `lastValidation` assertions from the purchase success test:

```dart
// Change from:
s.lastValidation != null && s.lastValidation!.success == true,
// To:
s.lastOperation == PurchaseOperation.purchase,
```

Update the initial state test — remove `lastValidation` assertion:

```dart
// Remove: expect(cubit.state.lastValidation, isNull);
```

- [ ] **Step 2: Run tests**

Run: `cd /Users/aicoder/Documents/openops/project/quanitya/public/quanitya_flutter && flutter test test/features/purchase/cubits/purchase_cubit_test.dart --no-pub 2>&1 > /tmp/purchase_test.txt && cat /tmp/purchase_test.txt`
Expected: All tests pass

- [ ] **Step 3: Commit**

```bash
git add test/features/purchase/cubits/purchase_cubit_test.dart
git commit -m "test: update purchase cubit tests for mode parameter and removed lastValidation"
```

---

## Chunk 3: App-Wide Mode Indicator

### Task 9: Create mode indicator widget

**Files:**
- Create: `lib/features/app_operating_mode/widgets/mode_indicator.dart`

- [ ] **Step 1: Write the widget**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../design_system/primitives/app_sizes.dart';
import '../../../design_system/primitives/quanitya_palette.dart';
import '../cubits/app_operating_cubit.dart';
import '../models/app_operating_mode.dart';

/// Displays a small icon indicating the current server connection status.
///
/// Hidden in local mode. Shows cloud/server icon colored by connection state:
/// - Sage green ([stateOn]) when connected
/// - Caution amber when disconnected
class ModeIndicator extends StatelessWidget {
  const ModeIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppOperatingCubit, AppOperatingState>(
      buildWhen: (prev, curr) =>
          prev.mode != curr.mode || prev.isConnected != curr.isConnected,
      builder: (context, state) {
        if (state.mode == AppOperatingMode.local) {
          return const SizedBox.shrink();
        }

        final palette = QuanityaPalette.primary;
        final color = state.isConnected
            ? palette.stateOnColor
            : palette.cautionColor;

        final icon = switch (state.mode) {
          AppOperatingMode.cloud => Icons.cloud,
          AppOperatingMode.selfHosted => Icons.dns,
          AppOperatingMode.local => Icons.cloud, // unreachable
        };

        return Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSizes.space),
          child: Icon(
            icon,
            color: color,
            size: AppSizes.iconSmall,
          ),
        );
      },
    );
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add lib/features/app_operating_mode/widgets/mode_indicator.dart
git commit -m "feat: add ModeIndicator widget for server connection status"
```

### Task 10: Wire mode indicator into NotebookShell

**Files:**
- Modify: `lib/features/home/pages/notebook_shell.dart`

- [ ] **Step 1: Add the ModeIndicator to the shell**

The NotebookShell uses a `Scaffold` with no `AppBar`. The mode indicator should be placed above the `FolderTabBar` or in a safe area at the top. Looking at the structure, the best place is inside the `Column` at the top, above the `Expanded(IndexedStack(...))`:

Add import:

```dart
import '../../app_operating_mode/widgets/mode_indicator.dart';
```

Add the indicator at the top of the Column children (after `Expanded`, before `FolderTabBar`). Actually, since there's no AppBar, place it as a small `Positioned` or simply in the top-right of the `SafeArea`. The simplest approach: wrap the `Scaffold` body in a `Stack` and position the indicator in the top-right:

```dart
body: Stack(
  children: [
    Column(
      children: [
        Expanded(
          child: IndexedStack(
            index: _currentIndex,
            children: const [
              TemporalHomePage(),
              ResultsSection(),
              PostagePage(),
              OfficePage(),
            ],
          ),
        ),
        FolderTabBar(
          currentIndex: _currentIndex,
          onTabSelected: (index) =>
              setState(() => _currentIndex = index),
          tabs: tabs,
        ),
      ],
    ),
    // Mode indicator — top-right, below safe area
    Positioned(
      top: MediaQuery.of(context).padding.top + AppSizes.space,
      right: AppSizes.space * 2,
      child: const ModeIndicator(),
    ),
  ],
),
```

Add import for `AppSizes`:

```dart
import '../../../design_system/primitives/app_sizes.dart';
```

- [ ] **Step 2: Run `dart analyze lib/features/home/`**

Expected: Clean

- [ ] **Step 3: Commit**

```bash
git add lib/features/home/pages/notebook_shell.dart
git commit -m "feat: wire ModeIndicator into NotebookShell"
```

### Task 11: Add mode indicator test

**Files:**
- Create: `test/features/app_operating_mode/widgets/mode_indicator_test.dart`

- [ ] **Step 1: Write widget test**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:quanitya_flutter/features/app_operating_mode/cubits/app_operating_cubit.dart';
import 'package:quanitya_flutter/features/app_operating_mode/models/app_operating_mode.dart';
import 'package:quanitya_flutter/features/app_operating_mode/widgets/mode_indicator.dart';

class MockAppOperatingCubit extends MockCubit<AppOperatingState>
    implements AppOperatingCubit {}

void main() {
  late MockAppOperatingCubit mockCubit;

  setUp(() {
    mockCubit = MockAppOperatingCubit();
  });

  Widget buildSubject() {
    return MaterialApp(
      home: BlocProvider<AppOperatingCubit>.value(
        value: mockCubit,
        child: const Scaffold(body: ModeIndicator()),
      ),
    );
  }

  testWidgets('hidden in local mode', (tester) async {
    when(() => mockCubit.state).thenReturn(
      const AppOperatingState(mode: AppOperatingMode.local),
    );
    await tester.pumpWidget(buildSubject());
    expect(find.byType(Icon), findsNothing);
  });

  testWidgets('shows cloud icon when in cloud mode connected', (tester) async {
    when(() => mockCubit.state).thenReturn(
      const AppOperatingState(
        mode: AppOperatingMode.cloud,
        isConnected: true,
      ),
    );
    await tester.pumpWidget(buildSubject());
    expect(find.byIcon(Icons.cloud), findsOneWidget);
  });

  testWidgets('shows dns icon when in selfHosted mode', (tester) async {
    when(() => mockCubit.state).thenReturn(
      const AppOperatingState(
        mode: AppOperatingMode.selfHosted,
        isConnected: true,
      ),
    );
    await tester.pumpWidget(buildSubject());
    expect(find.byIcon(Icons.dns), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run test**

Run: `cd /Users/aicoder/Documents/openops/project/quanitya/public/quanitya_flutter && flutter test test/features/app_operating_mode/widgets/mode_indicator_test.dart --no-pub 2>&1 > /tmp/mode_indicator_test.txt && cat /tmp/mode_indicator_test.txt`
Expected: All tests pass

- [ ] **Step 3: Commit**

```bash
git add test/features/app_operating_mode/widgets/mode_indicator_test.dart
git commit -m "test: add mode indicator widget tests"
```

### Task 12: Final verification

- [ ] **Step 1: Run full analysis**

Run: `cd /Users/aicoder/Documents/openops/project/quanitya/public/quanitya_flutter && dart analyze lib/ 2>&1 > /tmp/final_analyze.txt && cat /tmp/final_analyze.txt`
Expected: 0 issues

- [ ] **Step 2: Run all purchase tests**

Run: `cd /Users/aicoder/Documents/openops/project/quanitya/public/quanitya_flutter && flutter test test/features/purchase/ --no-pub 2>&1 > /tmp/purchase_tests.txt && cat /tmp/purchase_tests.txt`
Expected: All pass

- [ ] **Step 3: Run mode indicator tests**

Run: `cd /Users/aicoder/Documents/openops/project/quanitya/public/quanitya_flutter && flutter test test/features/app_operating_mode/ --no-pub 2>&1 > /tmp/mode_tests.txt && cat /tmp/mode_tests.txt`
Expected: All pass
