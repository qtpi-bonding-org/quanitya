# Entitlement Vertical Audit

## Summary

The entitlement vertical is structurally sound: every public repository and service method is wrapped in `tryMethod`, states implement `IUiFlowState`, cubits extend `QuanityaCubit`, and the exception chain (`EntitlementException`/`PurchaseException` → global mapper) is properly registered. Five concrete violations exist, spanning two silent-catch blocks that swallow initialization errors, two `!` null-assertion operators on fields already guarded by a `?.` null-check, fire-and-forget cubit calls in the `RefreshIndicator`, and a minor race-condition window in `refreshIfStale`.

---

## Violations Found

### 1. Silent Catches (Errors Swallowed Without State Emission)

- [ ] **entitlement_cubit.dart:47–49** — `_initialize()` catches all errors with `debugPrint` only; no error state is emitted. If `loadEntitlements()` or `loadStorageUsage()` fails during init the UI has no way to know (no toast, no retry button). **Rule violated:** Never fail silently — errors must propagate or be explicitly handled. **Fix:** Remove the `try/catch` wrapper and let `tryOperation` handle the error state, or emit a dedicated `EntitlementOperation.initialize` failure state.

- [ ] **purchase_cubit.dart:33–35** — `PurchaseCubit._initialize()` catches all errors with `debugPrint` only; `recoverPendingPurchases()` and `reconcileSubscriptionEntitlements()` failures are silently swallowed. **Rule violated:** Never fail silently — errors must propagate or be explicitly handled. **Fix:** Same pattern — remove the bare catch or emit a failure state so `UiFlowListener` can surface a toast.

### 2. Null-Assertion (`!`) Operator on Already-Null-Checked Fields

- [ ] **entitlement_service.dart:42** — `e.entitlement!.tag` uses `!` immediately after the `.where` guard `e.entitlement?.tag != null`. The `!` is safe logically but violates the "never use `!`" rule; the compiler has no way to prove the chain from the lambda is maintained across the `map`. **Rule violated:** Never use the `!` operator — use explicit null checks with typed exceptions. **Fix:** Use a local variable: `final ent = e.entitlement; if (ent == null) continue;` before building `CachedEntitlement`, eliminating both bangs on line 42 and 44.

- [ ] **entitlement_service.dart:44** — `e.entitlement!.type.name` — same issue as above, second `!` in the same `map` lambda. **Rule violated:** Never use the `!` operator. **Fix:** Covered by the same local-variable fix described for line 42.

- [ ] **purchase_service.dart:113–114** — `validationResult.tag!` and `validationResult.amount!` are used inside an `if (validationResult.tag != null && validationResult.amount != null)` guard, but the `!` assertions are still present. **Rule violated:** Never use the `!` operator. **Fix:** Extract locals: `final tag = validationResult.tag; final amount = validationResult.amount;` before the `if`, then use the non-null locals inside.

- [ ] **entitlement_cubit.dart:124** — `_lastRefresh!` is used inside an `if (_lastRefresh != null && ...)` guard. Logically safe, but violates the rule. **Rule violated:** Never use the `!` operator. **Fix:** Extract `final lastRefresh = _lastRefresh; if (lastRefresh != null && now.difference(lastRefresh).inSeconds < 60)`.

### 3. Fire-and-Forget Async Calls (Unawaited Futures in UI)

- [ ] **purchase_page.dart:58–60** — In the `BlocListener` callback, `..loadEntitlements()` and `..loadStorageUsage()` are called via cascade on `EntitlementCubit` but neither is `await`ed. Since the listener callback is not `async`, the returned futures are silently discarded. If either call throws before `tryOperation` catches it, the error is dropped with no state emission. **Rule violated:** Never ignore return values from async calls; fire-and-forget async calls that should be awaited. **Fix:** Mark the listener callback `async` and `await` each call in sequence, or combine into a single dedicated cubit method.

- [ ] **purchase_page.dart:64–69** — The `RefreshIndicator.onRefresh` callback is `async` but calls `context.read<PurchaseCubit>().loadProducts()`, `context.read<EntitlementCubit>().loadEntitlements()`, and `context.read<EntitlementCubit>().loadStorageUsage()` without `await`. The refresh indicator will complete its spinner immediately without waiting for any of the loads to finish, giving misleading UI feedback. **Rule violated:** Never ignore return values from async server calls. **Fix:** `await` each call inside `onRefresh`.

### 4. Race Condition / Concurrency Gap

- [ ] **entitlement_cubit.dart:119–143** — `refreshIfStale()` uses a plain `bool _isRefreshing` flag to prevent concurrent calls. However, `_isRefreshing = true` is set synchronously before the first `await`, but a caller that accesses this method concurrently from two separate `await` points (e.g., app-resume event fires twice before the first `tryOperation` starts) could pass the guard. The flag is also a raw field without synchronisation, which is not an issue in single-threaded Dart but is a documentation/intent gap. More critically, if `tryOperation` itself is already queuing state changes, a second unguarded call via `loadEntitlements()` (not debounced) can race against `refreshIfStale`. **Rule violated:** Potential race condition from concurrent calls to the same method. **Fix:** Combine the debounce flag into the `tryOperation` return value or use a `Completer`-based guard; at minimum document that `loadEntitlements` is not debounced and can run concurrently with `refreshIfStale`.

### 5. Cache Consistency — Non-Atomic Read-Modify-Write

- [ ] **entitlement_repository.dart:103–135** — `updateBalance()` does a read (`load()`) followed by a write (`store()`). These are two separate `SecurePreferences` calls with no transaction or lock. Concurrent callers (e.g., `purchase()` and a background reconcile arriving simultaneously) can interleave reads and writes, causing one write to silently clobber the other's changes. **Rule violated:** Cache must be updated atomically. **Fix:** Introduce a lock (e.g., `package:synchronized`) around the read-modify-write in `updateBalance`, or ensure all callers are serialised at the service layer.

### 6. Ignored Return Value from Server Call

- [ ] **purchase_cubit.dart:57–65** — `PurchaseCubit.purchase()` calls `_purchaseService.purchase(...)`, which returns `PurchaseValidationResult`. The return value is completely ignored (`await _purchaseService.purchase(request, mode: mode)`); the cubit emits success without inspecting the validation result. If `validationResult.tag` is null (incomplete server response), the cubit still emits `UiFlowStatus.success`. The partial-data path in `PurchaseService.purchase` only logs a `debugPrint`; nothing surfaces to the user. **Rule violated:** Never ignore return values from server calls — validation results and success flags must be checked. **Fix:** Capture the result and inspect `validationResult.tag`; emit a distinct `lastOperation` or pass the result to state so the UI can distinguish "purchase validated with entitlement" from "purchase accepted but entitlement data incomplete".

---

## Clean Files

- `lib/infrastructure/purchase/entitlement_exception.dart` — Correct domain exception shape; no violations.
- `lib/infrastructure/purchase/i_entitlement_service.dart` — Interface only; no violations.
- `lib/infrastructure/purchase/i_digital_purchase_repository.dart` — Interface only; no violations.
- `lib/infrastructure/purchase/i_purchase_service.dart` — Interface only; no violations.
- `lib/infrastructure/purchase/purchase_exception.dart` — Correct domain exception shape; no violations.
- `lib/infrastructure/purchase/entitlement_repository.dart` — All public methods wrapped in `tryMethod`; exception chain correct. (One non-atomic read-modify-write noted above under Cache Consistency.)
- `lib/features/purchase/cubits/entitlement_state.dart` — Correctly implements `IUiFlowState` with `UiFlowStateMixin`; all fields typed; `@freezed` applied correctly.
- `lib/features/purchase/cubits/purchase_state.dart` — Same as above; no violations.
- `lib/features/purchase/cubits/entitlement_message_mapper.dart` — Intentional `return null` (all operations are silent loads) is acceptable; errors correctly delegated to global mapper.
- `lib/features/purchase/cubits/purchase_message_mapper.dart` — Correct success-only mapping; error delegation to global mapper is correct.
- `lib/features/purchase/widgets/entitlement_display.dart` — Pure display widget; no state management or async; no violations.
- `lib/infrastructure/purchase/entitlement_service.dart` — All public methods wrapped in `tryMethod` (except the `!` violations noted above).
- `lib/infrastructure/purchase/purchase_service.dart` — All public methods wrapped in `tryMethod` (except the `!` violations and the partial-result log noted above).
