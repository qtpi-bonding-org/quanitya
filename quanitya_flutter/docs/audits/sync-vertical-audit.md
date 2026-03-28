# Sync Vertical Audit

## Summary

The sync vertical is broadly well-structured: public service/repo methods are wrapped in `tryMethod`, cubits extend `QuanityaCubit` and use `tryOperation`, and states implement `IUiFlowState`. However, several silent-catch blocks swallow errors without propagating them, `reconnectWithNewKeys()` bypasses the entitlement gate that `connect()` enforces, there are `!` operator usages in `PowerSyncRepository`, and the stream listener in `E2EEPuller` has no error handler — meaning decryption failures silently drop events rather than surfacing them. These gaps mean real-world sync failures can occur with no user feedback.

---

## Violations Found

### 1. Silent Catches / Errors Not Propagated

- [ ] **app_syncing_cubit.dart:48–50** — `_initialize()` swallows all exceptions with an empty `catch (e) {}`. If DB read or initial `connect()` fails at startup the cubit stays in `idle` status and the user sees nothing. **Rule violated:** Never fail silently — errors must propagate or be explicitly handled. **Fix:** Replace the empty catch with `emit(state.copyWith(status: UiFlowStatus.failure, error: e))` so `UiFlowListener` can surface a toast.

- [ ] **app_syncing_cubit.dart:83–92** — `_handleExternalModeChange()` catches errors and emits a failure state directly rather than going through `tryOperation`. This bypasses the `QuanityaCubit` error-normalisation path and the global exception mapper. **Rule violated:** Use `tryOperation` for all async work in cubits. **Fix:** Refactor `_handleExternalModeChange` as a `tryOperation` lambda so errors flow through the standard cubit error path.

- [ ] **e2ee_puller.dart:84–90** — `EncryptedTableProcessor.processEncryptedRecords()` catches per-record exceptions and calls `debugPrint` only, then continues. This means decryption failures for individual records are permanently silenced with no state update or counter. **Rule violated:** Never fail silently. **Fix:** At minimum, surface a count of failed records via the `E2EEPuller.getSyncStatus()` return value or emit an error event that `SyncStatusCubit` can observe.

- [ ] **e2ee_puller.dart:512–535** — `_startWatching()` sets up a `stream.listen()` with no `onError` handler. Any stream error (e.g., Drift query failure) will propagate as an unhandled exception and kill the subscription silently. **Rule violated:** Never fail silently — errors must propagate or be explicitly handled. **Fix:** Add `onError: (e, st) => debugPrint(...)` at minimum, or route errors to a state/event so they surface in the UI.

---

### 2. `!` Operator Usage

- [ ] **powersync_service.dart:148** — `await _powerSyncDb!.initialize()` uses `!` on `_powerSyncDb` which was just assigned on line 134. Although practically non-null here, the pattern breaks the "no `!`" rule and will throw an opaque `Null check operator used on a null value` if the assignment above ever throws mid-init and leaves `_powerSyncDb` null. **Rule violated:** Never use `!` operator — use explicit null checks with typed exceptions. **Fix:** Extract to a local `final db = _powerSyncDb; if (db == null) throw PowerSyncException(...)` pattern or use `requireNonNull`.

- [ ] **powersync_service.dart:151** — `await _powerSyncDb!.initialize()` in the recovery block (second SQLCipher failure path). Same issue as above. **Rule violated:** Same. **Fix:** Same local-variable pattern.

- [ ] **powersync_service.dart:159** — `await _powerSyncDb!.initialize()` — third occurrence, in fresh-key recovery path. **Rule violated:** Same. **Fix:** Same.

- [ ] **powersync_service.dart:163** — `AppDatabase(_powerSyncDb!)` — `_powerSyncDb` assigned just above, but same reasoning applies. **Rule violated:** Same. **Fix:** Same.

- [ ] **powersync_service.dart:184** — `await _powerSyncDb!.connect(connector: connector)` inside `connect()` after an early-return guard `if (_powerSyncDb == null) return`. The guard prevents the crash, but the `!` still violates the rule and the guard only silently returns (no exception thrown) when uninitialized — a second issue. **Rule violated:** No `!` operator; and the silent return on uninitialised state is itself a silent failure. **Fix:** Throw `PowerSyncException('PowerSync not initialized — call initialize() first')` in the null guard instead of returning, and use a local variable.

- [ ] **powersync_service.dart:194** — `await _powerSyncDb!.disconnect()` inside `disconnect()` after a `_isConnected` guard. Same silent-return + `!` problem. **Rule violated:** Same. **Fix:** Same pattern.

- [ ] **powersync_service.dart:202** — `return _powerSyncDb!.statusStream` in `statusStream` getter after an explicit null check that returns `Stream.empty()`. The code is logically safe, but the `!` still violates the rule. **Rule violated:** No `!` operator. **Fix:** Use a local variable.

- [ ] **e2ee_puller.dart:88, 103, 516, 527** — Multiple `(record as dynamic).updatedAt` and `(encrypted as dynamic).id` / `encryptedData` casts via `dynamic` then immediately property-accessed. These are implicit `!`-equivalent accesses: if the property is absent on the dynamic object, it throws `NoSuchMethodError` with no typed context. **Rule violated:** No `!` operator — use explicit null checks with typed exceptions. **Fix:** Define a typed interface or extract helper functions that return typed results and throw `SyncException` on missing fields.

---

### 3. Auth / Entitlement Gate Bypass in `reconnectWithNewKeys()`

- [ ] **sync_service.dart:140–158** — `reconnectWithNewKeys()` calls `_powerSync.connect(_client, mode)` directly, bypassing the `_authOrchestrator.ensureAuthenticated()` and `_entitlementRepo.hasSyncAccess()` checks that `connect()` enforces. If the session has expired or the entitlement has lapsed at key-rotation time, PowerSync will connect with an unauthenticated or unauthorised client. **Rule violated:** Sync mode transition must enforce auth/entitlement checks. **Fix:** Replace the direct `_powerSync.connect(...)` call with `await connect(mode)` (the full `SyncService.connect()` method).

---

### 4. Atomicity: Mode Persist vs Connection

- [ ] **sync_service.dart:108–121** — `switchMode()` persists the new mode to the database (`_syncRepo.updateMode(newMode)`) before the connection attempt succeeds. If `connect()` throws (e.g., no entitlement, network down), the persisted mode is now `cloud`/`selfHosted` but PowerSync is not connected. On next cold start, `AppSyncingCubit._initialize()` reads the persisted mode and tries to auto-connect, which may succeed or fail again — but the user saw a failure UI and may not realise the mode was already saved. **Rule violated:** Sync mode transition should be atomic (persist + connect/disconnect succeed together). **Fix:** Either roll back the persisted mode on `connect()` failure, or persist only after `connect()` succeeds.

---

### 5. `tryOperation` / `tryMethod` Missing on Public Methods

- [ ] **e2ee_puller.dart — `resetCheckpoints()`** — This public method on `IE2EEPuller` performs a database delete directly with no `tryMethod` wrapper. A Drift exception will propagate unwrapped as an untyped error. **Rule violated:** Wrap all public service/repo methods with `tryMethod`. **Fix:** Wrap the body in `tryMethod(() async { ... }, SyncException.new, 'resetCheckpoints')`.

- [ ] **e2ee_puller.dart — `getSyncStatus()`** — Public method on `IE2EEPuller` performs raw `customSelect` queries with no `tryMethod` wrapper. **Rule violated:** Same. **Fix:** Wrap body in `tryMethod`.

- [ ] **e2ee_puller.dart — `initialize()`** — Public interface method on `IE2EEPuller`. The outer `initialize()` body is not wrapped in `tryMethod`; internal failures propagate as untyped exceptions. **Rule violated:** Same. **Fix:** Wrap with `tryMethod`.

- [ ] **e2ee_puller.dart — `dispose()`** — Public method; subscription cancellations can throw; no `tryMethod`. **Rule violated:** Same. **Fix:** Wrap with `tryMethod`.

- [ ] **app_syncing_repository.dart — `watchSettings()`** — Returns a `Stream` computed via `asyncMap`. The `asyncMap` callback calls `_ensureInitialized()` which can throw, but stream errors are not caught/typed here. Since `watchSettings()` is public and used in the cubit's stream subscription, an error on first emission would surface as an unhandled stream error. **Rule violated:** Wrap all public service/repo methods with `tryMethod` (or equivalent stream error handling). **Fix:** Add `.handleError((e) => throw AppSyncingException('watchSettings failed', e))` on the returned stream, or wrap `_ensureInitialized()` calls in a typed try/catch inside the `asyncMap`.

---

### 6. `SyncStatusCubit` Manual State Management Around `tryOperation`

- [ ] **sync_status_cubit.dart:40–52** — `retrySync()` manually emits `isRetrying: true` before calling `tryOperation`, then in a `finally` block checks `if (state.isRetrying)` and re-emits. This is fragile: if `tryOperation` itself emits a loading state, `isRetrying` and the loading overlay can conflict. The `finally` guard `if (state.isRetrying)` also races — `tryOperation`'s success state emits synchronously from the lambda return, which sets a new state before the `finally` runs, making the guard evaluation order non-obvious. **Rule violated:** Use `tryOperation` for all async work; avoid manual state manipulation that partially duplicates `tryOperation` concerns. **Fix:** Drive `isRetrying` entirely from `tryOperation`'s `emitLoading` parameter or a dedicated state field set and cleared only within the `tryOperation` lambda, not manually outside it.

---

### 7. `_cachedEndpoint` Race in `_ServerpodConnector`

- [ ] **powersync_service.dart:241** — `_cachedEndpoint ??= endpoint` in `fetchCredentials()` caches the first endpoint seen and never updates it. If the user switches from cloud to selfHosted (or the backend URL rotates), the cached endpoint is stale and used for all subsequent credential fetches until the connector is recreated. The connector is only recreated on `connect()`, but `reconnectWithNewKeys()` reuses the existing `_powerSyncDb` connection (bypasses connector recreation). **Rule violated:** State can get out of sync between cubit state and PowerSync connection. **Fix:** Remove the cache (`_cachedEndpoint`) entirely and use the live `endpoint` from each `fetchCredentials()` call, since JWT fetches are already authenticated round-trips.

---

### 8. Network Offline / Online Transition Gaps

- [ ] **sync_service.dart:108–121** — `switchMode()` calls `_networkService.testConnection()` to gate mode switching, but `reconnect()` and `reconnectWithNewKeys()` do not test network reachability before attempting to connect. A retry called when the device is offline will call `_authOrchestrator.ensureAuthenticated()` and fail with a network error, surfacing a `SyncException`. While this is not silent, the failure message may be confusing ("connect failed") rather than "offline — try again when connected". **Note:** This is a UX concern rather than a hard rule violation, but worth addressing.

---

## Clean Files

The following files had no violations:

- `lib/features/app_syncing_mode/cubits/app_syncing_state.dart` — Correct `@freezed` + `IUiFlowState` + `UiFlowStateMixin` pattern; all fields properly defaulted.
- `lib/features/app_syncing_mode/cubits/app_syncing_message_mapper.dart` — Correct `IStateMessageMapper` implementation; returns `null` for errors (delegates to global mapper) as required.
- `lib/features/app_syncing_mode/models/app_syncing_mode.dart` — Clean enum with `supportsSync` predicate; uses `ILocalizationService` correctly.
- `lib/features/app_syncing_mode/exceptions/app_syncing_exceptions.dart` — Correct typed exception pattern.
- `lib/features/sync_status/cubits/sync_status_state.dart` — Correct `@freezed` + `IUiFlowState` implementation.
- `lib/features/sync_status/cubits/sync_status_message_mapper.dart` — Minimal and correct.
- `lib/features/sync_status/widgets/sync_status_indicator.dart` — Clean read-only widget; UI orchestrates retry via `context.read<SyncStatusCubit>().retrySync()`, no cubit-to-cubit calls.
- `lib/infrastructure/sync/sync_service.dart` — All public methods wrapped in `tryMethod`; no `!` operators; correct exception class. (See violation §3 for one auth-bypass concern specific to `reconnectWithNewKeys`.)
- `lib/features/app_syncing_mode/repositories/app_syncing_repository.dart` — All public `Future<>` methods wrapped in `tryMethod` with `AppSyncingException`. (See violation §5 for `watchSettings` stream edge case.)
