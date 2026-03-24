# Account Vertical Audit

## Summary

The account vertical is largely well-structured: services consistently use `tryMethod`, cubits use `tryOperation`, states implement `IUiFlowState`, and the exception chain (repository → service → cubit → UI) is intact for the majority of code paths. However, there are several violations concentrated in three areas: fire-and-forget calls in UI code, silent `catch` blocks in service methods, `!` operator usages, and two `loadLocalDeviceInfo` calls that bypass `tryOperation` entirely.

---

## Violations Found

### 1. Fire-and-Forget Async Calls

- [ ] **account_recovery_page.dart:334** — `context.read<RecoveryKeyCubit>().recoverAccount(...)` is called without `await` inside an `async` button callback. If `recoverAccount` throws (it shouldn't under normal `tryOperation` flow, but any unhandled re-throw would be a silent drop), the caller never observes the result. **Rule violated:** Never use fire-and-forget async calls. **Fix:** Add `await` before the `recoverAccount` call.

- [ ] **account_recovery_page.dart:108** — `await entitlementCubit.markPurchased()` and `await entitlementCubit.loadEntitlements()` are awaited inside a `BlocListener.listener` callback (which is `async`) — this is correct. However, `GetIt.instance<AppSyncingCubit>().recoverFromCloudSync()` at line 112 is also awaited but called on a raw `GetIt`-resolved cubit, not on a cubit from the widget tree. If the `AppSyncingCubit` instance was closed or replaced, the await resolves on a stale instance with no error. **Rule violated:** Cubits must not be called directly from other cubits or services; UI orchestrates via `BlocListener`. **Fix:** Inject `AppSyncingCubit` via `context.read<AppSyncingCubit>()` so the widget-tree-owned instance is used, guarded by `context.mounted`.

### 2. Silent Catch Blocks (Swallowed Errors)

- [ ] **account_service.dart:185–188** — Inside `createAccount()`, the cross-device key setup block catches all exceptions and only calls `debugPrint`, discarding the error entirely. The rule allows this for non-critical paths, but there is no typed exception or propagation to let calling code know cross-device setup failed. **Rule violated:** Never fail silently — errors must propagate or be explicitly handled. **Fix:** At minimum, re-throw a typed non-fatal signal (e.g., store a warning flag on the result) or document explicitly that this is a declared silent no-op with a `// ignore: silent_non_critical` comment keyed to the project's exception policy.

- [ ] **account_service.dart:339–343** — Inside `registerAccountWithServer()`, the cross-device key registration block catches all exceptions and only calls `debugPrint`. Same silent swallow issue as above on a network-touching operation. **Rule violated:** Never fail silently. **Fix:** Same as above — either propagate a non-fatal typed warning or document the deliberate silent policy.

### 3. `!` Operator Usages

- [ ] **account_service.dart:661** — `publicKeyHex: callerKeyHex!,` in `recoverFromCrossDeviceKey()`. `callerKeyHex` was fetched via `getDeviceSigningPublicKeyHex()` at line 653 and stored as `String?`. A null check was already performed at line 635 for `localKeyHex` (and `localDeviceKey`), but `callerKeyHex` is fetched a second time at line 653 after keys were stored and is forced with `!` without an explicit guard. If the key store has a transient failure between the two fetches, this crashes. **Rule violated:** Never use `!` — use explicit null checks with typed exceptions. **Fix:** Add `if (callerKeyHex == null) throw const AccountRecoveryException('Device key not available after generation');` before the call.

- [ ] **account_service.dart:722** — `publicKeyHex: cdCallerKeyHex!,` in `recreateCrossDeviceKey()`. Same pattern: `cdCallerKeyHex` from `getDeviceSigningPublicKeyHex()` at line 714 is typed `String?` and force-unwrapped. **Rule violated:** Never use `!`. **Fix:** Add `if (cdCallerKeyHex == null) throw const AuthException('Device signing key not available');` before the call.

- [ ] **account_service.dart:774** — `publicKeyHex: pubKeyHex!,` in `listDevices()`. `pubKeyHex` is typed `String?` from line 768 and force-unwrapped. **Rule violated:** Never use `!`. **Fix:** Add `if (pubKeyHex == null) throw AuthException('Device public key not available', kind: AuthFailure.general);` before the call.

- [ ] **account_service.dart:800** — `publicKeyHex: pubKeyHex!,` in `revokeDevice()`. Same pattern. **Rule violated:** Never use `!`. **Fix:** Add a null guard before the server call.

### 4. `loadLocalDeviceInfo` Bypasses `tryOperation`

- [ ] **device_management_cubit.dart:116–123** — `loadLocalDeviceInfo()` calls `_deviceInfoService.getDeviceName()` and `_keyRepository.hasExistingKeys()` outside of `tryOperation`, then emits via a bare `emit(...)`. If either call throws, the exception propagates unhandled out of the cubit's public method — it is not caught, not placed in `state.error`, and not shown to the user via `UiFlowListener`. **Rule violated:** Use `tryOperation` for all async work in cubits; errors must propagate through state. **Fix:** Wrap the body of `loadLocalDeviceInfo` in `tryOperation(() async { ... })`.

### 5. `checkExistingAccount` Bypasses `tryOperation`

- [ ] **onboarding_cubit.dart:43–46** — `checkExistingAccount()` is a public async method that calls `_keyRepository.getKeyStatus()` without `tryOperation`. If the repository throws, the exception escapes the cubit as an unhandled future rejection, bypassing the cubit's error state. **Rule violated:** Use `tryOperation` for all async work in cubits. **Fix:** Wrap with `tryOperation`; return `false` on failure (or bubble the error into state).

### 6. `initBackupPage` Bypasses `tryOperation`

- [ ] **onboarding_cubit.dart:49–52** — `initBackupPage()` calls `_localAuthService.isDeviceAuthAvailable()` and then `emit(...)` directly without `tryOperation`. Any platform exception from `isDeviceAuthAvailable` escapes unhandled. **Rule violated:** Use `tryOperation` for all async work in cubits. **Fix:** Wrap with `tryOperation`.

### 7. Partial Cleanup in `deleteAccount` (DeleteService)

- [ ] **delete_service.dart:64–90** — `deleteAccount()` does not call `_keyRepository.clearKeys()` or `_authRepo.deleteRegistrationPayload()`. After server deletion, the device's cryptographic keys (device key, symmetric key) and the stored registration payload remain in secure storage. A future `factoryReset` call would clear them, but if the user installs fresh from the App Store after account deletion, neither cleanup is triggered. **Rule violated:** Account deletion must clean up all local state. **Fix:** Add `await _keyRepository.clearKeys()` and `await _authRepo.deleteRegistrationPayload()` after clearing the registration flag in `deleteAccount`.

### 8. Multi-Step Recovery Not Atomic — Symmetric Key Stored After Device Registration

- [ ] **account_service.dart:483** — In `recoverAccount()`, the symmetric key is stored locally (step 8) only after the device has been registered with the server (step 7). If `storeSymmetricDataKeyJwk` fails after `registerDevice` succeeds, the server has a registered device but the device has no symmetric key locally — the account is in a broken state with no way to recover without a second recovery attempt. **Rule violated:** Multi-step operations should be atomic or ordered to allow safe retry. **Fix:** Reorder: store the symmetric key locally before registering the device on the server, so a crash before server registration leaves the device in a clean, retryable state. Or wrap both in a compensating action.

- [ ] **account_service.dart:669** — Same issue in `recoverFromCrossDeviceKey()`: `storeSymmetricDataKeyJwk` at line 669 comes after `registerDeviceForAccount` at line 658. Same broken-state risk if the store step fails. **Fix:** Same reordering recommendation as above.

### 9. `ensureRegistered` Not Wrapped in `tryMethod`

- [ ] **account_service.dart:357–360** — `ensureRegistered()` is a public method that calls `_authRepo.isRegisteredWithServer` and `registerAccountWithServer(...)` but has no `tryMethod` wrapper of its own. If `isRegisteredWithServer` throws an `AuthRepositoryException`, it propagates unwrapped (not converted to `AccountCreationException`). Callers in `AuthAccountOrchestrator` catch `DeviceAuthenticationException` specifically, so a repository exception here would slip past that catch. **Rule violated:** All public service/repo methods must be wrapped with `tryMethod`. **Fix:** Wrap the body of `ensureRegistered` with `tryMethod(..., (msg, [c]) => AccountCreationException(msg, cause: c), 'ensureRegistered')`.

### 10. `clearUltimateKeySession` Is a Synchronous Public Method Without Error Handling

- [ ] **account_service.dart:750–752** — `clearUltimateKeySession()` is `void` (synchronous) and delegates directly to `_keyRepository.clearTemporaryUltimateKey()`. If the repository implementation throws synchronously (e.g., platform storage error), it propagates out of the cubit that calls it without any error path. Since there is no `tryMethod` variant for synchronous void methods, this should at minimum have a try/catch that logs the failure. **Rule violated:** Never fail silently; errors must propagate or be explicitly handled. **Fix:** Wrap the body in a `try/catch` that either re-throws a typed `AuthException` or records the failure in cubit state.

### 11. UI Widget Uses Raw `GetIt` to Resolve Cubits Mid-Listener

- [ ] **account_recovery_page.dart:107–112** — Inside the `BlocListener.listener`, `GetIt.instance<EntitlementCubit>()` and `GetIt.instance<AppSyncingCubit>()` are resolved directly and their methods are `await`-ed. These cubit operations run outside any cubit's `tryOperation`, so any exception they throw will be an unhandled error in the listener callback — it is not caught by `UiFlowListener`, will not trigger a toast, and may appear as an unhandled future error in Flutter's error handler. **Rule violated:** Errors must propagate through state → `UiFlowListener` → `PostItToast`. **Fix:** Either use `context.read<T>()` for cubits already in the tree, or wrap the listener body in a try/catch that dispatches a failure state or shows a toast manually.

---

## Clean Files

The following files have no violations and comply with all documented patterns:

- `lib/infrastructure/auth/auth_repository.dart` — All public methods wrapped in `tryMethod`, no `!` operators, no silent catches.
- `lib/infrastructure/auth/registration_payload.dart` — Pure data model; no async operations, no control flow issues.
- `lib/infrastructure/auth/auth_service.dart` — All public methods wrapped in `tryMethod`, null checks are explicit, error propagation is intact.
- `lib/infrastructure/auth/local_auth_service.dart` — All public methods wrapped in `tryMethod`; the inner `PlatformException` catch maps to typed result values (not silent drops) and does not escape `tryMethod`.
- `lib/features/settings/cubits/device_management/device_management_state.dart` — Correct `@freezed` + `IUiFlowState` + `UiFlowStateMixin` implementation.
- `lib/features/settings/cubits/device_management/device_management_message_mapper.dart` — Correct `IStateMessageMapper` implementation; returns `null` for errors to delegate to global mapper.
- `lib/features/settings/cubits/recovery_key/recovery_key_state.dart` — Correct state implementation.
- `lib/features/settings/cubits/recovery_key/recovery_key_cubit.dart` — All operations use `tryOperation`; no cubit-to-cubit calls; no `!` operators.
- `lib/features/settings/cubits/recovery_key/recovery_key_message_mapper.dart` — Correct mapper implementation.
- `lib/features/onboarding/services/onboarding_message_mapper.dart` — Correct mapper; exhaustive switch over `OnboardingOperation`.
- `lib/features/onboarding/cubits/onboarding_state.dart` — Correct `@freezed` + `IUiFlowState` implementation.
- `lib/features/onboarding/pages/connect_device_page.dart` — Pure navigation widget; no async operations.
- `lib/infrastructure/auth/auth_account_orchestrator.dart` — Wraps with `tryMethod`; the inner `on DeviceAuthenticationException` catch is intentional retry logic, not a silent swallow.
