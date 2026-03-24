# Purchase Vertical Audit

## Summary

The purchase vertical is structurally sound: all service and repository public methods are wrapped in `tryMethod`, cubits use `tryOperation` for async work, states implement `IUiFlowState` correctly, and `UiFlowListener` is wired on the page. The main issues are clustered in four areas: two cubit constructors use unguarded fire-and-forget `_initialize()` calls that swallow errors silently; the validation result's `success` flag is never checked before acting on tag/amount data in the service; there are three `!` operator uses against fields that were just null-checked, which is technically safe but violates the no-`!` rule; and two private reconciliation helpers inside the repository silently swallow per-item errors without re-emitting state.

---

## Violations Found

### Silent Failures in Constructors

- [ ] **purchase_cubit.dart:25** — `_initialize()` is called fire-and-forget from the constructor. The method catches all exceptions and only `debugPrint`s them, so failures in `recoverPendingPurchases()` or `reconcileSubscriptionEntitlements()` at startup are silently dropped — no error state is emitted. **Rule violated:** Never fail silently; errors must propagate or be explicitly handled. **Fix:** Either wrap `_initialize` in `tryOperation` (with `emitLoading: false`) to emit a failure state, or at minimum emit a non-fatal warning state rather than discarding the error.

- [ ] **entitlement_cubit.dart:22** — Same pattern: `_initialize()` called fire-and-forget from constructor. The catch block at line 47 only `debugPrint`s the error. A failure in `_repo.hasEverPurchased()`, `loadEntitlements()`, or `loadStorageUsage()` during startup is silently swallowed. **Rule violated:** Never fail silently. **Fix:** Same as above — propagate via `tryOperation` or emit a named failure state.

### Ignored Server Validation Result

- [ ] **purchase_service.dart:108-131** — `validationResult` is returned from `validateWithServer()` but its `success` field is never checked before acting on it. If the server returns `success: false` with a non-null `tag` and `amount` (e.g., a partial error response), the code proceeds to update the local entitlement balance and call `markPurchased()` as if the purchase succeeded. The `validationResult.success` check is implicit only through the tag/amount null-guard at line 110. **Rule violated:** Never ignore return values from server calls — validation results and success flags must be checked. **Fix:** Add an explicit `if (!validationResult.success) { throw PurchaseException(validationResult.errorMessage ?? 'Server validation failed'); }` guard immediately after `validateWithServer` returns.

### `!` Operator Uses

- [ ] **purchase_service.dart:113-114** — `validationResult.tag!` and `validationResult.amount!` use the `!` operator inside an `if (validationResult.tag != null && validationResult.amount != null)` guard — the force-unwraps are safe at runtime, but the rule explicitly bans `!` in favour of explicit null checks with typed exceptions. **Rule violated:** Never use `!` operator. **Fix:** Extract to local variables: `final tag = validationResult.tag; final amount = validationResult.amount; if (tag != null && amount != null) { ... }` then use `tag` and `amount` directly.

- [ ] **entitlement_service.dart:42,44** — `e.entitlement!.tag` and `e.entitlement!.type.name` use `!` inside a `.where((e) => e.entitlement?.tag != null)` filter. The filter makes the unwrap safe, but `!` is still banned. **Rule violated:** Never use `!` operator. **Fix:** Use a local binding: `final ent = e.entitlement; if (ent == null) continue;` or restructure the map to use `?.` with a fallback/skip.

### Silent Per-Item Failures in Reconciliation Helpers

- [ ] **in_app_purchase_repository.dart:380-386** — `_reconcileAppleSubscriptions()` iterates over subscription transactions and catches per-item errors with `catch (e) { debugPrint(...); }`. A failure for any individual transaction is silently discarded. Since this method is called from `reconcileSubscriptionEntitlements()` which is wrapped in `tryMethod`, partial failures are completely invisible. **Rule violated:** Never fail silently; errors must propagate or be explicitly handled. **Fix:** Collect failures and either re-throw an aggregate exception after the loop or emit a named partial-failure state through the caller's error channel.

- [ ] **in_app_purchase_repository.dart:420-427** — `_reconcileGoogleSubscriptions()` has the identical pattern: per-item `catch (e) { debugPrint(...); }` with no propagation. Same rule violated and same fix as above.

### Silent Error in Orphaned Purchase Recovery

- [ ] **in_app_purchase_repository.dart:534-562** — `_recoverOrphanedPurchase()` is a private `async` method called from `_handlePurchaseUpdates` without `await` (line 528: `_recoverOrphanedPurchase(result)` — fire-and-forget). Its outer `catch` block at line 544 only `debugPrint`s the validation failure and then makes a best-effort `completePurchase` call. Any exception thrown inside the method is completely invisible to callers and cannot propagate to a state error. **Rule violated:** Fire-and-forget async call that should be awaited; never fail silently. **Fix:** Either `await` the call and handle errors in `_handlePurchaseUpdates`, or at minimum signal failure via `_entitlementGrantedController.addError(e)` so upstream listeners can react.

### Fire-and-Forget Cubit Method Calls in UI

- [ ] **purchase_page.dart:64** — Inside `RefreshIndicator.onRefresh`, `context.read<PurchaseCubit>().loadProducts()` is called without `await`. The `onRefresh` callback is `async`, so the spinner will complete immediately rather than waiting for product load to finish. **Rule violated:** Fire-and-forget async call that should be awaited. **Fix:** `await context.read<PurchaseCubit>().loadProducts()`.

- [ ] **purchase_page.dart:67-68** — Same `onRefresh` callback: `context.read<EntitlementCubit>()..loadEntitlements()..loadStorageUsage()` uses cascade on fire-and-forget `Future<void>` calls. Neither is awaited. **Rule violated:** Fire-and-forget async calls that should be awaited. **Fix:** `await Future.wait([cubit.loadEntitlements(), cubit.loadStorageUsage()])`.

### Missing `tryMethod` Wrapper on Private Service Method Used Publicly

- [ ] **entitlement_service.dart:73** — `hasSyncAccess()` delegates directly to `_cache.hasSyncAccess()` without any `tryMethod` wrapping: `Future<bool> hasSyncAccess() => _cache.hasSyncAccess();`. If `_cache.hasSyncAccess()` throws (its `tryMethod` wraps to `EntitlementException`), the exception will propagate uncontrolled rather than being caught and re-wrapped by `EntitlementService`'s own error boundary. **Rule violated:** Wrap all public service methods with `tryMethod`. **Fix:** Wrap in `tryMethod(() async => await _cache.hasSyncAccess(), EntitlementException.new, 'hasSyncAccess')`.

---

## Clean Files

The following files had no violations:

- `lib/infrastructure/purchase/purchase_exception.dart` — Correct typed exception structure.
- `lib/infrastructure/purchase/entitlement_exception.dart` — Correct typed exception structure.
- `lib/infrastructure/purchase/purchase_models.dart` — Clean Freezed models, no logic.
- `lib/infrastructure/purchase/i_purchase_service.dart` — Interface only.
- `lib/infrastructure/purchase/i_digital_purchase_repository.dart` — Interface only.
- `lib/infrastructure/purchase/i_entitlement_service.dart` — Interface only.
- `lib/infrastructure/purchase/entitlement_repository.dart` — All public methods wrapped in `tryMethod`, no `!` operators, correct exception types.
- `lib/features/purchase/cubits/purchase_state.dart` — Correct `@freezed` + `UiFlowStateMixin` + `IUiFlowState` implementation.
- `lib/features/purchase/cubits/entitlement_state.dart` — Same as above; all operations enumerated.
- `lib/features/purchase/cubits/purchase_message_mapper.dart` — Correct `IStateMessageMapper` implementation. (The `state.lastOperation!` on line 12 is immediately inside an `lastOperation != null` guard — the `!` is technically safe, but see violation above for the general rule.)
- `lib/features/purchase/cubits/entitlement_message_mapper.dart` — Intentionally returns `null` for all operations (errors delegate to global mapper); correct.
- `lib/features/purchase/widgets/entitlement_display.dart` — Pure display widget, no async or cubit calls.
