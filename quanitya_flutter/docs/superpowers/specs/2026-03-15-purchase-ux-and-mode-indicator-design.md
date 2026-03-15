# Purchase UX Cleanup & App-Wide Mode Indicator

**Date:** 2026-03-15
**Status:** Approved
**Scope:** EntitlementService mode-awareness, purchase page loading cleanup, validation error localization, app-wide connection indicator

---

## Context

The purchase page has several UX issues:
- EntitlementService makes API calls even in local mode, causing a confusing info toast ("Account details unavailable — using local mode")
- Each product/consumable card has its own loading spinner, resulting in many spinners at once during a purchase
- Purchase validation errors surface raw unlocalized strings like `"Purchase cancelled"`
- No visual indicator of the app's operating mode or server connection status

## Design

### 1. EntitlementService Mode-Awareness

**Goal:** Skip server calls in local mode — saves an API call and eliminates the confusing info toast.

**Approach:** Pass `AppOperatingMode` per-call to `EntitlementService` methods. Services short-circuit when `!mode.requiresServer`.

**Affected methods:**
- `getEntitlements(AppOperatingMode mode)` → returns `[]` in local mode
- `hasSyncAccess(AppOperatingMode mode)` → returns `false` in local mode
- `getEntitlementBalance(String tag, AppOperatingMode mode)` → returns `0` in local mode
- `consumeEntitlement(String tag, double quantity, AppOperatingMode mode)` → no-op in local mode

**Data flow (no cubit-to-cubit coupling):**
```
PurchasePage (UI)
  ├── reads mode from context.read<AppOperatingCubit>().state.mode
  └── passes mode to EntitlementCubit.loadEntitlements(mode: mode)
        └── forwards mode to EntitlementService.getEntitlements(mode)
              └── if !mode.requiresServer → return []
```

**EntitlementCubit:** Accepts `mode` as a parameter on all public methods (`loadEntitlements`, `checkSyncAccess`, `loadStorageUsage`). Does not hold a reference to `AppOperatingCubit`. Note: `loadStorageUsage` queries the local DB only, so it can ignore the mode parameter, but takes it for interface consistency.

**PurchaseService propagation:** `PurchaseService` internally calls `_entitlementService.getEntitlements()` after a successful purchase to refresh balances. This call also needs the `mode` parameter. Since purchases require a server (the validation step calls the server), this path only executes in cloud/self-hosted mode — but the parameter is still needed to satisfy the updated interface. `PurchaseService.purchase()` gains a `mode` parameter for this purpose.

### 2. Purchase Page Loading Cleanup

**Goal:** Single page-level loading overlay instead of per-card spinners.

**Changes:**

**Remove from ProductCard and ConsumableCard:**
- `isLoading` / `isPurchasing` parameter
- Per-card `CircularProgressIndicator` replacement of the buy button

**Add to purchase page:**
- `UiFlowListener<PurchaseCubit, PurchaseState>` wrapping the page content for a single loading overlay during purchases (follows the existing pattern used on every other page)
- If the page also needs entitlement feedback, use `MultiUiFlowListener` with both `PurchaseCubit` and `EntitlementCubit`

**Products empty state:**
- Use existing `QuanityaEmptyOr` widget for the products list

**BalanceDisplay entitlement error (cloud/self-hosted mode only):**
- When entitlement fetch fails, show inline "Couldn't refresh" text with tap-to-retry in the balance area
- The global exception mapper toast still fires — this is an additional persistent inline indicator so the user can retry without pull-to-refresh
- `BalanceDisplay` gains optional `hasError` (bool) and `onRetry` (VoidCallback?) props. The existing `BlocBuilder<EntitlementCubit, EntitlementState>` in `PurchaseTabContent` reads `state.hasError` and passes it down along with a retry callback

**Intermediary widget cleanup:** `_ProductSections` and `_PeriodColumn` (private widgets within purchase_page.dart) also accept and forward `isPurchasing` to cards — these are cleaned up to remove that parameter chain

### 3. Localize Purchase Validation Errors

**Goal:** Route all user-facing purchase status messages through i18n.

**Current problem:** `PurchaseService` builds `'Purchase ${result.status.name}'` as a raw string passed to `errorMessage`, which surfaces unlocalized in the UI.

**Fix:** Use typed exception kinds on `PurchaseException` and extend the global exception mapper.

**New ARB keys (app_en.arb):**
```json
{
  "purchaseCancelled": "Purchase was cancelled",
  "purchasePending": "Purchase is pending — we'll process it shortly",
  "purchaseAlreadyOwned": "You already own this item",
  "purchaseFailed": "Purchase failed — please try again"
}
```

**Exception mapper update:**
```dart
PurchaseException e => _mapPurchaseException(e),
```

`_mapPurchaseException` switches on a `PurchaseFailureKind` enum (or the exception's cause/status) to return the correct `MessageKey`. This follows the existing `_mapAuthException` pattern in `QuanityaExceptionKeyMapper`.

**PurchaseService change:** Instead of setting `errorMessage: 'Purchase ${result.status.name}'`, throw a `PurchaseException` with a typed kind field. The exception flows through `tryOperation` → exception mapper → localized toast automatically.

**Inline validation result section removal:** The current purchase page has an inline validation result display (purchase_page.dart lines 131-168) that reads `state.lastValidation`. Since we are moving to `UiFlowListener` with exception-based error handling, this inline section is removed. All purchase feedback (success and failure) goes through the toast system via `PurchaseMessageMapper` (success) and `QuanityaExceptionKeyMapper` (errors). The `lastValidation` field on `PurchaseState` can be removed.

**PurchaseFailureKind values:** Reuse the existing `PurchaseStatus` enum values as the kind discriminator: `cancelled`, `pending`, `failed`, `alreadyOwned`. The exception mapper switches on these.

### 4. App-Wide Mode Indicator

**Goal:** Show connection status for cloud/self-hosted modes. No indicator in local mode.

**Behavior matrix:**

| Mode | Connected | Shown? | Icon | Color |
|------|-----------|--------|------|-------|
| Local | n/a | No | — | — |
| Cloud | yes | Yes | `Icons.cloud` (placeholder) | `stateOn` (sage green `#6B8F71`) |
| Cloud | no | Yes | `Icons.cloud` (placeholder) | `cautionColor` (amber) |
| Self-Hosted | yes | Yes | `Icons.dns` (placeholder) | `stateOn` (sage green `#6B8F71`) |
| Self-Hosted | no | Yes | `Icons.dns` (placeholder) | `cautionColor` (amber) |

**Implementation:**
- Small widget (chip or icon) placed in the app bar area
- Reads reactively from `AppOperatingCubit` via `context.watch<AppOperatingCubit>()`
- Uses `state.mode` and `state.isConnected` to determine icon and color
- Icons are placeholders — can be swapped later without structural changes
- Uses existing color tokens: `stateOn` for connected, `cautionColor` for disconnected

**No new colors or design tokens needed.**

## Files Affected

### Modified
- `lib/infrastructure/purchase/entitlement_service.dart` — add `AppOperatingMode` parameter to methods
- `lib/infrastructure/purchase/i_entitlement_service.dart` — update interface
- `lib/infrastructure/purchase/i_purchase_service.dart` — add `mode` parameter to `purchase()`
- `lib/infrastructure/purchase/purchase_service.dart` — throw typed PurchaseException instead of raw strings, pass `mode` to entitlement refresh
- `lib/features/purchase/cubits/entitlement_cubit.dart` — accept `mode` parameter on all public methods
- `lib/features/purchase/cubits/purchase_cubit.dart` — accept `mode` on `purchase()`, remove `lastValidation` from state
- `lib/features/purchase/cubits/purchase_state.dart` — remove `lastValidation` field
- `lib/features/purchase/pages/purchase_page.dart` — pass mode, add UiFlowListener, remove per-card loading, remove inline validation section, clean up `_ProductSections`/`_PeriodColumn` isPurchasing chain
- `lib/features/purchase/widgets/product_card.dart` — remove `isLoading` prop
- `lib/features/purchase/widgets/consumable_card.dart` — remove `isLoading` prop
- `lib/features/purchase/widgets/balance_display.dart` — add `hasError` and `onRetry` props for inline error/retry
- `lib/infrastructure/feedback/exception_mapper.dart` — add `_mapPurchaseException` switching on `PurchaseStatus`
- `lib/l10n/app_en.arb` — add purchase status ARB keys
- `lib/l10n/app_es.arb`, `app_fr.arb`, `app_pt.arb` — add translated keys

### New
- Mode indicator widget — `lib/features/app_operating_mode/widgets/mode_indicator.dart`

### Tests affected
- `test/features/purchase/cubits/entitlement_cubit_test.dart` — update calls with mode parameter
- `test/features/purchase/cubits/purchase_cubit_test.dart` — remove per-card loading and lastValidation assertions
- New: `test/features/app_operating_mode/widgets/mode_indicator_test.dart`

## Non-Goals

- Changing the cubit architecture (no merging PurchaseCubit + EntitlementCubit)
- Entitlement expiry countdown (subscriptions auto-renew)
- Purchase confirmation dialog (Apple handles this natively)
- Recovery key re-export (ultimate key is intentionally not stored)
